import 'package:flutter/material.dart';

import '../../../../core/models/app_models.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../home/presentation/widgets/app_shell_background.dart';

class ShellScaffold extends StatelessWidget {
  const ShellScaffold({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelect,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final List<AppDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppShellBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 1180;
              final isCompact = constraints.maxWidth < 760;
              final sidePanelWidth =
                  constraints.maxWidth >= 1320 ? 260.0 : 232.0;
              return Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? 24 : (isCompact ? 12 : 16),
                  vertical: isCompact ? 12 : 20,
                ),
                child: isWide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: sidePanelWidth,
                            child: _NavigationPanel(
                              destinations: destinations,
                              selectedIndex: selectedIndex,
                              onSelect: onSelect,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: _ContentPanel(
                                title: title, subtitle: subtitle, child: child),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          _MobileHeader(
                            title: title,
                            subtitle: subtitle,
                            destinations: destinations,
                            selectedIndex: selectedIndex,
                            onSelect: onSelect,
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: _ContentPanel(
                                title: title, subtitle: subtitle, child: child),
                          ),
                        ],
                      ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _NavigationPanel extends StatelessWidget {
  const _NavigationPanel({
    required this.destinations,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<AppDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Feishu Home', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('私人记忆系统', style: theme.textTheme.bodyMedium),
          const SizedBox(height: 24),
          ...List.generate(destinations.length, (index) {
            final item = destinations[index];
            final selected = index == selectedIndex;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: () => onSelect(index),
                borderRadius: BorderRadius.circular(18),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.deepNavy
                        : Colors.white.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: selected ? Colors.transparent : AppColors.line,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        item.icon,
                        color: selected ? Colors.white : AppColors.deepNavy,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        item.label,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: selected ? Colors.white : AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.76),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Local-first AI', style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                Text('SMB 读取、SQLite 索引、本地推理优先。',
                    style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContentPanel extends StatelessWidget {
  const _ContentPanel({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final theme = Theme.of(context);
        final isCompact = constraints.maxWidth < 760;
        return GlassCard(
          padding: EdgeInsets.fromLTRB(
            isCompact ? 16 : 24,
            isCompact ? 18 : 24,
            isCompact ? 16 : 24,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: isCompact
                    ? theme.textTheme.headlineSmall
                    : theme.textTheme.displayMedium,
              ),
              const SizedBox(height: 10),
              Text(
                subtitle,
                style: isCompact
                    ? theme.textTheme.bodyMedium
                    : theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 22),
              Expanded(child: child),
            ],
          ),
        );
      },
    );
  }
}

class _MobileHeader extends StatelessWidget {
  const _MobileHeader({
    required this.title,
    required this.subtitle,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelect,
  });

  final String title;
  final String subtitle;
  final List<AppDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(subtitle, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(destinations.length, (index) {
                final item = destinations[index];
                final selected = index == selectedIndex;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: ChoiceChip(
                    selected: selected,
                    label: Text(item.label),
                    avatar: Icon(item.icon, size: 18),
                    onSelected: (_) => onSelect(index),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
