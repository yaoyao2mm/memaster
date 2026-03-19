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

class _ServiceLaunchPlan {
  const _ServiceLaunchPlan({
    required this.executable,
    required this.arguments,
    required this.description,
    required this.healthCheckAttempts,
  });

  final String executable;
  final List<String> arguments;
  final String description;
  final int healthCheckAttempts;
}

class LocalServiceRuntime {
  LocalServiceRuntime({LocalApiClient? apiClient})
      : _apiClient = apiClient ?? LocalApiClient();

  final LocalApiClient _apiClient;
  Process? _process;
  bool _launchInProgress = false;
  String? _lastError;
  String? _launchDescription;
  int _healthCheckAttemptLimit = 24;

  String? get lastError => _lastError;
  String? get serviceDirectoryPath => _resolveServiceDirectory()?.path;
  String? get launchDescription => _launchDescription;
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

    if (_process == null && !_launchInProgress) {
      final plan = await _startService();
      if (plan != null) {
        _launchDescription = plan.description;
        _healthCheckAttemptLimit = plan.healthCheckAttempts;
      }
    }

    for (var attempt = 0; attempt < _healthCheckAttemptLimit; attempt += 1) {
      if (await isHealthy()) {
        return const ServiceBootstrapResult(ready: true);
      }
      if (_process == null && !_launchInProgress) {
        final plan = await _startService();
        if (plan != null) {
          _launchDescription = plan.description;
          _healthCheckAttemptLimit = plan.healthCheckAttempts;
        }
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

  Future<_ServiceLaunchPlan?> _startService() async {
    if (_launchInProgress) {
      return null;
    }
    _launchInProgress = true;

    final serviceDir = _resolveServiceDirectory();
    if (serviceDir == null) {
      _lastError = '找不到本地 service 目录。';
      _launchInProgress = false;
      return null;
    }

    final plan = _createLaunchPlan(serviceDir);
    if (plan == null) {
      _lastError = _buildMissingRuntimeError(serviceDir);
      _launchInProgress = false;
      return null;
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
      'PATH': _buildLaunchPath(serviceDir),
      'LOCAL_AI_DB_PATH': '${appDataDir.path}/memory.db',
      'LOCAL_AI_THUMBNAILS_DIR': thumbnailsDir.path,
    };

    try {
      _process = await Process.start(
        plan.executable,
        plan.arguments,
        workingDirectory: serviceDir.path,
        environment: environment,
      );
      final launchedProcess = _process!;
      unawaited(
        launchedProcess.exitCode.then((exitCode) {
          if (identical(_process, launchedProcess)) {
            _process = null;
          }
          if (exitCode != 0) {
            _lastError ??= '本地服务已退出，exit code: $exitCode';
          }
        }),
      );
      unawaited(
        launchedProcess.stdout.transform(utf8.decoder).listen(
          (chunk) {
            logFile.writeAsStringSync(chunk, mode: FileMode.append);
          },
        ).asFuture<void>(),
      );
      unawaited(
        launchedProcess.stderr.transform(utf8.decoder).listen(
          (chunk) {
            _lastError = chunk.trim().isEmpty ? _lastError : chunk.trim();
            logFile.writeAsStringSync(chunk, mode: FileMode.append);
          },
        ).asFuture<void>(),
      );
    } catch (error) {
      _lastError = '$error';
      _process = null;
    } finally {
      _launchInProgress = false;
    }

    return plan;
  }

  Directory? _resolveServiceDirectory() {
    for (final candidate in _serviceDirectoryCandidates()) {
      if (candidate.existsSync()) {
        return candidate;
      }
    }
    return null;
  }

  List<Directory> _serviceDirectoryCandidates() {
    final candidates = <Directory>[];
    final visited = <String>{};

    void addCandidate(String path) {
      if (visited.add(path)) {
        candidates.add(Directory(path));
      }
    }

    addCandidate('${Directory.current.path}/service');

    final executableDir = File(Platform.resolvedExecutable).parent;
    addCandidate('${executableDir.parent.path}/Resources/service');

    for (final base in [
      Directory.current,
      executableDir,
      executableDir.parent,
      executableDir.parent.parent,
    ]) {
      for (final ancestor in _ancestorDirectories(base)) {
        addCandidate('${ancestor.path}/service');
      }
    }

    return candidates;
  }

  Iterable<Directory> _ancestorDirectories(Directory start) sync* {
    var current = start.absolute;
    while (true) {
      yield current;
      final parent = current.parent;
      if (parent.path == current.path) {
        break;
      }
      current = parent;
    }
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

  _ServiceLaunchPlan? _createLaunchPlan(Directory serviceDir) {
    final bundledPython = _resolvePythonExecutable(serviceDir);
    if (_isBundledServiceDirectory(serviceDir)) {
      if (bundledPython == null) {
        return null;
      }
      return _pythonLaunchPlan(
        pythonPath: bundledPython.path,
        description: 'embedded Python runtime',
      );
    }

    if (bundledPython != null) {
      return _pythonLaunchPlan(
        pythonPath: bundledPython.path,
        description: 'service/.venv Python runtime',
      );
    }

    final uvExecutable = _resolveUvExecutable(serviceDir);
    if (uvExecutable != null) {
      return _ServiceLaunchPlan(
        executable: uvExecutable.path,
        arguments: const [
          'run',
          'uvicorn',
          'app.main:app',
          '--host',
          '127.0.0.1',
          '--port',
          '4318',
        ],
        description: 'uv run from local repository service',
        healthCheckAttempts: 120,
      );
    }

    return null;
  }

  _ServiceLaunchPlan _pythonLaunchPlan({
    required String pythonPath,
    required String description,
  }) {
    return _ServiceLaunchPlan(
      executable: pythonPath,
      arguments: const [
        '-m',
        'uvicorn',
        'app.main:app',
        '--host',
        '127.0.0.1',
        '--port',
        '4318',
      ],
      description: description,
      healthCheckAttempts: 40,
    );
  }

  bool _isBundledServiceDirectory(Directory serviceDir) {
    return serviceDir.path.contains(
        '${Platform.pathSeparator}Resources${Platform.pathSeparator}service');
  }

  File? _resolveUvExecutable(Directory serviceDir) {
    final executableNames = Platform.isWindows
        ? const ['uv.exe', 'uv.bat', 'uv.cmd']
        : const ['uv'];

    for (final entry in _launchPathEntries(serviceDir)) {
      if (entry.isEmpty) {
        continue;
      }
      for (final name in executableNames) {
        final file = File('$entry${Platform.pathSeparator}$name');
        if (file.existsSync()) {
          return file;
        }
      }
    }

    return null;
  }

  String _buildLaunchPath(Directory serviceDir) {
    return _launchPathEntries(serviceDir).join(Platform.isWindows ? ';' : ':');
  }

  List<String> _launchPathEntries(Directory serviceDir) {
    final separator = Platform.isWindows ? ';' : ':';
    final pathEntries = <String>[
      if (Platform.environment['PATH'] case final value?) ...value
          .split(separator)
          .where((entry) => entry.isNotEmpty),
      if (Platform.isMacOS) ...[
        '/opt/homebrew/bin',
        '/usr/local/bin',
        '/usr/bin',
        '/bin',
        '/usr/sbin',
        '/sbin',
      ],
      if (Platform.environment['HOME'] case final home?) ...[
        '$home/.local/bin',
        '$home/bin',
      ],
      if (Platform.isWindows) '${serviceDir.path}\\.venv\\Scripts',
      if (!Platform.isWindows) '${serviceDir.path}/.venv/bin',
    ];

    final uniqueEntries = <String>[];
    for (final entry in pathEntries) {
      if (entry.isEmpty || uniqueEntries.contains(entry)) {
        continue;
      }
      uniqueEntries.add(entry);
    }
    return uniqueEntries;
  }

  String _buildMissingRuntimeError(Directory serviceDir) {
    if (_isBundledServiceDirectory(serviceDir)) {
      return '找不到打包后的 Python 运行时，请检查 app bundle 内的 Resources/service/.venv。';
    }
    return '开发环境缺少可启动的 service 运行时。请安装 uv，或先在 service/ 下执行一次 uv sync。';
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
