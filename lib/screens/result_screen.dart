import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/app_theme.dart';
import '../models/conversion_format.dart';

class ResultScreen extends StatelessWidget {
  final String outputPath;
  final ConversionFormat format;
  final String originalName;

  const ResultScreen({
    super.key,
    required this.outputPath,
    required this.format,
    required this.originalName,
  });

  @override
  Widget build(BuildContext context) {
    final fileName = outputPath.split('/').last;
    final file = File(outputPath);
    final sizeBytes = file.existsSync() ? file.lengthSync() : 0;
    final displaySize = sizeBytes > 1024 * 1024
        ? '${(sizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB'
        : '${(sizeBytes / 1024).toStringAsFixed(1)} KB';

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSuccessIcon()
                  .animate()
                  .scale(duration: 600.ms, curve: Curves.elasticOut),
              const SizedBox(height: 32),
              const Text(
                'Conversion réussie !',
                style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w800),
              ).animate().fadeIn(delay: 300.ms),
              const SizedBox(height: 10),
              Text(
                '$originalName → ${format.label}',
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 14),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 400.ms),
              const SizedBox(height: 40),
              _buildFileCard(fileName, displaySize)
                  .animate()
                  .fadeIn(delay: 500.ms)
                  .slideY(begin: 0.2),
              const SizedBox(height: 32),
              _buildActions(context).animate().fadeIn(delay: 600.ms),
            ],
          ),
        ),
      ),
    );
  }

  bool _looksLikePdf(List<int> header) {
    if (header.length < 4) return false;
    // PDF header: %PDF
    return header[0] == 0x25 &&
        header[1] == 0x50 &&
        header[2] == 0x44 &&
        header[3] == 0x46;
  }

  bool _looksLikeZip(List<int> header) {
    if (header.length < 4) return false;
    // ZIP/APK header: PK\x03\x04 or PK\x05\x06 (empty) or PK\x07\x08
    return header[0] == 0x50 &&
        header[1] == 0x4B &&
        (header[2] == 0x03 || header[2] == 0x05 || header[2] == 0x07);
  }

  Widget _buildSuccessIcon() {
    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [format.color.withOpacity(0.8), format.color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
              color: format.color.withOpacity(0.5),
              blurRadius: 30,
              offset: const Offset(0, 12))
        ],
      ),
      child: const Icon(Icons.check_rounded, color: Colors.white, size: 56),
    );
  }

  Widget _buildFileCard(String fileName, String displaySize) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: format.color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: format.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(format.icon, color: format.color, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(fileName,
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(format.label,
                        style: TextStyle(
                            color: format.color,
                            fontSize: 12,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(width: 8),
                    Text('• $displaySize',
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    final mimeType = _mimeTypeFor(format.extension);
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 54,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [format.color.withOpacity(0.9), format.color]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: format.color.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8))
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: () async {
                final f = File(outputPath);
                if (!f.existsSync()) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Fichier introuvable')),
                  );
                  return;
                }

                // lire les premiers octets pour vérifier le type réel
                List<int> header = [];
                try {
                  header = await f.openRead(0, 8).first;
                } catch (_) {
                  // ignore
                }

                final looksPdf = _looksLikePdf(header);
                final looksZip = _looksLikeZip(header);

                if (!looksPdf &&
                    format.extension.toLowerCase() == 'pdf' &&
                    looksZip) {
                  if (!context.mounted) return;
                  final proceed = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Type de fichier inattendu'),
                      content: const Text(
                          'Le fichier semble être une archive (APK/ZIP) et non un PDF. Voulez-vous quand même l\'ouvrir ?'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Annuler')),
                        TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Ouvrir')),
                      ],
                    ),
                  );
                  if (proceed != true) return;
                }

                OpenFilex.open(outputPath, type: mimeType);
              },
              icon: const Icon(Icons.open_in_new_rounded, color: Colors.white),
              label: const Text('Ouvrir le fichier',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: OutlinedButton.icon(
            onPressed: () async {
              try {
                final f = File(outputPath);
                if (!f.existsSync()) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Fichier introuvable pour le partage')),
                  );
                  return;
                }
                final sz = f.lengthSync();
                if (sz == 0) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Le fichier est vide et ne peut pas être partagé')),
                  );
                  return;
                }

                // lire les premiers octets pour vérifier le type réel
                List<int> header = [];
                try {
                  header = await f.openRead(0, 8).first;
                } catch (_) {}

                final looksPdf = _looksLikePdf(header);
                final looksZip = _looksLikeZip(header);

                // Inférer l'extension depuis le chemin de sortie si le mimeType donné ne correspond pas
                String ext = '';
                final parts = outputPath.split('/').last.split('.');
                if (parts.length >= 2) ext = parts.last.toLowerCase();
                final usedMime =
                    _mimeTypeFor(ext.isNotEmpty ? ext : format.extension);

                if (format.extension.toLowerCase() == 'pdf' &&
                    looksZip &&
                    !looksPdf) {
                  if (!context.mounted) return;
                  final proceed = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Type de fichier inattendu'),
                      content: const Text(
                          'Le fichier converti semble être une archive (APK/ZIP) et non un PDF. Voulez-vous quand même le partager ?'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Annuler')),
                        TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Partager')),
                      ],
                    ),
                  );
                  if (proceed != true) return;
                }

                await Share.shareXFiles(
                  [XFile(outputPath, mimeType: usedMime)],
                  text: 'Fichier converti avec FileConvert',
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Erreur lors du partage: ${e.toString()}')),
                );
              }
            },
            icon: const Icon(Icons.share_rounded, color: AppTheme.primary),
            label: const Text('Partager',
                style: TextStyle(
                    color: AppTheme.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.primary, width: 1.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
            icon: const Icon(Icons.home_rounded, color: AppTheme.textSecondary),
            label: const Text("Retour à l'accueil",
                style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                  color: AppTheme.textSecondary.withOpacity(0.3), width: 1.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ],
    );
  }

  String _mimeTypeFor(String ext) {
    switch (ext.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      // Office / document formats
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'doc':
        return 'application/msword';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case 'ppt':
        return 'application/vnd.ms-powerpoint';
      case 'odt':
        return 'application/vnd.oasis.opendocument.text';
      case 'rtf':
        return 'application/rtf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'bmp':
        return 'image/bmp';
      case 'webp':
        return 'image/webp';
      case 'tiff':
      case 'tif':
        return 'image/tiff';
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      case 'flac':
        return 'audio/flac';
      case 'aac':
        return 'audio/aac';
      case 'ogg':
        return 'audio/ogg';
      case 'm4a':
        return 'audio/mp4';
      case 'mp4':
        return 'video/mp4';
      case 'avi':
        return 'video/x-msvideo';
      case 'mov':
        return 'video/quicktime';
      case 'mkv':
        return 'video/x-matroska';
      case 'webm':
        return 'video/webm';
      case 'txt':
        return 'text/plain';
      case 'html':
      case 'htm':
        return 'text/html';
      case 'csv':
        return 'text/csv';
      default:
        return 'application/octet-stream';
    }
  }
}
