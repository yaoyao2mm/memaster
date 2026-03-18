import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../network/local_api_client.dart';

class ServiceBootstrapResult {
  const ServiceBootstrapResult({
    required this.ready,
    this.error,
  });

  final bool ready;
  final String? error;
}

class LocalServiceRuntime {
  LocalServiceRuntime({LocalApiClient? apiClient})
      : _apiClient = apiClient ?? LocalApiClient();

  final LocalApiClient _apiClient;
  Process? _process;
  bool _startAttempted = false;
  String? _lastError;

  String? get lastError => _lastError;
  String? get serviceDirectoryPath => _resolveServiceDirectory()?.path;
  String? get pythonExecutablePath {
    final serviceDir = _resolveServiceDirectory();
    if (serviceDir == null) {
      return null;
    }
    return _resolvePythonExecutable(serviceDir)?.path;
  }

  String get appDataPath => _resolveAppDataDirectory().path;
  String get logFilePath =>
      '${_resolveAppDataDirectory().path}/logs/service.log';

  Future<ServiceBootstrapResult> ensureReady() async {
    if (await isHealthy()) {
      return const ServiceBootstrapResult(ready: true);
    }

    if (!_startAttempted) {
      _startAttempted = true;
      await _startService();
    }

    for (var attempt = 0; attempt < 24; attempt += 1) {
      if (await isHealthy()) {
        return const ServiceBootstrapResult(ready: true);
      }
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }

    return ServiceBootstrapResult(
      ready: false,
      error: _lastError ?? '本地服务启动失败，请检查 Python 环境和 service 目录。',
    );
  }

  Future<bool> isHealthy() async {
    try {
      final payload = await _apiClient.getJson('/health');
      return payload['status'] == 'ok';
    } catch (_) {
      return false;
    }
  }

  Future<void> _startService() async {
    final serviceDir = _resolveServiceDirectory();
    if (serviceDir == null) {
      _lastError = '找不到本地 service 目录。';
      return;
    }

    final python = _resolvePythonExecutable(serviceDir);
    if (python == null) {
      _lastError = '找不到 service/.venv/bin/python。';
      return;
    }

    final appDataDir = _resolveAppDataDirectory();
    final thumbnailsDir = Directory('${appDataDir.path}/thumbnails');
    if (!thumbnailsDir.existsSync()) {
      thumbnailsDir.createSync(recursive: true);
    }
    final logsDir = Directory('${appDataDir.path}/logs');
    if (!logsDir.existsSync()) {
      logsDir.createSync(recursive: true);
    }
    final logFile = File('${logsDir.path}/service.log');

    final environment = <String, String>{
      ...Platform.environment,
      'LOCAL_AI_DB_PATH': '${appDataDir.path}/memory.db',
      'LOCAL_AI_THUMBNAILS_DIR': thumbnailsDir.path,
    };

    try {
      _process = await Process.start(
        python.path,
        const [
          '-m',
          'uvicorn',
          'app.main:app',
          '--host',
          '127.0.0.1',
          '--port',
          '4318',
        ],
        workingDirectory: serviceDir.path,
        environment: environment,
      );
      unawaited(
        _process!.stdout.transform(utf8.decoder).listen(
          (chunk) {
            logFile.writeAsStringSync(chunk, mode: FileMode.append);
          },
        ).asFuture<void>(),
      );
      unawaited(
        _process!.stderr.transform(utf8.decoder).listen(
          (chunk) {
            _lastError = chunk.trim().isEmpty ? _lastError : chunk.trim();
            logFile.writeAsStringSync(chunk, mode: FileMode.append);
          },
        ).asFuture<void>(),
      );
    } catch (error) {
      _lastError = '$error';
    }
  }

  Directory? _resolveServiceDirectory() {
    final candidates = [
      Directory('${Directory.current.path}/service'),
      Directory(
        '${File(Platform.resolvedExecutable).parent.parent.path}/Resources/service',
      ),
    ];
    for (final candidate in candidates) {
      if (candidate.existsSync()) {
        return candidate;
      }
    }
    return null;
  }

  File? _resolvePythonExecutable(Directory serviceDir) {
    final candidates = [
      File('${serviceDir.path}/.venv/bin/python'),
      File('${serviceDir.path}/.venv/Scripts/python.exe'),
    ];
    for (final candidate in candidates) {
      if (candidate.existsSync()) {
        return candidate;
      }
    }
    return null;
  }

  Directory _resolveAppDataDirectory() {
    final home = Platform.environment['HOME'];
    if (Platform.isMacOS && home != null) {
      final dir = Directory('$home/Library/Application Support/memaster');
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
      return dir;
    }
    if (Platform.isLinux && home != null) {
      final dir = Directory('$home/.local/share/memaster');
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
      return dir;
    }
    final appData = Platform.environment['APPDATA'];
    if (Platform.isWindows && appData != null) {
      final dir = Directory('$appData\\memaster');
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
      return dir;
    }
    final fallback = Directory('${Directory.systemTemp.path}/memaster');
    if (!fallback.existsSync()) {
      fallback.createSync(recursive: true);
    }
    return fallback;
  }
}
