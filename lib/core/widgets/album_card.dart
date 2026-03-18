import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../theme/app_colors.dart';

class AlbumCard extends StatelessWidget {
  const AlbumCard({super.key, required this.album, this.compact = false});

  final SmartAlbum album;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(compact ? 16 : 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [album.color, Colors.white],
        ),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: compact ? 42 : 48,
            height: compact ? 42 : 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Text(album.coverLabel, style: theme.textTheme.labelLarge),
          ),
          const Spacer(),
          Text(album.title, style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(album.count, style: theme.textTheme.labelLarge?.copyWith(color: AppColors.deepNavy)),
          const SizedBox(height: 8),
          Text(album.description, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

