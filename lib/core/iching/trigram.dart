import 'package:windmark/core/iching/wuxing.dart';

class Trigram {
  const Trigram._(
    this.number,
    this.name,
    this.nature,
    this.element,
    this.lines,
  );

  final int number;
  final String name;
  final String nature;
  final WuXing element;

  /// 自下而上，true 为阳爻。
  final List<bool> lines;

  static const qian = Trigram._(1, '乾', '天', WuXing.metal, [true, true, true]);
  static const dui = Trigram._(2, '兑', '泽', WuXing.metal, [true, true, false]);
  static const li = Trigram._(3, '离', '火', WuXing.fire, [true, false, true]);
  static const zhen = Trigram._(4, '震', '雷', WuXing.wood, [true, false, false]);
  static const xun = Trigram._(5, '巽', '风', WuXing.wood, [false, true, true]);
  static const kan = Trigram._(6, '坎', '水', WuXing.water, [false, true, false]);
  static const gen = Trigram._(7, '艮', '山', WuXing.earth, [false, false, true]);
  static const kun = Trigram._(8, '坤', '地', WuXing.earth, [false, false, false]);

  static const values = [qian, dui, li, zhen, xun, kan, gen, kun];

  static Trigram byNumber(int number) {
    final remainder = number % 8;
    final normalized = remainder == 0 ? 8 : remainder;
    return values[normalized - 1];
  }

  static Trigram byName(String name) {
    return values.firstWhere((trigram) => trigram.name == name);
  }

  static Trigram fromLines(List<bool> lines) {
    for (final trigram in values) {
      if (_same(trigram.lines, lines)) {
        return trigram;
      }
    }
    throw ArgumentError('无法识别的三爻');
  }
}

bool _same(List<bool> left, List<bool> right) {
  if (left.length != right.length) {
    return false;
  }
  for (var i = 0; i < left.length; i++) {
    if (left[i] != right[i]) {
      return false;
    }
  }
  return true;
}
