import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'glass_card.dart';

class AsyncContent<T> extends StatelessWidget {
  const AsyncContent({
    super.key,
    required this.future,
    required this.builder,
  });

  final Future<T> future;
  final Widget Function(BuildContext context, T data) builder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<T>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return builder(context, snapshot.data as T);
        }
        if (snapshot.hasError) {
          return GlassCard(
            child: Text(
              '数据暂时不可用，请检查本地服务状态。',
              style: theme.textTheme.bodyLarge,
            ),
          );
        }
        return GlassCard(
          child: SizedBox(
            height: 240,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(AppColors.electricBlue),
                  ),
                  const SizedBox(height: 16),
                  Text('正在连接本地记忆服务…', style: theme.textTheme.bodyLarge),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
