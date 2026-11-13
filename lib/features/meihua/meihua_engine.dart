import 'dart:math';

import 'package:windmark/core/calendar/lunar_calendar.dart';
import 'package:windmark/core/iching/hexagram.dart';
import 'package:windmark/core/iching/hexagram_book.dart';
import 'package:windmark/core/iching/trigram.dart';
import 'package:windmark/core/iching/wuxing.dart';
import 'package:windmark/core/models/reading_record.dart';

enum BodyUseRelation {
  useGeneratesBody('吉', '用生体'),
  bodyGeneratesUse('耗', '体生用'),
  bodyOvercomesUse('可成', '体克用'),
  useOvercomesBody('阻', '用克体'),
  same('平', '比和');

  const BodyUseRelation(this.tone, this.classicName);

  final String tone;
  final String classicName;

  String get summary => switch (this) {
    BodyUseRelation.useGeneratesBody => '外力来生扶体卦，所问之事多有助力，可以顺势推进。',
    BodyUseRelation.bodyGeneratesUse => '体去生用，自己消耗较大。事情能做，但不宜铺得太开。',
    BodyUseRelation.bodyOvercomesUse => '体卦制约用卦，事情可由自己把握。成事需要主动，也要避免用力过猛。',
    BodyUseRelation.useOvercomesBody => '用卦来克体卦，外部阻力明显。宜暂缓、迂回，先稳住再行动。',
    BodyUseRelation.same => '体用同气，局势平稳。按既定步骤推进即可，不必强求突变。',
  };

  static BodyUseRelation between(WuXing body, WuXing function) {
    if (function.generates(body)) {
      return BodyUseRelation.useGeneratesBody;
    }
    if (body.generates(function)) {
      return BodyUseRelation.bodyGeneratesUse;
    }
    if (body.overcomes(function)) {
      return BodyUseRelation.bodyOvercomesUse;
    }
    if (function.overcomes(body)) {
      return BodyUseRelation.useOvercomesBody;
    }
    return BodyUseRelation.same;
  }
}

class MeihuaCast {
  const MeihuaCast({
    required this.upper,
    required this.lower,
    required this.movingLine,
    required this.method,
    required this.detail,
    required this.createdAt,
    this.question = '',
  });

  final Trigram upper;
  final Trigram lower;
  final int movingLine;
  final String method;
  final String detail;
  final DateTime createdAt;
  final String question;

  MeihuaCast withQuestion(String question) {
    return MeihuaCast(
      upper: upper,
      lower: lower,
      movingLine: movingLine,
      method: method,
      detail: detail,
      createdAt: createdAt,
      question: question,
    );
  }

  Hexagram get original => Hexagram.fromTrigrams(lower, upper);

  Hexagram get changed => original.changeAt([movingLine - 1]);

  Hexagram get mutual => original.mutual;

  bool get movingInUpper => movingLine > 3;

  Trigram get body => movingInUpper ? lower : upper;

  Trigram get function => movingInUpper ? upper : lower;

  BodyUseRelation get relation =>
      BodyUseRelation.between(body.element, function.element);

  HexagramEntry get originalEntry => HexagramBook.of(original);

  List<String> get paragraphs {
    final position = movingInUpper ? '上卦为用，下卦为体' : '下卦为用，上卦为体';
    final mutualEntry = HexagramBook.of(mutual);
    final changedEntry = HexagramBook.of(changed);
    return [
      '$method。$detail',
      '本卦${originalEntry.title}。${originalEntry.text}',
      '动爻在${YaoPosition.names[movingLine - 1]}，$position。体卦${body.name}（${body.element.label}），用卦${function.name}（${function.element.label}），${relation.classicName}。${relation.summary}',
      '互卦${mutualEntry.title}，用来看过程：${mutualEntry.text}',
      '变卦${changedEntry.title}，用来看趋向：${changedEntry.text}',
    ];
  }

