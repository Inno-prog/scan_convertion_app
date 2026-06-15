import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/app_theme.dart';
import '../services/storage_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  StorageService? _storage;
  UserProfile _profile = const UserProfile();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final storage = await StorageService.getInstance();
    setState(() {
      _storage = storage;
      _profile = storage.getProfile();
    });
  }

  Future<void> _editProfile() async {
    final nameCtrl = TextEditingController(text: _profile.name);
    final emailCtrl = TextEditingController(text: _profile.email);

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Modifier le profil',
            style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: _inputDecoration('Nom', Icons.person_rounded),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailCtrl,
              style: const TextStyle(color: AppTheme.textPrimary),
              keyboardType: TextInputType.emailAddress,
              decoration: _inputDecoration('Email', Icons.email_rounded),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: const Text('Enregistrer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result == true) {
      final updated = _profile.copyWith(
        name: nameCtrl.text.trim().isEmpty ? _profile.name : nameCtrl.text.trim(),
        email: emailCtrl.text.trim().isEmpty ? _profile.email : emailCtrl.text.trim(),
      );
      await _storage?.saveProfile(updated);
      setState(() => _profile = updated);
    }
  }

  Future<void> _changeAvatar() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppTheme.textSecondary.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          const Text('Choisir une photo',
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.camera_alt_rounded, color: AppTheme.primary),
            title: const Text('Prendre une photo',
                style: TextStyle(color: AppTheme.textPrimary)),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_rounded, color: AppTheme.primary),
            title: const Text('Choisir depuis la galerie',
                style: TextStyle(color: AppTheme.textPrimary)),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
          if (_profile.avatarPath != null)
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
              title: const Text('Supprimer la photo',
                  style: TextStyle(color: Colors.red)),
              onTap: () => Navigator.pop(context, null),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );

    if (source == null && _profile.avatarPath != null) {
      // Supprimer avatar
      final updated = UserProfile(
          name: _profile.name,
          email: _profile.email,
          avatarPath: null);
      await _storage?.saveProfile(updated);
      setState(() => _profile = updated);
      return;
    }
    if (source == null) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 80);
    if (picked == null) return;

    final updated = _profile.copyWith(avatarPath: picked.path);
    await _storage?.saveProfile(updated);
    setState(() => _profile = updated);
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppTheme.textSecondary),
      prefixIcon: Icon(icon, color: AppTheme.primary, size: 20),
      filled: true,
      fillColor: AppTheme.surfaceLight,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primary)),
    );
  }

  String _formatSize(int bytes) {
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(0)} KB';
    }
    return '$bytes B';
  }

  @override
  Widget build(BuildContext context) {
    final total = _storage?.getTotalConversions() ?? 0;
    final formats = _storage?.getUsedFormats().length ?? 0;
    final savedBytes = _storage?.getTotalSavedBytes() ?? 0;
    final history = _storage?.getHistory() ?? [];

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 16),
              // Avatar
              Stack(
                children: [
                  GestureDetector(
                    onTap: _changeAvatar,
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        gradient: _profile.avatarPath == null
                            ? const LinearGradient(
                                colors: [AppTheme.primary, AppTheme.secondary],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: AppTheme.primary, width: 2),
                      ),
                      child: _profile.avatarPath != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(26),
                              child: Image.file(File(_profile.avatarPath!),
                                  fit: BoxFit.cover),
                            )
                          : const Icon(Icons.person_rounded,
                              color: Colors.white, size: 50),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _changeAvatar,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.background, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt_rounded,
                            color: Colors.white, size: 14),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(_profile.name,
                  style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(_profile.email,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 14)),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _editProfile,
                icon: const Icon(Icons.edit_rounded, size: 16, color: AppTheme.primary),
                label: const Text('Modifier le profil',
                    style: TextStyle(color: AppTheme.primary, fontSize: 14)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.primary),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                ),
              ),
              const SizedBox(height: 28),
              // Stats
              Row(
                children: [
                  _StatCard(
                      label: 'Conversions',
                      value: '$total',
                      icon: Icons.swap_horiz_rounded,
                      color: AppTheme.primary),
                  const SizedBox(width: 12),
                  _StatCard(
                      label: 'Formats',
                      value: '$formats',
                      icon: Icons.category_rounded,
                      color: AppTheme.secondary),
                  const SizedBox(width: 12),
                  _StatCard(
                      label: 'Traités',
                      value: _formatSize(savedBytes),
                      icon: Icons.storage_rounded,
                      color: const Color(0xFF4CAF50)),
                ],
              ),
              const SizedBox(height: 28),
              // Historique
              if (history.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Activité récente',
                        style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                    TextButton(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            backgroundColor: AppTheme.surface,
                            title: const Text('Effacer l\'historique',
                                style: TextStyle(color: AppTheme.textPrimary)),
                            content: const Text(
                                'Supprimer toutes les conversions ?',
                                style:
                                    TextStyle(color: AppTheme.textSecondary)),
                            actions: [
                              TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Annuler',
                                      style: TextStyle(
                                          color: AppTheme.textSecondary))),
                              TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Supprimer',
                                      style: TextStyle(color: Colors.red))),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await _storage!.clearHistory();
                          setState(() {});
                        }
                      },
                      child: const Text('Tout effacer',
                          style: TextStyle(color: Colors.red, fontSize: 13)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...history.take(10).map((r) {
                  final d = r.date;
                  final ds =
                      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.swap_horiz_rounded,
                              color: AppTheme.primary, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(r.originalName,
                                  style: const TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              Text(
                                  '→ ${r.outputFormat.toUpperCase()} • $ds',
                                  style: const TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 11)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded,
                              color: AppTheme.textSecondary, size: 18),
                          onPressed: () async {
                            await _storage!.deleteRecord(r.id);
                            setState(() {});
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                              minWidth: 32, minHeight: 32),
                        ),
                      ],
                    ),
                  );
                }),
              ] else
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.history_rounded,
                          color: AppTheme.textSecondary.withOpacity(0.4),
                          size: 40),
                      const SizedBox(height: 12),
                      const Text('Aucune conversion encore',
                          style: TextStyle(
                              color: AppTheme.textSecondary, fontSize: 14)),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.w800),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 11),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
