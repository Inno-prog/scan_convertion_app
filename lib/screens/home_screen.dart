import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/app_theme.dart';
import '../models/conversion_format.dart';
import '../widgets/category_card.dart';
import '../widgets/recent_conversions.dart';
import 'converter_screen.dart';
import 'document_scanner_screen.dart';
import 'qr_scanner_screen.dart';
// scans_history_screen is imported where needed

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildSearchBar(context)),
            SliverToBoxAdapter(child: _buildSectionTitle('Catégories')),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => CategoryCard(
                    category: fileCategories[index],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ConverterScreen(category: fileCategories[index]),
                      ),
                    ),
                  ).animate().fadeIn(delay: (index * 80).ms).slideY(begin: 0.2),
                  childCount: fileCategories.length,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.1,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            SliverToBoxAdapter(child: _buildSectionTitle('Scan')),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildScannerCard(context, index),
                  childCount: 2,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.1,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            SliverToBoxAdapter(child: _buildSectionTitle('Conversions récentes')),
            const SliverToBoxAdapter(child: RecentConversions()),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: GestureDetector(
        onTap: () => _showFormatSearch(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
          ),
child: Row(
                children: const [
                  Icon(Icons.search_rounded, color: AppTheme.textSecondary, size: 20),
                  SizedBox(width: 12),
                  Text('Rechercher un format...', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                ],
              ),
        ),
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
      child: Text(
        title,
        style: const TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildScannerCard(BuildContext context, int index) {
    final items = [
      {
        'icon': Icons.document_scanner_rounded,
        'label': 'Scanner PDF',
        'color': const Color(0xFF4CAF50),
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DocumentScannerScreen())),
      },
      {
        'icon': Icons.qr_code_scanner_rounded,
        'label': 'QR Code',
        'color': const Color(0xFFFF5722),
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QrScannerScreen())),
      },
    ];
    final item = items[index];

    return GestureDetector(
      onTap: item['onTap'] as void Function(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [(item['color'] as Color), (item['color'] as Color).withOpacity(0.75)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: (item['color'] as Color).withOpacity(0.3), blurRadius: 14, offset: const Offset(0, 6)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item['icon'] as IconData, color: Colors.white, size: 32),
              const SizedBox(height: 14),
              Text(item['label'] as String,
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              const Text('Toucher pour scanner',
                  style: TextStyle(color: Colors.white70, fontSize: 11)),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: (index * 80).ms).scale(begin: const Offset(0.9, 0.9));
  }

  void _showFormatSearch(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _FormatSearchSheet(),
    );
  }
}

class _FormatSearchSheet extends StatefulWidget {
  const _FormatSearchSheet();

  @override
  State<_FormatSearchSheet> createState() => _FormatSearchSheetState();
}

class _FormatSearchSheetState extends State<_FormatSearchSheet> {
  String _query = '';

  List<(FileCategory, ConversionFormat)> get _results {
    if (_query.isEmpty) return [];
    final q = _query.toLowerCase();
    final results = <(FileCategory, ConversionFormat)>[];
    for (final cat in fileCategories) {
      for (final fmt in cat.outputFormats) {
        if (fmt.label.toLowerCase().contains(q) || fmt.extension.toLowerCase().contains(q)) {
          results.add((cat, fmt));
        }
      }
    }
    return results;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (_, controller) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.textSecondary.withOpacity(0.4), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                autofocus: true,
                onChanged: (v) => setState(() => _query = v),
                style: const TextStyle(color: AppTheme.textPrimary),
decoration: InputDecoration(
                   hintText: 'Ex: pdf, mp3, jpg...',
                   hintStyle: const TextStyle(color: AppTheme.textSecondary),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primary),
                  filled: true,
                  fillColor: AppTheme.surfaceLight,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                controller: controller,
                itemCount: _results.length,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemBuilder: (_, i) {
                  final (cat, fmt) = _results[i];
                  return ListTile(
                    leading: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(color: fmt.color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                      child: Icon(fmt.icon, color: fmt.color, size: 20),
                    ),
                    title: Text(fmt.label, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                    subtitle: Text('Catégorie: ${cat.name}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => ConverterScreen(category: cat)));
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
