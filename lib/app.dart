import 'package:flutter/material.dart';

import 'core/data/memory_repository.dart';
import 'core/services/local_service_runtime.dart';
import 'core/theme/app_theme.dart';
import 'features/bootstrap/presentation/pages/app_bootstrap_page.dart';
import 'features/shell/presentation/pages/app_shell_page.dart';

class MemasterApp extends StatelessWidget {
  const MemasterApp({
    super.key,
    this.skipBootstrap = false,
    this.repository,
    this.serviceRuntime,
  });

  final bool skipBootstrap;
  final MemoryRepository? repository;
  final LocalServiceRuntime? serviceRuntime;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'memaster',
      theme: AppTheme.light(),
      home: skipBootstrap
          ? const AppShellPage()
          : AppBootstrapPage(
              repository: repository ?? MemoryRepository.instance,
              serviceRuntime: serviceRuntime ?? LocalServiceRuntime(),
            ),
    );
  }
}
