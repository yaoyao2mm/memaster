import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/models/app_models.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_window_frame.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../home/presentation/widgets/app_shell_background.dart';

class _SelectDestinationIntent extends Intent {
  const _SelectDestinationIntent(this.index);

  final int index;
}

class _RelativeDestinationIntent extends Intent {
  const _RelativeDestinationIntent(this.delta);

  final int delta;
}

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
    final shortcuts = <ShortcutActivator, Intent>{
      const SingleActivator(LogicalKeyboardKey.digit1, alt: true):
          const _SelectDestinationIntent(0),
      const SingleActivator(LogicalKeyboardKey.digit2, alt: true):
          const _SelectDestinationIntent(1),
      const SingleActivator(LogicalKeyboardKey.digit3, alt: true):
          const _SelectDestinationIntent(2),
      const SingleActivator(LogicalKeyboardKey.digit4, alt: true):
          const _SelectDestinationIntent(3),
      const SingleActivator(LogicalKeyboardKey.digit5, alt: true):
          const _SelectDestinationIntent(4),
      const SingleActivator(LogicalKeyboardKey.digit6, alt: true):
          const _SelectDestinationIntent(5),
      const SingleActivator(LogicalKeyboardKey.arrowLeft, alt: true):
          const _RelativeDestinationIntent(-1),
      const SingleActivator(LogicalKeyboardKey.arrowRight, alt: true):
          const _RelativeDestinationIntent(1),
    };

    return AppShellBackground(
      child: Shortcuts(
        shortcuts: shortcuts,
        child: Actions(
          actions: {
            _SelectDestinationIntent: CallbackAction<_SelectDestinationIntent>(
              onInvoke: (intent) {
                if (intent.index < destinations.length) {
                  onSelect(intent.index);
                }
                return null;
              },
            ),
            _RelativeDestinationIntent:
                CallbackAction<_RelativeDestinationIntent>(
              onInvoke: (intent) {
                final nextIndex = (selectedIndex + intent.delta)
                    .clamp(0, destinations.length - 1);
                if (nextIndex != selectedIndex) {
                  onSelect(nextIndex);
                }
                return null;
              },
            ),
          },
          child: Focus(
            autofocus: true,
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: AppWindowFrame(
                child: SafeArea(
                  top: false,
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
                                      destinations: destinations,
                                      selectedIndex: selectedIndex,
                                      onSelect: onSelect,
                                      title: title,
                                      subtitle: subtitle,
                                      child: child,
                                    ),
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
                                      destinations: destinations,
                                      selectedIndex: selectedIndex,
                                      onSelect: onSelect,
                                      title: title,
                                      subtitle: subtitle,
                                      child: child,
                                    ),
                                  ),
                                ],
                              ),
                      );
                    },
                  ),
                ),
              ),
            ),
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
          Text('memaster', style: theme.textTheme.titleLarge),
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
                      Container(
                        width: 24,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${index + 1}',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color:
                                selected ? Colors.white70 : AppColors.mutedInk,
                          ),
                        ),
                      ),
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
                const SizedBox(height: 12),
                Text(
                  '快捷键: Alt + 1-6 切换页面，Alt + ←/→ 顺序切换。',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppColors.mutedInk,
                  ),
                ),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final theme = Theme.of(context);
        final isCompact = constraints.maxWidth < 760;
        final current = destinations[selectedIndex];
        final previousEnabled = selectedIndex > 0;
        final nextEnabled = selectedIndex < destinations.length - 1;
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
              Wrap(
                spacing: 10,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F5FF),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${selectedIndex + 1}',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: AppColors.mutedInk,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(current.icon, size: 18, color: AppColors.deepNavy),
                        const SizedBox(width: 8),
                        Text(current.label, style: theme.textTheme.labelLarge),
                      ],
                    ),
                  ),
                  if (!isCompact)
                    Text(
                      'Alt + 1-6 / Alt + ← →',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: AppColors.mutedInk,
                      ),
                    ),
                  OutlinedButton.icon(
                    onPressed: previousEnabled
                        ? () => onSelect(selectedIndex - 1)
                        : null,
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text('上一页'),
                  ),
                  OutlinedButton.icon(
                    onPressed:
                        nextEnabled ? () => onSelect(selectedIndex + 1) : null,
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: const Text('下一页'),
                  ),
                ],
              ),
              const SizedBox(height: 18),
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
