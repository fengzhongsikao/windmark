import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:windmark/app/windmark_app.dart';
import 'package:windmark/core/storage/history_store.dart';
import 'package:windmark/features/liuyao/liuyao_engine.dart';
import 'package:windmark/features/liuyao/liuyao_page.dart';
import 'package:windmark/features/profile/history_list_page.dart';
import 'package:windmark/features/profile/user_profile.dart';

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
          userProfileStoreProvider.overrideWithValue(MemoryUserProfileStore()),
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
    await tester.enterText(find.byKey(const ValueKey('meihua-question')), '近况');
    await tester.pump();
    await tester.ensureVisible(find.text('起卦'));
    await tester.tap(find.text('起卦'));
    await tester.pumpAndSettle();
    expect(find.text('【本卦】'), findsOneWidget);
    await _saveWithTitle(tester, '梅花近况');

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    await tester.tap(_tab('六爻'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('liuyao-question')), '近况');
    await tester.pump();
    await _scrollLiuyao(tester, find.text('一键起卦'));
    await tester.tap(find.text('一键起卦'));
    await tester.pumpAndSettle();
    await _scrollLiuyao(tester, find.text('解卦'));
    await tester.tap(find.text('解卦'));
    await tester.pumpAndSettle();
    expect(find.text('世'), findsOneWidget);
    await _saveWithTitle(tester, '六爻近况');

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    await _scrollLiuyao(tester, find.byKey(const ValueKey('cast-mode')));
    await tester.tap(find.byKey(const ValueKey('cast-mode')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('手动指定').last);
    await tester.pumpAndSettle();
    expect(find.text('逐爻选择阴阳'), findsOneWidget);

    const picks = ['少阴', '少阳', '老阴', '老阳', '少阳', '少阴'];
    for (var i = 0; i < picks.length; i++) {
      final row = find.byKey(ValueKey('manual-yao-${5 - i}'));
      await _scrollLiuyao(tester, row);
      await tester.tap(
        find.descendant(
          of: row,
          matching: find.byType(PopupMenuButton<YaoKind>),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(PopupMenuItem<YaoKind>),
          matching: find.text(picks[i]),
        ),
      );
      await tester.pumpAndSettle();
    }

    await _scrollLiuyao(tester, find.text('解卦'));
    await tester.tap(find.text('解卦'));
    await tester.pumpAndSettle();
    expect(find.text('世'), findsOneWidget);
    await _saveWithTitle(tester, '手动六爻');

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    await tester.tap(_tab('我的'));
    await tester.pumpAndSettle();
    expect(find.text('共 3 次排盘'), findsOneWidget);
    expect(find.text('风痕'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('display-name')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('display-name-field')),
      '山客',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('display-name-save')));
    await tester.pumpAndSettle();
    expect(find.text('山客'), findsOneWidget);
    expect(find.text('梅花排盘记录'), findsOneWidget);
    expect(find.text('六爻排盘记录'), findsOneWidget);

    await tester.tap(find.text('梅花排盘记录'));
    await tester.pumpAndSettle();
    final tile = find.descendant(
      of: find.byType(Dismissible),
      matching: find.text('梅花近况'),
    );
    expect(tile, findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('history-search')),
      '没有这项',
    );
    await tester.pump();
    expect(find.text('没有匹配的排盘记录。'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('history-search')), '梅花');
    await tester.pump();
    expect(_onHistory('梅花近况'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('history-search')), '');
    await tester.pump();

    await tester.tap(find.text('编辑'));
    await tester.pumpAndSettle();
    expect(find.text('完成'), findsOneWidget);
    expect(find.text('取消'), findsOneWidget);
    await tester.tap(_onHistory('梅花近况'));
    await tester.pump();
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(find.text('编辑'), findsOneWidget);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(Dismissible)),
    );
    for (var i = 0; i < 10; i++) {
      await gesture.moveBy(const Offset(-30, 0));
      await tester.pump();
    }
    expect(find.text('删除'), findsOneWidget);
    await gesture.up();
    await tester.pumpAndSettle();

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('六爻排盘记录'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('编辑'));
    await tester.pumpAndSettle();
    await tester.tap(_onHistory('六爻近况'));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('history-delete-selected')));
    await tester.pumpAndSettle();
    expect(_onHistory('六爻近况'), findsNothing);
    expect(_onHistory('手动六爻'), findsOneWidget);
  });
}

Finder _onHistory(String text) {
  return find.descendant(
    of: find.byType(HistoryListPage),
    matching: find.text(text),
  );
}

Future<void> _saveWithTitle(WidgetTester tester, String title) async {
  await tester.tap(find.text('保存'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const ValueKey('record-title')), title);
  await tester.pump();
  await tester.tap(find.byKey(const ValueKey('record-title-save')));
  await tester.pumpAndSettle();
  expect(find.text('已保存'), findsOneWidget);
}

Future<void> _scrollLiuyao(WidgetTester tester, Finder target) async {
  final scrollable = find
      .descendant(
        of: find.byType(LiuyaoPage),
        matching: find.byType(Scrollable),
      )
      .first;
  if (target.evaluate().isEmpty) {
    await tester.drag(scrollable, const Offset(0, 2400));
    await tester.pumpAndSettle();
  }
  await tester.scrollUntilVisible(target, 280, scrollable: scrollable);
}

Finder _tab(String label) {
  return find.descendant(
    of: find.byType(NavigationBar),
    matching: find.text(label),
  );
}
