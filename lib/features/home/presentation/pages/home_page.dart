import 'package:flutter/material.dart';

import '../../../../core/data/memory_repository.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/async_content.dart';
import '../../../../core/widgets/album_card.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/person_tile.dart';
import '../../../../core/widgets/section_title.dart';
import '../../../../core/widgets/stat_chip.dart';
import '../../../../core/models/app_models.dart';

class HomePage extends StatefulWidget {
  HomePage({
    super.key,
    MemoryRepository? repository,
    this.onNavigate,
  }) : _repository = repository ?? MemoryRepository.instance;

  final MemoryRepository _repository;
  final ValueChanged<AppShellTab>? onNavigate;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<DashboardData> _dashboardFuture;
  DateTime? _lastLoadedAt;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _loadDashboard();
  }

  Future<DashboardData> _loadDashboard() async {
    final data = await widget._repository.fetchDashboard();
    if (mounted) {
      setState(() {
        _lastLoadedAt = DateTime.now();
      });
    }
    return data;
  }

  Future<void> _refresh() async {
    final future = _loadDashboard();
    setState(() {
      _dashboardFuture = future;
    });
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return AsyncContent<DashboardData>(
      future: _dashboardFuture,
      onRetry: () {
        _refresh();
      },
      builder: (context, data) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 1180;
            return RefreshIndicator(
              onRefresh: _refresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 24),
                child: isWide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 7,
                            child: _MainColumn(
                              data: data,
                              onNavigate: widget.onNavigate,
                              onRefresh: _refresh,
                              lastLoadedAt: _lastLoadedAt,
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            flex: 4,
                            child: _SideColumn(
                              data: data,
                              onNavigate: widget.onNavigate,
                              onRefresh: _refresh,
                              lastLoadedAt: _lastLoadedAt,
                            ),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          _MainColumn(
                            data: data,
                            onNavigate: widget.onNavigate,
                            onRefresh: _refresh,
                            lastLoadedAt: _lastLoadedAt,
                          ),
                          const SizedBox(height: 24),
                          _SideColumn(
                            data: data,
                            onNavigate: widget.onNavigate,
                            onRefresh: _refresh,
                            lastLoadedAt: _lastLoadedAt,
                          ),
                        ],
                      ),
              ),
            );
          },
        );
      },
    );
  }
}

class _MainColumn extends StatelessWidget {
  const _MainColumn({
    required this.data,
    this.onNavigate,
    required this.onRefresh,
    this.lastLoadedAt,
  });

  final DashboardData data;
  final ValueChanged<AppShellTab>? onNavigate;
  final Future<void> Function() onRefresh;
  final DateTime? lastLoadedAt;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _HeroPanel(
          data: data,
          onNavigate: onNavigate,
          onRefresh: onRefresh,
          lastLoadedAt: lastLoadedAt,
        ),
        const SizedBox(height: 24),
        _SourceOverviewSection(
          sources: data.sources,
          jobs: data.scanJobs,
          onNavigate: onNavigate,
        ),
        const SizedBox(height: 24),
        _AlbumSection(
          albums: data.smartAlbums,
          onNavigate: onNavigate,
        ),
        const SizedBox(height: 24),
        _MemoryFlowSection(
          events: data.recentEvents,
          onNavigate: onNavigate,
        ),
      ],
    );
  }
}

class _SideColumn extends StatelessWidget {
  const _SideColumn({
    required this.data,
    this.onNavigate,
    required this.onRefresh,
    this.lastLoadedAt,
  });

