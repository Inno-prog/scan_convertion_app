import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import '../models/app_theme.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  int _notifCount = 0;

  final List<String> _titles = ['FileConvert', 'Récents', 'Mon Profil'];

  @override
  void initState() {
    super.initState();
    _refreshNotifCount();
  }

  void _refreshNotifCount() {
    setState(() => _notifCount = NotificationService().unreadCount);
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final screens = [
      const HomeScreen(),
      _RecentsScreen(onRefresh: _refresh),
      const ProfileScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [AppTheme.primary, AppTheme.secondary],
          ).createShader(bounds),
          child: Text(
            _titles[_currentIndex],
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22),
          ),
        ),
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: AppTheme.textPrimary),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: AppTheme.textPrimary),
                onPressed: () => _showNotificationsPanel(context),
              ),
              if (_notifCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: AppTheme.secondary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        _notifCount > 9 ? '9+' : '$_notifCount',
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          border: Border(top: BorderSide(color: AppTheme.primary.withOpacity(0.15), width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: AppTheme.primary,
          unselectedItemColor: AppTheme.textSecondary,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Accueil',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_outlined),
              activeIcon: Icon(Icons.history_rounded),
              label: 'Récents',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: AppTheme.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primary, AppTheme.secondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.swap_horiz_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('FileConvert',
                          style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
                      Text('v1.0.0', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(color: AppTheme.surfaceLight, height: 1),
            const SizedBox(height: 12),
            _DrawerItem(
              icon: Icons.home_rounded,
              label: 'Accueil',
              isActive: _currentIndex == 0,
              onTap: () { Navigator.pop(context); setState(() => _currentIndex = 0); },
            ),
            _DrawerItem(
              icon: Icons.history_rounded,
              label: 'Récents',
              isActive: _currentIndex == 1,
              onTap: () { Navigator.pop(context); setState(() => _currentIndex = 1); },
            ),
            _DrawerItem(
              icon: Icons.person_rounded,
              label: 'Mon Profil',
              isActive: _currentIndex == 2,
              onTap: () { Navigator.pop(context); setState(() => _currentIndex = 2); },
            ),
            const Divider(color: AppTheme.surfaceLight, height: 32, indent: 20, endIndent: 20),
            _DrawerItem(
              icon: Icons.settings_rounded,
              label: 'Paramètres',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
              },
            ),
            _DrawerItem(
              icon: Icons.help_outline_rounded,
              label: 'Aide & Support',
              onTap: () {
                Navigator.pop(context);
                _showHelp(context);
              },
            ),
            _DrawerItem(
              icon: Icons.star_outline_rounded,
              label: "Noter l'app",
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Merci pour votre soutien ! ⭐'),
                    backgroundColor: AppTheme.primary,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              },
            ),
            const Spacer(),
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text('© 2025 FileConvert', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  void _showNotificationsPanel(BuildContext context) {
    final notifService = NotificationService();
    notifService.markAllRead();
    _refreshNotifCount();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final notifs = notifService.notifications;
          return DraggableScrollableSheet(
            initialChildSize: 0.55,
            maxChildSize: 0.9,
            minChildSize: 0.3,
            expand: false,
            builder: (_, controller) => Column(
              children: [
                const SizedBox(height: 12),
                Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: AppTheme.textSecondary.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Notifications',
                          style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w700)),
                      if (notifs.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            notifService.clearAll();
                            setModalState(() {});
                            _refreshNotifCount();
                          },
                          child: const Text('Tout effacer',
                              style: TextStyle(color: Colors.red, fontSize: 13)),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: notifs.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.notifications_off_outlined,
                                  color: AppTheme.textSecondary.withOpacity(0.3),
                                  size: 56),
                              const SizedBox(height: 12),
                              const Text('Aucune notification',
                                  style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 15)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: controller,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: notifs.length,
                          itemBuilder: (_, i) {
                            final n = notifs[i];
                            final icon = n.type == NotifType.success
                                ? Icons.check_circle_rounded
                                : n.type == NotifType.error
                                    ? Icons.error_rounded
                                    : Icons.info_rounded;
                            final color = n.type == NotifType.success
                                ? const Color(0xFF4CAF50)
                                : n.type == NotifType.error
                                    ? Colors.red
                                    : AppTheme.primary;
                            final d = n.date;
                            final ds =
                                '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')} - ${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceLight,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: color.withOpacity(0.2)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(icon, color: color, size: 22),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(n.title,
                                            style: const TextStyle(
                                                color: AppTheme.textPrimary,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600)),
                                        const SizedBox(height: 2),
                                        Text(n.body,
                                            style: const TextStyle(
                                                color: AppTheme.textSecondary,
                                                fontSize: 12)),
                                        const SizedBox(height: 4),
                                        Text(ds,
                                            style: TextStyle(
                                                color: AppTheme.textSecondary
                                                    .withOpacity(0.6),
                                                fontSize: 10)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Aide & Support', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Comment convertir un fichier :', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600)),
            SizedBox(height: 8),
            Text('1. Choisissez une catégorie sur l\'accueil\n2. Sélectionnez votre fichier\n3. Choisissez le format de sortie\n4. Appuyez sur "Convertir"',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.6)),
            SizedBox(height: 16),
            Text('Formats supportés :', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600)),
            SizedBox(height: 8),
            Text('Documents, Images, Audio, Vidéo, Tableurs',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer', style: TextStyle(color: AppTheme.primary)),
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;

  const _DrawerItem({required this.icon, required this.label, required this.onTap, this.isActive = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? AppTheme.primary.withOpacity(0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: isActive ? AppTheme.primary : AppTheme.textSecondary, size: 22),
        title: Text(label,
            style: TextStyle(
              color: isActive ? AppTheme.primary : AppTheme.textPrimary,
              fontSize: 15,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.normal,
            )),
        onTap: onTap,
        horizontalTitleGap: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// ---- Écran Récents ----

class _RecentsScreen extends StatefulWidget {
  final VoidCallback onRefresh;
  const _RecentsScreen({required this.onRefresh});

  @override
  State<_RecentsScreen> createState() => _RecentsScreenState();
}

class _RecentsScreenState extends State<_RecentsScreen> {
  StorageService? _storage;
  List<ConversionRecord> _history = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final storage = await StorageService.getInstance();
    setState(() {
      _storage = storage;
      _history = storage.getHistory();
    });
  }

  Future<void> _delete(String id) async {
    await _storage?.deleteRecord(id);
    setState(() => _history = _storage?.getHistory() ?? []);
    widget.onRefresh();
  }

  @override
  Widget build(BuildContext context) {
    if (_storage == null) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }

    if (_history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_rounded, color: AppTheme.textSecondary.withOpacity(0.3), size: 72),
            const SizedBox(height: 16),
            const Text('Aucune conversion récente',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text('Vos fichiers convertis apparaîtront ici',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppTheme.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _history.length,
        itemBuilder: (_, i) {
          final r = _history[i];
          final date = r.date;
          final dateStr =
              '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}  ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
          final fileExists = File(r.outputPath).existsSync();

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primary.withOpacity(0.08)),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.swap_horiz_rounded, color: AppTheme.primary, size: 22),
              ),
              title: Text(r.originalName,
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 2),
                  Text('→ ${r.outputFormat.toUpperCase()} • ${r.categoryName}',
                      style: const TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w500)),
                  Text(dateStr, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (fileExists)
                    IconButton(
                      icon: const Icon(Icons.open_in_new_rounded, color: AppTheme.primary, size: 20),
                      onPressed: () => OpenFilex.open(r.outputPath),
                      tooltip: 'Ouvrir',
                    ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.textSecondary, size: 20),
                    onPressed: () => _delete(r.id),
                    tooltip: 'Supprimer',
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
