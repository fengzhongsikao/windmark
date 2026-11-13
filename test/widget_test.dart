import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:windmark/app/windmark_app.dart';
import 'package:windmark/core/storage/history_store.dart';

void main() {
  testWidgets('底部四个入口可以完成梅花和六爻', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          historyStoreProvider.overrideWithValue(MemoryHistoryStore()),
        ],
        child: const WindmarkApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(_tab('首页'), findsOneWidget);
    expect(_tab('梅花'), findsOneWidget);
    expect(_tab('六爻'), findsOneWidget);
    expect(_tab('我的'), findsOneWidget);

    await tester.tap(_tab('梅花'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('起卦'));
    await tester.tap(find.text('起卦'));
    await tester.pumpAndSettle();
    expect(find.text('体用'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    await tester.tap(_tab('六爻'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('一键起卦'));
    await tester.tap(find.text('一键起卦'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('解卦'));
    await tester.tap(find.text('解卦'));
    await tester.pumpAndSettle();
    expect(find.text('世'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    await tester.tap(_tab('我的'));
    await tester.pumpAndSettle();
    expect(find.text('共 2 次占问'), findsOneWidget);
  });
}

Finder _tab(String label) {
  return find.descendant(
    of: find.byType(NavigationBar),
    matching: find.text(label),
  );
}
