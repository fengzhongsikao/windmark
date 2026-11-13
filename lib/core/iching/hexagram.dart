import 'package:windmark/core/iching/trigram.dart';

abstract final class YaoPosition {
  static const names = ['初爻', '二爻', '三爻', '四爻', '五爻', '上爻'];
}

class Hexagram {
  Hexagram(List<bool> lines) : lines = List.unmodifiable(lines) {
    if (lines.length != 6) {
      throw ArgumentError('一卦必须有六爻');
    }
  }

  factory Hexagram.fromTrigrams(Trigram lower, Trigram upper) {
    return Hexagram([...lower.lines, ...upper.lines]);
  }

  /// 自下而上，true 为阳爻。
  final List<bool> lines;

  Trigram get lower => Trigram.fromLines(lines.sublist(0, 3));

  Trigram get upper => Trigram.fromLines(lines.sublist(3, 6));

  Hexagram changeAt(Iterable<int> indexes) {
    final next = [...lines];
    for (final index in indexes) {
      next[index] = !next[index];
    }
    return Hexagram(next);
  }

  /// 互卦取二三四爻为下卦，三四五爻为上卦。
  Hexagram get mutual {
    return Hexagram([
      lines[1],
      lines[2],
      lines[3],
      lines[2],
      lines[3],
      lines[4],
    ]);
  }
}
