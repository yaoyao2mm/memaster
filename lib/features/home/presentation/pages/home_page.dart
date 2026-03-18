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

class HomePage extends StatelessWidget {
  HomePage({
    super.key,
    MemoryRepository? repository,
    this.onNavigate,
  }) : _repository = repository ?? MemoryRepository.instance;

  final MemoryRepository _repository;
  final ValueChanged<AppShellTab>? onNavigate;

  @override
  Widget build(BuildContext context) {
    return AsyncContent<DashboardData>(
      future: _repository.fetchDashboard(),
      builder: (context, data) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 1180;
            return SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 7,
                          child: _MainColumn(
                            data: data,
                            onNavigate: onNavigate,
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          flex: 4,
                          child: _SideColumn(
                            data: data,
                            onNavigate: onNavigate,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        _MainColumn(data: data, onNavigate: onNavigate),
                        const SizedBox(height: 24),
                        _SideColumn(data: data, onNavigate: onNavigate),
                      ],
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
  });

  final DashboardData data;
  final ValueChanged<AppShellTab>? onNavigate;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _HeroPanel(data: data, onNavigate: onNavigate),
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
  });

  final DashboardData data;
  final ValueChanged<AppShellTab>? onNavigate;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _StatusPanel(
          jobs: data.scanJobs,
          onNavigate: onNavigate,
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
  });

  final DashboardData data;
  final ValueChanged<AppShellTab>? onNavigate;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final theme = Theme.of(context);
        final isCompact = constraints.maxWidth < 720;
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
                          'UGREEN NAS online',
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
                children:
                    data.stats.map((stat) => StatChip(stat: stat)).toList(),
              ),
              const SizedBox(height: 28),
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
                            Text(item.date, style: theme.textTheme.labelLarge),
                            const SizedBox(height: 6),
                            Text(item.description,
                                style: theme.textTheme.bodyMedium),
                          ],
                        ),
                      ),
                    ],
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
    this.onNavigate,
  });

  final List<ScanJob> jobs;
  final ValueChanged<AppShellTab>? onNavigate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('系统状态', style: theme.textTheme.titleLarge),
          const SizedBox(height: 20),
          _StatusRow(
              label: 'NAS 路径',
              value: jobs.isEmpty
                  ? '/Volumes/UGREEN/HomeMedia'
                  : '/Volumes/UGREEN/HomeMedia'),
          const _StatusRow(label: '连接协议', value: 'SMB'),
          _StatusRow(
              label: '索引模式', value: jobs.isEmpty ? '增量扫描' : jobs.first.status),
          const _StatusRow(label: '推理模式', value: '本地优先'),
          const SizedBox(height: 18),
          LinearProgressIndicator(
            value: jobs.isEmpty ? 0.72 : jobs.first.progress,
            borderRadius: BorderRadius.circular(999),
            minHeight: 10,
            backgroundColor: AppColors.line,
            valueColor: const AlwaysStoppedAnimation(AppColors.electricBlue),
          ),
          const SizedBox(height: 10),
          Text(
            '当前扫描进度 ${(jobs.isEmpty ? 0.72 : jobs.first.progress) * 100 ~/ 1}%',
            style: theme.textTheme.bodyMedium,
          ),
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
