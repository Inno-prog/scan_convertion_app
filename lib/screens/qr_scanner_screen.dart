import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/app_theme.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  final ImagePicker _picker = ImagePicker();
  bool _isScanned = false;
  String? _lastScanValue;
  String _lastScanType = 'QR Code';

  @override
  void initState() {
    super.initState();
    _controller.start();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
  // theme mode handled elsewhere

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text('Scanner QR Code',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        ),
        actions: [
          IconButton(
            onPressed: _controller.toggleTorch,
            icon: Icon(
              _controller.torchEnabled ? Icons.flash_on_rounded : Icons.flash_off_rounded,
              color: Colors.white,
            ),
          ),
          IconButton(
            onPressed: _controller.switchCamera,
            icon: const Icon(Icons.flip_camera_ios_rounded, color: Colors.white),
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: _isScanned
          ? null
          : FloatingActionButton.extended(
              onPressed: _handleGalleryPick,
              backgroundColor: AppTheme.primary,
              icon: const Icon(Icons.photo_library_rounded, color: Colors.white),
              label: const Text('Galerie',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
    );
  }

  Widget _buildBody() {
    if (_isScanned && _lastScanValue != null) {
      return Container(
        color: Colors.black.withOpacity(0.75),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _ScanResultCard(
              value: _lastScanValue!,
              type: _lastScanType,
              onOpen: () => _handleOpenUrl(_lastScanValue!),
              onRescan: () {
                setState(() {
                  _isScanned = false;
                  _lastScanValue = null;
                });
                _controller.start();
              },
            ),
          ),
        ),
      );
    }

    return MobileScanner(
      controller: _controller,
      onDetect: _onBarcodeDetected,
    );
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    if (_isScanned) return;

    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw != null && raw.trim().isNotEmpty) {
        setState(() {
          _lastScanValue = raw.trim();
          _lastScanType = barcode.format.name;
          _isScanned = true;
        });
        _controller.stop();
        break;
      }
    }
  }

  Future<void> _handleGalleryPick() async {
    final photoStatus = await Permission.photos.request();
    if (!photoStatus.isGranted && Platform.isIOS) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Permission galerie requise'),
          backgroundColor: AppTheme.secondary,
        ),
      );
      return;
    }

    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (picked == null || !mounted) return;

    setState(() {});
    _controller.stop();

    try {
      final completer = Completer<String?>();
      final sub = _controller.barcodes.listen((event) {
        if (!completer.isCompleted && event.barcodes.isNotEmpty) {
          final raw = event.barcodes.first.rawValue;
          if (raw != null && raw.trim().isNotEmpty) {
            completer.complete(raw.trim());
          }
        }
      });

      await _controller.analyzeImage(picked.path);
      final result = await completer.future.timeout(
        const Duration(seconds: 15),
        onTimeout: () => null,
      );
      await sub.cancel();

      if (!mounted) return;
      if (result != null && result.trim().isNotEmpty) {
        setState(() {
          _lastScanValue = result.trim();
          _lastScanType = 'QR Code';
          _isScanned = true;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aucun QR code detecte dans cette image'),
            backgroundColor: AppTheme.secondary,
          ),
        );
        _controller.start();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
        );
      }
      _controller.start();
    }
  }

  Future<void> _handleOpenUrl(String value) async {
    Uri? uri;
    try {
      uri = Uri.parse(value);
      if (!uri.hasScheme) uri = Uri.parse('https://$value');
    } catch (e) {
      if (!mounted) return;
      await _showValueDialog(value);
      return;
    }

    final canLaunch = await canLaunchUrl(uri);
    if (canLaunch) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      await _showValueDialog(value);
    }
  }

  Future<void> _showValueDialog(String value) async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Contenu QR',
            style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
        content: Text(value,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
        ],
      ),
    );
  }
}

class _ScanResultCard extends StatelessWidget {
  final String value;
  final String type;
  final VoidCallback onOpen;
  final VoidCallback onRescan;

  const _ScanResultCard({
    required this.value,
    required this.type,
    required this.onOpen,
    required this.onRescan,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.primary.withOpacity(0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: Color(0xFF4CAF50),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 48),
          ),
          const SizedBox(height: 24),
          Text('Code detecte !',
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(type,
              style: TextStyle(
                  color: AppTheme.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.primary.withOpacity(0.15)),
            ),
            child: Text(
              value,
              style: const TextStyle(
                  color: AppTheme.textPrimary, fontSize: 14, height: 1.5),
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: onRescan,
                  style: TextButton.styleFrom(
                    backgroundColor: AppTheme.surfaceLight,
                    padding:
                        const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Rescanner',
                      style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton(
                  onPressed: onOpen,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding:
                        const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Ouvrir',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
