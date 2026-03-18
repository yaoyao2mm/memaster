import 'package:flutter/material.dart';

import '../../../../core/data/memory_repository.dart';
import '../../../../core/models/app_models.dart';
import '../../../../core/widgets/album_card.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/section_title.dart';

class AlbumsPage extends StatefulWidget {
  AlbumsPage({super.key, MemoryRepository? repository})
      : _repository = repository ?? MemoryRepository.instance;

  final MemoryRepository _repository;

  @override
  State<AlbumsPage> createState() => _AlbumsPageState();
}

class _AlbumsPageState extends State<AlbumsPage> {
  late Future<List<SmartAlbum>> _albumsFuture;
  Future<List<MediaAsset>>? _assetsFuture;
  SmartAlbum? _selectedAlbum;
  bool _updatingAsset = false;

  @override
  void initState() {
    super.initState();
    _albumsFuture = widget._repository.fetchAlbums();
  }

  void _selectAlbum(SmartAlbum album) {
    setState(() {
      _selectedAlbum = album;
      _assetsFuture = widget._repository.fetchAssets(albumType: _albumType(album), limit: 120);
    });
  }

  Future<void> _changeAssetAlbum(MediaAsset asset, String newAlbumType) async {
    if (_updatingAsset || asset.smartAlbumType == newAlbumType) {
      return;
    }
    setState(() {
      _updatingAsset = true;
    });
    final ok = await widget._repository.applyAlbumCorrection(
      assetId: asset.assetId,
      from: asset.smartAlbumType,
      to: newAlbumType,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _updatingAsset = false;
      _albumsFuture = widget._repository.fetchAlbums();
      if (_selectedAlbum != null) {
        _assetsFuture = widget._repository.fetchAssets(
          albumType: _albumType(_selectedAlbum!),
          limit: 120,
        );
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? '分类已更新' : '分类更新失败，请检查本地服务'),
      ),
    );
  }

  String _albumType(SmartAlbum album) {
    switch (album.coverLabel) {
      case 'CAT':
        return 'pet';
      case 'TRIP':
        return 'travel';
      case 'DOC':
        return 'document';
      case 'FOOD':
        return 'food';
      case 'VID':
        return 'video';
      default:
        return 'daily';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<List<SmartAlbum>>(
      future: _albumsFuture,
      builder: (context, snapshot) {
        final albums = snapshot.data ?? const <SmartAlbum>[];
        final selected = _selectedAlbum ?? (albums.isNotEmpty ? albums.first : null);
        if (_selectedAlbum == null && selected != null) {
          _selectedAlbum = selected;
          _assetsFuture ??= widget._repository.fetchAssets(albumType: _albumType(selected), limit: 120);
        }

        return ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle(
                    eyebrow: 'Curated',
                    title: '首期最有价值的语义相册',
                    actionLabel: '按置信度排序',
                  ),
                  const SizedBox(height: 22),
                  if (snapshot.connectionState == ConnectionState.waiting && albums.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final columns = constraints.maxWidth >= 980
                            ? 3
                            : constraints.maxWidth >= 640
                                ? 2
                                : 1;
                        return GridView.builder(
                          itemCount: albums.length,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: columns,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: columns == 1 ? 1.45 : 1.1,
                          ),
                          itemBuilder: (context, index) {
                            final album = albums[index];
                            final isSelected = selected?.title == album.title;
                            return InkWell(
                              onTap: () => _selectAlbum(album),
                              borderRadius: BorderRadius.circular(24),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: isSelected ? const Color(0xFF3D6BFF) : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: AlbumCard(album: album),
                              ),
                            );
                          },
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
                  Text(
                    selected == null ? '素材列表' : '${selected.title} · 真实扫描结果',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 18),
                  if (selected == null)
                    Text('请先选择一个智能相册。', style: theme.textTheme.bodyLarge)
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
                          return Text('当前相册还没有真实素材。', style: theme.textTheme.bodyLarge);
                        }
                        return Column(
                          children: assets
                              .map(
                                (asset) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.82),
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(color: const Color(0x1A10223A)),
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
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
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              _formatSize(asset.sizeBytes),
                                              style: theme.textTheme.labelLarge,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 14),
                                        Row(
                                          children: [
                                            Text('当前分类', style: theme.textTheme.bodyMedium),
                                            const SizedBox(width: 12),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withValues(alpha: 0.82),
                                                borderRadius: BorderRadius.circular(14),
                                                border: Border.all(color: const Color(0x1A10223A)),
                                              ),
                                              child: DropdownButtonHideUnderline(
                                                child: DropdownButton<String>(
                                                  value: asset.smartAlbumType,
                                                  isDense: true,
                                                  items: const [
                                                    DropdownMenuItem(value: 'pet', child: Text('宠物')),
                                                    DropdownMenuItem(value: 'travel', child: Text('旅行')),
                                                    DropdownMenuItem(value: 'daily', child: Text('日常')),
                                                    DropdownMenuItem(value: 'document', child: Text('文档')),
                                                    DropdownMenuItem(value: 'video', child: Text('视频')),
                                                    DropdownMenuItem(value: 'food', child: Text('美食')),
                                                  ],
                                                  onChanged: _updatingAsset
                                                      ? null
                                                      : (value) {
                                                          if (value == null) return;
                                                          _changeAssetAlbum(asset, value);
                                                        },
                                                ),
                                              ),
                                            ),
                                          ],
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
        width: 52,
        height: 52,
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
