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
  late final TextEditingController _pathController;
  late Future<List<ScanJob>> _jobsFuture;
  late Future<List<CorrectionRecord>> _correctionsFuture;
  String _mode = 'incremental';
  bool _recursive = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _pathController = TextEditingController(text: '/Volumes/UGREEN/HomeMedia');
    _jobsFuture = widget._repository.fetchScanJobs();
    _correctionsFuture = widget._repository.fetchCorrections();
  }

  @override
  void dispose() {
    _pathController.dispose();
    super.dispose();
  }

  void _refresh() {
    setState(() {
      _jobsFuture = widget._repository.fetchScanJobs();
      _correctionsFuture = widget._repository.fetchCorrections();
    });
  }

  Future<void> _createScanJob() async {
    if (_submitting) {
      return;
    }
    final rootPath = _pathController.text.trim();
    if (rootPath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先输入 NAS 挂载路径。')),
      );
      return;
    }

    setState(() {
      _submitting = true;
    });

    final job = await widget._repository.createScanJob(
      rootPath: rootPath,
      recursive: _recursive,
      mode: _mode,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _submitting = false;
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
                    eyebrow: 'Connect & Scan',
                    title: '连接 NAS 路径并发起真实扫描',
                    actionLabel: 'SMB 挂载后直接输入路径',
                  ),
                  const SizedBox(height: 22),
                  TextField(
                    controller: _pathController,
                    decoration: InputDecoration(
                      labelText: 'NAS 挂载路径',
                      hintText: '/Volumes/UGREEN/HomeMedia',
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
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.76),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.line),
                          ),
                          child: DropdownButton<String>(
                            value: _mode,
                            borderRadius: BorderRadius.circular(16),
                            items: const [
                              DropdownMenuItem(value: 'incremental', child: Text('增量扫描')),
                              DropdownMenuItem(value: 'full', child: Text('全量扫描')),
                              DropdownMenuItem(value: 'thumbnail', child: Text('缩略图任务')),
                              DropdownMenuItem(value: 'people', child: Text('人物任务')),
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
                      OutlinedButton(
                        onPressed: _refresh,
                        child: const Text('刷新状态'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '建议先在系统里把绿联 NAS 通过 SMB 挂载出来，再把挂载路径填进来。当前服务会直接扫描该目录并写入本地 SQLite。',
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
                      final corrections = correctionSnapshot.data ?? const <CorrectionRecord>[];
                      if (correctionSnapshot.connectionState == ConnectionState.waiting &&
                          corrections.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      if (corrections.isEmpty) {
                        return Text('还没有人工修正记录。', style: theme.textTheme.bodyLarge);
                      }
                      return Column(
                        children: corrections
                            .map(
                              (item) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.82),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(color: AppColors.line),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(item.assetId, style: theme.textTheme.titleMedium),
                                            const SizedBox(height: 6),
                                            Text(
                                              '${item.kind} · ${item.fromValue} -> ${item.toValue}',
                                              style: theme.textTheme.bodyMedium,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text('已记录', style: theme.textTheme.labelLarge),
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
                  if (snapshot.connectionState == ConnectionState.waiting && jobs.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (snapshot.hasError && jobs.isEmpty)
                    Text('当前无法连接本地服务，请先启动 FastAPI 服务。', style: theme.textTheme.bodyLarge)
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
                                  Expanded(child: Text(job.title, style: theme.textTheme.titleMedium)),
                                  Text(job.status, style: theme.textTheme.labelLarge),
                                ],
                              ),
                              const SizedBox(height: 10),
                              LinearProgressIndicator(
                                value: job.progress,
                                minHeight: 10,
                                borderRadius: BorderRadius.circular(999),
                                backgroundColor: AppColors.line,
                                valueColor: const AlwaysStoppedAnimation(AppColors.electricBlue),
                              ),
                              const SizedBox(height: 10),
                              Text(job.detail, style: theme.textTheme.bodyMedium),
                              if (job.rootPath != null || job.mode != null) ...[
                                const SizedBox(height: 10),
                                Text(
                                  '${job.mode ?? 'task'} · ${job.rootPath ?? ''}',
                                  style: theme.textTheme.labelLarge?.copyWith(color: AppColors.mutedInk),
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
                  Text('1. SMB 挂载目录扫描', style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 8),
                  Text('2. SQLite 索引和增量变更检测', style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 8),
                  Text('3. 缩略图生成和图片 embedding', style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 8),
                  Text('4. 人脸聚类和人工修正回写', style: theme.textTheme.bodyLarge),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
