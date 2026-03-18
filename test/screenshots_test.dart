import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:memaster/core/data/memory_repository.dart';
import 'package:memaster/core/models/app_models.dart';
import 'package:memaster/core/network/local_api_client.dart';
import 'package:memaster/core/theme/app_theme.dart';
import 'package:memaster/features/albums/presentation/pages/albums_page.dart';
import 'package:memaster/features/organize/presentation/pages/organize_page.dart';
import 'package:memaster/features/people/presentation/pages/people_page.dart';
import 'package:memaster/features/shell/presentation/widgets/shell_scaffold.dart';
import 'package:memaster/features/timeline/presentation/pages/timeline_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await Future.wait([
      _loadFont('PlusJakartaSans', 'assets/fonts/PlusJakartaSans-Regular.ttf'),
      _loadFont('PlusJakartaSans', 'assets/fonts/PlusJakartaSans-Medium.ttf'),
      _loadFont('PlusJakartaSans', 'assets/fonts/PlusJakartaSans-Bold.ttf'),
      _loadFont('NotoSansCJKsc', 'assets/fonts/NotoSansCJKsc-Regular.otf'),
    ]);
  });

  final repository = MemoryRepository(apiClient: _FailingApiClient());
  const destinations = [
    AppDestination(label: '总览', icon: Icons.grid_view_rounded),
    AppDestination(label: '智能相册', icon: Icons.photo_library_rounded),
    AppDestination(label: '人物', icon: Icons.group_rounded),
    AppDestination(label: '时间轴', icon: Icons.auto_stories_rounded),
    AppDestination(label: '整理', icon: Icons.tune_rounded),
  ];

  Future<void> pumpPage(
    WidgetTester tester, {
    required String title,
    required String subtitle,
    required Widget child,
    required int selectedIndex,
  }) async {
    await tester.binding.setSurfaceSize(const Size(1512, 982));
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: ShellScaffold(
          destinations: destinations,
          selectedIndex: selectedIndex,
          onSelect: (_) {},
          title: title,
          subtitle: subtitle,
          child: child,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('generate albums screenshot', (tester) async {
    await pumpPage(
      tester,
      title: '智能相册',
      subtitle: '按语义自动组织，而不是按文件夹命名来回查找。',
      child: AlbumsPage(repository: repository),
      selectedIndex: 1,
    );
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('../assets/readme/albums-demo.png'));
  });

  testWidgets('generate people screenshot', (tester) async {
    await pumpPage(
      tester,
      title: '人物与关系',
      subtitle: '先做聚类，再由你确认谁是谁，系统才会稳定记住。',
      child: PeoplePage(repository: repository),
      selectedIndex: 2,
    );
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('../assets/readme/people-demo.png'));
  });

  testWidgets('generate timeline screenshot', (tester) async {
    await pumpPage(
      tester,
      title: '记忆时间轴',
      subtitle: '让系统把素材按事件和时间重新讲述，而不是平铺所有图片。',
      child: TimelinePage(repository: repository),
      selectedIndex: 3,
    );
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('../assets/readme/timeline-demo.png'));
  });

  testWidgets('generate organize screenshot', (tester) async {
    await pumpPage(
      tester,
      title: '整理中枢',
      subtitle: '所有扫描、缩略图、分类和待修正任务都应该在这里被管理。',
      child: OrganizePage(repository: repository),
      selectedIndex: 4,
    );
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('../assets/readme/organize-demo.png'));
  });
}

Future<void> _loadFont(String family, String assetPath) async {
  final loader = FontLoader(family)..addFont(rootBundle.load(assetPath));
  await loader.load();
}

class _FailingApiClient extends LocalApiClient {
  _FailingApiClient() : super(httpClient: _ThrowingClient());

  @override
  Future<Map<String, dynamic>> getJson(String path) async {
    throw Exception('Use mock fallback');
  }

  @override
  Future<Map<String, dynamic>> postJson(
    String path, {
    required Map<String, dynamic> body,
  }) async {
    throw Exception('Use mock fallback');
  }
}

class _ThrowingClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    throw Exception('HTTP disabled in screenshot tests');
  }
}
