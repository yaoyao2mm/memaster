import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/models/app_models.dart';
import '../../../albums/presentation/pages/albums_page.dart';
import '../../../home/presentation/pages/home_page.dart';
import '../../../library/presentation/pages/library_page.dart';
import '../../../organize/presentation/pages/organize_page.dart';
import '../../../people/presentation/pages/people_page.dart';
import '../../../timeline/presentation/pages/timeline_page.dart';
import '../widgets/shell_scaffold.dart';

class AppShellPage extends StatefulWidget {
  const AppShellPage({super.key});

  @override
  State<AppShellPage> createState() => _AppShellPageState();
}

class _AppShellPageState extends State<AppShellPage> {
  static const destinations = [
    AppDestination(label: '总览', icon: Icons.grid_view_rounded),
    AppDestination(label: '资产库', icon: Icons.perm_media_rounded),
    AppDestination(label: '智能相册', icon: Icons.photo_library_rounded),
    AppDestination(label: '人物', icon: Icons.group_rounded),
    AppDestination(label: '时间轴', icon: Icons.auto_stories_rounded),
    AppDestination(label: '整理', icon: Icons.tune_rounded),
  ];

  late int selectedIndex;

  @override
  void initState() {
    super.initState();
    selectedIndex = _initialSelectedIndex();
  }

  int _initialSelectedIndex() {
    const defaultIndex = 0;
    final rawValue = Platform.environment['MEMASTER_SCREENSHOT_PAGE'];
    switch (rawValue) {
      case 'albums':
        return 2;
      case 'library':
        return 1;
      case 'people':
        return 3;
      case 'timeline':
        return 4;
      case 'organize':
        return 5;
      default:
        return defaultIndex;
    }
  }

  @override
  Widget build(BuildContext context) {
    final configs = [
      (
        title: '你的记忆总览',
        subtitle: '先看系统对素材的理解结果，再进入具体分类和修正流程。',
        child: HomePage(),
      ),
      (
        title: '统一资产库',
        subtitle: '先按来源、标签和路径筛选，再决定从哪条记忆线继续深入。',
        child: LibraryPage(),
      ),
      (
        title: '智能相册',
        subtitle: '按语义自动组织，而不是按文件夹命名来回查找。',
        child: AlbumsPage(),
      ),
      (
        title: '人物与关系',
        subtitle: '先做聚类，再由你确认谁是谁，系统才会稳定记住。',
        child: PeoplePage(),
      ),
      (
        title: '记忆时间轴',
        subtitle: '让系统把素材按事件和时间重新讲述，而不是平铺所有图片。',
        child: TimelinePage(),
      ),
      (
        title: '整理中枢',
        subtitle: '所有扫描、缩略图、分类和待修正任务都应该在这里被管理。',
        child: OrganizePage(),
      ),
    ];

    final active = configs[selectedIndex];
    return ShellScaffold(
      destinations: destinations,
      selectedIndex: selectedIndex,
      onSelect: (index) => setState(() => selectedIndex = index),
      title: active.title,
      subtitle: active.subtitle,
      child: active.child,
    );
  }
}
