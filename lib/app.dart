import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/shell/presentation/pages/app_shell_page.dart';

class CodexFeishuHomeApp extends StatelessWidget {
  const CodexFeishuHomeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'memaster',
      theme: AppTheme.light(),
      home: const AppShellPage(),
    );
  }
}
