import 'dart:math';

import 'package:windmark/core/calendar/lunar_calendar.dart';
import 'package:windmark/core/iching/hexagram.dart';
import 'package:windmark/core/iching/hexagram_book.dart';
import 'package:windmark/core/iching/palace.dart';
import 'package:windmark/core/iching/wuxing.dart';
import 'package:windmark/core/models/reading_record.dart';

enum DivinationTopic {
  general('综合'),
  career('事业'),
  wealth('财运'),
  relationship('感情'),
  health('健康'),
  travel('出行');

  const DivinationTopic(this.label);

  final String label;
}

enum YaoKind {
  oldYin(6, false, true, '老阴'),
  youngYang(7, true, false, '少阳'),
  youngYin(8, false, false, '少阴'),
  oldYang(9, true, true, '老阳');

  const YaoKind(this.sum, this.yang, this.changing, this.label);

  final int sum;
  final bool yang;
  final bool changing;
  final String label;

  static YaoKind fromSum(int sum) {
    return YaoKind.values.firstWhere((kind) => kind.sum == sum);
  }

  /// 三枚铜钱里背面的个数。背为阳计三，字为阴计二。
  /// 一背为少阳，两背为少阴，三背为老阳，三字为老阴。
  static YaoKind fromBackCount(int count) {
    return switch (count) {
      0 => YaoKind.oldYin,
      1 => YaoKind.youngYang,
      2 => YaoKind.youngYin,
      3 => YaoKind.oldYang,
      _ => throw ArgumentError('背面数量必须在 0 到 3 之间'),
    };
  }
}

class CoinThrow {
  const CoinThrow(this.backs);

  /// 三枚铜钱。true 为背，false 为字。
  final List<bool> backs;

  YaoKind get kind => YaoKind.fromBackCount(backs.where((back) => back).length);
}

enum ReadingTone {
  smooth('顺'),
  steady('平'),
  slow('缓'),
  unclear('不明');

  const ReadingTone(this.label);

  final String label;
}

class InstalledLine {
  const InstalledLine({
    required this.index,
    required this.kind,
    required this.ganzhi,
    required this.relative,
    required this.spirit,
    required this.strength,
    required this.isShi,
    required this.isYing,
  });

  final int index;
  final YaoKind kind;
  final String ganzhi;
  final String relative;
  final String spirit;
  final String strength;
  final bool isShi;
  final bool isYing;

  String get branch => ganzhi.substring(1);

  WuXing get element => elementOfBranch(branch);

  String get position => YaoPosition.names[index];
}

class NajiaLine {
  const NajiaLine({required this.ganzhi, required this.relative});

  final String ganzhi;
  final String relative;

  String get stem => ganzhi.substring(0, 1);

  String get branch => ganzhi.substring(1);

  WuXing get element => elementOfBranch(branch);
}

class LiuyaoReading {
  const LiuyaoReading({
    required this.lines,
    required this.original,
    required this.changed,
    required this.palace,
    required this.topic,
    required this.question,
    required this.createdAt,
    required this.lunar,
    required this.tone,
    required this.paragraphs,
  });

  final List<InstalledLine> lines;
  final HexagramEntry original;
  final HexagramEntry? changed;
  final PalacePlacement palace;
  final DivinationTopic topic;
  final String question;
  final DateTime createdAt;
  final LunarDate lunar;
  final ReadingTone tone;
  final List<String> paragraphs;

  ReadingRecord toRecord({required String title}) {
    final moving = lines.where((line) => line.kind.changing).length;
    return ReadingRecord(
      id: 'liuyao-${createdAt.microsecondsSinceEpoch}',
      kind: ReadingKind.liuyao,
      createdAt: createdAt,
      title: title,
      summary: '${topic.label} · ${tone.label}${moving == 0 ? ' · 静卦' : ' · $moving 爻动'}',
      payload: {
        'lines': lines.map((line) => line.kind.sum).toList(),
        'topic': topic.name,
        'question': question,
      },
    );
  }

