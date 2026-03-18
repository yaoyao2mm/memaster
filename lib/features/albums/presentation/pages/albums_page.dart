import 'package:flutter/material.dart';

import '../../../../core/data/memory_repository.dart';
import '../../../../core/models/app_models.dart';
import '../../../../core/theme/app_colors.dart';
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
  late final TextEditingController _assetQueryController;
  Future<List<MediaAsset>>? _assetsFuture;
  SmartAlbum? _selectedAlbum;
  bool _updatingAsset = false;
  String _assetQuery = '';
  _AlbumAssetSort _sort = _AlbumAssetSort.modifiedDesc;

  @override
  void initState() {
    super.initState();
    _assetQueryController = TextEditingController();
    _albumsFuture = widget._repository.fetchAlbums();
  }

  @override
  void dispose() {
    _assetQueryController.dispose();
    super.dispose();
  }

  void _selectAlbum(SmartAlbum album) {
    setState(() {
      _selectedAlbum = album;
      _assetsFuture = widget._repository
          .fetchAssets(albumType: _albumType(album), limit: 120);
    });
  }

  void _refresh() {
    setState(() {
      _albumsFuture = widget._repository.fetchAlbums();
      if (_selectedAlbum != null) {
        _assetsFuture = widget._repository.fetchAssets(
          albumType: _albumType(_selectedAlbum!),
          limit: 120,
        );
      }
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
        final selected =
            _selectedAlbum ?? (albums.isNotEmpty ? albums.first : null);
        if (_selectedAlbum == null && selected != null) {
          _selectedAlbum = selected;
          _assetsFuture ??= widget._repository.fetchAssets(
            albumType: _albumType(selected),
            limit: 120,
          );
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
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      FilledButton.tonalIcon(
                        onPressed: _refresh,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('刷新相册'),
                      ),
                      if (selected != null) _InfoPill(label: selected.count),
                      if (selected != null)
                        _InfoPill(label: _albumLabel(_albumType(selected))),
                    ],
                  ),
                  const SizedBox(height: 18),
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      albums.isEmpty)
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
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
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
                                    color: isSelected
                                        ? const Color(0xFF3D6BFF)
                                        : Colors.transparent,
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
                  if (selected != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      selected.description,
                      style: theme.textTheme.bodyMedium,
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
                      hintText: '筛选当前相册素材，例如 cat / trip / screenshot',
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
                    Text('请先选择一个智能相册。', style: theme.textTheme.bodyLarge)
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
                        final visibleAssets = _sortAssets(
                          assets.where((asset) {
                            if (_assetQuery.isEmpty) {
                              return true;
                            }
                            final haystack =
                                '${asset.fileName} ${asset.relativePath} ${asset.tags.join(' ')}'
                                    .toLowerCase();
                            return haystack.contains(_assetQuery);
                          }).toList(),
                        );
                        if (assets.isEmpty) {
                          return Text('当前相册还没有真实素材。',
                              style: theme.textTheme.bodyLarge);
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                DropdownButtonHideUnderline(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.76),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: AppColors.line),
                                    ),
                                    child: DropdownButton<_AlbumAssetSort>(
                                      value: _sort,
                                      borderRadius: BorderRadius.circular(16),
                                      items: const [
                                        DropdownMenuItem(
                                          value: _AlbumAssetSort.modifiedDesc,
                                          child: Text('按时间排序'),
                                        ),
                                        DropdownMenuItem(
                                          value: _AlbumAssetSort.sizeDesc,
                                          child: Text('按体积排序'),
                                        ),
                                        DropdownMenuItem(
                                          value: _AlbumAssetSort.nameAsc,
                                          child: Text('按名称排序'),
                                        ),
                                      ],
                                      onChanged: (value) {
                                        if (value == null) {
                                          return;
                                        }
                                        setState(() {
                                          _sort = value;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                                _InfoPill(
                                    label: '当前 ${visibleAssets.length} 条'),
                                if (_assetQuery.isNotEmpty)
                                  _InfoPill(label: '搜索: $_assetQuery'),
                              ],
                            ),
                            const SizedBox(height: 18),
                            if (visibleAssets.isEmpty)
                              Text(
                                '当前筛选条件下没有素材。',
                                style: theme.textTheme.bodyLarge,
                              )
                            else
                              Column(
                                children: visibleAssets
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
                                                color: const Color(0x1A10223A)),
                                          ),
                                          child: Column(
                                            children: [
                                              Row(
                                                children: [
                                                  _AssetThumbnail(asset: asset),
                                                  const SizedBox(width: 14),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          asset.fileName,
                                                          style: theme.textTheme
                                                              .titleMedium,
                                                        ),
                                                        const SizedBox(
                                                            height: 6),
                                                        Text(
                                                          asset.relativePath,
                                                          style: theme.textTheme
                                                              .bodyMedium,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Text(
                                                    _formatSize(
                                                        asset.sizeBytes),
                                                    style: theme
                                                        .textTheme.labelLarge,
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 14),
                                              Wrap(
                                                spacing: 8,
                                                runSpacing: 8,
                                                children: [
                                                  _InfoPill(
                                                    label: asset.sourceName ??
                                                        'Unknown Source',
                                                  ),
                                                  ...asset.tags.map(
                                                    (tag) => _InfoPill(
                                                      label: tag,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 14),
                                              Row(
                                                children: [
                                                  Text(
                                                    '当前分类',
                                                    style: theme
                                                        .textTheme.bodyMedium,
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 12,
                                                      vertical: 4,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white
                                                          .withValues(
                                                              alpha: 0.82),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              14),
                                                      border: Border.all(
                                                          color: const Color(
                                                              0x1A10223A)),
                                                    ),
                                                    child:
                                                        DropdownButtonHideUnderline(
                                                      child: DropdownButton<
                                                          String>(
                                                        value: asset
                                                            .smartAlbumType,
                                                        isDense: true,
                                                        items: const [
                                                          DropdownMenuItem(
                                                              value: 'pet',
                                                              child:
                                                                  Text('宠物')),
                                                          DropdownMenuItem(
                                                              value: 'travel',
                                                              child:
                                                                  Text('旅行')),
                                                          DropdownMenuItem(
                                                              value: 'daily',
                                                              child:
                                                                  Text('日常')),
                                                          DropdownMenuItem(
                                                              value: 'document',
                                                              child:
                                                                  Text('文档')),
                                                          DropdownMenuItem(
                                                              value: 'video',
                                                              child:
                                                                  Text('视频')),
                                                          DropdownMenuItem(
                                                              value: 'food',
                                                              child:
                                                                  Text('美食')),
                                                        ],
                                                        onChanged:
                                                            _updatingAsset
                                                                ? null
                                                                : (value) {
                                                                    if (value ==
                                                                        null) {
                                                                      return;
                                                                    }
                                                                    _changeAssetAlbum(
                                                                      asset,
                                                                      value,
                                                                    );
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

  List<MediaAsset> _sortAssets(List<MediaAsset> assets) {
    final sorted = [...assets];
    switch (_sort) {
      case _AlbumAssetSort.modifiedDesc:
        sorted
            .sort((left, right) => right.modifiedAt.compareTo(left.modifiedAt));
        break;
      case _AlbumAssetSort.sizeDesc:
        sorted.sort((left, right) => right.sizeBytes.compareTo(left.sizeBytes));
        break;
      case _AlbumAssetSort.nameAsc:
        sorted.sort((left, right) => left.fileName.compareTo(right.fileName));
        break;
    }
    return sorted;
  }
}

enum _AlbumAssetSort {
  modifiedDesc,
  sizeDesc,
  nameAsc,
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

String _albumLabel(String albumType) {
  switch (albumType) {
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

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.label});

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
