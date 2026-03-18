import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class SectionTitle extends StatelessWidget {
  const SectionTitle({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.actionLabel,
    this.onActionTap,
  });

  final String eyebrow;
  final String title;
  final String actionLabel;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final theme = Theme.of(context);
        final isCompact = constraints.maxWidth < 560;
        return Flex(
          direction: isCompact ? Axis.vertical : Axis.horizontal,
          crossAxisAlignment:
              isCompact ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: [
            Expanded(
              flex: isCompact ? 0 : 1,
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
            SizedBox(height: isCompact ? 10 : 0, width: isCompact ? 0 : 16),
            onActionTap == null
                ? Text(
                    actionLabel,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: AppColors.mutedInk,
                    ),
                  )
                : TextButton(
                    onPressed: onActionTap,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.deepNavy,
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(actionLabel),
                  ),
          ],
        );
      },
    );
  }
}
