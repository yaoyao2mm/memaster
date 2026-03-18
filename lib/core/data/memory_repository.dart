import '../models/app_models.dart';
import '../network/local_api_client.dart';
import 'mock_memory_data.dart';

class MemoryRepository {
  MemoryRepository({LocalApiClient? apiClient})
      : _apiClient = apiClient ?? LocalApiClient();

  final LocalApiClient _apiClient;

  static final instance = MemoryRepository();

  Future<DashboardData> fetchDashboard() async {
    try {
      final json = await _apiClient.getJson('/dashboard');
      return DashboardData.fromJson(json);
    } catch (_) {
      return MockMemoryData.dashboard;
    }
  }

  Future<List<SmartAlbum>> fetchAlbums() async {
    try {
      final json = await _apiClient.getJson('/albums');
      return _parseList(json['items'], SmartAlbum.fromJson);
    } catch (_) {
      return MockMemoryData.albums;
    }
  }

  Future<List<MediaAsset>> fetchAssets({
    String? albumType,
    int? limit,
  }) async {
    try {
      final params = <String>[
        if (albumType != null && albumType.isNotEmpty) 'album_type=$albumType',
        if (limit != null) 'limit=$limit',
      ];
      final suffix = params.isEmpty ? '' : '?${params.join('&')}';
      final json = await _apiClient.getJson('/assets$suffix');
      return _parseList(json['items'], MediaAsset.fromJson);
    } catch (_) {
      final items = MockMemoryData.assets;
      if (albumType == null || albumType.isEmpty) {
        return items;
      }
      return items.where((item) => item.smartAlbumType == albumType).toList();
    }
  }

  Future<List<PersonCluster>> fetchPeople() async {
    try {
      final json = await _apiClient.getJson('/people');
      return _parseList(json['items'], PersonCluster.fromJson);
    } catch (_) {
      return MockMemoryData.people;
    }
  }

  Future<bool> confirmPerson({
    required String clusterId,
    required String name,
    required bool isSelf,
  }) async {
    try {
      await _apiClient.postJson(
        '/people/$clusterId/confirm',
        body: {
          'name': name,
          'is_self': isSelf,
        },
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<MemoryEvent>> fetchTimeline() async {
    try {
      final json = await _apiClient.getJson('/timeline');
      return _parseList(json['items'], MemoryEvent.fromJson);
    } catch (_) {
      return MockMemoryData.memoryEvents;
    }
  }

  Future<List<MediaAsset>> fetchTimelineAssets({
    required String eventId,
    int limit = 120,
  }) async {
    try {
      final json = await _apiClient.getJson('/timeline/$eventId/assets?limit=$limit');
      return _parseList(json['items'], MediaAsset.fromJson);
    } catch (_) {
      return MockMemoryData.assets;
    }
  }

  Future<List<ScanJob>> fetchScanJobs() async {
    try {
      final json = await _apiClient.getJson('/dashboard');
      return _parseList(json['scan_jobs'], ScanJob.fromJson);
    } catch (_) {
      return MockMemoryData.scanJobs;
    }
  }

  Future<ScanJob?> createScanJob({
    required String rootPath,
    required bool recursive,
    required String mode,
  }) async {
    try {
      final created = await _apiClient.postJson(
        '/scan-jobs',
        body: {
          'root_path': rootPath,
          'recursive': recursive,
          'mode': mode,
        },
      );
      final jobId = created['job_id'] as String?;
      if (jobId == null || jobId.isEmpty) {
        return null;
      }
      final job = await _apiClient.getJson('/scan-jobs/$jobId');
      return ScanJob.fromJson(job);
    } catch (_) {
      return null;
    }
  }

  Future<bool> applyAlbumCorrection({
    required String assetId,
    required String from,
    required String to,
  }) async {
    try {
      await _apiClient.postJson(
        '/corrections',
        body: {
          'asset_id': assetId,
          'kind': 'album_label',
          'from': from,
          'to': to,
        },
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<CorrectionRecord>> fetchCorrections({int limit = 20}) async {
    try {
      final json = await _apiClient.getJson('/corrections?limit=$limit');
      return _parseList(json['items'], CorrectionRecord.fromJson);
    } catch (_) {
      return MockMemoryData.corrections;
    }
  }

  List<T> _parseList<T>(
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
}
