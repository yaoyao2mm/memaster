import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../theme/app_colors.dart';

class PersonTile extends StatelessWidget {
  const PersonTile({super.key, required this.person});

  final PersonCluster person;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: person.color,
            child: Text(person.name.substring(0, 1), style: theme.textTheme.titleMedium),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(person.name, style: theme.textTheme.bodyLarge),
                const SizedBox(height: 4),
                Text('${person.assetCount} 张 · ${person.trait}', style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
          Text('查看', style: theme.textTheme.labelLarge),
        ],
      ),
    );
  }
}