  final DashboardData data;
  final ValueChanged<AppShellTab>? onNavigate;
  final Future<void> Function() onRefresh;
  final DateTime? lastLoadedAt;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _StatusPanel(
          jobs: data.scanJobs,
          sources: data.sources,
          onNavigate: onNavigate,
          onRefresh: onRefresh,
          lastLoadedAt: lastLoadedAt,
        ),
        const SizedBox(height: 24),
        _InsightPanel(signals: data.signals),
        const SizedBox(height: 24),
        _PeoplePanel(
          people: data.people,
          onNavigate: onNavigate,
        ),
      ],
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({
    required this.data,
    this.onNavigate,
    required this.onRefresh,
    this.lastLoadedAt,
  });

  final DashboardData data;
  final ValueChanged<AppShellTab>? onNavigate;
  final Future<void> Function() onRefresh;
  final DateTime? lastLoadedAt;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final theme = Theme.of(context);
        final isCompact = constraints.maxWidth < 720;
        final primarySource =
            data.sources.isNotEmpty ? data.sources.first : null;
        final statusText = primarySource == null
            ? '本地索引待配置'
            : '${primarySource.displayName} ${_sourceStatusLabel(primarySource.status)}';
        return GlassCard(
          padding: EdgeInsets.all(isCompact ? 20 : 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: AppColors.aqua,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          statusText,
                          style: theme.textTheme.labelLarge,
                        ),
                      ],
                    ),
                  ),
                  _TopNavButton(
                    label: '记忆',
                    onTap: () => onNavigate?.call(AppShellTab.timeline),
                  ),
                  _TopNavButton(
                    label: '人物',
                    onTap: () => onNavigate?.call(AppShellTab.people),
                  ),
                  _TopNavButton(
                    label: '整理',
                    onTap: () => onNavigate?.call(AppShellTab.organize),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: onRefresh,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('刷新总览'),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Text(
                '为你的生活素材建立\n会自己理解内容的记忆层。',
                style: isCompact
                    ? theme.textTheme.headlineMedium
                    : theme.textTheme.displayMedium,
              ),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Text(
                  '不再只是浏览 NAS 文件夹。系统会自动理解猫、人像、本人、旅行与日常片段，并把它们整理成可回看的记忆。',
                  style: isCompact
                      ? theme.textTheme.bodyMedium
                      : theme.textTheme.bodyLarge,
                ),
              ),
              const SizedBox(height: 28),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: data.stats
                    .map(
                      (stat) => StatChip(
                        stat: stat,
                        onTap: () => onNavigate?.call(_statTarget(stat.label)),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 28),
              if (lastLoadedAt != null) ...[
                Text(
                  '最近刷新 ${_formatRefreshTime(lastLoadedAt!)}',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppColors.mutedInk,
                  ),
                ),
                const SizedBox(height: 14),
              ],
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.deepNavy, Color(0xFF223555)],
                  ),
                ),
                child: isCompact
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '首期 MVP 建议',
                            style: theme.textTheme.labelLarge
                                ?.copyWith(color: Colors.white70),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '先做 macOS 桌面端，把扫描、缩略图、分类和人物聚类跑通。',
                            style: theme.textTheme.titleLarge
                                ?.copyWith(color: Colors.white),
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: () =>
                                onNavigate?.call(AppShellTab.organize),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.deepNavy,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 16,
                              ),
                            ),
                            child: const Text('开始构建'),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '首期 MVP 建议',
                                  style: theme.textTheme.labelLarge
                                      ?.copyWith(color: Colors.white70),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  '先做 macOS 桌面端，把扫描、缩略图、分类和人物聚类跑通。',
                                  style: theme.textTheme.titleLarge
                                      ?.copyWith(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          FilledButton(
                            onPressed: () =>
                                onNavigate?.call(AppShellTab.organize),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.deepNavy,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 16,
                              ),
                            ),
                            child: const Text('开始构建'),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SourceOverviewSection extends StatelessWidget {
  const _SourceOverviewSection({
    required this.sources,
    required this.jobs,
    this.onNavigate,
  });

  final List<MediaSource> sources;
  final List<ScanJob> jobs;
  final ValueChanged<AppShellTab>? onNavigate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(
            eyebrow: 'Sources',
            title: '来源概览与最近状态',
            actionLabel: '进入整理中枢',
            onActionTap: () => onNavigate?.call(AppShellTab.organize),
          ),
          const SizedBox(height: 22),
          if (sources.isEmpty)
            Text('还没有接入来源。先添加一个本机目录或 NAS 挂载路径。',
                style: theme.textTheme.bodyLarge)
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 1080
                    ? 3
                    : constraints.maxWidth >= 720
                        ? 2
                        : 1;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: sources.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: columns == 1 ? 2.4 : 1.55,
                  ),
                  itemBuilder: (context, index) {
                    final source = sources[index];
                    final sourceJobs = jobs
                        .where((job) => job.sourceId == source.sourceId)
                        .toList();
                    final latestJob =
                        sourceJobs.isNotEmpty ? sourceJobs.first : null;
                    return InkWell(
                      onTap: () => onNavigate?.call(AppShellTab.organize),
                      borderRadius: BorderRadius.circular(22),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.82),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: AppColors.line),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    source.displayName,
                                    style: theme.textTheme.titleMedium,
                                  ),
                                ),
                                _InfoPill(
                                  label: _sourceStatusLabel(source.status),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              source.rootPath,
                              style: theme.textTheme.bodyMedium,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 14),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _InfoPill(
                                  label: source.sourceType == 'mounted_folder'
                                      ? '挂载来源'
                                      : '本机来源',
                                ),
                                _InfoPill(
                                  label: source.lastScanAt == null ||
                                          source.lastScanAt!.isEmpty
                                      ? '未扫描'
                                      : '最近扫描 ${_shortTimestamp(source.lastScanAt!)}',
                                ),
                              ],
                            ),
                            if (latestJob != null) ...[
                              const SizedBox(height: 14),
                              Text(
                                latestJob.title,
                                style: theme.textTheme.labelLarge,
                              ),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: latestJob.progress,
                                minHeight: 8,
                                borderRadius: BorderRadius.circular(999),
                                backgroundColor: AppColors.line,
                                valueColor: const AlwaysStoppedAnimation(
                                  AppColors.electricBlue,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
        ],
      ),
    );
  }
}

