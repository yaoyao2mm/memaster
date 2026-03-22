import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../theme/app_colors.dart';
import '../window/window_frame_support.dart';
import 'glass_card.dart';

class AppWindowFrame extends StatelessWidget {
  const AppWindowFrame({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!supportsCustomWindowFrame) {
      return child;
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: const _WindowHeader(),
        ),
        const SizedBox(height: 8),
        Expanded(child: child),
      ],
    );
  }
}

class _WindowHeader extends StatefulWidget {
  const _WindowHeader();

  @override
  State<_WindowHeader> createState() => _WindowHeaderState();
}

class _WindowHeaderState extends State<_WindowHeader> with WindowListener {
  bool _isMaximized = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _syncWindowState();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  Future<void> _syncWindowState() async {
    final isMaximized = await windowManager.isMaximized();
    if (!mounted) {
      return;
    }
    setState(() {
      _isMaximized = isMaximized;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      borderRadius: 20,
      child: SizedBox(
        height: 40,
        child: Row(
          children: [
            const _BrandGlyph(),
            const SizedBox(width: 10),
            const Expanded(
              child: DragToMoveArea(
                child: SizedBox.expand(),
              ),
            ),
            const SizedBox(width: 10),
            _WindowActionButton(
              tooltip: '最小化',
              icon: Icons.remove_rounded,
              onPressed: () => windowManager.minimize(),
            ),
            const SizedBox(width: 8),
            _WindowActionButton(
              tooltip: _isMaximized ? '还原' : '最大化',
              icon: _isMaximized
                  ? Icons.filter_none_rounded
                  : Icons.crop_square_rounded,
              onPressed: () async {
                if (_isMaximized) {
                  await windowManager.unmaximize();
                } else {
                  await windowManager.maximize();
                }
              },
            ),
            const SizedBox(width: 8),
            _WindowActionButton(
              tooltip: '关闭',
              icon: Icons.close_rounded,
              accentColor: const Color(0xFFFFE2E7),
              iconColor: const Color(0xFF9F304A),
              hoverColor: const Color(0xFFFFD1DA),
              onPressed: () => windowManager.close(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void onWindowMaximize() {
    setState(() {
      _isMaximized = true;
    });
  }

  @override
  void onWindowUnmaximize() {
    setState(() {
      _isMaximized = false;
    });
  }
}

class _BrandGlyph extends StatelessWidget {
  const _BrandGlyph();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.deepNavy,
            AppColors.electricBlue,
            AppColors.aqua,
          ],
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 5,
            top: 5,
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 5,
            top: 8,
            child: Container(
              width: 9,
              height: 3,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Positioned(
            left: 5,
            bottom: 5,
            child: Container(
              width: 14,
              height: 3,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WindowActionButton extends StatefulWidget {
  const _WindowActionButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.accentColor = const Color(0xF5FFFFFF),
    this.iconColor = AppColors.deepNavy,
    this.hoverColor = const Color(0xFFEAF1FF),
  });

  final String tooltip;
  final IconData icon;
  final Future<void> Function() onPressed;
  final Color accentColor;
  final Color iconColor;
  final Color hoverColor;

  @override
  State<_WindowActionButton> createState() => _WindowActionButtonState();
}

class _WindowActionButtonState extends State<_WindowActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: widget.onPressed,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _hovered ? widget.hoverColor : widget.accentColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.line),
              ),
              child: Icon(
                widget.icon,
                size: 18,
                color: widget.iconColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
