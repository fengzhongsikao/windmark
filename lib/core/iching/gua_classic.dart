import 'dart:convert';

import 'package:flutter/services.dart';

class GuaClassic {
  const GuaClassic({
    required this.id,
    required this.guaCi,
    required this.yaoCi,
    required this.tuan,
    required this.daXiang,
    required this.xiaoXiang,
    required this.wenyan,
    required this.xu,
    required this.za,
  });

  final int id;
  final String guaCi;

  /// 自初爻至上爻。用九、用六若单独成句，附在最后。
  final List<String> yaoCi;

  /// 彖传。
  final String tuan;

  /// 大象。
  final String daXiang;

  /// 小象，自初爻至上爻。乾、坤在末条附用九、用六。
  final List<String> xiaoXiang;

  /// 文言。只有乾、坤有。
  final List<String> wenyan;

  /// 序卦里说到这一卦的一句。
  final String xu;

  /// 杂卦里说到这一卦的一句。
  final String za;
}

class GuaTextBook {
  GuaTextBook(this._byId);

  final Map<int, GuaClassic> _byId;

  static Future<GuaTextBook>? _loading;

  static Future<GuaTextBook> load() {
    return _loading ??= _read();
  }

  static Future<GuaTextBook> _read() async {
    final raw = await rootBundle.loadString('assets/data.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final rows = json['data'] as List<dynamic>;
    return GuaTextBook({
      for (final row in rows.cast<Map<String, dynamic>>())
        row['id'] as int: GuaClassic(
          id: row['id'] as int,
          guaCi: _clean(row['gua_ci'] as String),
          yaoCi: [
            for (final line in row['yao_ci'] as List<dynamic>)
              ..._expand(line as String),
          ],
          tuan: _clean(row['tuan'] as String),
          daXiang: _clean(row['da_xiang'] as String),
          xiaoXiang: [
            for (final line in row['xiao_xiang'] as List<dynamic>)
              _clean(line as String),
          ],
          wenyan: [
            for (final line in row['wenyan'] as List<dynamic>)
              _clean(line as String),
          ],
          xu: _clean(row['xu'] as String),
          za: _clean(row['za'] as String),
        ),
    });
  }

  GuaClassic? byNumber(int number) => _byId[number];
}

String _clean(String text) => text.replaceAll(RegExp(r'\s+'), '').trim();

final _yaoHead = RegExp('初[九六]|[九六][二三四五]|上[九六]|用[九六]');

List<String> _expand(String text) {
  final cleaned = _clean(text);
  final marks = _yaoHead.allMatches(cleaned).toList();
  if (marks.length <= 1) {
    return [cleaned];
  }
  return [
    for (var i = 0; i < marks.length; i++)
      cleaned
          .substring(
            marks[i].start,
            i + 1 < marks.length ? marks[i + 1].start : cleaned.length,
          )
          .trim(),
  ];
}

/// 1 为初爻，6 为上爻。用九、用六返回空。
int? yaoLineOf(String text) {
  const heads = [
    ['初九', '初六'],
    ['九二', '六二'],
    ['九三', '六三'],
    ['九四', '六四'],
    ['九五', '六五'],
    ['上九', '上六'],
  ];
  for (var i = 0; i < heads.length; i++) {
    if (heads[i].any(text.startsWith)) {
      return i + 1;
    }
  }
  return null;
}
