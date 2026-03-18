import 'package:flutter/material.dart';

import '../../../../core/data/memory_repository.dart';
import '../../../../core/models/app_models.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/section_title.dart';

class OrganizePage extends StatefulWidget {
  OrganizePage({super.key, MemoryRepository? repository})
      : _repository = repository ?? MemoryRepository.instance;

  final MemoryRepository _repository;

  @override
  State<OrganizePage> createState() => _OrganizePageState();
}

class _OrganizePageState extends State<OrganizePage> {
  late final TextEditingController _displayNameController;
  late final TextEditingController _pathController;
  late Future<List<MediaSource>> _sourcesFuture;
  late Future<List<ScanJob>> _jobsFuture;
  late Future<List<CorrectionRecord>> _correctionsFuture;
  String _sourceType = 'local_folder';
  String? _selectedSourceId;
  String _mode = 'incremental';
  bool _recursive = true;
  bool _submitting = false;
  bool _creatingSource = false;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController(text: 'UGREEN HomeMedia');
    _pathController = TextEditingController(text: '/Volumes/UGREEN/HomeMedia');
    _sourcesFuture = widget._repository.fetchSources();
    _jobsFuture = widget._repository.fetchScanJobs();
    _correctionsFuture = widget._repository.fetchCorrections();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _pathController.dispose();
    super.dispose();
  }

  void _refresh() {
    setState(() {
      _sourcesFuture = widget._repository.fetchSources();
      _jobsFuture = widget._repository.fetchScanJobs();
      _correctionsFuture = widget._repository.fetchCorrections();
    });
  }

  Future<void> _createSource() async {
    if (_creatingSource) {
      return;
    }
    final displayName = _displayNameController.text.trim();
    final rootPath = _pathController.text.trim();
    if (displayName.isEmpty || rootPath.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请先填写来源名称和路径。')));
      return;
    }

    setState(() {
      _creatingSource = true;
    });

    final source = await widget._repository.createSource(
      displayName: displayName,
      rootPath: rootPath,
      sourceType: _sourceType,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _creatingSource = false;
      if (source != null) {
        _selectedSourceId = source.sourceId;
      }
      _sourcesFuture = widget._repository.fetchSources();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          source == null ? '来源创建失败，请确认本地服务已启动。' : '已添加来源：${source.displayName}',
        ),
      ),
    );
  }

  Future<void> _createScanJob() async {
    if (_submitting) {
      return;
    }
    if (_selectedSourceId == null || _selectedSourceId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先创建并选择一个数据来源。')),
      );
      return;
    }

    setState(() {
      _submitting = true;
    });

    final job = await widget._repository.createScanJob(
      sourceId: _selectedSourceId!,
      recursive: _recursive,
      mode: _mode,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _submitting = false;
      _sourcesFuture = widget._repository.fetchSources();
      _jobsFuture = widget._repository.fetchScanJobs();
      _correctionsFuture = widget._repository.fetchCorrections();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          job == null ? '扫描任务创建失败，请确认本地服务已启动。' : '扫描任务已提交：${job.title}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<List<MediaSource>>(
      future: _sourcesFuture,
      builder: (context, sourceSnapshot) {
        final sources = sourceSnapshot.data ?? const <MediaSource>[];
        final selectedSource = sources.cast<MediaSource?>().firstWhere(
              (item) => item?.sourceId == _selectedSourceId,
              orElse: () => sources.isNotEmpty ? sources.first : null,
            );
        if (_selectedSourceId == null && selectedSource != null) {
          _selectedSourceId = selectedSource.sourceId;
        }

        return FutureBuilder<List<ScanJob>>(
          future: _jobsFuture,
          builder: (context, snapshot) {
            final jobs = snapshot.data ?? const <ScanJob>[];
            return ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionTitle(
                        eyebrow: 'Sources',
                        title: '先建立数据来源，再发起索引任务',
                        actionLabel: '本机目录、NAS 挂载路径、外接盘都可以',
                      ),
                      const SizedBox(height: 22),
                      TextField(
                        controller: _displayNameController,
                        decoration: _inputDecoration(
                          labelText: '来源名称',
                          hintText: 'UGREEN HomeMedia',
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _pathController,
                        decoration: _inputDecoration(
                          labelText: '来源路径',
                          hintText: '/Volumes/UGREEN/HomeMedia',
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          DropdownButtonHideUnderline(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.76),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.line),
                              ),
                              child: DropdownButton<String>(
                                value: _sourceType,
                                borderRadius: BorderRadius.circular(16),
                                items: const [
                                  DropdownMenuItem(
                                      value: 'local_folder',
                                      child: Text('本机目录')),
                                  DropdownMenuItem(
                                      value: 'mounted_folder',
                                      child: Text('挂载目录 / NAS')),
                                ],
                                onChanged: (value) {
                                  if (value == null) return;
                                  setState(() {
                                    _sourceType = value;
                                  });
                                },
                              ),
                            ),
                          ),
                          FilledButton.tonal(
                            onPressed: _creatingSource ? null : _createSource,
                            child: Text(_creatingSource ? '添加中…' : '添加来源'),
                          ),
                          OutlinedButton(
                            onPressed: _refresh,
                            child: const Text('刷新状态'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      if (sourceSnapshot.connectionState ==
                              ConnectionState.waiting &&
                          sources.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (sources.isEmpty)
                        Text('还没有配置数据来源。先添加一个本机目录或 NAS 挂载路径。',
                            style: theme.textTheme.bodyLarge)
                      else
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: sources
                              .map(
                                (source) => ChoiceChip(
                                  selected:
                                      source.sourceId == _selectedSourceId,
                                  label: Text(source.displayName),
                                  onSelected: (_) {
                                    setState(() {
                                      _selectedSourceId = source.sourceId;
                                    });
                                  },
                                ),
                              )
                              .toList(),
                        ),
                      if (selectedSource != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.82),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppColors.line),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(selectedSource.displayName,
                                  style: theme.textTheme.titleMedium),
                              const SizedBox(height: 6),
                              Text(selectedSource.rootPath,
                                  style: theme.textTheme.bodyMedium),
                              const SizedBox(height: 8),
                              Text(
                                '${selectedSource.sourceType} · ${selectedSource.status}',
                                style: theme.textTheme.labelLarge
                                    ?.copyWith(color: AppColors.mutedInk),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionTitle(
                        eyebrow: 'Scan',
                        title: '对选中的来源发起扫描和索引',
                        actionLabel: '扫描任务现在绑定到来源，而不是临时路径',
                      ),
                      const SizedBox(height: 22),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          DropdownButtonHideUnderline(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.76),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.line),
                              ),
                              child: DropdownButton<String>(
                                value: _mode,
                                borderRadius: BorderRadius.circular(16),
                                items: const [
                                  DropdownMenuItem(
                                      value: 'incremental',
                                      child: Text('增量扫描')),
                                  DropdownMenuItem(
                                      value: 'full', child: Text('全量扫描')),
                                  DropdownMenuItem(
                                      value: 'thumbnail', child: Text('缩略图任务')),
                                  DropdownMenuItem(
                                      value: 'people', child: Text('人物任务')),
                                ],
                                onChanged: (value) {
                                  if (value == null) return;
                                  setState(() {
                                    _mode = value;
                                  });
                                },
                              ),
                            ),
                          ),
                          FilterChip(
                            selected: _recursive,
                            label: const Text('递归扫描子目录'),
                            onSelected: (value) {
                              setState(() {
                                _recursive = value;
                              });
                            },
                          ),
                          FilledButton(
                            onPressed: _submitting ? null : _createScanJob,
                            child: Text(_submitting ? '提交中…' : '开始扫描'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '这一步只会记录并索引来源中的素材，不改变原文件存放位置。后续搜索、标签、人物和时间轴都建立在这层索引之上。',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionTitle(
                        eyebrow: 'Corrections',
                        title: '最近的人工修正记录',
                        actionLabel: '用于训练后续偏好',
                      ),
                      const SizedBox(height: 20),
                      FutureBuilder<List<CorrectionRecord>>(
                        future: _correctionsFuture,
                        builder: (context, correctionSnapshot) {
                          final corrections = correctionSnapshot.data ??
                              const <CorrectionRecord>[];
                          if (correctionSnapshot.connectionState ==
                                  ConnectionState.waiting &&
                              corrections.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          if (corrections.isEmpty) {
                            return Text('还没有人工修正记录。',
                                style: theme.textTheme.bodyLarge);
                          }
                          return Column(
                            children: corrections
                                .map(
                                  (item) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.white
                                            .withValues(alpha: 0.82),
                                        borderRadius: BorderRadius.circular(18),
                                        border:
                                            Border.all(color: AppColors.line),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(item.assetId,
                                                    style: theme
                                                        .textTheme.titleMedium),
                                                const SizedBox(height: 6),
                                                Text(
                                                  '${item.kind} · ${item.fromValue} -> ${item.toValue}',
                                                  style: theme
                                                      .textTheme.bodyMedium,
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text('已记录',
                                              style:
                                                  theme.textTheme.labelLarge),
                                        ],
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionTitle(
                        eyebrow: 'Pipeline',
                        title: '扫描、缩略图、分类和修正任务',
                        actionLabel: '来自本地服务',
                      ),
                      const SizedBox(height: 22),
                      if (snapshot.connectionState == ConnectionState.waiting &&
                          jobs.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (snapshot.hasError && jobs.isEmpty)
                        Text('当前无法连接本地服务，请先启动 FastAPI 服务。',
                            style: theme.textTheme.bodyLarge)
                      else
                        ...jobs.map(
                          (job) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
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
                                          child: Text(job.title,
                                              style:
                                                  theme.textTheme.titleMedium)),
                                      Text(job.status,
                                          style: theme.textTheme.labelLarge),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  LinearProgressIndicator(
                                    value: job.progress,
                                    minHeight: 10,
                                    borderRadius: BorderRadius.circular(999),
                                    backgroundColor: AppColors.line,
                                    valueColor: const AlwaysStoppedAnimation(
                                        AppColors.electricBlue),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(job.detail,
                                      style: theme.textTheme.bodyMedium),
                                  if (job.rootPath != null ||
                                      job.mode != null) ...[
                                    const SizedBox(height: 10),
                                    Text(
                                      '${job.sourceName ?? '未命名来源'} · ${job.mode ?? 'task'} · ${job.rootPath ?? ''}',
                                      style: theme.textTheme.labelLarge
                                          ?.copyWith(color: AppColors.mutedInk),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('首期后台能力边界', style: theme.textTheme.titleLarge),
                      const SizedBox(height: 16),
                      Text('1. 多来源管理与扫描', style: theme.textTheme.bodyLarge),
                      const SizedBox(height: 8),
                      Text('2. SQLite 索引和增量变更检测',
                          style: theme.textTheme.bodyLarge),
                      const SizedBox(height: 8),
                      Text('3. 缩略图生成和图片 embedding',
                          style: theme.textTheme.bodyLarge),
                      const SizedBox(height: 8),
                      Text('4. 人脸聚类和人工修正回写', style: theme.textTheme.bodyLarge),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  InputDecoration _inputDecoration({
    required String labelText,
    required String hintText,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.72),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.line),
      ),
    );
  }
}
