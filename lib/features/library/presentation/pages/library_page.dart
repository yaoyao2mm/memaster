import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  late final TextEditingController _queryController;
  List<MediaAsset> _assetsCache = const [];
  String? _selectedSourceId;
  String _selectedAlbumType = 'all';
  _AssetSort _sort = _AssetSort.modifiedDesc;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _queryController = TextEditingController();
    _sourcesFuture = widget._repository.fetchSources();
    _assetsFuture = _loadAssets();
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<List<MediaAsset>> _loadAssets() {
    return widget._repository.fetchAssets(
      sourceId: _selectedSourceId,
      albumType: _selectedAlbumType == 'all' ? null : _selectedAlbumType,
      limit: 240,
    );
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
      _assetsFuture = _loadAssets();
    });
  }

  void _refresh() {
    setState(() {
      _sourcesFuture = widget._repository.fetchSources();
      _assetsFuture = _loadAssets();
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedSourceId = null;
      _selectedAlbumType = 'all';
      _query = '';
      _queryController.clear();
      _assetsFuture = _loadAssets();
    });
  }

  Future<void> _showAssetDetail(MediaAsset asset) async {
    final theme = Theme.of(context);
    final fullPath = _assetFullPath(asset);
    final tagController = TextEditingController();
    var currentAsset = asset;
    var tagSubmitting = false;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> syncAsset(MediaAsset nextAsset) async {
              currentAsset = nextAsset;
              if (mounted) {
                setState(() {
                  _assetsCache = _assetsCache
                      .map((item) =>
                          item.assetId == nextAsset.assetId ? nextAsset : item)
                      .toList();
                });
              }
              setSheetState(() {});
            }

            Future<void> addTag() async {
              final tag = tagController.text.trim();
              if (tag.isEmpty || tagSubmitting) {
                return;
              }
              setSheetState(() {
                tagSubmitting = true;
              });
              final updated = await widget._repository.addAssetTag(
                assetId: currentAsset.assetId,
                tag: tag,
              );
              tagController.clear();
              setSheetState(() {
                tagSubmitting = false;
              });
              if (updated != null) {
                await syncAsset(updated);
              }
            }

            Future<void> removeTag(String tag) async {
              if (tagSubmitting) {
                return;
              }
              setSheetState(() {
                tagSubmitting = true;
              });
              final updated = await widget._repository.removeAssetTag(
                assetId: currentAsset.assetId,
                tag: tag,
              );
              setSheetState(() {
                tagSubmitting = false;
              });
              if (updated != null) {
                await syncAsset(updated);
              }
            }

            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: GlassCard(
                borderRadius: 32,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompact = constraints.maxWidth < 560;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                currentAsset.fileName,
                                style: theme.textTheme.headlineSmall,
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '这条记录来自统一索引层。你现在可以维护来源、分类、标签和文件定位信息。',
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 18),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _MetaPill(
                              label:
                                  currentAsset.sourceName ?? 'Unknown Source',
                            ),
                            _MetaPill(
                              label: _albumLabel(currentAsset.smartAlbumType),
                            ),
                            _MetaPill(
                              label: currentAsset.mediaKind == 'video'
                                  ? '视频'
                                  : '图片',
                            ),
                            _MetaPill(
                                label: _formatSize(currentAsset.sizeBytes)),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text('用户标签', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 10),
                        if (currentAsset.tags.isEmpty)
                          Text('还没有用户标签。', style: theme.textTheme.bodyMedium)
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: currentAsset.tags
                                .map(
                                  (tag) => InputChip(
                                    label: Text(tag),
                                    onDeleted: () => removeTag(tag),
                                  ),
                                )
                                .toList(),
                          ),
                        const SizedBox(height: 12),
                        isCompact
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  TextField(
                                    controller: tagController,
                                    decoration: InputDecoration(
                                      hintText: '新增标签，例如 猫猫 / 精选 / 要整理',
                                      filled: true,
                                      fillColor:
                                          Colors.white.withValues(alpha: 0.72),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: const BorderSide(
                                          color: AppColors.line,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: const BorderSide(
                                          color: AppColors.line,
                                        ),
                                      ),
                                    ),
                                    onSubmitted: (_) => addTag(),
                                  ),
                                  const SizedBox(height: 12),
                                  FilledButton(
                                    onPressed: tagSubmitting ? null : addTag,
                                    child:
                                        Text(tagSubmitting ? '提交中…' : '添加标签'),
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: tagController,
                                      decoration: InputDecoration(
                                        hintText: '新增标签，例如 猫猫 / 精选 / 要整理',
                                        filled: true,
                                        fillColor: Colors.white
                                            .withValues(alpha: 0.72),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          borderSide: const BorderSide(
                                            color: AppColors.line,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          borderSide: const BorderSide(
                                            color: AppColors.line,
                                          ),
                                        ),
                                      ),
                                      onSubmitted: (_) => addTag(),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  FilledButton(
                                    onPressed: tagSubmitting ? null : addTag,
                                    child:
                                        Text(tagSubmitting ? '提交中…' : '添加标签'),
                                  ),
                                ],
                              ),
                        const SizedBox(height: 20),
                        _DetailRow(
                            label: '来源根目录', value: currentAsset.rootPath),
                        _DetailRow(
                            label: '相对路径', value: currentAsset.relativePath),
                        _DetailRow(label: '完整路径', value: fullPath),
                        _DetailRow(
                            label: '修改时间', value: currentAsset.modifiedAt),
                        const SizedBox(height: 20),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            FilledButton.icon(
                              onPressed: () => _openOriginal(fullPath),
                              icon: const Icon(Icons.open_in_new_rounded),
                              label: const Text('打开原文件'),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => _revealInFileManager(fullPath),
                              icon: const Icon(Icons.folder_open_rounded),
                              label: const Text('在 Finder 中显示'),
                            ),
                            OutlinedButton.icon(
                              onPressed: () async {
                                final messenger = ScaffoldMessenger.of(context);
                                await Clipboard.setData(
                                  ClipboardData(text: fullPath),
                                );
                                if (!mounted) {
                                  return;
                                }
                                messenger.showSnackBar(
                                  const SnackBar(content: Text('完整路径已复制')),
                                );
                              },
                              icon: const Icon(Icons.content_copy_rounded),
                              label: const Text('复制路径'),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
    tagController.dispose();
  }

  String _assetFullPath(MediaAsset asset) {
    final separator = asset.rootPath.endsWith(Platform.pathSeparator)
        ? ''
        : Platform.pathSeparator;
    return '${asset.rootPath}$separator${asset.relativePath}';
  }

  Future<void> _openOriginal(String fullPath) async {
    await _runDesktopOpen(
      macosArgs: [fullPath],
      linuxArgs: [fullPath],
      windowsArgs: ['/c', 'start', '', fullPath],
      failureMessage: '无法打开原文件',
    );
  }

  Future<void> _revealInFileManager(String fullPath) async {
    await _runDesktopOpen(
      macosArgs: ['-R', fullPath],
      linuxArgs: [File(fullPath).parent.path],
      windowsArgs: ['/c', 'explorer', '/select,', fullPath],
      failureMessage: '无法在文件管理器中定位该文件',
    );
  }

  Future<void> _runDesktopOpen({
    required List<String> macosArgs,
    required List<String> linuxArgs,
    required List<String> windowsArgs,
    required String failureMessage,
  }) async {
    try {
      ProcessResult result;
      if (Platform.isMacOS) {
        result = await Process.run('open', macosArgs);
      } else if (Platform.isLinux) {
        result = await Process.run('xdg-open', linuxArgs);
      } else if (Platform.isWindows) {
        result = await Process.run('cmd', windowsArgs);
      } else {
        throw UnsupportedError('Unsupported platform');
      }
      if (result.exitCode != 0) {
        throw ProcessException(
            'open', macosArgs, '${result.stderr}', result.exitCode);
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failureMessage)));
    }
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
                    controller: _queryController,
                    onChanged: (value) {
                      setState(() {
                        _query = value.trim().toLowerCase();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: '搜索文件名或相对路径，例如 cat / travel / screenshot',
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
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      FilledButton.tonalIcon(
                        onPressed: _refresh,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('刷新'),
                      ),
                      DropdownButtonHideUnderline(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.76),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.line),
                          ),
                          child: DropdownButton<_AssetSort>(
                            value: _sort,
                            borderRadius: BorderRadius.circular(16),
                            items: const [
                              DropdownMenuItem(
                                value: _AssetSort.modifiedDesc,
                                child: Text('按时间排序'),
                              ),
                              DropdownMenuItem(
                                value: _AssetSort.sizeDesc,
                                child: Text('按体积排序'),
                              ),
                              DropdownMenuItem(
                                value: _AssetSort.nameAsc,
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
                      if (_selectedSourceId != null ||
                          _selectedAlbumType != 'all' ||
                          _query.isNotEmpty)
                        OutlinedButton(
                          onPressed: _clearFilters,
                          child: const Text('清除过滤'),
                        ),
                    ],
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
                _assetsCache = assets;
                final visibleAssets = assets.where((asset) {
                  if (_query.isEmpty) {
                    return true;
                  }
                  final haystack =
                      '${asset.fileName} ${asset.relativePath} ${asset.sourceName ?? ''}'
                          .toLowerCase();
                  return haystack.contains(_query);
                }).toList();
                final displayAssets = _assetsCache.isEmpty
                    ? visibleAssets
                    : _assetsCache.where((asset) {
                        if (_query.isEmpty) {
                          return true;
                        }
                        final haystack =
                            '${asset.fileName} ${asset.relativePath} ${asset.sourceName ?? ''} ${asset.tags.join(' ')}'
                                .toLowerCase();
                        return haystack.contains(_query);
                      }).toList();
                final sortedAssets = _sortAssets(displayAssets);
                return GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('已索引资产', style: theme.textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text(
                        '当前显示 ${sortedAssets.length} 条结果，来源 ${sources.length} 个',
                        style: theme.textTheme.bodyMedium,
                      ),
                      if (_selectedSourceId != null ||
                          _selectedAlbumType != 'all' ||
                          _query.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (_selectedSourceId != null)
                              _MetaPill(label: _selectedSourceLabel(sources)),
                            if (_selectedAlbumType != 'all')
                              _MetaPill(label: _albumLabel(_selectedAlbumType)),
                            if (_query.isNotEmpty)
                              _MetaPill(label: '搜索: $_query'),
                          ],
                        ),
                      ],
                      const SizedBox(height: 18),
                      if (assetSnapshot.connectionState ==
                              ConnectionState.waiting &&
                          assets.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (sortedAssets.isEmpty)
                        Text('当前过滤条件下还没有资产。', style: theme.textTheme.bodyLarge)
                      else
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final columns =
                                constraints.maxWidth >= 1120 ? 2 : 1;
                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: sortedAssets.length,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                mainAxisSpacing: 14,
                                crossAxisSpacing: 14,
                                childAspectRatio: columns == 1 ? 2.6 : 2.25,
                              ),
                              itemBuilder: (context, index) {
                                return _AssetLibraryCard(
                                  asset: sortedAssets[index],
                                  onTap: () =>
                                      _showAssetDetail(sortedAssets[index]),
                                );
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

  List<MediaAsset> _sortAssets(List<MediaAsset> assets) {
    final sorted = [...assets];
    switch (_sort) {
      case _AssetSort.modifiedDesc:
        sorted
            .sort((left, right) => right.modifiedAt.compareTo(left.modifiedAt));
        break;
      case _AssetSort.sizeDesc:
        sorted.sort((left, right) => right.sizeBytes.compareTo(left.sizeBytes));
        break;
      case _AssetSort.nameAsc:
        sorted.sort((left, right) => left.fileName.compareTo(right.fileName));
        break;
    }
    return sorted;
  }

  String _selectedSourceLabel(List<MediaSource> sources) {
    for (final source in sources) {
      if (source.sourceId == _selectedSourceId) {
        return source.displayName;
      }
    }
    return '已选来源';
  }
}

enum _AssetSort {
  modifiedDesc,
  sizeDesc,
  nameAsc,
}

class _AssetLibraryCard extends StatelessWidget {
  const _AssetLibraryCard({required this.asset, required this.onTap});

  final MediaAsset asset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final theme = Theme.of(context);
        final isCompact = constraints.maxWidth < 520;
        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.84),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.line),
            ),
            child: isCompact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _AssetThumbnail(asset: asset),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              asset.fileName,
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.mutedInk,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        asset.relativePath,
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _MetaPill(
                              label: asset.sourceName ?? 'Unknown Source'),
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
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _AssetThumbnail(asset: asset),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(asset.fileName,
                                style: theme.textTheme.titleMedium),
                            const SizedBox(height: 6),
                            Text(
                              asset.relativePath,
                              style: theme.textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _MetaPill(
                                  label: asset.sourceName ?? 'Unknown Source',
                                ),
                                _MetaPill(
                                  label: _albumLabel(asset.smartAlbumType),
                                ),
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
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.mutedInk,
                      ),
                    ],
                  ),
          ),
        );
      },
    );
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

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelLarge),
          const SizedBox(height: 4),
          Text(value, style: theme.textTheme.bodyMedium),
        ],
      ),
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
