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
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _peopleFuture = widget._repository.fetchPeople();
  }

  Future<void> _confirmPerson(PersonCluster person, bool isSelf) async {
    if (_submitting) return;
    setState(() {
      _submitting = true;
    });
    final ok = await widget._repository.confirmPerson(
      clusterId: person.id,
      name: isSelf ? '我' : person.name == '待确认人物 A' ? '朋友' : person.name,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<List<PersonCluster>>(
      future: _peopleFuture,
      builder: (context, snapshot) {
        final people = snapshot.data ?? const <PersonCluster>[];
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
                  if (snapshot.connectionState == ConnectionState.waiting && people.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else
                    ...people.map(
                      (person) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _PersonReviewTile(
                          person: person,
                          busy: _submitting,
                          onConfirmSelf: () => _confirmPerson(person, true),
                          onConfirmKnown: () => _confirmPerson(person, false),
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
                      style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white),
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
                child: Text(person.name.substring(0, 1), style: theme.textTheme.titleMedium),
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
