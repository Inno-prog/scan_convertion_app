import 'package:flutter/material.dart';
import '../models/app_theme.dart';
import '../services/storage_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  AppSettings _settings = const AppSettings();
  StorageService? _storage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final storage = await StorageService.getInstance();
    setState(() {
      _storage = storage;
      _settings = storage.getSettings();
    });
  }

  Future<void> _save(AppSettings settings) async {
    setState(() => _settings = settings);
    await _storage?.saveSettings(settings);
  }

  Future<void> _clearCache() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Vider le cache', style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text('Supprimer tout l\'historique de conversions ?',
            style: TextStyle(color: AppTheme.textSecondary)),
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
    if (confirm == true) {
      await _storage?.clearHistory();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Cache vidé avec succès'),
            backgroundColor: AppTheme.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  void _changeLanguage() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.textSecondary.withOpacity(0.4), borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          const Text('Choisir la langue', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          for (final lang in ['Français', 'English', 'Español', 'Deutsch', 'Português'])
            ListTile(
              title: Text(lang, style: const TextStyle(color: AppTheme.textPrimary)),
              trailing: _settings.language == lang
                  ? const Icon(Icons.check_rounded, color: AppTheme.primary)
                  : null,
              onTap: () {
                _save(_settings.copyWith(language: lang));
                Navigator.pop(context);
              },
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: _storage == null
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : ListView(
              children: [
                _sectionHeader('Apparence'),
                _SettingsTile(
                  icon: Icons.dark_mode_rounded,
                  title: 'Thème sombre',
                  trailing: Switch(
                    value: _settings.darkMode,
                    onChanged: (v) => _save(_settings.copyWith(darkMode: v)),
                    activeColor: AppTheme.primary,
                  ),
                ),
                _sectionHeader('Notifications'),
                _SettingsTile(
                  icon: Icons.notifications_rounded,
                  title: 'Activer les notifications',
                  trailing: Switch(
                    value: _settings.notifications,
                    onChanged: (v) => _save(_settings.copyWith(notifications: v)),
                    activeColor: AppTheme.primary,
                  ),
                ),
                _sectionHeader('Général'),
                _SettingsTile(
                  icon: Icons.language_rounded,
                  title: 'Langue',
                  trailing: Text(_settings.language, style: const TextStyle(color: AppTheme.textSecondary)),
                  onTap: _changeLanguage,
                ),
                _SettingsTile(
                  icon: Icons.delete_outline_rounded,
                  title: 'Vider le cache',
                  subtitle: 'Supprimer l\'historique des conversions',
                  onTap: _clearCache,
                ),
                _sectionHeader('À propos'),
                _SettingsTile(
                  icon: Icons.info_outline_rounded,
                  title: 'À propos de FileConvert',
                  onTap: () => showAboutDialog(
                    context: context,
                    applicationName: 'FileConvert',
                    applicationVersion: '1.0.0',
                    applicationIcon: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.secondary]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.swap_horiz_rounded, color: Colors.white),
                    ),
                    applicationLegalese: '© 2025 FileConvert\nTous droits réservés',
                  ),
                ),
                _SettingsTile(
                  icon: Icons.star_outline_rounded,
                  title: 'Noter l\'application',
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Merci pour votre soutien ! ⭐'),
                      backgroundColor: AppTheme.primary,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
      child: Text(title.toUpperCase(),
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({required this.icon, required this.title, this.subtitle, this.trailing, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.primary.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppTheme.primary, size: 20),
      ),
      title: Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15)),
      subtitle: subtitle != null
          ? Text(subtitle!, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12))
          : null,
      trailing: trailing ?? const Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary),
      onTap: onTap,
    );
  }
}
