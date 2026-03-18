import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memaster/app.dart';

void main() {
  testWidgets('home dashboard renders key memory sections',
      (WidgetTester tester) async {
    await tester.pumpWidget(const CodexFeishuHomeApp(skipBootstrap: true));
    await tester.pumpAndSettle();

    expect(find.text('UGREEN NAS online'), findsOneWidget);
    expect(find.text('像杂志目录一样浏览你的记忆分类'), findsOneWidget);
    expect(find.text('最近生成的记忆线索'), findsOneWidget);
    expect(find.text('系统状态'), findsOneWidget);
  });

  testWidgets('app stays stable on narrow desktop widths',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(760, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const CodexFeishuHomeApp(skipBootstrap: true));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('你的记忆总览'), findsWidgets);
    expect(find.text('UGREEN NAS online'), findsOneWidget);
  });

  testWidgets('home quick actions navigate to organize section',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const CodexFeishuHomeApp(skipBootstrap: true));
    await tester.pumpAndSettle();

    final cta = find.widgetWithText(FilledButton, '开始构建').first;
    await tester.ensureVisible(cta);
    await tester.tap(cta);
    await tester.pumpAndSettle();

    expect(find.text('整理中枢'), findsWidgets);
    expect(find.text('先建立数据来源，再发起索引任务'), findsOneWidget);
  });

  testWidgets('shell supports keyboard shortcuts for section switching',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const CodexFeishuHomeApp(skipBootstrap: true));
    await tester.pumpAndSettle();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.digit6);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
    await tester.pumpAndSettle();

    expect(find.text('整理中枢'), findsWidgets);
    expect(find.text('仅看当前来源任务'), findsOneWidget);
  });
}
