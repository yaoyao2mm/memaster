import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:memaster/core/data/memory_repository.dart';
import 'package:memaster/core/network/local_api_client.dart';
import 'package:memaster/core/theme/app_theme.dart';
import 'package:memaster/features/albums/presentation/pages/albums_page.dart';
import 'package:memaster/features/people/presentation/pages/people_page.dart';
import 'package:memaster/features/timeline/presentation/pages/timeline_page.dart';

void main() {
  final repository = MemoryRepository(apiClient: _FailingApiClient());

  Future<void> pumpPage(WidgetTester tester, Widget child) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: Scaffold(body: child),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('albums page filters assets within selected album',
      (tester) async {
    await pumpPage(tester, AlbumsPage(repository: repository));

    await tester.tap(find.text('可爱的小猫').first);
    await tester.pumpAndSettle();

    expect(find.text('当前分类'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'zzz');
    await tester.pumpAndSettle();

    expect(find.text('当前筛选条件下没有素材。'), findsOneWidget);
  });

  testWidgets('people page filters clusters by query', (tester) async {
    await pumpPage(tester, PeoplePage(repository: repository));

    await tester.enterText(find.byType(TextField).first, '家人');
    await tester.pumpAndSettle();

    expect(find.text('朋友'), findsNothing);
    expect(find.text('当前筛选条件下没有人物簇。'), findsNothing);
  });

  testWidgets('timeline page filters events by tag', (tester) async {
    await pumpPage(tester, TimelinePage(repository: repository));

    await tester.tap(find.widgetWithText(ChoiceChip, '人物'));
    await tester.pumpAndSettle();

    expect(find.text('新人物簇待确认'), findsOneWidget);
    expect(find.text('猫咪相册更新'), findsNothing);
  });
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

  @override
  Future<Map<String, dynamic>> deleteJson(String path) async {
    throw Exception('Use mock fallback');
  }
}

class _ThrowingClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    throw Exception('HTTP disabled in widget tests');
  }
}
