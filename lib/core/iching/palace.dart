import 'package:windmark/core/iching/hexagram_book.dart';
import 'package:windmark/core/iching/wuxing.dart';

class PalacePlacement {
  const PalacePlacement({
    required this.name,
    required this.element,
    required this.generation,
  });

  final String name;
  final WuXing element;
  final int generation;

  int get shiIndex => const [5, 0, 1, 2, 3, 4, 3, 2][generation];

  String get generationLabel => const [
    '本宫',
    '一世',
    '二世',
    '三世',
    '四世',
    '五世',
    '游魂',
    '归魂',
  ][generation];

  String get label => '$name宫 · $generationLabel';
}

abstract final class Palaces {
  static final Map<String, PalacePlacement> byHexagramName = {
    for (final palace in _palaces)
      for (var generation = 0; generation < palace.members.length; generation++)
        palace.members[generation]: PalacePlacement(
          name: palace.name,
          element: palace.element,
          generation: generation,
        ),
  };

  static PalacePlacement of(HexagramEntry entry) {
    final placement = byHexagramName[entry.name];
    if (placement == null) {
      throw StateError('八宫缺少 ${entry.name}');
    }
    return placement;
  }
}

class _PalaceSpec {
  const _PalaceSpec(this.name, this.element, this.members);

  final String name;
  final WuXing element;
  final List<String> members;
}

const _palaces = <_PalaceSpec>[
  _PalaceSpec('乾', WuXing.metal, ['乾', '姤', '遁', '否', '观', '剥', '晋', '大有']),
  _PalaceSpec('坎', WuXing.water, ['坎', '节', '屯', '既济', '革', '丰', '明夷', '师']),
  _PalaceSpec('艮', WuXing.earth, ['艮', '贲', '大畜', '损', '睽', '履', '中孚', '渐']),
  _PalaceSpec('震', WuXing.wood, ['震', '豫', '解', '恒', '升', '井', '大过', '随']),
  _PalaceSpec('巽', WuXing.wood, ['巽', '小畜', '家人', '益', '无妄', '噬嗑', '颐', '蛊']),
  _PalaceSpec('离', WuXing.fire, ['离', '旅', '鼎', '未济', '蒙', '涣', '讼', '同人']),
  _PalaceSpec('坤', WuXing.earth, ['坤', '复', '临', '泰', '大壮', '夬', '需', '比']),
  _PalaceSpec('兑', WuXing.metal, ['兑', '困', '萃', '咸', '蹇', '谦', '小过', '归妹']),
];