  ReadingRecord toRecord({required String title}) {
    return ReadingRecord(
      id: 'meihua-${createdAt.microsecondsSinceEpoch}',
      kind: ReadingKind.meihua,
      createdAt: createdAt,
      title: title,
      summary: '${relation.classicName} · ${relation.tone}',
      payload: {
        'upper': upper.number,
        'lower': lower.number,
        'moving': movingLine,
        'method': method,
        'detail': detail,
        'question': question,
      },
    );
  }

  factory MeihuaCast.fromPayload(
    Map<String, Object?> payload,
    DateTime createdAt,
  ) {
    return MeihuaCast(
      upper: Trigram.byNumber(_asInt(payload['upper'])),
      lower: Trigram.byNumber(_asInt(payload['lower'])),
      movingLine: _asInt(payload['moving']),
      method: payload['method']! as String,
      detail: payload['detail']! as String,
      createdAt: createdAt,
      question: payload['question'] as String? ?? '',
    );
  }
}

abstract final class MeihuaEngine {
  static MeihuaCast? timeCast(DateTime moment) {
    final lunar = LunarCalendar.fromSolar(moment);
    if (lunar == null) {
      return null;
    }
    final year = lunar.yearBranchNumber;
    final month = lunar.month;
    final day = lunar.day;
    final hour = hourBranchNumber(moment.hour);
    final upperNumber = year + month + day;
    final lowerNumber = upperNumber + hour;
    final leapNote = lunar.isLeapMonth ? '闰月按本月数计。' : '';
    return MeihuaCast(
      upper: Trigram.byNumber(upperNumber),
      lower: Trigram.byNumber(lowerNumber),
      movingLine: _moving(lowerNumber),
      method: '时间起卦',
      detail:
          '${lunar.labelWithHour(moment.hour)}。年 $year、月 $month、日 $day、时 $hour。$leapNote',
      createdAt: moment,
    );
  }

  static MeihuaCast? numberCast({required int number, required DateTime at}) {
    if (number < 0 || number > 999) {
      return null;
    }
    final digits = number.toString().padLeft(3, '0');
    final hundreds = int.parse(digits[0]);
    final tens = int.parse(digits[1]);
    final units = int.parse(digits[2]);
    return MeihuaCast(
      upper: Trigram.byNumber(hundreds),
      lower: Trigram.byNumber(tens),
      movingLine: _movingFromEight(units),
      method: '数字起卦',
      detail: '数字 $digits。百位 $hundreds，十位 $tens，个位 $units。',
      createdAt: at,
    );
  }

  static MeihuaCast manualCast({
    required Trigram upper,
    required Trigram lower,
    required int movingLine,
    required DateTime at,
  }) {
    return MeihuaCast(
      upper: upper,
      lower: lower,
      movingLine: movingLine,
      method: '手动指定',
      detail:
          '上卦${upper.name}，下卦${lower.name}，${YaoPosition.names[movingLine - 1]}动。',
      createdAt: at,
    );
  }

  static MeihuaCast randomCast(Random random, DateTime at) {
    return MeihuaCast(
      upper: Trigram.byNumber(random.nextInt(8) + 1),
      lower: Trigram.byNumber(random.nextInt(8) + 1),
      movingLine: random.nextInt(6) + 1,
      method: '自动起卦',
      detail: '未取时间与报数，直接得到上卦、下卦和动爻。',
      createdAt: at,
    );
  }

  static int _moving(int value) {
    final remainder = value % 6;
    return remainder == 0 ? 6 : remainder;
  }

  /// 个位除以 8。余 0 当作 8；7、8 再减去 6，落到六爻之内。
  static int _movingFromEight(int value) {
    final remainder = value % 8;
    final normalized = remainder == 0 ? 8 : remainder;
    return normalized > 6 ? normalized - 6 : normalized;
  }
}

int _asInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  throw FormatException('数字字段无效');
}
