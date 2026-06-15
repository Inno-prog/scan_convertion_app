import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'package:open_filex/open_filex.dart';
import '../models/app_theme.dart';

class PdfPreviewScreen extends StatefulWidget {
  final String pdfPath;
  final int pageCount;
  final VoidCallback onSave;

  const PdfPreviewScreen({
    super.key,
    required this.pdfPath,
    required this.pageCount,
    required this.onSave,
  });

  @override
  State<PdfPreviewScreen> createState() => _PdfPreviewScreenState();
}

class _PdfPreviewScreenState extends State<PdfPreviewScreen> {
  late PdfControllerPinch _pdfController;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _pdfController = PdfControllerPinch(
      document: PdfDocument.openFile(widget.pdfPath),
    );
  }

  @override
  void dispose() {
    _pdfController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Aperçu du PDF', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary),
          onPressed: () {
            if (!_isSaved) {
              File(widget.pdfPath).delete();
            }
            Navigator.of(context).pop();
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PdfViewPinch(
                controller: _pdfController,
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
                    child: Text('${widget.pageCount} page(s)', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      if (!_isSaved) {
                        widget.onSave();
                        setState(() => _isSaved = true);
                      }
                      OpenFilex.open(widget.pdfPath);
                    },
                    icon: const Icon(Icons.open_in_browser_rounded, color: AppTheme.primary, size: 18),
                    label: const Text('Ouvrir', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.5)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isSaved
                        ? null
                        : () {
                            widget.onSave();
                            setState(() => _isSaved = true);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('PDF sauvegardé avec succès', style: TextStyle(color: Colors.white)),
                                backgroundColor: AppTheme.primary,
                              ),
                            );
                          },
                    icon: const Icon(Icons.save_rounded, color: Colors.white, size: 20),
                    label: Text(_isSaved ? 'Sauvegardé' : 'Sauvegarder PDF',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
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
        ),
      ),
    );
  }
}