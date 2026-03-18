import 'package:flutter/material.dart';

import '../../../../core/data/memory_repository.dart';
import '../../../../core/models/app_models.dart';
import '../../../../core/network/local_api_client.dart';
import '../../../../core/services/local_service_runtime.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../home/presentation/widgets/app_shell_background.dart';
import '../../../onboarding/presentation/pages/onboarding_page.dart';
import '../../../shell/presentation/pages/app_shell_page.dart';

enum _BootstrapPhase { loading, onboarding, ready, failed }

class AppBootstrapPage extends StatefulWidget {
  const AppBootstrapPage({
    super.key,
    required this.repository,
    required this.serviceRuntime,
  });

  final MemoryRepository repository;
  final LocalServiceRuntime serviceRuntime;

  @override
  State<AppBootstrapPage> createState() => _AppBootstrapPageState();
}

class _AppBootstrapPageState extends State<AppBootstrapPage> {
  final _apiClient = LocalApiClient();
  _BootstrapPhase _phase = _BootstrapPhase.loading;
  String? _error;
  int _initialIndex = 0;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _phase = _BootstrapPhase.loading;
      _error = null;
    });

    final result = await widget.serviceRuntime.ensureReady();
    if (!result.ready) {
      if (!mounted) {
        return;
      }
      setState(() {
        _phase = _BootstrapPhase.failed;
        _error = result.error;
      });
      return;
    }

    final sources = await _fetchSources();
    if (!mounted) {
      return;
    }
    setState(() {
      _phase =
          sources.isEmpty ? _BootstrapPhase.onboarding : _BootstrapPhase.ready;
      _initialIndex = 0;
    });
  }

  Future<List<MediaSource>> _fetchSources() async {
    try {
      final payload = await _apiClient.getJson('/sources');
      final rawItems = payload['items'];
      if (rawItems is! List) {
        return const [];
      }
      return rawItems
          .whereType<Map>()
          .map((item) => MediaSource.fromJson(item.cast<String, dynamic>()))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_phase) {
      case _BootstrapPhase.ready:
        return AppShellPage(initialSelectedIndex: _initialIndex);
      case _BootstrapPhase.onboarding:
        return OnboardingPage(
          repository: widget.repository,
          onCompleted: () {
            setState(() {
              _phase = _BootstrapPhase.ready;
              _initialIndex = AppShellTab.library.index;
            });
          },
        );
      case _BootstrapPhase.failed:
        return _BootstrapScaffold(
          title: '本地服务启动失败',
          description: _error ?? '当前无法自动拉起本地 service。',
          details: [
            ('最后错误', widget.serviceRuntime.lastError ?? '无更多错误信息'),
            ('service 目录', widget.serviceRuntime.serviceDirectoryPath ?? '未找到'),
            (
              'Python 可执行文件',
              widget.serviceRuntime.pythonExecutablePath ?? '未找到',
            ),
            ('日志文件', widget.serviceRuntime.logFilePath),
          ],
          actionLabel: '重试启动',
          onAction: _bootstrap,
        );
      case _BootstrapPhase.loading:
        return const _BootstrapScaffold(
          title: '正在准备本地索引服务',
          description: '先检查服务健康状态；如果还没启动，app 会自动在后台拉起它。',
          details: [
            ('步骤 1', '检查 http://127.0.0.1:4318/health'),
            ('步骤 2', '如未就绪，则拉起本地 FastAPI service'),
            ('步骤 3', '若还没有来源，进入首次引导'),
          ],
          loading: true,
        );
    }
  }
}

class _BootstrapScaffold extends StatelessWidget {
  const _BootstrapScaffold({
    required this.title,
    required this.description,
    this.details = const [],
    this.actionLabel,
    this.onAction,
    this.loading = false,
  });

  final String title;
  final String description;
  final List<(String, String)> details;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppShellBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: GlassCard(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (loading) ...[
                        const CircularProgressIndicator(),
                        const SizedBox(height: 20),
                      ],
                      Text(title, style: theme.textTheme.displayMedium),
                      const SizedBox(height: 12),
                      Text(description, style: theme.textTheme.bodyLarge),
                      if (details.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        ...details.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _BootstrapDetailRow(
                              label: item.$1,
                              value: item.$2,
                            ),
                          ),
                        ),
                      ],
                      if (actionLabel != null && onAction != null) ...[
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: onAction,
                          child: Text(actionLabel!),
                        ),
                      ],
                    ],
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

class _BootstrapDetailRow extends StatelessWidget {
  const _BootstrapDetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelLarge),
          const SizedBox(height: 6),
          Text(value, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
