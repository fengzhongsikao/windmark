import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:windmark/core/calendar/lunar_calendar.dart';
import 'package:windmark/core/iching/gua_classic.dart';
import 'package:windmark/core/iching/hexagram_book.dart';
import 'package:windmark/core/iching/trigram.dart';
import 'package:windmark/core/iching/hexagram_relation.dart';
import 'package:windmark/core/iching/palace.dart';
import 'package:windmark/core/iching/wuxing.dart';
import 'package:windmark/core/models/reading_record.dart';
import 'package:windmark/features/liuyao/liuyao_engine.dart';
import 'package:windmark/features/liuyao/liuyao_result_page.dart';
import 'package:windmark/features/meihua/meihua_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('农历', () {
    final newYears = {
      DateTime(2000, 2, 5): 2000,
      DateTime(2008, 2, 7): 2008,
      DateTime(2010, 2, 14): 2010,
      DateTime(2019, 2, 5): 2019,
      DateTime(2020, 1, 25): 2020,
      DateTime(2021, 2, 12): 2021,
      DateTime(2022, 2, 1): 2022,
      DateTime(2023, 1, 22): 2023,
      DateTime(2024, 2, 10): 2024,
      DateTime(2025, 1, 29): 2025,
      DateTime(2026, 2, 17): 2026,
      DateTime(2027, 2, 6): 2027,
    };

    for (final entry in newYears.entries) {
      test('${entry.key.year} 春节是正月初一', () {
        final lunar = LunarCalendar.fromSolar(entry.key);
        expect(lunar, isNotNull);
        expect(lunar!.year, entry.value);
        expect(lunar.month, 1);
        expect(lunar.day, 1);
        expect(lunar.isLeapMonth, isFalse);
      });
    }

    test('春节前一天仍属上一年', () {
      final eve = LunarCalendar.fromSolar(DateTime(2024, 2, 9))!;
      expect(eve.year, 2023);
      expect(eve.day, greaterThanOrEqualTo(29));
    });

    test('日期逐日推进', () {
      var previous = LunarCalendar.fromSolar(DateTime(2024, 1, 1))!;
      for (var i = 1; i < 400; i++) {
        final current = LunarCalendar.fromSolar(
          DateTime(2024, 1, 1).add(Duration(days: i)),
        )!;
        expect(
          current.day == previous.day + 1 || current.day == 1,
          isTrue,
          reason: '$current 接在 $previous 之后',
        );
        if (current.day == 1) {
          expect(previous.day, greaterThanOrEqualTo(29));
        }
        previous = current;
      }
    });

    test('2023 年有闰月', () {
      final found = List.generate(365, (index) {
        return LunarCalendar.fromSolar(
          DateTime(2023, 1, 1).add(Duration(days: index)),
        );
      }).any((lunar) => lunar?.isLeapMonth ?? false);
      expect(found, isTrue);
    });

    test('范围外返回空', () {
      expect(LunarCalendar.fromSolar(DateTime(1899, 12, 31)), isNull);
      expect(LunarCalendar.fromSolar(DateTime(2101, 1, 1)), isNull);
    });

    test('时辰与日干', () {
      expect(hourBranchNumber(0), 1);
      expect(hourBranchNumber(23), 1);
      expect(hourBranchName(23), '子');
      expect(hourBranchNumber(1), 2);
      expect(dayStemIndex(DateTime(1900, 1, 1)), 0);
      expect(dayStemIndex(DateTime(2000, 1, 1)), 4);
      expect(stems[dayStemIndex(DateTime(2000, 1, 1))], '戊');
    });
  });

  group('卦表', () {
    test('六十四卦与八宫一一对应', () {
      expect(HexagramBook.entries, hasLength(64));
      final pairs = HexagramBook.entries
          .map((entry) => '${entry.upperName}${entry.lowerName}')
          .toSet();
      expect(pairs, hasLength(64));
      expect(Palaces.byHexagramName, hasLength(64));
      for (final entry in HexagramBook.entries) {
        expect(Palaces.byHexagramName.containsKey(entry.name), isTrue);
      }
    });

    test('常见卦名', () {
      expect(HexagramBook.byNumber(1).title, '乾为天');
      expect(HexagramBook.byNumber(2).title, '坤为地');
      expect(HexagramBook.byNumber(11).title, '地天泰');
      expect(HexagramBook.byNumber(12).title, '天地否');
      expect(HexagramBook.byNumber(44).title, '天风姤');
      expect(HexagramBook.byNumber(63).title, '水火既济');
      expect(HexagramBook.byNumber(64).title, '火水未济');
    });

    test('六冲卦与六合卦', () {
      expect(HexagramRelations.of('乾'), '六冲卦');
      expect(HexagramRelations.of('大壮'), '六冲卦');
      expect(HexagramRelations.of('无妄'), '六冲卦');
      expect(HexagramRelations.of('泰'), '六合卦');
      expect(HexagramRelations.of('节'), '六合卦');
      expect(HexagramRelations.of('屯'), isNull);
      expect(HexagramRelations.chong.length, 10);
      expect(HexagramRelations.he.length, 8);
    });

    test('屯的互卦是剥', () {
      final tun = HexagramBook.byNumber(3).hexagram;
      expect(HexagramBook.of(tun.mutual).name, '剥');
    });

    test('卦辞爻辞按卦序读出', () async {
      final book = await GuaTextBook.load();
      final qian = book.byNumber(1)!;
      expect(qian.guaCi, contains('元亨利贞'));
      expect(qian.yaoCi[0], startsWith('初九'));
      expect(qian.yaoCi[4], startsWith('九五'));
      expect(qian.yaoCi[5], startsWith('上九'));
      expect(qian.yaoCi.last, startsWith('用九'));
      expect(book.byNumber(2)!.yaoCi.first, contains('履霜'));
      expect(book.byNumber(64), isNotNull);
    });

    test('同一天的今日卦不变', () {
      final date = DateTime(2026, 11, 13);
      expect(HexagramBook.daily(date).number, HexagramBook.daily(date).number);
    });
  });

  group('梅花', () {
    test('数字起卦按先天数取余', () {
      final cast = MeihuaEngine.numberCast(
        number: 986,
        at: DateTime(2026, 11, 13),
      )!;
      expect(cast.upper.name, '乾');
      expect(cast.lower.name, '坤');
      expect(cast.movingLine, 6);
      expect(cast.relation, BodyUseRelation.bodyGeneratesUse);
    });

    test('个位除以 8 后仍落在六爻内', () {
      final zero = MeihuaEngine.numberCast(
        number: 170,
        at: DateTime(2026, 11, 13),
      )!;
      expect(zero.upper.name, '乾');
      expect(zero.lower.name, '艮');
      expect(zero.movingLine, 2);
      final seven = MeihuaEngine.numberCast(
        number: 117,
        at: DateTime(2026, 11, 13),
      )!;
      expect(seven.movingLine, 1);
    });

    test('动爻在下卦时用卦为下卦', () {
      final cast = MeihuaEngine.numberCast(
        number: 181,
        at: DateTime(2026, 11, 13),
      )!;
      expect(cast.body.name, '乾');
      expect(cast.function.name, '坤');
      expect(cast.relation, BodyUseRelation.useGeneratesBody);
      expect(cast.originalEntry.title, '天地否');
    });

    test('坤卦上爻动变剥，错乾综坤', () {
      final cast = MeihuaEngine.manualCast(
        upper: Trigram.kun,
        lower: Trigram.kun,
        movingLine: 6,
        at: DateTime(2026, 11, 13, 15, 20),
      );
      expect(HexagramBook.of(cast.changed).name, '剥');
      expect(HexagramBook.of(cast.original.opposite).name, '乾');
      expect(HexagramBook.of(cast.original.inverted).name, '坤');
    });

    test('丙午年正月初一子时为天泽履', () {
      final cast = MeihuaEngine.timeCast(DateTime(2026, 2, 17))!;
      expect(cast.upper.name, '乾');
      expect(cast.lower.name, '兑');
      expect(cast.movingLine, 4);
      expect(cast.originalEntry.title, '天泽履');
    });

    test('记录可以还原', () {
      final cast = MeihuaEngine.numberCast(
        number: 181,
        at: DateTime(2026, 1, 2, 8),
      )!;
      final encoded = jsonDecode(
        jsonEncode(cast.withQuestion('近况').toRecord(title: '近况').toJson()),
      ) as Map;
      final record = ReadingRecord.fromJson(Map<String, dynamic>.from(encoded));
      final restored = MeihuaCast.fromPayload(record.payload, record.createdAt);
      expect(restored.originalEntry.title, '天地否');
      expect(restored.movingLine, 1);
      expect(restored.question, '近况');
      expect(record.title, '近况');
    });
  });

  group('六爻', () {
    test('乾卦纳甲、世应与六神', () {
      final at = DateTime(2000, 1, 1, 9);
      final reading = LiuyaoEngine.interpret(
        lines: List.filled(6, YaoKind.youngYang),
        topic: DivinationTopic.general,
        question: '近况',
        at: at,
      );
      expect(reading.original.title, '乾为天');
      expect(reading.palace.label, '乾宫 · 本宫');
      expect(reading.changed, isNull);
      expect(reading.lines.first.ganzhi, '甲子');
      expect(reading.lines.first.relative, '子孙');
      expect(reading.lines.first.spirit, '勾陈');
      expect(
        reading.lines.map((line) => line.spirit).toList(),
        ['勾陈', '腾蛇', '白虎', '玄武', '青龙', '朱雀'],
      );
      expect(reading.lines.last.isShi, isTrue);
      expect(reading.lines[2].isYing, isTrue);
      expect(reading.lines.last.relative, '父母');
      expect(reading.lines.last.branch, '戌');
      final lunar = LunarCalendar.fromSolar(at)!;
      expect(
        reading.lines.first.strength,
        LiuyaoEngine.strengthLabel(
          WuXing.water,
          elementOfLunarMonth(lunar.month),
        ),
      );
    });

    testWidgets('360 宽的本卦变卦并排不溢出', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final reading = LiuyaoEngine.interpret(
        lines: [
          YaoKind.oldYin,
          YaoKind.youngYang,
          YaoKind.youngYang,
          YaoKind.youngYang,
          YaoKind.youngYang,
          YaoKind.youngYang,
        ],
        topic: DivinationTopic.general,
        question: '近况',
        at: DateTime(2026, 11, 18, 12),
      );
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: LiuyaoResultPage(reading: reading, canSave: false),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    test('六神按日干从初爻起', () {
      const firstSpirit = {
        6: '青龙',
        7: '青龙',
        8: '朱雀',
        9: '朱雀',
        10: '勾陈',
        11: '腾蛇',
        12: '白虎',
        13: '白虎',
        14: '玄武',
        15: '玄武',
      };
      for (final entry in firstSpirit.entries) {
        final at = DateTime(2026, 11, entry.key, 12);
        final reading = LiuyaoEngine.interpret(
          lines: List.filled(6, YaoKind.youngYang),
          topic: DivinationTopic.general,
          question: '近况',
          at: at,
        );
        expect(reading.lines.first.spirit, entry.value, reason: stems[dayStemIndex(at)]);
      }
    });

    test('姤为一世，初爻发动变为乾', () {
      final reading = LiuyaoEngine.interpret(
        lines: [
          YaoKind.oldYin,
          YaoKind.youngYang,
          YaoKind.youngYang,
          YaoKind.youngYang,
          YaoKind.youngYang,
          YaoKind.youngYang,
        ],
        topic: DivinationTopic.career,
        question: '',
        at: DateTime(2026, 5, 1),
      );
      expect(reading.original.title, '天风姤');
      expect(reading.changed!.title, '乾为天');
      expect(reading.palace.generationLabel, '一世');
      expect(reading.lines.first.isShi, isTrue);
      expect(reading.lines.first.relative, '父母');
      expect(reading.lines.first.kind.changing, isTrue);
      expect(reading.lines[3].isYing, isTrue);
    });

    test('铜钱以背为阳、字为阴', () {
      expect(YaoKind.fromBackCount(1), YaoKind.youngYang);
      expect(YaoKind.fromBackCount(2), YaoKind.youngYin);
      expect(YaoKind.fromBackCount(3), YaoKind.oldYang);
      expect(YaoKind.fromBackCount(0), YaoKind.oldYin);
      expect(YaoKind.youngYang.changing, isFalse);
      expect(YaoKind.youngYin.changing, isFalse);
      expect(YaoKind.oldYang.changing, isTrue);
      expect(YaoKind.oldYin.changing, isTrue);

      final random = Random(7);
      for (var i = 0; i < 40; i++) {
        final cast = LiuyaoEngine.throwCoins(random);
        expect(cast.backs, hasLength(3));
        expect(
          cast.kind,
          YaoKind.fromBackCount(cast.backs.where((back) => back).length),
        );
      }
    });

    test('六爻记录可以还原', () {
      final reading = LiuyaoEngine.interpret(
        lines: List.filled(6, YaoKind.youngYin),
        topic: DivinationTopic.wealth,
        question: '这笔收入',
        at: DateTime(2026, 6, 1, 15),
      );
      final encoded = jsonDecode(
        jsonEncode(reading.toRecord(title: '这笔收入').toJson()),
      ) as Map;
      final record = ReadingRecord.fromJson(Map<String, dynamic>.from(encoded));
      final restored = LiuyaoReading.fromPayload(
        record.payload,
        record.createdAt,
      );
      expect(restored.original.title, reading.original.title);
      expect(restored.topic, DivinationTopic.wealth);
      expect(restored.question, '这笔收入');
      expect(record.title, '这笔收入');
    });
  });
}