class _AlbumSection extends StatelessWidget {
  const _AlbumSection({
    required this.albums,
    this.onNavigate,
  });

  final List<SmartAlbum> albums;
  final ValueChanged<AppShellTab>? onNavigate;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(
            eyebrow: 'Smart Albums',
            title: '像杂志目录一样浏览你的记忆分类',
            actionLabel: '查看全部',
            onActionTap: () => onNavigate?.call(AppShellTab.albums),
          ),
          const SizedBox(height: 22),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 820 ? 2 : 1;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: albums.length < 4 ? albums.length : 4,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: columns == 2 ? 1.9 : 1.45,
                ),
                itemBuilder: (context, index) {
                  final album = albums[index];
                  return AlbumCard(album: album);
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MemoryFlowSection extends StatelessWidget {
  const _MemoryFlowSection({
    required this.events,
    this.onNavigate,
  });

  final List<MemoryEvent> events;
  final ValueChanged<AppShellTab>? onNavigate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(
            eyebrow: 'Memory Flow',
            title: '最近生成的记忆线索',
            actionLabel: '进入时间轴',
            onActionTap: () => onNavigate?.call(AppShellTab.timeline),
          ),
          const SizedBox(height: 22),
          ...events.take(3).map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: InkWell(
                    onTap: () => onNavigate?.call(AppShellTab.timeline),
                    borderRadius: BorderRadius.circular(18),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          margin: const EdgeInsets.only(top: 4),
                          decoration: const BoxDecoration(
                            color: AppColors.electricBlue,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.date,
                                  style: theme.textTheme.labelLarge),
                              const SizedBox(height: 6),
                              Text(item.title,
                                  style: theme.textTheme.titleMedium),
                              const SizedBox(height: 6),
                              Text(item.description,
                                  style: theme.textTheme.bodyMedium),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        _InfoPill(label: item.tag),
                      ],
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({
    required this.jobs,
    required this.sources,
    this.onNavigate,
    required this.onRefresh,
    this.lastLoadedAt,
  });

  final List<ScanJob> jobs;
  final List<MediaSource> sources;
  final ValueChanged<AppShellTab>? onNavigate;
  final Future<void> Function() onRefresh;
  final DateTime? lastLoadedAt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeJobs = jobs.where((job) => job.status != '已完成').length;
    final latestJob = jobs.isNotEmpty ? jobs.first : null;
    MediaSource? primarySource;
    if (latestJob?.sourceId != null) {
      for (final source in sources) {
        if (source.sourceId == latestJob!.sourceId) {
          primarySource = source;
          break;
        }
      }
    }
    primarySource ??= sources.isNotEmpty ? sources.first : null;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('系统状态', style: theme.textTheme.titleLarge),
              ),
              IconButton(
                tooltip: '刷新状态',
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _StatusRow(
            label: '当前来源',
            value: primarySource?.displayName ?? '未配置',
          ),
          _StatusRow(
            label: '路径',
            value: latestJob?.rootPath ?? primarySource?.rootPath ?? '待添加来源',
          ),
          _StatusRow(
            label: '连接方式',
            value: primarySource?.sourceType == 'mounted_folder'
                ? 'SMB / 挂载目录'
                : '本机目录',
          ),
          _StatusRow(
            label: '处理中任务',
            value: '$activeJobs 个',
          ),
          const _StatusRow(label: '推理模式', value: '本地优先'),
          const SizedBox(height: 18),
          LinearProgressIndicator(
            value: latestJob?.progress ?? 0,
            borderRadius: BorderRadius.circular(999),
            minHeight: 10,
            backgroundColor: AppColors.line,
            valueColor: const AlwaysStoppedAnimation(AppColors.electricBlue),
          ),
          const SizedBox(height: 10),
          Text(
            latestJob == null
                ? '还没有运行中的任务。'
                : '${latestJob.title} ${(latestJob.progress) * 100 ~/ 1}%',
            style: theme.textTheme.bodyMedium,
          ),
          if (lastLoadedAt != null) ...[
            const SizedBox(height: 10),
            Text(
              '刷新于 ${_formatRefreshTime(lastLoadedAt!)}',
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppColors.mutedInk,
              ),
            ),
          ],
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => onNavigate?.call(AppShellTab.organize),
            icon: const Icon(Icons.tune_rounded),
            label: const Text('进入整理中枢'),
          ),
        ],
      ),
    );
  }
}

