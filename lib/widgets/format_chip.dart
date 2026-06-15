import 'package:flutter/material.dart';
import '../models/app_theme.dart';
import '../models/conversion_format.dart';

class FormatChip extends StatelessWidget {
  final ConversionFormat format;
  final bool isSelected;
  final VoidCallback onTap;

  const FormatChip({super.key, required this.format, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? format.color.withOpacity(0.2) : AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? format.color : AppTheme.textSecondary.withOpacity(0.2),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: format.color.withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 4))]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(format.icon, color: isSelected ? format.color : AppTheme.textSecondary, size: 16),
            const SizedBox(width: 6),
            Text(
              format.label,
              style: TextStyle(
                color: isSelected ? format.color : AppTheme.textSecondary,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