  factory LiuyaoReading.fromPayload(
    Map<String, Object?> payload,
    DateTime createdAt,
  ) {
    final rawLines = payload['lines']! as List;
    return LiuyaoEngine.interpret(
      lines: [
        for (final item in rawLines) YaoKind.fromSum((item as num).toInt()),
      ],
      topic: DivinationTopic.values.byName(payload['topic']! as String),
      question: payload['question'] as String? ?? '',
      at: createdAt,
    );
  }
}

abstract final class LiuyaoEngine {
  /// 按卦的上下卦纳甲，六亲相对本宫五行。
  static List<NajiaLine> najiaLines(Hexagram hexagram, WuXing palaceElement) {
    final ganzhi = [
      ..._najia[hexagram.lower.name]!.lower,
      ..._najia[hexagram.upper.name]!.upper,
    ];
    return [
      for (final item in ganzhi)
        NajiaLine(
          ganzhi: item,
          relative: _relative(palaceElement, elementOfBranch(item.substring(1))),
        ),
    ];
  }

  static CoinThrow throwCoins(Random random) {
    return CoinThrow([
      for (var i = 0; i < 3; i++) random.nextBool(),
    ]);
  }

  static LiuyaoReading interpret({
    required List<YaoKind> lines,
    required DivinationTopic topic,
    required String question,
    required DateTime at,
  }) {
    if (lines.length != 6) {
      throw ArgumentError('六爻需要摇满六次');
    }
    final lunar = LunarCalendar.fromSolar(at);
    if (lunar == null) {
      throw StateError('这个日期无法换算农历');
    }

    final hexagram = Hexagram([for (final line in lines) line.yang]);
    final original = HexagramBook.of(hexagram);
    final palace = Palaces.of(original);
    final changingIndexes = [
      for (var i = 0; i < lines.length; i++)
        if (lines[i].changing) i,
    ];
    final changed = changingIndexes.isEmpty
        ? null
        : HexagramBook.of(hexagram.changeAt(changingIndexes));
    final monthElement = elementOfLunarMonth(lunar.month);
    final stem = dayStemIndex(at);
    final spiritStart = _spiritStart(stem);
    final ganzhi = [
      ..._najia[hexagram.lower.name]!.lower,
      ..._najia[hexagram.upper.name]!.upper,
    ];
    final yingIndex = (palace.shiIndex + 3) % 6;
    final installed = [
      for (var i = 0; i < 6; i++)
        InstalledLine(
          index: i,
          kind: lines[i],
          ganzhi: ganzhi[i],
          relative: _relative(
            palace.element,
            elementOfBranch(ganzhi[i].substring(1)),
          ),
          spirit: _spirits[(spiritStart + i) % 6],
          strength: strengthLabel(
            elementOfBranch(ganzhi[i].substring(1)),
            monthElement,
          ),
          isShi: i == palace.shiIndex,
          isYing: i == yingIndex,
        ),
    ];
    final tone = _tone(installed, topic);
    return LiuyaoReading(
      lines: installed,
      original: original,
      changed: changed,
      palace: palace,
      topic: topic,
      question: question,
      createdAt: at,
      lunar: lunar,
      tone: tone,
      paragraphs: _paragraphs(
        lines: installed,
        original: original,
        changed: changed,
        palace: palace,
        topic: topic,
        lunar: lunar,
        tone: tone,
      ),
    );
  }

  static String strengthLabel(WuXing line, WuXing month) {
    if (line == month) {
      return '旺';
    }
    if (month.generates(line)) {
      return '相';
    }
    if (line.generates(month)) {
      return '休';
    }
    if (month.overcomes(line)) {
      return '囚';
    }
    return '死';
  }

  static String _relative(WuXing palace, WuXing line) {
    if (line == palace) {
      return '兄弟';
    }
    if (palace.generates(line)) {
      return '子孙';
    }
    if (line.generates(palace)) {
      return '父母';
    }
    if (palace.overcomes(line)) {
      return '妻财';
    }
    return '官鬼';
  }

  static int _spiritStart(int stemIndex) {
    return switch (stemIndex) {
      0 || 1 => 0,
      2 || 3 => 1,
      4 => 2,
      5 => 3,
      6 || 7 => 4,
      _ => 5,
    };
  }

