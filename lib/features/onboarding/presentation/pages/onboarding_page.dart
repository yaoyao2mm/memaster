import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/data/memory_repository.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../home/presentation/widgets/app_shell_background.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({
    super.key,
    required this.repository,
    required this.onCompleted,
  });

  final MemoryRepository repository;
  final VoidCallback onCompleted;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _pathController;
  String _sourceType = 'local_folder';
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: '我的照片');
    _pathController = TextEditingController(text: _defaultPath());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pathController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) {
      return;
    }
    final displayName = _nameController.text.trim();
    final rootPath = _pathController.text.trim();
    if (displayName.isEmpty || rootPath.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请填写来源名称和路径。')));
      return;
    }
    if (!Directory(rootPath).existsSync()) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('路径不存在，或当前挂载目录还没就绪。')));
      return;
    }

    setState(() {
      _submitting = true;
    });

    final source = await widget.repository.createSource(
      displayName: displayName,
      rootPath: rootPath,
      sourceType: _sourceType,
    );
    final job = source == null
        ? null
        : await widget.repository.createScanJob(
            sourceId: source.sourceId,
            recursive: true,
            mode: 'incremental',
          );

    if (!mounted) {
      return;
    }

    setState(() {
      _submitting = false;
    });

    if (source == null || job == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('首次来源创建失败。')));
      return;
    }

    widget.onCompleted();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppShellBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: GlassCard(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('先跑通第一个索引闭环', style: theme.textTheme.displayMedium),
                      const SizedBox(height: 12),
                      Text(
                        '先添加第一个来源，系统会立即扫描并建立你的本地索引。完成后你就能在资产库里搜索、打标签并定位原图。',
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 28),
                      TextField(
                        controller: _nameController,
                        decoration: _inputDecoration(
                          labelText: '来源名称',
                          hintText: '我的照片',
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _pathController,
                        decoration: _inputDecoration(
                          labelText: '来源路径',
                          hintText: _defaultPath(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _PathPresetChip(
                            label: 'Pictures',
                            onTap: () => _applyPreset(
                              displayName: '我的照片',
                              path: _defaultPath(),
                              sourceType: 'local_folder',
                            ),
                          ),
                          _PathPresetChip(
                            label: 'UGREEN NAS',
                            onTap: () => _applyPreset(
                              displayName: 'UGREEN HomeMedia',
                              path: '/Volumes/UGREEN/HomeMedia',
                              sourceType: 'mounted_folder',
                            ),
                          ),
                          _PathPresetChip(
                            label: 'Desktop Exports',
                            onTap: () => _applyPreset(
                              displayName: '导出素材',
                              path: '${_homePath()}/Desktop/Exports',
                              sourceType: 'local_folder',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          ChoiceChip(
                            selected: _sourceType == 'local_folder',
                            label: const Text('本机目录'),
                            onSelected: (_) {
                              setState(() {
                                _sourceType = 'local_folder';
                              });
                            },
                          ),
                          ChoiceChip(
                            selected: _sourceType == 'mounted_folder',
                            label: const Text('挂载目录 / NAS'),
                            onSelected: (_) {
                              setState(() {
                                _sourceType = 'mounted_folder';
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.74),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.line),
                        ),
                        child: Text(
                          '对用户只暴露一个桌面 app；本地 service 会在后台自动运行。当前这一步的目标只有一个：把“添加来源 -> 扫描 -> 进资产库”跑通。',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        '创建完成后会直接跳到资产库，方便你马上确认索引结果。',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _submitting ? null : _submit,
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: Text(
                          _submitting ? '创建并扫描中…' : '创建来源并开始第一次扫描',
                        ),
                      ),
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

  void _applyPreset({
    required String displayName,
    required String path,
    required String sourceType,
  }) {
    setState(() {
      _nameController.text = displayName;
      _pathController.text = path;
      _sourceType = sourceType;
    });
  }

  String _homePath() {
    final home = Platform.environment['HOME'];
    if (home != null && home.isNotEmpty) {
      return home;
    }
    return '/Users/john';
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

  String _defaultPath() {
    return '${_homePath()}/Pictures';
  }
}

class _PathPresetChip extends StatelessWidget {
  const _PathPresetChip({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
    );
  }
}
