import 'package:flutter/material.dart';

import '../../../../core/data/memory_repository.dart';
import '../../../../core/models/app_models.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/section_title.dart';

class PeoplePage extends StatefulWidget {
  PeoplePage({super.key, MemoryRepository? repository})
      : _repository = repository ?? MemoryRepository.instance;

  final MemoryRepository _repository;

  @override
  State<PeoplePage> createState() => _PeoplePageState();
}

class _PeoplePageState extends State<PeoplePage> {
  late Future<List<PersonCluster>> _peopleFuture;
  late final TextEditingController _queryController;
  bool _submitting = false;
  String _query = '';
  String _reviewFilter = 'all';

  @override
  void initState() {
    super.initState();
    _queryController = TextEditingController();
    _peopleFuture = widget._repository.fetchPeople();
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  void _refresh() {
    setState(() {
      _peopleFuture = widget._repository.fetchPeople();
    });
  }

  Future<void> _confirmPerson(
    PersonCluster person, {
    required bool isSelf,
    required String name,
  }) async {
    if (_submitting) return;
    setState(() {
      _submitting = true;
    });
    final ok = await widget._repository.confirmPerson(
      clusterId: person.id,
      name: name,
      isSelf: isSelf,
    );
    if (!mounted) return;
    setState(() {
      _submitting = false;
      _peopleFuture = widget._repository.fetchPeople();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? '人物身份已确认' : '人物确认失败')),
    );
  }

  Future<void> _showConfirmDialog(PersonCluster person,
      {required bool isSelf}) async {
    final controller = TextEditingController(
      text: isSelf
          ? '我'
          : person.name.startsWith('待确认')
              ? ''
              : person.name,
    );
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isSelf ? '确认“本人”身份' : '确认人物名称'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: isSelf ? '我' : '输入人物名称',
            ),
            onSubmitted: (value) {
              Navigator.of(context).pop(value.trim());
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
              child: const Text('确认'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (!mounted || result == null || result.isEmpty) {
      return;
    }
    await _confirmPerson(person, isSelf: isSelf, name: result);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<List<PersonCluster>>(
      future: _peopleFuture,
      builder: (context, snapshot) {
        final people = snapshot.data ?? const <PersonCluster>[];
        final filteredPeople = people.where((person) {
          final reviewMatches = _reviewFilter == 'all' ||
              (_reviewFilter == 'confirmed' &&
                  person.reviewState == 'confirmed') ||
              (_reviewFilter == 'needs_review' &&
                  person.reviewState != 'confirmed');
          if (!reviewMatches) {
            return false;
          }
          if (_query.isEmpty) {
            return true;
          }
          final haystack = '${person.name} ${person.trait}'.toLowerCase();
          return haystack.contains(_query);
        }).toList();
        final confirmedCount =
            people.where((person) => person.reviewState == 'confirmed').length;
        final pendingCount = people.length - confirmedCount;
        final selfCount = people.where((person) => person.isSelf).length;
        return ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle(
                    eyebrow: 'Clusters',
                    title: '先让系统识别人，再让它学会关系',
                    actionLabel: '重新聚类',
                  ),
                  const SizedBox(height: 22),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      FilledButton.tonalIcon(
                        onPressed: _refresh,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('刷新人物'),
                      ),
                      _ReviewPill(label: '已确认 $confirmedCount'),
                      _ReviewPill(label: '待确认 $pendingCount'),
                      _ReviewPill(label: '本人 $selfCount'),
                    ],
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: _queryController,
                    onChanged: (value) {
                      setState(() {
                        _query = value.trim().toLowerCase();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: '搜索人物名称或特征，例如 家人 / 最近新增',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _queryController.clear();
                                setState(() {
                                  _query = '';
                                });
                              },
                              icon: const Icon(Icons.close_rounded),
                            ),
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
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      ChoiceChip(
                        selected: _reviewFilter == 'all',
                        label: const Text('全部'),
                        onSelected: (_) {
                          setState(() {
                            _reviewFilter = 'all';
                          });
                        },
                      ),
                      ChoiceChip(
                        selected: _reviewFilter == 'needs_review',
                        label: const Text('待确认'),
                        onSelected: (_) {
                          setState(() {
                            _reviewFilter = 'needs_review';
                          });
                        },
                      ),
                      ChoiceChip(
                        selected: _reviewFilter == 'confirmed',
                        label: const Text('已确认'),
                        onSelected: (_) {
                          setState(() {
                            _reviewFilter = 'confirmed';
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      people.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (filteredPeople.isEmpty)
                    Text('当前筛选条件下没有人物簇。', style: theme.textTheme.bodyLarge)
                  else
                    ...filteredPeople.map(
                      (person) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _PersonReviewTile(
                          person: person,
                          busy: _submitting,
                          onConfirmSelf: () =>
                              _showConfirmDialog(person, isSelf: true),
                          onConfirmKnown: () =>
                              _showConfirmDialog(person, isSelf: false),
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
                  Text('人物识别策略', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 16),
                  const _StepLine(
                    index: '01',
                    title: '人脸检测',
                    description: '从图片里识别出可能的人脸区域，并过滤低质量样本。',
                  ),
                  const _StepLine(
                    index: '02',
                    title: '特征向量',
                    description: '提取人脸 embedding，为后续聚类和身份确认提供基础。',
                  ),
                  const _StepLine(
                    index: '03',
                    title: '人工确认',
                    description: '由你把其中一个簇指定为“我”，其余人物逐步命名。',
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.deepNavy,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '“本人”不是直接分类结果，而是聚类 + 人工确认之后的稳定身份标签。',
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ReviewPill extends StatelessWidget {
  const _ReviewPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F5FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelLarge),
    );
  }
}

class _PersonReviewTile extends StatelessWidget {
  const _PersonReviewTile({
    required this.person,
    required this.busy,
    required this.onConfirmSelf,
    required this.onConfirmKnown,
  });

  final PersonCluster person;
  final bool busy;
  final VoidCallback onConfirmSelf;
  final VoidCallback onConfirmKnown;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: person.color,
                child: Text(person.name.substring(0, 1),
                    style: theme.textTheme.titleMedium),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      person.isSelf ? '${person.name} · 本人' : person.name,
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${person.assetCount} 张 · ${person.trait}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: person.reviewState == 'confirmed'
                      ? const Color(0xFFE9FFF1)
                      : const Color(0xFFFFF6E8),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  person.reviewState == 'confirmed' ? '已确认' : '待确认',
                  style: theme.textTheme.labelLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              FilledButton(
                onPressed: busy ? null : onConfirmSelf,
                child: const Text('设为我'),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: busy ? null : onConfirmKnown,
                child: const Text('确认人物'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepLine extends StatelessWidget {
  const _StepLine({
    required this.index,
    required this.title,
    required this.description,
  });

  final String index;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.line),
            ),
            child: Text(index, style: theme.textTheme.labelLarge),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(description, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
