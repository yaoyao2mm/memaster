import 'package:flutter/material.dart';

import '../../../../core/data/memory_repository.dart';
import '../../../../core/models/app_models.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/section_title.dart';

class LibraryPage extends StatefulWidget {
  LibraryPage({super.key, MemoryRepository? repository})
      : _repository = repository ?? MemoryRepository.instance;

  final MemoryRepository _repository;

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  late Future<List<MediaSource>> _sourcesFuture;
  late Future<List<MediaAsset>> _assetsFuture;
  String? _selectedSourceId;
  String _selectedAlbumType = 'all';
  String _query = '';

  @override
  void initState() {
    super.initState();
    _sourcesFuture = widget._repository.fetchSources();
    _assetsFuture = widget._repository.fetchAssets(limit: 240);
  }

  void _applyFilters({
    String? sourceId,
    String? albumType,
  }) {
    setState(() {
      _selectedSourceId = sourceId;
      if (albumType != null) {
        _selectedAlbumType = albumType;
      }
      _assetsFuture = widget._repository.fetchAssets(
        sourceId: _selectedSourceId,
        albumType: _selectedAlbumType == 'all' ? null : _selectedAlbumType,
        limit: 240,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<List<MediaSource>>(
      future: _sourcesFuture,
      builder: (context, sourceSnapshot) {
        final sources = sourceSnapshot.data ?? const <MediaSource>[];
        final filteredAssetsFuture = _assetsFuture;
        return ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle(
                    eyebrow: 'Indexed Assets',
                    title: '统一资产库',
                    actionLabel: '来源、标签和路径会在这里聚合',
                  ),
                  const SizedBox(height: 22),
                  TextField(
                    onChanged: (value) {
                      setState(() {
                        _query = value.trim().toLowerCase();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: '搜索文件名或相对路径，例如 cat / travel / screenshot',
                      prefixIcon: const Icon(Icons.search_rounded),
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
                        selected: _selectedSourceId == null,
                        label: const Text('全部来源'),
                        onSelected: (_) => _applyFilters(sourceId: null),
                      ),
                      ...sources.map(
                        (source) => ChoiceChip(
                          selected: _selectedSourceId == source.sourceId,
                          label: Text(source.displayName),
                          onSelected: (_) =>
                              _applyFilters(sourceId: source.sourceId),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: const [
                      _LibraryAlbumChip(label: '全部分类', value: 'all'),
                      _LibraryAlbumChip(label: '宠物', value: 'pet'),
                      _LibraryAlbumChip(label: '旅行', value: 'travel'),
                      _LibraryAlbumChip(label: '日常', value: 'daily'),
                      _LibraryAlbumChip(label: '文档', value: 'document'),
                      _LibraryAlbumChip(label: '视频', value: 'video'),
                      _LibraryAlbumChip(label: '美食', value: 'food'),
                    ].map((chip) {
                      final selected = chip.value == _selectedAlbumType;
                      return ChoiceChip(
                        selected: selected,
                        label: Text(chip.label),
                        onSelected: (_) => _applyFilters(
                          sourceId: _selectedSourceId,
                          albumType: chip.value,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '这页展示的是统一索引后的资产集合。来源不改变原文件存放方式，但你可以在这里跨来源查看、过滤和定位素材。',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            FutureBuilder<List<MediaAsset>>(
              future: filteredAssetsFuture,
              builder: (context, assetSnapshot) {
                final assets = assetSnapshot.data ?? const <MediaAsset>[];
                final visibleAssets = assets.where((asset) {
                  if (_query.isEmpty) {
                    return true;
                  }
                  final haystack =
                      '${asset.fileName} ${asset.relativePath} ${asset.sourceName ?? ''}'
                          .toLowerCase();
                  return haystack.contains(_query);
                }).toList();
                return GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('已索引资产', style: theme.textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text(
                        '当前显示 ${visibleAssets.length} 条结果',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 18),
                      if (assetSnapshot.connectionState ==
                              ConnectionState.waiting &&
                          assets.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (visibleAssets.isEmpty)
                        Text('当前过滤条件下还没有资产。', style: theme.textTheme.bodyLarge)
                      else
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final columns =
                                constraints.maxWidth >= 1120 ? 2 : 1;
                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: visibleAssets.length,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                mainAxisSpacing: 14,
                                crossAxisSpacing: 14,
                                childAspectRatio: columns == 1 ? 2.6 : 2.25,
                              ),
                              itemBuilder: (context, index) {
                                return _AssetLibraryCard(
                                    asset: visibleAssets[index]);
                              },
                            );
                          },
                        ),
                    ],
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _AssetLibraryCard extends StatelessWidget {
  const _AssetLibraryCard({required this.asset});

  final MediaAsset asset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AssetThumbnail(asset: asset),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(asset.fileName, style: theme.textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(asset.relativePath, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MetaPill(label: asset.sourceName ?? 'Unknown Source'),
                    _MetaPill(label: _albumLabel(asset.smartAlbumType)),
                    _MetaPill(label: _formatSize(asset.sizeBytes)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  asset.rootPath,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppColors.mutedInk,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _albumLabel(String value) {
    switch (value) {
      case 'pet':
        return '宠物';
      case 'travel':
        return '旅行';
      case 'document':
        return '文档';
      case 'video':
        return '视频';
      case 'food':
        return '美食';
      default:
        return '日常';
    }
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F5FB),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelLarge),
    );
  }
}

class _LibraryAlbumChip {
  const _LibraryAlbumChip({required this.label, required this.value});

  final String label;
  final String value;
}

String _formatSize(int bytes) {
  if (bytes >= 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  if (bytes >= 1024) {
    return '${(bytes / 1024).toStringAsFixed(0)} KB';
  }
  return '$bytes B';
}

class _AssetThumbnail extends StatelessWidget {
  const _AssetThumbnail({required this.asset});

  final MediaAsset asset;

  @override
  Widget build(BuildContext context) {
    final uri = asset.thumbnailUrl;
    if (uri == null || uri.isEmpty) {
      return _FallbackThumbnail(kind: asset.mediaKind);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.network(
        'http://127.0.0.1:4318$uri',
        width: 72,
        height: 72,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _FallbackThumbnail(kind: asset.mediaKind),
      ),
    );
  }
}

class _FallbackThumbnail extends StatelessWidget {
  const _FallbackThumbnail({required this.kind});

  final String kind;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
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
