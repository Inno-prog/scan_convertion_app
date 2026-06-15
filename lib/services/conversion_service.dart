import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

class ConversionService {
  Future<String> convertFile({
    required String filePath,
    required String outputFormat,
    required Function(double) onProgress,
    Uint8List? fileBytes,
  }) async {
    String actualInputPath = filePath;
    
    // Si le fichier n'existe pas et que nous avons les bytes, créer un fichier temp
    final file = File(filePath);
    if (!file.existsSync()) {
      if (fileBytes == null) {
        throw Exception('Fichier introuvable: $filePath');
      }
      final tmpDir = await getTemporaryDirectory();
      final safeName = filePath.split('/').last;
      final tmpPath = '${tmpDir.path}/${DateTime.now().millisecondsSinceEpoch}_$safeName';
      await File(tmpPath).writeAsBytes(fileBytes);
      actualInputPath = tmpPath;
    }

    final fileName = actualInputPath.split('/').last;
    final baseName = fileName.contains('.')
        ? fileName.substring(0, fileName.lastIndexOf('.'))
        : fileName;
    final inputExt = fileName.contains('.')
        ? fileName.split('.').last.toLowerCase()
        : '';

    final dir = await getTemporaryDirectory();
    // Nom unique avec timestamp pour éviter les conflits
    final ts = DateTime.now().millisecondsSinceEpoch;
    final outputPath = '$dir/${baseName}_$ts.$outputFormat';

    onProgress(0.1);

    // Image → PDF (via package pdf)
    if (_isImage(inputExt) && outputFormat == 'pdf') {
      await _convertImageToPdf(actualInputPath, outputPath, onProgress);
      return outputPath;
    }

    // Images → images (via package image)
    if (_isImage(inputExt) && _isImage(outputFormat)) {
      await _convertImage(actualInputPath, outputPath, outputFormat, onProgress);
      return outputPath;
    }

    // Tout le reste → FFmpeg (audio, vidéo, image→webp, etc.)
    if (_isAudio(inputExt) || _isVideo(inputExt) ||
        _isAudio(outputFormat) || _isVideo(outputFormat) ||
        (_isImage(inputExt) && outputFormat == 'webp') ||
        (_isImage(outputFormat) && !_isImage(inputExt))) {
      await _convertWithFFmpeg(actualInputPath, outputPath, inputExt, outputFormat, onProgress);
      return outputPath;
    }

    // Documents texte
    if (_isTextDoc(inputExt) && _isTextDoc(outputFormat)) {
      await _convertTextDoc(actualInputPath, outputPath, inputExt, outputFormat, onProgress);
      return outputPath;
    }

    // Fallback : copie simple
    onProgress(0.5);
    await File(actualInputPath).copy(outputPath);
    onProgress(1.0);
    return outputPath;
  }

  // ── Image → PDF (package pdf) ──────────────────────────────────────────

