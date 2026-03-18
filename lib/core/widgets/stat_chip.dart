import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../theme/app_colors.dart';

class StatChip extends StatelessWidget {
  const StatChip({
    super.key,
    required this.stat,
    this.onTap,
  });

  final MemoryStat stat;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.74),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(stat.label, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            Text(stat.value, style: theme.textTheme.titleLarge),
            if (stat.delta != null) ...[
              const SizedBox(height: 6),
              Text(
                stat.delta!,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: AppColors.electricBlue,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
