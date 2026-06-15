import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:dotted_border/dotted_border.dart';
import '../models/app_theme.dart';
import '../models/conversion_format.dart';
import '../services/conversion_service.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../widgets/format_chip.dart';
import 'result_screen.dart';

class ConverterScreen extends StatefulWidget {
  final FileCategory category;
  const ConverterScreen({super.key, required this.category});

  @override
  State<ConverterScreen> createState() => _ConverterScreenState();
}

class _ConverterScreenState extends State<ConverterScreen> {
  PlatformFile? _selectedFile;
  ConversionFormat? _selectedFormat;
  bool _isConverting = false;
  double _progress = 0;
  String _statusText = '';

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: widget.category.inputExtensions,
    );
    if (result != null) {
      final picked = result.files.first;
      // Defensive: ensure extension is allowed (some platforms may bypass filter)
      final name = picked.name;
      final parts = name.split('.');
      final ext = parts.length >= 2 ? parts.last.toLowerCase() : '';
      if (ext.isEmpty || !widget.category.inputExtensions.contains(ext)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Format non supporté: .$ext. Sélectionnez un fichier ${widget.category.inputExtensions.join(', ')}')),
        );
        return;
      }

      setState(() {
        _selectedFile = picked;
        _selectedFormat = null;
      });
    }
  }

  Future<void> _convert() async {
    if (_selectedFile == null || _selectedFormat == null) return;
    setState(() {
      _isConverting = true;
      _progress = 0;
      _statusText = 'Préparation...';
    });

    await NotificationService().showConversionStarted(_selectedFile!.name);

    try {
      final service = ConversionService();
      final outputPath = await service.convertFile(
        filePath: _selectedFile!.path!,
        outputFormat: _selectedFormat!.extension,
        onProgress: (p) {
          if (!mounted) return;
          setState(() {
            _progress = p;
            if (p < 0.2) {
              _statusText = 'Préparation...';
            } else if (p < 0.7) {
              _statusText = 'Conversion en cours...';
            } else if (p < 0.95) {
              _statusText = 'Finalisation...';
            } else {
              _statusText = 'Terminé !';
            }
          });
        },
      );

      // Sauvegarder dans l'historique
      final storage = await StorageService.getInstance();
      await storage.addRecord(ConversionRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        originalName: _selectedFile!.name,
        outputPath: outputPath,
        outputFormat: _selectedFormat!.extension,
        categoryName: widget.category.name,
        date: DateTime.now(),
        fileSizeBytes: _selectedFile!.size,
      ));

      await NotificationService().showConversionSuccess(
        _selectedFile!.name,
        _selectedFormat!.label,
      );

      if (!mounted) return;
      // Réinitialiser l'état AVANT de naviguer
      setState(() => _isConverting = false);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            outputPath: outputPath,
            format: _selectedFormat!,
            originalName: _selectedFile!.name,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isConverting = false);
      await NotificationService()
          .showConversionError(_selectedFile!.name, e.toString());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isConverting ? _buildConvertingView() : _buildMainView(),
    );
  }

  Widget _buildMainView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDropZone()
              .animate()
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.1),
          const SizedBox(height: 28),
          if (_selectedFile != null) ...[
            _buildFileInfo().animate().fadeIn(duration: 300.ms),
            const SizedBox(height: 28),
            _buildFormatSelector().animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 32),
            _buildConvertButton()
                .animate()
                .fadeIn(delay: 200.ms)
                .slideY(begin: 0.2),
          ],
        ],
      ),
    );
  }

  Widget _buildDropZone() {
    return GestureDetector(
      onTap: _pickFile,
      child: DottedBorder(
        color: _selectedFile != null
            ? AppTheme.primary
            : AppTheme.textSecondary.withOpacity(0.4),
        strokeWidth: 2,
        dashPattern: const [8, 4],
        borderType: BorderType.RRect,
        radius: const Radius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 40),
          decoration: BoxDecoration(
            color: _selectedFile != null
                ? AppTheme.primary.withOpacity(0.08)
                : AppTheme.surfaceLight.withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      widget.category.color.withOpacity(0.8),
                      widget.category.color
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                        color: widget.category.color.withOpacity(0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 6))
                  ],
                ),
                child:
                    Icon(widget.category.icon, color: Colors.white, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                _selectedFile == null
                    ? 'Appuyez pour sélectionner'
                    : 'Changer de fichier',
                style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Text(
                widget.category.inputExtensions
                    .map((e) => e.toUpperCase())
                    .join(' • '),
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFileInfo() {
    final file = _selectedFile!;
    final sizeKb = (file.size / 1024).toStringAsFixed(1);
    final sizeMb = (file.size / (1024 * 1024)).toStringAsFixed(2);
    final displaySize = file.size > 1024 * 1024 ? '$sizeMb MB' : '$sizeKb KB';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: widget.category.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(widget.category.icon,
                color: widget.category.color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(file.name,
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(displaySize,
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded,
                color: AppTheme.textSecondary, size: 20),
            onPressed: () => setState(() {
              _selectedFile = null;
              _selectedFormat = null;
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Convertir en',
            style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: widget.category.outputFormats.map((fmt) {
            final isSelected = _selectedFormat?.extension == fmt.extension;
            return FormatChip(
              format: fmt,
              isSelected: isSelected,
              onTap: () => setState(() => _selectedFormat = fmt),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildConvertButton() {
    final canConvert = _selectedFile != null && _selectedFormat != null;
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: canConvert
              ? const LinearGradient(
                  colors: [AppTheme.primary, Color(0xFF9C63FF)])
              : null,
          color: canConvert ? null : AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          boxShadow: canConvert
              ? [
                  const BoxShadow(
                      color: Color(0x556C63FF),
                      blurRadius: 20,
                      offset: Offset(0, 8))
                ]
              : null,
        ),
        child: ElevatedButton(
          onPressed: canConvert ? _convert : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.swap_horiz_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Text(
                canConvert
                    ? 'Convertir en ${_selectedFormat!.label}'
                    : 'Sélectionnez un format',
                style: TextStyle(
                  color: canConvert ? Colors.white : AppTheme.textSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConvertingView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.secondary]),
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x556C63FF),
                      blurRadius: 30,
                      offset: Offset(0, 10))
                ],
              ),
              child: const Icon(Icons.autorenew_rounded,
                  color: Colors.white, size: 50),
            ).animate(onPlay: (c) => c.repeat()).rotate(duration: 1500.ms),
            const SizedBox(height: 40),
            Text(_statusText,
                style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 24),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _progress,
                minHeight: 8,
                backgroundColor: AppTheme.surfaceLight,
                valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
              ),
            ),
            const SizedBox(height: 12),
            Text('${(_progress * 100).toInt()}%',
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
