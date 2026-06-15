import 'package:flutter/material.dart';
import '../models/app_theme.dart';

class RecentConversions extends StatelessWidget {
  const RecentConversions({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primary.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Icon(Icons.history_rounded, color: AppTheme.textSecondary.withOpacity(0.5), size: 40),
          const SizedBox(height: 12),
          const Text(
            'Aucune conversion récente',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 6),
          const Text(
            'Vos fichiers convertis apparaîtront ici',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