  static int _rank(String strength) {
    return switch (strength) {
      '旺' => 5,
      '相' => 4,
      '休' => 3,
      '囚' => 2,
      _ => 1,
    };
  }

  static ReadingTone _toneFromRank(int rank) {
    if (rank >= 4) {
      return ReadingTone.smooth;
    }
    if (rank == 3) {
      return ReadingTone.steady;
    }
    return ReadingTone.slow;
  }

  static ReadingTone _tone(List<InstalledLine> lines, DivinationTopic topic) {
    ReadingTone fromRelative(String relative) {
      final matched = lines.where((line) => line.relative == relative).toList();
      if (matched.isEmpty) {
        return ReadingTone.unclear;
      }
      final best = matched.map((line) => _rank(line.strength)).reduce(max);
      return _toneFromRank(best);
    }

    final shi = lines.firstWhere((line) => line.isShi);
    return switch (topic) {
      DivinationTopic.general || DivinationTopic.travel => _toneFromRank(
        _rank(shi.strength),
      ),
      DivinationTopic.career => fromRelative('官鬼'),
      DivinationTopic.wealth => fromRelative('妻财'),
      DivinationTopic.relationship => _toneFromRank(
        _rank(lines.firstWhere((line) => line.isYing).strength),
      ),
      DivinationTopic.health => _healthTone(lines),
    };
  }

  static ReadingTone _healthTone(List<InstalledLine> lines) {
    final medicine = lines.where((line) => line.relative == '子孙').toList();
    final illness = lines.where((line) => line.relative == '官鬼').toList();
    if (medicine.isEmpty && illness.isEmpty) {
      return ReadingTone.unclear;
    }
    final medicineRank = medicine.isEmpty
        ? 0
        : medicine.map((line) => _rank(line.strength)).reduce(max);
    final illnessRank = illness.isEmpty
        ? 0
        : illness.map((line) => _rank(line.strength)).reduce(max);
    if (medicineRank >= 4 && medicineRank >= illnessRank) {
      return ReadingTone.smooth;
    }
    if (illnessRank >= 4 && illnessRank > medicineRank) {
      return ReadingTone.slow;
    }
    return ReadingTone.steady;
  }

  static List<String> _paragraphs({
    required List<InstalledLine> lines,
    required HexagramEntry original,
    required HexagramEntry? changed,
    required PalacePlacement palace,
    required DivinationTopic topic,
    required LunarDate lunar,
    required ReadingTone tone,
  }) {
    final shi = lines.firstWhere((line) => line.isShi);
    final ying = lines.firstWhere((line) => line.isYing);
    final moving = lines.where((line) => line.kind.changing).toList();
    final changeText = changed == null
        ? '六爻皆静，事态以本卦格局为主，没有突然的转折。'
        : '动而变为${changed.title}。动爻在${moving.map((line) => line.position).join('、')}，这些位置是正在变化的地方。';
    return [
      '本卦${original.title}，${palace.label}。${lunar.dateLabel}，月令${elementOfLunarMonth(lunar.month).label}。$changeText',
      '世爻在${shi.position}，${shi.relative}${shi.branch}${shi.element.label}，月令${shi.strength}。应爻在${ying.position}，${ying.relative}${ying.branch}${ying.element.label}，月令${ying.strength}。${_shiYing(shi.element, ying.element)}',
      _movingText(moving),
      _topicText(lines, topic, tone),
      original.text,
    ];
  }

  static String _shiYing(WuXing shi, WuXing ying) {
    if (shi == ying) {
      return '世应比和，彼此势均，宜商量着办。';
    }
    if (ying.generates(shi)) {
      return '应生世，外缘相助，所问之事比较容易得到回应。';
    }
    if (shi.generates(ying)) {
      return '世生应，自己付出较多，成事靠主动。';
    }
    if (shi.overcomes(ying)) {
      return '世克应，自己握有主动。推进时宜留有余地。';
    }
    return '应克世，外部压力较大。宜放慢，先处理阻力。';
  }

