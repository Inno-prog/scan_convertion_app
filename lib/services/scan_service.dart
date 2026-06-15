import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:convert';
import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/scan_record.dart';

class ScanService {
  static ScanService? _instance;
  static const _scansKey = 'scan_history';

  ScanService._();

  static Future<ScanService> getInstance() async {
    _instance ??= ScanService._();
    return _instance!;
  }

  Future<String> _getScansDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final scansDir = Directory('${dir.path}/scans');
    if (!await scansDir.exists()) {
      await scansDir.create(recursive: true);
    }
    return scansDir.path;
  }

  Future<List<ScanRecord>> getScanHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_scansKey) ?? [];
    return raw.map((e) => ScanRecord.fromJson(jsonDecode(e))).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> addScanRecord(ScanRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_scansKey) ?? [];
    final list = raw.map((e) => ScanRecord.fromJson(jsonDecode(e))).toList();
    list.insert(0, record);
    final trimmed = list.take(100).toList();
    await prefs.setStringList(
      _scansKey,
      trimmed.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }

  Future<void> deleteScanRecord(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_scansKey) ?? [];
    final list = raw.map((e) => ScanRecord.fromJson(jsonDecode(e))).toList();
    final filtered = list.where((r) => r.id != id).toList();
    await prefs.setStringList(
      _scansKey,
      filtered.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }

  Future<void> clearScanHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_scansKey);
  }

  Future<String> createPdfFromImages(
    List<String> imagePaths, {
    void Function(double)? onProgress,
    bool applyAutoCrop = false,
  }) async {
    final scansDir = await _getScansDir();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'scan_$timestamp.pdf';
    final outputPath = '$scansDir/$fileName';

    final pdf = pw.Document();

    for (var i = 0; i < imagePaths.length; i++) {
      onProgress?.call((i + 1) / (imagePaths.length + 1));

      final imageFile = File(imagePaths[i]);
      final bytes = await imageFile.readAsBytes();

      final decoded = img.decodeImage(bytes);
      if (decoded == null) continue;

      final finalImage = applyAutoCrop ? _autoCropDocument(decoded) : decoded;

      final pImage = pw.MemoryImage(
        Uint8List.fromList(img.encodeJpg(finalImage, quality: 95)),
      );

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (_) => pw.Center(
            child: pw.Image(pImage, fit: pw.BoxFit.contain),
          ),
        ),
      );
    }

    onProgress?.call(1.0);

    final pdfBytes = await pdf.save();
    await File(outputPath).writeAsBytes(pdfBytes);

    return outputPath;
  }

  img.Image _autoCropDocument(img.Image source) {
    final gray = img.grayscale(source);

    final width = gray.width;
    final height = gray.height;

    final threshold = 200;

    int top = 0;
    outerTop:
    for (int y = 0; y < height ~/ 2; y++) {
      for (int x = 0; x < width; x++) {
        final pixel = gray.getPixel(x, y);
        final luminance = (pixel.r.toInt() * 0.299 +
                pixel.g.toInt() * 0.587 +
                pixel.b.toInt() * 0.114)
            .toInt();
        if (luminance < threshold) {
          top = max(0, y - 5);
          break outerTop;
        }
      }
    }

    int bottom = height - 1;
    outerBottom:
    for (int y = height - 1; y >= height ~/ 2; y--) {
      for (int x = 0; x < width; x++) {
        final pixel = gray.getPixel(x, y);
        final luminance = (pixel.r.toInt() * 0.299 +
                pixel.g.toInt() * 0.587 +
                pixel.b.toInt() * 0.114)
            .toInt();
        if (luminance < threshold) {
          bottom = min(height - 1, y + 5);
          break outerBottom;
        }
      }
    }

    int left = 0;
    outerLeft:
    for (int x = 0; x < width ~/ 2; x++) {
      for (int y = 0; y < height; y++) {
        final pixel = gray.getPixel(x, y);
        final luminance = (pixel.r.toInt() * 0.299 +
                pixel.g.toInt() * 0.587 +
                pixel.b.toInt() * 0.114)
            .toInt();
        if (luminance < threshold) {
          left = max(0, x - 5);
          break outerLeft;
        }
      }
    }

    int right = width - 1;
    outerRight:
    for (int x = width - 1; x >= width ~/ 2; x--) {
      for (int y = 0; y < height; y++) {
        final pixel = gray.getPixel(x, y);
        final luminance = (pixel.r.toInt() * 0.299 +
                pixel.g.toInt() * 0.587 +
                pixel.b.toInt() * 0.114)
            .toInt();
        if (luminance < threshold) {
          right = min(width - 1, x + 5);
          break outerRight;
        }
      }
    }

    final cropWidth = max(10, right - left);
    final cropHeight = max(10, bottom - top);

    return img.copyCrop(
      source,
      x: left,
      y: top,
      width: cropWidth,
      height: cropHeight,
    );
  }

  Future<String> saveScannedImage(String imagePath) async {
    final scansDir = await _getScansDir();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'scan_$timestamp.jpg';
    final outputPath = '$scansDir/$fileName';

    final source = File(imagePath);
    final bytes = await source.readAsBytes();
    final decoded = img.decodeImage(bytes);

    if (decoded != null) {
      final cropped = _autoCropDocument(decoded);
      final compressed = img.encodeJpg(cropped, quality: 90);
      await File(outputPath).writeAsBytes(compressed);
    } else {
      await source.copy(outputPath);
    }

    return outputPath;
  }
}
