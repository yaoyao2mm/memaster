import 'package:flutter_test/flutter_test.dart';

import 'package:memaster/app.dart';

void main() {
  testWidgets('home dashboard renders key memory sections', (WidgetTester tester) async {
    await tester.pumpWidget(const CodexFeishuHomeApp());
    await tester.pumpAndSettle();

    expect(find.text('UGREEN NAS online'), findsOneWidget);
    expect(find.text('像杂志目录一样浏览你的记忆分类'), findsOneWidget);
    expect(find.text('最近生成的记忆线索'), findsOneWidget);
    expect(find.text('系统状态'), findsOneWidget);
  });
}
