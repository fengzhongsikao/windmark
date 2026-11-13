import 'package:windmark/core/iching/hexagram_book.dart';
import 'package:windmark/core/iching/wuxing.dart';

class PalacePlacement {
  const PalacePlacement({
    required this.name,
    required this.element,
    required this.generationLabel,
    required this.shiIndex,
  });

  final String name;
  final WuXing element;
  final String generationLabel;

  /// 自下而上，0 为初爻。
  final int shiIndex;

  String get label {
    if (generationLabel == '游魂' || generationLabel == '归魂') {
      return '$name宫 · $generationLabel';
    }
    if (generationLabel == '本宫') {
      return '$name宫 · 本宫';
    }
    return '$name宫';
  }
}

abstract final class Palaces {
  static final Map<String, PalacePlacement> byHexagramName = {
    for (final palace in _palaces) ...{
      for (var index = 0; index < palace.members.length; index++)
        palace.members[index]: PalacePlacement(
          name: palace.name,
          element: palace.element,
          generationLabel: _generations[index],
          shiIndex: _shi[index],
        ),
      palace.youhun: PalacePlacement(
        name: palace.name,
        element: palace.element,
        generationLabel: '游魂',
        shiIndex: 3,
      ),
      palace.guihun: PalacePlacement(
        name: palace.name,
        element: palace.element,
        generationLabel: '归魂',
        shiIndex: 2,
      ),
    },
  };

  static PalacePlacement of(HexagramEntry entry) {
    final placement = byHexagramName[entry.name];
    if (placement == null) {
      throw StateError('八宫缺少 ${entry.name}');
    }
    return placement;
  }
}

const _generations = ['本宫', '一世', '二世', '三世', '四世', '五世'];

/// 本宫在上爻，一世在初爻，之后逐爻上移到五世。
const _shi = [5, 0, 1, 2, 3, 4];

class _PalaceSpec {
  const _PalaceSpec(
    this.name,
    this.element,
    this.members, {
    required this.youhun,
    required this.guihun,
  });

  final String name;
  final WuXing element;

  /// 本宫到五世。
  final List<String> members;
  final String youhun;
  final String guihun;
}

const _palaces = <_PalaceSpec>[
  _PalaceSpec(
    '乾',
    WuXing.metal,
    ['乾', '姤', '遁', '否', '观', '剥'],
    youhun: '晋',
    guihun: '大有',
  ),
  _PalaceSpec(
    '坎',
    WuXing.water,
    ['坎', '节', '屯', '既济', '革', '丰'],
    youhun: '明夷',
    guihun: '师',
  ),
  _PalaceSpec(
    '艮',
    WuXing.earth,
    ['艮', '贲', '大畜', '损', '睽', '履'],
    youhun: '中孚',
    guihun: '渐',
  ),
  _PalaceSpec(
    '震',
    WuXing.wood,
    ['震', '豫', '解', '恒', '升', '井'],
    youhun: '大过',
    guihun: '随',
  ),
  _PalaceSpec(
    '巽',
    WuXing.wood,
    ['巽', '小畜', '家人', '益', '无妄', '噬嗑'],
    youhun: '颐',
    guihun: '蛊',
  ),
  _PalaceSpec(
    '离',
    WuXing.fire,
    ['离', '旅', '鼎', '未济', '蒙', '涣'],
    youhun: '讼',
    guihun: '同人',
  ),
  _PalaceSpec(
    '坤',
    WuXing.earth,
    ['坤', '复', '临', '泰', '大壮', '夬'],
    youhun: '需',
    guihun: '比',
  ),
  _PalaceSpec(
    '兑',
    WuXing.metal,
    ['兑', '困', '萃', '咸', '蹇', '谦'],
    youhun: '小过',
    guihun: '归妹',
  ),
];