  Future<void> _convertImageToPdf(
    String inputPath,
    String outputPath,
    Function(double) onProgress,
  ) async {
    onProgress(0.2);
    final bytes = await File(inputPath).readAsBytes();
    onProgress(0.4);
    final decoded = img.decodeImage(bytes);
    if (decoded == null) throw Exception('Impossible de décoder l\'image');
    final pngBytes = img.encodePng(decoded);
    onProgress(0.6);
    final pdf = pw.Document();
    final pdfImage = pw.MemoryImage(pngBytes);
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat(
        decoded.width.toDouble(),
        decoded.height.toDouble(),
      ),
      build: (ctx) => pw.Image(pdfImage, fit: pw.BoxFit.contain),
    ));
    onProgress(0.9);
    await File(outputPath).writeAsBytes(await pdf.save());
    onProgress(1.0);
  }

  // ── Image → Image (package image) ────────────────────────────────────────

  Future<void> _convertImage(
    String inputPath,
    String outputPath,
    String outputFormat,
    Function(double) onProgress,
  ) async {
    onProgress(0.2);
    final bytes = await File(inputPath).readAsBytes();
    onProgress(0.4);

    final decoded = img.decodeImage(bytes);
    if (decoded == null) throw Exception('Impossible de décoder l\'image');

    onProgress(0.65);
    Uint8List encoded;

    switch (outputFormat.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        encoded = img.encodeJpg(decoded, quality: 90);
        break;
      case 'png':
        encoded = img.encodePng(decoded);
        break;
      case 'bmp':
        encoded = img.encodeBmp(decoded);
        break;
      case 'gif':
        encoded = img.encodeGif(decoded);
        break;
      case 'tiff':
      case 'tif':
        encoded = img.encodeTiff(decoded);
        break;
      default:
        encoded = img.encodePng(decoded);
    }

    onProgress(0.9);
    await File(outputPath).writeAsBytes(encoded);
    onProgress(1.0);
  }

  // ── FFmpeg ────────────────────────────────────────────────────────────────

  Future<void> _convertWithFFmpeg(
    String inputPath,
    String outputPath,
    String inputExt,
    String outputFormat,
    Function(double) onProgress,
  ) async {
    onProgress(0.2);

    // Vérifier que le fichier d'entrée existe
    final inputFile = File(inputPath);
    if (!inputFile.existsSync()) {
      throw Exception('Fichier source introuvable pour FFmpeg: $inputPath');
    }

    final args = _buildArgs(inputPath, outputPath, inputExt, outputFormat);
    onProgress(0.3);

    final session = await FFmpegKit.execute(args);
    final returnCode = await session.getReturnCode();
    onProgress(0.9);

    if (!ReturnCode.isSuccess(returnCode)) {
      final logs = await session.getAllLogsAsString() ?? '';
      // Extraire le message d'erreur pertinent
      final lines = logs.split('\n').where((l) => l.contains('Error') || l.contains('error') || l.contains('Invalid')).toList();
      final msg = lines.isNotEmpty ? lines.last : logs.substring(0, logs.length.clamp(0, 200));
      throw Exception(msg.isEmpty ? 'Conversion échouée (code $returnCode)' : msg);
    }

    if (!File(outputPath).existsSync()) {
      throw Exception('Fichier de sortie non généré');
    }

    onProgress(1.0);
  }

  String _buildArgs(String input, String output, String inputExt, String format) {
    final i = '"$input"';
    final o = '"$output"';
    switch (format.toLowerCase()) {
      // ── Audio ──
      case 'mp3':
        return '-i $i -vn -acodec libmp3lame -q:a 2 -y $o';
      case 'aac':
        return '-i $i -vn -acodec aac -b:a 192k -y $o';
      case 'wav':
        return '-i $i -vn -acodec pcm_s16le -y $o';
      case 'flac':
        return '-i $i -vn -acodec flac -y $o';
      case 'ogg':
        return '-i $i -vn -acodec libvorbis -q:a 4 -y $o';
      case 'm4a':
        return '-i $i -vn -acodec aac -b:a 192k -movflags +faststart -y $o';
      // ── Vidéo ──
      case 'mp4':
        return '-i $i -vcodec libx264 -acodec aac -preset ultrafast -crf 28 -y $o';
      case 'avi':
        return '-i $i -vcodec mpeg4 -acodec libmp3lame -y $o';
      case 'mov':
        return '-i $i -vcodec libx264 -acodec aac -y $o';
      case 'mkv':
        return '-i $i -vcodec libx264 -acodec aac -y $o';
      case 'webm':
        return '-i $i -vcodec libvpx -acodec libvorbis -y $o';
      case 'gif':
        if (_isVideo(inputExt)) {
          return '-i $i -vf fps=8,scale=320:-1:flags=lanczos -loop 0 -y $o';
        }
        return '-i $i -y $o';
      // ── Image via FFmpeg ──
      case 'webp':
        return '-i $i -vframes 1 -q:v 75 -y $o';
      case 'pdf':
        return '-i $i -y $o';
      // ── Extraction audio depuis vidéo ──
      default:
        if (_isVideo(inputExt) && _isAudio(format)) {
          return '-i $i -vn -y $o';
        }
        return '-i $i -y $o';
    }
  }

  // ── Texte ─────────────────────────────────────────────────────────────────

  Future<void> _convertTextDoc(
    String inputPath,
    String outputPath,
    String inputExt,
    String outputFormat,
    Function(double) onProgress,
  ) async {
    onProgress(0.3);
    final content = await File(inputPath).readAsString();
    onProgress(0.6);

    String result;
    switch (outputFormat.toLowerCase()) {
      case 'html':
        result = '<!DOCTYPE html><html><head><meta charset="UTF-8"></head><body><pre>${_escHtml(content)}</pre></body></html>';
        break;
      case 'txt':
        result = inputExt == 'html' ? content.replaceAll(RegExp(r'<[^>]*>'), '') : content;
        break;
      case 'csv':
        result = content.split('\n').map((l) => '"${l.replaceAll('"', '""')}"').join('\n');
        break;
      default:
        result = content;
    }

    onProgress(0.9);
    await File(outputPath).writeAsString(result, encoding: const Utf8Codec());
    onProgress(1.0);
  }

  String _escHtml(String t) => t
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');

  // ── Helpers ───────────────────────────────────────────────────────────────

  bool _isImage(String ext) => const {
    'jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'tiff', 'tif', 'heic'
  }.contains(ext.toLowerCase());

  bool _isAudio(String ext) => const {
    'mp3', 'wav', 'flac', 'aac', 'ogg', 'm4a', 'wma', 'opus'
  }.contains(ext.toLowerCase());

  bool _isVideo(String ext) => const {
    'mp4', 'avi', 'mov', 'mkv', 'wmv', 'flv', 'webm', 'm4v', '3gp'
  }.contains(ext.toLowerCase());

  bool _isTextDoc(String ext) => const {
    'txt', 'html', 'htm', 'csv', 'md'
  }.contains(ext.toLowerCase());
}
