import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import '../models/app_theme.dart';
import '../models/scan_record.dart';
import '../services/scan_service.dart';
import 'scans_history_screen.dart';
import 'pdf_preview_screen.dart';

class DocumentScannerScreen extends StatefulWidget {
  const DocumentScannerScreen({super.key});

  @override
  State<DocumentScannerScreen> createState() => _DocumentScannerScreenState();
}

class _DocumentScannerScreenState extends State<DocumentScannerScreen> {
  final ImagePicker _picker = ImagePicker();
  ScanService? _scanService;
  List<String> _pages = [];
  bool _isProcessing = false;
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _initScanService();
  }

  Future<void> _initScanService() async {
    final service = await ScanService.getInstance();
    if (!mounted) return;
    setState(() => _scanService = service);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Scanner Document', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 20)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_pages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.history_rounded, color: AppTheme.textPrimary),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ScansHistoryScreen())),
              tooltip: 'Historique scans',
            ),
        ],
      ),
      body: SafeArea(
        child: _isProcessing
            ? _buildProcessingView()
            : _pages.isEmpty
                ? _buildEmptyView()
                : _buildPreviewView(),
      ),
      floatingActionButton: _isProcessing
          ? null
          : FloatingActionButton.extended(
              onPressed: _showAddPageSheet,
              backgroundColor: AppTheme.secondary,
              icon: const Icon(Icons.add_a_photo_rounded, color: Colors.white),
              label: const Text('Ajouter page', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.document_scanner_rounded, color: AppTheme.primary.withValues(alpha: 0.25), size: 100).animate().fadeIn(duration: 600.ms),
            const SizedBox(height: 24),
            Text('Scanner un document', style: TextStyle(color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.w700)).animate().fadeIn(duration: 800.ms),
            const SizedBox(height: 12),
            Text('Prenez une photo ou selectionnez une image',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 14, height: 1.5), textAlign: TextAlign.center)
                .animate().fadeIn(duration: 1000.ms),
            const SizedBox(height: 48),
            _ActionButton(
              icon: Icons.camera_alt_rounded,
              label: 'Appareil photo',
              color: AppTheme.primary,
              onTap: _pickFromCamera,
            ).animate().fadeIn(duration: 1200.ms).slideY(begin: 0.2),
            const SizedBox(height: 16),
            _ActionButton(
              icon: Icons.photo_library_rounded,
              label: 'Galerie',
              color: AppTheme.secondary,
              onTap: _pickFromGallery,
            ).animate().fadeIn(duration: 1400.ms).slideY(begin: 0.2),
            const SizedBox(height: 16),
            _ActionButton(
              icon: Icons.folder_open_rounded,
              label: 'Fichiers',
              color: AppTheme.primary.withValues(alpha: 0.8),
              onTap: _pickFromFiles,
            ).animate().fadeIn(duration: 1600.ms).slideY(begin: 0.2),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 200,
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(value: _progress, strokeWidth: 6, color: AppTheme.primary),
                Positioned.fill(
                  child: Center(
                    child: Text('${(_progress * 100).toInt()}%',
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text('Generation du PDF...', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildPreviewView() {
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            itemCount: _pages.length,
            itemBuilder: (_, index) {
              return _PreviewPage(
                imagePath: _pages[index],
                pageNumber: index + 1,
                totalPages: _pages.length,
                onDelete: () => _removePage(index),
              );
            },
          ),
        ),
Container(
           padding: const EdgeInsets.all(20),
           decoration: BoxDecoration(
             color: AppTheme.surface,
             border: Border(top: BorderSide(color: AppTheme.primary.withValues(alpha: 0.1), width: 1)),
           ),
           child: Row(
             children: [
               Expanded(
                 child: Text('${_pages.length} page(s)', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
               ),
               OutlinedButton.icon(
                 onPressed: _scanService != null ? _previewPdf : null,
                 icon: const Icon(Icons.visibility_rounded, color: AppTheme.primary, size: 18),
                 label: const Text('Aperçu PDF', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600)),
                 style: OutlinedButton.styleFrom(
                   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                   side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.5)),
                 ),
               ),
               const SizedBox(width: 12),
               ElevatedButton.icon(
                 onPressed: _scanService != null ? _generatePdf : null,
                 icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 20),
                 label: const Text('Sauvegarder PDF', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                 style: ElevatedButton.styleFrom(
                   backgroundColor: AppTheme.primary,
                   padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                 ),
               ),
             ],
           ),
         ),
      ],
    );
  }

  Future<void> _pickFromCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permission camera requise'), backgroundColor: AppTheme.secondary),
      );
      return;
    }

    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
        preferredCameraDevice: CameraDevice.rear,
        maxWidth: 4096,
        maxHeight: 4096,
      );

      if (photo != null && mounted) {
        final croppedPath = await _cropImage(photo.path);
        if (croppedPath != null) {
          setState(() => _pages.add(croppedPath));
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur camera: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
        maxWidth: 4096,
        maxHeight: 4096,
      );

      if (image != null && mounted) {
        final croppedPath = await _cropImage(image.path);
        if (croppedPath != null) {
          setState(() => _pages.add(croppedPath));
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur galerie: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _pickFromFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final newPaths = <String>[];
        for (final file in result.files) {
          if (file.path != null) {
            final croppedPath = await _cropImage(file.path!);
            if (croppedPath != null) {
              newPaths.add(croppedPath);
            }
          }
        }
        if (newPaths.isNotEmpty && mounted) {
          setState(() => _pages.addAll(newPaths));
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur fichiers: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<String?> _cropImage(String imagePath) async {
    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imagePath,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Rogner le document',
            toolbarColor: AppTheme.primary,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
            hideBottomControls: false,
          ),
IOSUiSettings(
               title: 'Rogner le document',
             ),
        ],
      );

      if (croppedFile != null && mounted) {
        return croppedFile.path;
      }
    } catch (e) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur rognage: $e'), backgroundColor: Colors.red),
      );
    }
    return null;
  }

  Future<void> _showAddPageSheet() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SheetOption(
              icon: Icons.camera_alt_rounded,
              label: 'Appareil photo',
              onTap: () {
                Navigator.pop(context);
                _pickFromCamera();
              },
            ),
            const SizedBox(height: 12),
            _SheetOption(
              icon: Icons.photo_library_rounded,
              label: 'Galerie',
              onTap: () {
                Navigator.pop(context);
                _pickFromGallery();
              },
            ),
            const SizedBox(height: 12),
            _SheetOption(
              icon: Icons.folder_open_rounded,
              label: 'Fichiers',
              onTap: () {
                Navigator.pop(context);
                _pickFromFiles();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _removePage(int index) {
    setState(() => _pages.removeAt(index));
  }

  Future<String?> _generatePreviewPdf() async {
    if (_scanService == null || _pages.isEmpty) return null;

    setState(() {
      _isProcessing = true;
      _progress = 0;
    });

    try {
      debugPrint('Generation apercu PDF avec ${_pages.length} page(s)');

      return await _scanService!.createPdfFromImages(
        _pages,
        onProgress: (value) {
          if (mounted) {
            setState(() => _progress = value);
          }
        },
        applyAutoCrop: false,
      );
    } catch (e, stack) {
      debugPrint('Erreur apercu PDF: $e\n$stack');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
      return null;
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

Future<void> _previewPdf() async {
    final outputPath = await _generatePreviewPdf();
    if (outputPath == null) return;

    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfPreviewScreen(
          pdfPath: outputPath,
          pageCount: _pages.length,
          onSave: () => _savePdf(outputPath),
        ),
      ),
    );

    if (!mounted) return;
    setState(() => _pages.clear());
  }

  Future<void> _savePdf(String pdfPath) async {
    final stat = await File(pdfPath).stat();
    final record = ScanRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      fileName: pdfPath.split('/').last,
      filePath: pdfPath,
      pageCount: _pages.length,
      date: DateTime.now(),
      fileSizeBytes: stat.size,
    );
    await _scanService!.addScanRecord(record);
    debugPrint('Record sauvegarde: ${record.fileName}');

    setState(() => _pages.clear());

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('PDF sauvegarde: ${record.fileName}', style: const TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.primary,
      ),
    );
  }

  Future<void> _generatePdf() async {
    if (_scanService == null || _pages.isEmpty) return;

    setState(() {
      _isProcessing = true;
      _progress = 0;
    });

    try {
      debugPrint('Debut generation PDF avec ${_pages.length} page(s)');

      final outputPath = await _scanService!.createPdfFromImages(
        _pages,
        onProgress: (value) {
          if (mounted) {
            setState(() => _progress = value);
          }
        },
      );

      debugPrint('PDF genere: $outputPath');

      final stat = await File(outputPath).stat();
      final record = ScanRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        fileName: outputPath.split('/').last,
        filePath: outputPath,
        pageCount: _pages.length,
        date: DateTime.now(),
        fileSizeBytes: stat.size,
      );
      await _scanService!.addScanRecord(record);
      debugPrint('Record ajoute: ${record.fileName}');

      if (!mounted) return;

      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: AppTheme.surface,
          title: const Text('PDF cree !', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Fichier: ${record.fileName}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              const SizedBox(height: 8),
              Text('Pages: ${record.pageCount} • ${(record.fileSizeBytes / 1024).toStringAsFixed(1)} Ko',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              Text('Chemin: $outputPath', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer', style: TextStyle(color: AppTheme.textSecondary)),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                OpenFilex.open(outputPath);
              },
              style: FilledButton.styleFrom(backgroundColor: AppTheme.primary),
              child: const Text('Ouvrir', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      setState(() => _pages.clear());
    } catch (e, stack) {
      debugPrint('Erreur generation PDF: $e\n$stack');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }
}

class _PreviewPage extends StatelessWidget {
  final String? imagePath;
  final int pageNumber;
  final int totalPages;
  final VoidCallback onDelete;

  const _PreviewPage({required this.imagePath, required this.pageNumber, required this.totalPages, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: AppTheme.surfaceLight,
          ),
          clipBehavior: Clip.antiAlias,
          child: imagePath != null
              ? Image.file(File(imagePath!), fit: BoxFit.contain)
              : Container(
                  color: AppTheme.surfaceLight,
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_rounded, color: AppTheme.textSecondary, size: 60),
                        SizedBox(height: 16),
                        Text('Page vide', style: TextStyle(color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                ),
        ),
        Positioned(
          top: 40,
          left: 40,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('$pageNumber / $totalPages',
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ),
        Positioned(
          top: 32,
          right: 32,
          child: IconButton(
            icon: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              child: const Icon(Icons.delete_rounded, color: Colors.white, size: 20),
            ),
            onPressed: onDelete,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.85)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _SheetOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SheetOption({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primary, size: 22),
            const SizedBox(width: 16),
            Text(label, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
