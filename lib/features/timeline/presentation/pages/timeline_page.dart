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
  Future<List<MediaAsset>>? _assetsFuture;
  MemoryEvent? _selectedEvent;

  @override
  void initState() {
    super.initState();
    _eventsFuture = widget._repository.fetchTimeline();
  }

  void _selectEvent(MemoryEvent event) {
    setState(() {
      _selectedEvent = event;
      _assetsFuture = widget._repository.fetchTimelineAssets(eventId: event.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<List<MemoryEvent>>(
      future: _eventsFuture,
      builder: (context, snapshot) {
        final events = snapshot.data ?? const <MemoryEvent>[];
        final selected = _selectedEvent ?? (events.isNotEmpty ? events.first : null);
        if (_selectedEvent == null && selected != null) {
          _selectedEvent = selected;
          _assetsFuture ??= widget._repository.fetchTimelineAssets(eventId: selected.id);
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
                  if (snapshot.connectionState == ConnectionState.waiting && events.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else
                    ...events.map(
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
                                    margin: const EdgeInsets.symmetric(vertical: 8),
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
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(event.date, style: theme.textTheme.labelLarge),
                                      const SizedBox(height: 6),
                                      Text(event.title, style: theme.textTheme.titleLarge),
                                      const SizedBox(height: 8),
                                      Text(event.description, style: theme.textTheme.bodyMedium),
                                      const SizedBox(height: 12),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF0F5FF),
                                          borderRadius: BorderRadius.circular(999),
                                        ),
                                        child: Text(event.tag, style: theme.textTheme.labelLarge),
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
                  const SizedBox(height: 18),
                  if (selected == null)
                    Text('先选择一个记忆事件。', style: theme.textTheme.bodyLarge)
                  else
                    FutureBuilder<List<MediaAsset>>(
                      future: _assetsFuture,
                      builder: (context, assetSnapshot) {
                        final assets = assetSnapshot.data ?? const <MediaAsset>[];
                        if (assetSnapshot.connectionState == ConnectionState.waiting && assets.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 32),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        if (assets.isEmpty) {
                          return Text('这个记忆事件下暂时还没有素材。', style: theme.textTheme.bodyLarge);
                        }
                        return Column(
                          children: assets
                              .take(12)
                              .map(
                                (asset) => Padding(
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
                                        _TimelineThumbnail(asset: asset),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(asset.fileName, style: theme.textTheme.titleMedium),
                                              const SizedBox(height: 6),
                                              Text(asset.relativePath, style: theme.textTheme.bodyMedium),
                                            ],
                                          ),
                                        ),
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
          ],
        );
      },
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
