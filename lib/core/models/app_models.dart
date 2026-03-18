import 'package:flutter/material.dart';

class MemoryStat {
  const MemoryStat({
    required this.label,
    required this.value,
    this.delta,
  });

  final String label;
  final String value;
  final String? delta;

  factory MemoryStat.fromJson(Map<String, dynamic> json) {
    return MemoryStat(
      label: json['label'] as String? ?? '',
      value: json['value'] as String? ?? '',
      delta: json['delta'] as String?,
    );
  }
}

class SmartAlbum {
  const SmartAlbum({
    required this.title,
    required this.count,
    required this.description,
    required this.color,
    required this.coverLabel,
  });

  final String title;
  final String count;
  final String description;
  final Color color;
  final String coverLabel;

  factory SmartAlbum.fromJson(Map<String, dynamic> json) {
    return SmartAlbum(
      title: json['title'] as String? ?? '',
      count: json['count'] as String? ?? '',
      description: json['description'] as String? ?? '',
      color: _colorFromString(json['color'] as String?),
      coverLabel: json['cover_label'] as String? ?? '',
    );
  }
}

class MemoryEvent {
  const MemoryEvent({
    required this.id,
    required this.date,
    required this.title,
    required this.description,
    required this.tag,
  });

  final String id;
  final String date;
  final String title;
  final String description;
  final String tag;

  factory MemoryEvent.fromJson(Map<String, dynamic> json) {
    return MemoryEvent(
      id: json['id'] as String? ?? '',
      date: json['date'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      tag: json['tag'] as String? ?? '',
    );
  }
}

class PersonCluster {
  const PersonCluster({
    required this.id,
    required this.name,
    required this.assetCount,
    required this.trait,
    required this.color,
    required this.reviewState,
    this.isSelf = false,
  });

  final String id;
  final String name;
  final int assetCount;
  final String trait;
  final Color color;
  final String reviewState;
  final bool isSelf;

  factory PersonCluster.fromJson(Map<String, dynamic> json) {
    return PersonCluster(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      assetCount: json['asset_count'] as int? ?? 0,
      trait: json['trait'] as String? ?? '',
      color: _colorFromString(json['color'] as String?),
      reviewState: json['review_state'] as String? ?? 'needs_review',
      isSelf: json['is_self'] as bool? ?? false,
    );
  }
}

class ScanJob {
  const ScanJob({
    required this.title,
    required this.status,
    required this.progress,
    required this.detail,
    this.rootPath,
    this.mode,
  });

  final String title;
  final String status;
  final double progress;
  final String detail;
  final String? rootPath;
  final String? mode;

  factory ScanJob.fromJson(Map<String, dynamic> json) {
    return ScanJob(
      title: json['title'] as String? ?? '',
      status: json['status'] as String? ?? '',
      progress: (json['progress'] as num?)?.toDouble() ?? 0,
      detail: json['detail'] as String? ?? '',
      rootPath: json['root_path'] as String?,
      mode: json['mode'] as String?,
    );
  }
}

class MediaAsset {
  const MediaAsset({
    required this.assetId,
    required this.fileName,
    required this.relativePath,
    required this.mediaKind,
    required this.smartAlbumType,
    this.thumbnailUrl,
    required this.sizeBytes,
    required this.modifiedAt,
    required this.rootPath,
  });

  final String assetId;
  final String fileName;
  final String relativePath;
  final String mediaKind;
  final String smartAlbumType;
  final String? thumbnailUrl;
  final int sizeBytes;
  final String modifiedAt;
  final String rootPath;

  factory MediaAsset.fromJson(Map<String, dynamic> json) {
    return MediaAsset(
      assetId: json['asset_id'] as String? ?? '',
      fileName: json['file_name'] as String? ?? '',
      relativePath: json['relative_path'] as String? ?? '',
      mediaKind: json['media_kind'] as String? ?? '',
      smartAlbumType: json['smart_album_type'] as String? ?? '',
      thumbnailUrl: json['thumbnail_url'] as String?,
      sizeBytes: json['size_bytes'] as int? ?? 0,
      modifiedAt: json['modified_at'] as String? ?? '',
      rootPath: json['root_path'] as String? ?? '',
    );
  }
}

class CorrectionRecord {
  const CorrectionRecord({
    required this.correctionId,
    required this.assetId,
    required this.kind,
    required this.fromValue,
    required this.toValue,
    required this.createdAt,
  });

  final String correctionId;
  final String assetId;
  final String kind;
  final String fromValue;
  final String toValue;
  final String createdAt;

  factory CorrectionRecord.fromJson(Map<String, dynamic> json) {
    return CorrectionRecord(
      correctionId: json['correction_id'] as String? ?? '',
      assetId: json['asset_id'] as String? ?? '',
      kind: json['kind'] as String? ?? '',
      fromValue: json['from'] as String? ?? '',
      toValue: json['to_value'] as String? ?? json['to'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}

class AppDestination {
  const AppDestination({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;
}

class DashboardData {
  const DashboardData({
    required this.stats,
    required this.smartAlbums,
    required this.signals,
    required this.recentEvents,
    required this.scanJobs,
    required this.people,
  });

  final List<MemoryStat> stats;
  final List<SmartAlbum> smartAlbums;
  final List<MemoryStat> signals;
  final List<MemoryEvent> recentEvents;
  final List<ScanJob> scanJobs;
  final List<PersonCluster> people;

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      stats: _listFromJson(json['stats'], MemoryStat.fromJson),
      smartAlbums: _listFromJson(json['smart_albums'], SmartAlbum.fromJson),
      signals: _listFromJson(json['signals'], MemoryStat.fromJson),
      recentEvents: _listFromJson(json['recent_events'], MemoryEvent.fromJson),
      scanJobs: _listFromJson(json['scan_jobs'], ScanJob.fromJson),
      people: _listFromJson(json['people'], PersonCluster.fromJson),
    );
  }
}

List<T> _listFromJson<T>(
  dynamic raw,
  T Function(Map<String, dynamic>) parser,
) {
  if (raw is! List) {
    return const [];
  }
  return raw
      .whereType<Map>()
      .map((item) => parser(item.cast<String, dynamic>()))
      .toList();
}

Color _colorFromString(String? raw) {
  if (raw == null || raw.isEmpty) {
    return const Color(0xFFE5E7EB);
  }
  final normalized = raw.replaceFirst('#', '');
  final value = int.tryParse(
    normalized.length == 6 ? 'FF$normalized' : normalized,
    radix: 16,
  );
  return Color(value ?? 0xFFE5E7EB);
}