class _InsightPanel extends StatelessWidget {
  const _InsightPanel({required this.signals});

  final List<MemoryStat> signals;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
            eyebrow: 'Signals',
            title: '这周系统观察到的重点',
            actionLabel: '更多',
          ),
          const SizedBox(height: 18),
          ...signals.map(
              (entry) => _InsightRow(label: entry.label, value: entry.value)),
        ],
      ),
    );
  }
}

class _PeoplePanel extends StatelessWidget {
  const _PeoplePanel({
    required this.people,
    this.onNavigate,
  });

  final List<PersonCluster> people;
  final ValueChanged<AppShellTab>? onNavigate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('人物与关系', style: theme.textTheme.titleLarge),
          const SizedBox(height: 18),
          ...people.map(
            (person) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: PersonTile(
                person: person,
                onTap: () => onNavigate?.call(AppShellTab.people),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F5FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelLarge),
    );
  }
}

class _TopNavButton extends StatelessWidget {
  const _TopNavButton({
    required this.label,
    this.onTap,
  });

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.line),
        ),
        child: Text(label, style: Theme.of(context).textTheme.labelLarge),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: theme.textTheme.labelLarge,
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  const _InsightRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            Expanded(child: Text(label, style: theme.textTheme.bodyLarge)),
            Text(value, style: theme.textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}

AppShellTab _statTarget(String label) {
  switch (label) {
    case '已索引素材':
      return AppShellTab.library;
    case '智能相册':
      return AppShellTab.albums;
    case '待确认人物':
      return AppShellTab.people;
    default:
      return AppShellTab.organize;
  }
}

String _sourceStatusLabel(String status) {
  switch (status) {
    case 'ready':
      return '已就绪';
    case 'syncing':
      return '同步中';
    case 'failed':
      return '异常';
    default:
      return status;
  }
}

String _shortTimestamp(String raw) {
  if (raw.length >= 10) {
    return raw.substring(5, 10);
  }
  return raw;
}

String _formatRefreshTime(DateTime value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  final second = value.second.toString().padLeft(2, '0');
  return '$hour:$minute:$second';
}
