import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class SectionTitle extends StatelessWidget {
  const SectionTitle({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.actionLabel,
  });

  final String eyebrow;
  final String title;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow.toUpperCase(),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: AppColors.electricBlue,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(title, style: theme.textTheme.headlineSmall),
            ],
          ),
        ),
        Text(
          actionLabel,
          style: theme.textTheme.labelLarge?.copyWith(color: AppColors.mutedInk),
        ),
      ],
    );
  }
}

