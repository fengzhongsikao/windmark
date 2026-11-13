/// 初四、二五、三上三对地支全冲，或全合。
abstract final class HexagramRelations {
  static const chong = <String>{
    '乾',
    '坤',
    '震',
    '巽',
    '坎',
    '离',
    '艮',
    '兑',
    '无妄',
    '大壮',
  };

  static const he = <String>{
    '泰',
    '否',
    '豫',
    '贲',
    '复',
    '困',
    '旅',
    '节',
  };

  static String? of(String name) {
    if (chong.contains(name)) {
      return '六冲卦';
    }
    if (he.contains(name)) {
      return '六合卦';
    }
    return null;
  }
}
