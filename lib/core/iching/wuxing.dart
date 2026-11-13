enum WuXing {
  metal,
  wood,
  water,
  fire,
  earth;

  String get label => switch (this) {
    WuXing.metal => '金',
    WuXing.wood => '木',
    WuXing.water => '水',
    WuXing.fire => '火',
    WuXing.earth => '土',
  };

  bool generates(WuXing other) {
    return switch (this) {
      WuXing.wood => other == WuXing.fire,
      WuXing.fire => other == WuXing.earth,
      WuXing.earth => other == WuXing.metal,
      WuXing.metal => other == WuXing.water,
      WuXing.water => other == WuXing.wood,
    };
  }

  bool overcomes(WuXing other) {
    return switch (this) {
      WuXing.wood => other == WuXing.earth,
      WuXing.earth => other == WuXing.water,
      WuXing.water => other == WuXing.fire,
      WuXing.fire => other == WuXing.metal,
      WuXing.metal => other == WuXing.wood,
    };
  }
}

WuXing elementOfBranch(String branch) {
  return switch (branch) {
    '子' || '亥' => WuXing.water,
    '寅' || '卯' => WuXing.wood,
    '巳' || '午' => WuXing.fire,
    '申' || '酉' => WuXing.metal,
    '辰' || '戌' || '丑' || '未' => WuXing.earth,
    _ => throw ArgumentError('无法识别的地支：$branch'),
  };
}

/// 寅月为一月，丑月为十二月。
WuXing elementOfLunarMonth(int month) {
  return switch (month) {
    1 || 2 => WuXing.wood,
    4 || 5 => WuXing.fire,
    7 || 8 => WuXing.metal,
    10 || 11 => WuXing.water,
    3 || 6 || 9 || 12 => WuXing.earth,
    _ => throw ArgumentError('农历月份超出范围：$month'),
  };
}
