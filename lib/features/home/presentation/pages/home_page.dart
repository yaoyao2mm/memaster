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
  HomePage({super.key, MemoryRepository? repository})
      : _repository = repository ?? MemoryRepository.instance;

  final MemoryRepository _repository;

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
                        Expanded(flex: 7, child: _MainColumn(data: data)),
                        const SizedBox(width: 24),
                        Expanded(flex: 4, child: _SideColumn(data: data)),
                      ],
                    )
                  : Column(
                      children: [
                        _MainColumn(data: data),
                        const SizedBox(height: 24),
                        _SideColumn(data: data),
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
  const _MainColumn({required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _HeroPanel(data: data),
        const SizedBox(height: 24),
        _AlbumSection(albums: data.smartAlbums),
        const SizedBox(height: 24),
        _MemoryFlowSection(events: data.recentEvents),
      ],
    );
  }
}

class _SideColumn extends StatelessWidget {
  const _SideColumn({required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _StatusPanel(jobs: data.scanJobs),
        const SizedBox(height: 24),
        _InsightPanel(signals: data.signals),
        const SizedBox(height: 24),
        _PeoplePanel(people: data.people),
      ],
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                    Text('UGREEN NAS online', style: theme.textTheme.labelLarge),
                  ],
                ),
              ),
              const Spacer(),
              _TopNavButton(label: '记忆'),
              const SizedBox(width: 12),
              _TopNavButton(label: '人物'),
              const SizedBox(width: 12),
              _TopNavButton(label: '整理'),
            ],
          ),
          const SizedBox(height: 28),
          Text('为你的生活素材建立\n会自己理解内容的记忆层。', style: theme.textTheme.displayMedium),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Text(
              '不再只是浏览 NAS 文件夹。系统会自动理解猫、人像、本人、旅行与日常片段，并把它们整理成可回看的记忆。',
              style: theme.textTheme.bodyLarge,
            ),
          ),
          const SizedBox(height: 28),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: data.stats.map((stat) => StatChip(stat: stat)).toList(),
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
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '首期 MVP 建议',
                        style: theme.textTheme.labelLarge?.copyWith(color: Colors.white70),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '先做 macOS 桌面端，把扫描、缩略图、分类和人物聚类跑通。',
                        style: theme.textTheme.titleLarge?.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                FilledButton(
                  onPressed: () {},
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.deepNavy,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  ),
                  child: const Text('开始构建'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AlbumSection extends StatelessWidget {
  const _AlbumSection({required this.albums});

  final List<SmartAlbum> albums;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
            eyebrow: 'Smart Albums',
            title: '像杂志目录一样浏览你的记忆分类',
            actionLabel: '查看全部',
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
  const _MemoryFlowSection({required this.events});

  final List<MemoryEvent> events;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
            eyebrow: 'Memory Flow',
            title: '最近生成的记忆线索',
            actionLabel: '进入时间轴',
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
                        Text(item.description, style: theme.textTheme.bodyMedium),
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
  const _StatusPanel({required this.jobs});

  final List<ScanJob> jobs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('系统状态', style: theme.textTheme.titleLarge),
          const SizedBox(height: 20),
          _StatusRow(label: 'NAS 路径', value: jobs.isEmpty ? '/Volumes/UGREEN/HomeMedia' : '/Volumes/UGREEN/HomeMedia'),
          const _StatusRow(label: '连接协议', value: 'SMB'),
          _StatusRow(label: '索引模式', value: jobs.isEmpty ? '增量扫描' : jobs.first.status),
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
          ...signals.map((entry) => _InsightRow(label: entry.label, value: entry.value)),
        ],
      ),
    );
  }
}

class _PeoplePanel extends StatelessWidget {
  const _PeoplePanel({required this.people});

  final List<PersonCluster> people;

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
              child: PersonTile(person: person),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopNavButton extends StatelessWidget {
  const _TopNavButton({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.line),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelLarge),
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