  static String _movingText(List<InstalledLine> moving) {
    if (moving.isEmpty) {
      return '没有动爻。事情更像是维持现有格局，宜按已有步骤做。';
    }
    final details = moving
        .map(
          (line) =>
              '${line.position}${line.relative}${line.branch}发动，月令${line.strength}',
        )
        .join('；');
    return '动爻提示变化的着力点：$details。旺相的动爻推动更明显，囚死的动爻多半是消耗。';
  }

  static String _topicText(
    List<InstalledLine> lines,
    DivinationTopic topic,
    ReadingTone tone,
  ) {
    final advice = switch (tone) {
      ReadingTone.smooth => '整体偏顺，可以按计划推进，仍要留有余地。',
      ReadingTone.steady => '整体平稳，宜按部就班，不必强求速成。',
      ReadingTone.slow => '整体偏滞，宜放慢、把条件补足，再做决定。',
      ReadingTone.unclear => '用神不显，信息不足。可以把问题问得更具体，或等事态清楚一些再看。',
    };
    final focus = switch (topic) {
      DivinationTopic.general => _focus(lines, '综合以世爻代表问卦之人', null),
      DivinationTopic.career => _focus(lines, '事业看官鬼', '官鬼'),
      DivinationTopic.wealth => _focus(lines, '财运看妻财', '妻财'),
      DivinationTopic.relationship => _relationship(lines),
      DivinationTopic.health => _health(lines),
      DivinationTopic.travel => _focus(lines, '出行看世爻是否能动身', null),
    };
    return '$focus$advice';
  }

  static String _focus(
    List<InstalledLine> lines,
    String intro,
    String? relative,
  ) {
    if (relative == null) {
      final shi = lines.firstWhere((line) => line.isShi);
      return '$intro。世爻${shi.strength}，${shi.kind.changing ? '并且发动' : '没有发动'}。';
    }
    final matched = lines.where((line) => line.relative == relative).toList();
    if (matched.isEmpty) {
      return '$intro。卦中不见$relative。';
    }
    final described = matched
        .map(
          (line) =>
              '${line.position}${line.strength}${line.kind.changing ? '，发动' : ''}',
        )
        .join('、');
    return '$intro，落在$described。';
  }

  static String _relationship(List<InstalledLine> lines) {
    final ying = lines.firstWhere((line) => line.isYing);
    return '感情先看应爻。应爻为${ying.relative}，月令${ying.strength}${ying.kind.changing ? '，并且发动' : ''}。不预设谁是谁，双方是否和合，可与世应生克一起看。';
  }

  static String _health(List<InstalledLine> lines) {
    final medicine = _focus(lines, '传统以子孙为药、调养之力', '子孙');
    final illness = _focus(lines, '以官鬼为病、压力之所在', '官鬼');
    return '$illness$medicine身体状况以医生意见为准，这里只作文化参照。';
  }
}

class _Najia {
  const _Najia(this.lower, this.upper);

  final List<String> lower;
  final List<String> upper;
}

const _spirits = ['青龙', '朱雀', '勾陈', '螣蛇', '白虎', '玄武'];

const _najia = <String, _Najia>{
  '乾': _Najia(['甲子', '甲寅', '甲辰'], ['壬午', '壬申', '壬戌']),
  '坤': _Najia(['乙未', '乙巳', '乙卯'], ['癸丑', '癸亥', '癸酉']),
  '震': _Najia(['庚子', '庚寅', '庚辰'], ['庚午', '庚申', '庚戌']),
  '巽': _Najia(['辛丑', '辛亥', '辛酉'], ['辛未', '辛巳', '辛卯']),
  '坎': _Najia(['戊寅', '戊辰', '戊午'], ['戊申', '戊戌', '戊子']),
  '离': _Najia(['己卯', '己丑', '己亥'], ['己酉', '己未', '己巳']),
  '艮': _Najia(['丙辰', '丙午', '丙申'], ['丙戌', '丙子', '丙寅']),
  '兑': _Najia(['丁巳', '丁卯', '丁丑'], ['丁亥', '丁酉', '丁未']),
};
