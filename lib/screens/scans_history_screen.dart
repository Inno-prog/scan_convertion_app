import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:open_filex/open_filex.dart';
import '../models/app_theme.dart';
import '../models/scan_record.dart';
import '../services/scan_service.dart';

class ScansHistoryScreen extends StatefulWidget {
  const ScansHistoryScreen({super.key});

  @override
  State<ScansHistoryScreen> createState() => _ScansHistoryScreenState();
}

class _ScansHistoryScreenState extends State<ScansHistoryScreen> {
  ScanService? _scanService;
  List<ScanRecord> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final service = await ScanService.getInstance();
    if (!mounted) return;
    setState(() {
      _scanService = service;
      _isLoading = true;
    });
    final list = await service.getScanHistory();
    if (!mounted) return;
    setState(() {
      _history = list;
      _isLoading = false;
    });
  }

  Future<void> _delete(String id) async {
    await _scanService?.deleteScanRecord(id);
    await _load();
  }

  Future<void> _confirmClear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Supprimer tout ?', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
        content: const Text('Tout l\'historique des scans sera supprime.', style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _scanService?.clearScanHistory();
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_scanService == null) {
      return const _LoadingView();
    }

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Historique scans', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 20)),
        actions: [
          if (_history.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete_sweep_rounded, color: Colors.red.withValues(alpha: 0.8)),
              onPressed: _confirmClear,
              tooltip: 'Tout effacer',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _history.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppTheme.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _history.length,
                    itemBuilder: (_, i) {
                      final r = _history[i];
                      final exists = File(r.filePath).existsSync();
                      return _ScanCard(
                        record: r,
                        exists: exists,
                        onTap: () {
                          if (exists) OpenFilex.open(r.filePath);
                        },
                        onDelete: () => _delete(r.id),
                      ).animate().fadeIn(delay: (i * 60).ms).slideY(begin: 0.08);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.picture_as_pdf_rounded, color: AppTheme.textSecondary.withValues(alpha: 0.25), size: 100),
          const SizedBox(height: 24),
          Text('Aucun scan', style: TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('Vos documents scannes apparaitront ici', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
        ],
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppTheme.surface,
      body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
    );
  }
}

class _ScanCard extends StatelessWidget {
  final ScanRecord record;
  final bool exists;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ScanCard({required this.record, required this.exists, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.08)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [AppTheme.primary, AppTheme.secondary], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 26),
        ),
        title: Text(
          record.fileName.split('/').last,
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text('${record.pageCount} page(s) • ${_size(record.fileSizeBytes)}',
                style: const TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w500)),
            Text(_date(record.date), style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (exists)
              IconButton(
                icon: const Icon(Icons.open_in_new_rounded, color: AppTheme.primary, size: 20),
                onPressed: onTap,
                tooltip: 'Ouvrir',
              ),
            IconButton(
              icon: Icon(Icons.delete_outline_rounded, color: Colors.red.withValues(alpha: 0.7), size: 20),
              onPressed: onDelete,
              tooltip: 'Supprimer',
            ),
          ],
        ),
      ),
    );
  }

  String _size(int bytes) {
    if (bytes < 1024) return '$bytes o';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} Ko';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} Mo';
  }

  String _date(DateTime date) {
    final months = const ['Jan', 'Fev', 'Mar', 'Avr', 'Mai', 'Juin', 'Juil', 'Aout', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}  '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
