import 'package:flutter/material.dart';

import '../../../../core/data/memory_repository.dart';
import '../../../../core/models/app_models.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/section_title.dart';

class TimelinePage extends StatefulWidget {
  TimelinePage({super.key, MemoryRepository? repository})
      : _repository = repository ?? MemoryRepository.instance;

  final MemoryRepository _repository;

  @override
  State<TimelinePage> createState() => _TimelinePageState();
}

class _TimelinePageState extends State<TimelinePage> {
  late Future<List<MemoryEvent>> _eventsFuture;
  late final TextEditingController _assetQueryController;
  Future<List<MediaAsset>>? _assetsFuture;
  MemoryEvent? _selectedEvent;
  String _tagFilter = 'all';
  String _assetQuery = '';

  @override
  void initState() {
    super.initState();
    _assetQueryController = TextEditingController();
    _eventsFuture = widget._repository.fetchTimeline();
  }

  @override
  void dispose() {
    _assetQueryController.dispose();
    super.dispose();
  }

  void _selectEvent(MemoryEvent event) {
    setState(() {
      _selectedEvent = event;
      _assetsFuture = widget._repository.fetchTimelineAssets(eventId: event.id);
    });
  }

  void _refresh() {
    setState(() {
      _eventsFuture = widget._repository.fetchTimeline();
      if (_selectedEvent != null) {
        _assetsFuture =
            widget._repository.fetchTimelineAssets(eventId: _selectedEvent!.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<List<MemoryEvent>>(
      future: _eventsFuture,
      builder: (context, snapshot) {
        final events = snapshot.data ?? const <MemoryEvent>[];
        final tags = {
          for (final event in events) event.tag,
        }.toList()
          ..sort();
        final visibleEvents = events.where((event) {
          return _tagFilter == 'all' || event.tag == _tagFilter;
        }).toList();
        final selected =
            visibleEvents.any((event) => event.id == _selectedEvent?.id)
                ? _selectedEvent
                : (visibleEvents.isNotEmpty ? visibleEvents.first : null);
        if (_selectedEvent == null && selected != null) {
          _selectedEvent = selected;
          _assetsFuture ??=
              widget._repository.fetchTimelineAssets(eventId: selected.id);
        } else if (selected != null && _selectedEvent?.id != selected.id) {
          _selectedEvent = selected;
          _assetsFuture =
              widget._repository.fetchTimelineAssets(eventId: selected.id);
        }

        return ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle(
                    eyebrow: 'Timeline',
                    title: '把照片串成事件，而不是文件名',
                    actionLabel: '切换月份',
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      FilledButton.tonalIcon(
                        onPressed: _refresh,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('刷新时间轴'),
                      ),
                      ChoiceChip(
                        selected: _tagFilter == 'all',
                        label: const Text('全部事件'),
                        onSelected: (_) {
                          setState(() {
                            _tagFilter = 'all';
                          });
                        },
                      ),
                      ...tags.map(
                        (tag) => ChoiceChip(
                          selected: _tagFilter == tag,
                          label: Text(tag),
                          onSelected: (_) {
                            setState(() {
                              _tagFilter = tag;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      events.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (visibleEvents.isEmpty)
                    Text('当前标签过滤下没有事件。', style: theme.textTheme.bodyLarge)
                  else
                    ...visibleEvents.map(
                      (event) => Padding(
                        padding: const EdgeInsets.only(bottom: 18),
                        child: InkWell(
                          onTap: () => _selectEvent(event),
                          borderRadius: BorderRadius.circular(22),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                children: [
                                  Container(
                                    width: 14,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: selected?.id == event.id
                                          ? AppColors.deepNavy
                                          : AppColors.electricBlue,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  Container(
                                    width: 2,
                                    height: 88,
                                    margin:
                                        const EdgeInsets.symmetric(vertical: 8),
                                    color: AppColors.line,
                                  ),
                                ],
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.82),
                                    borderRadius: BorderRadius.circular(22),
                                    border: Border.all(
                                      color: selected?.id == event.id
                                          ? AppColors.electricBlue
                                          : AppColors.line,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(event.date,
                                          style: theme.textTheme.labelLarge),
                                      const SizedBox(height: 6),
                                      Text(event.title,
                                          style: theme.textTheme.titleLarge),
                                      const SizedBox(height: 8),
                                      Text(event.description,
                                          style: theme.textTheme.bodyMedium),
                                      const SizedBox(height: 12),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF0F5FF),
                                          borderRadius:
                                              BorderRadius.circular(999),
                                        ),
                                        child: Text(event.tag,
                                            style: theme.textTheme.labelLarge),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
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
                  Text(
                    selected == null ? '事件详情' : '${selected.title} · 素材集合',
                    style: theme.textTheme.titleLarge,
                  ),
                  if (selected != null) ...[
                    const SizedBox(height: 8),
                    Text(selected.description,
                        style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _TimelinePill(label: selected.date),
                        _TimelinePill(label: selected.tag),
                      ],
                    ),
                  ],
                  const SizedBox(height: 18),
                  TextField(
                    controller: _assetQueryController,
                    onChanged: (value) {
                      setState(() {
                        _assetQuery = value.trim().toLowerCase();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: '搜索当前事件素材，例如 cat / trip / screen',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _assetQuery.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _assetQueryController.clear();
                                setState(() {
                                  _assetQuery = '';
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
                  const SizedBox(height: 18),
                  if (selected == null)
                    Text('先选择一个记忆事件。', style: theme.textTheme.bodyLarge)
                  else
                    FutureBuilder<List<MediaAsset>>(
                      future: _assetsFuture,
                      builder: (context, assetSnapshot) {
                        final assets =
                            assetSnapshot.data ?? const <MediaAsset>[];
                        if (assetSnapshot.connectionState ==
                                ConnectionState.waiting &&
                            assets.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 32),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final visibleAssets = assets.where((asset) {
                          if (_assetQuery.isEmpty) {
                            return true;
                          }
                          final haystack =
                              '${asset.fileName} ${asset.relativePath} ${asset.tags.join(' ')}'
                                  .toLowerCase();
                          return haystack.contains(_assetQuery);
                        }).toList();
                        if (assets.isEmpty) {
                          return Text(
                            '这个记忆事件下暂时还没有素材。',
                            style: theme.textTheme.bodyLarge,
                          );
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                _TimelinePill(
                                    label: '共 ${visibleAssets.length} 条'),
                                if (_assetQuery.isNotEmpty)
                                  _TimelinePill(label: '搜索: $_assetQuery'),
                              ],
                            ),
                            const SizedBox(height: 18),
                            if (visibleAssets.isEmpty)
                              Text(
                                '当前搜索条件下没有素材。',
                                style: theme.textTheme.bodyLarge,
                              )
                            else
                              Column(
                                children: visibleAssets
                                    .take(12)
                                    .map(
                                      (asset) => Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 12),
                                        child: Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: Colors.white
                                                .withValues(alpha: 0.82),
                                            borderRadius:
                                                BorderRadius.circular(18),
                                            border: Border.all(
                                                color: AppColors.line),
                                          ),
                                          child: Row(
                                            children: [
                                              _TimelineThumbnail(asset: asset),
                                              const SizedBox(width: 14),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      asset.fileName,
                                                      style: theme.textTheme
                                                          .titleMedium,
                                                    ),
                                                    const SizedBox(height: 6),
                                                    Text(
                                                      asset.relativePath,
                                                      style: theme
                                                          .textTheme.bodyMedium,
                                                    ),
                                                    if (asset
                                                        .tags.isNotEmpty) ...[
                                                      const SizedBox(
                                                          height: 10),
                                                      Wrap(
                                                        spacing: 8,
                                                        runSpacing: 8,
                                                        children: asset.tags
                                                            .map(
                                                              (tag) =>
                                                                  _TimelinePill(
                                                                label: tag,
                                                              ),
                                                            )
                                                            .toList(),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                          ],
                        );
                      },
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

class _TimelinePill extends StatelessWidget {
  const _TimelinePill({required this.label});

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

class _TimelineThumbnail extends StatelessWidget {
  const _TimelineThumbnail({required this.asset});

  final MediaAsset asset;

  @override
  Widget build(BuildContext context) {
    final uri = asset.thumbnailUrl;
    if (uri == null || uri.isEmpty) {
      return _TimelineFallback(kind: asset.mediaKind);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.network(
        'http://127.0.0.1:4318$uri',
        width: 52,
        height: 52,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _TimelineFallback(kind: asset.mediaKind),
      ),
    );
  }
}

class _TimelineFallback extends StatelessWidget {
  const _TimelineFallback({required this.kind});

  final String kind;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F5FF),
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.center,
      child: Text(
        kind == 'video' ? 'VID' : 'IMG',
        style: Theme.of(context).textTheme.labelLarge,
      ),
    );
  }
}
