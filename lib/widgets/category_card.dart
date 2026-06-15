import 'package:flutter/material.dart';
import '../models/app_theme.dart';
import '../models/conversion_format.dart';

class CategoryCard extends StatelessWidget {
  final FileCategory category;
  final VoidCallback onTap;

  const CategoryCard({super.key, required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: category.color.withOpacity(0.2)),
          boxShadow: [BoxShadow(color: category.color.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -16, top: -16,
              child: Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: category.color.withOpacity(0.07),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [category.color.withOpacity(0.7), category.color],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(color: category.color.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Icon(category.icon, color: Colors.white, size: 24),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(category.name, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(
                        '${category.outputFormats.length} formats',
                        style: TextStyle(color: category.color, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
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
