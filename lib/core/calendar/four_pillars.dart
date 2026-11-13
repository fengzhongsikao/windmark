import 'dart:math' as math;

import 'package:windmark/core/calendar/lunar_calendar.dart';

class Pillar {
  const Pillar(this.stemIndex, this.branchIndex);

  final int stemIndex;
  final int branchIndex;

  String get name => '${stems[stemIndex]}${branches[branchIndex]}';

  /// 本旬所空的两个地支。
  String get kongwang {
    final start = (branchIndex - stemIndex + 12) % 12;
    return '${branches[(start + 10) % 12]}${branches[(start + 11) % 12]}';
  }
}

class PillarSet {
  const PillarSet({
    required this.year,
    required this.month,
    required this.day,
    required this.hour,
    required this.termLabel,
  });

  final Pillar year;
  final Pillar month;
  final Pillar day;
  final Pillar hour;

  /// 当前节气到下一节气，北京时间。
  final String termLabel;

  static PillarSet of(DateTime moment) {
    final day = _dayPillar(moment);
    final hourBranch = hourBranchNumber(moment.hour) - 1;
    final hourStem = (_hourStemStart[day.stemIndex % 5] + hourBranch) % 10;
    final yearNumber = _ganzhiYear(moment);
    final monthBranch = _monthBranch(moment);
    final monthStem =
        (_yinMonthStem[stems.indexOf(_yearStem(yearNumber)) % 5] +
            (monthBranch - 2 + 12) % 12) %
        10;
    return PillarSet(
      year: Pillar((yearNumber - 4) % 10, (yearNumber - 4) % 12),
      month: Pillar(monthStem, monthBranch),
      day: day,
      hour: Pillar(hourStem, hourBranch),
      termLabel: _termSpan(moment),
    );
  }
}

const _hourStemStart = [0, 2, 4, 6, 8];

/// 甲己之年丙作首，五虎遁的寅月天干。
const _yinMonthStem = [2, 4, 6, 8, 0];

Pillar _dayPillar(DateTime moment) {
  final offset = DateTime.utc(
    moment.year,
    moment.month,
    moment.day,
  ).difference(DateTime.utc(1900, 1, 1)).inDays;
  return Pillar(offset % 10, (offset + 10) % 12);
}

String _yearStem(int year) => stems[(year - 4) % 10];

const _termNames = [
  '小寒',
  '大寒',
  '立春',
  '雨水',
  '惊蛰',
  '春分',
  '清明',
  '谷雨',
  '立夏',
  '小满',
  '芒种',
  '夏至',
  '小暑',
  '大暑',
  '立秋',
  '处暑',
  '白露',
  '秋分',
  '寒露',
  '霜降',
  '立冬',
  '小雪',
  '大雪',
  '冬至',
];

const _roughMinutes = [
  0,
  21208,
  42467,
  63836,
  85337,
  107014,
  128867,
  150921,
  173149,
  195551,
  218072,
  240693,
  263343,
  285989,
  308563,
  331033,
  353350,
  375494,
  397447,
  419210,
  440795,
  462224,
  483532,
  504758,
];

/// 十二节换月：小寒丑、立春寅……大雪子。
const _jieIndex = [0, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22];
const _jieBranch = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 0];

int _monthBranch(DateTime moment) {
  final utc = moment.toUtc();
  var branch = _jieBranch.last;
  for (final year in [utc.year - 1, utc.year, utc.year + 1]) {
    for (var i = 0; i < _jieIndex.length; i++) {
      final at = _termUtc(year, _jieIndex[i]);
      if (!at.isAfter(utc)) {
        branch = _jieBranch[i];
      }
    }
  }
  return branch;
}

int _ganzhiYear(DateTime moment) {
  final utc = moment.toUtc();
  var year = utc.year - 1;
  for (final candidate in [utc.year - 1, utc.year]) {
    final lichun = _termUtc(candidate, 2);
    if (!lichun.isAfter(utc)) {
      year = lichun.add(const Duration(hours: 8)).year;
    }
  }
  return year;
}

String _termSpan(DateTime moment) {
  final utc = moment.toUtc();
  final terms = <({String name, DateTime at})>[];
  for (final year in [utc.year - 1, utc.year, utc.year + 1]) {
    for (var i = 0; i < _termNames.length; i++) {
      terms.add((name: _termNames[i], at: _termUtc(year, i)));
    }
  }
  terms.sort((a, b) => a.at.compareTo(b.at));
  var current = terms.first;
  var next = terms[1];
  for (var i = 0; i < terms.length - 1; i++) {
    if (!terms[i].at.isAfter(utc)) {
      current = terms[i];
      next = terms[i + 1];
    }
  }
  return '${_formatTerm(current.name, current.at)} ~ ${_formatTerm(next.name, next.at)}';
}

String _formatTerm(String name, DateTime utc) {
  final time = utc.add(const Duration(hours: 8));
  final month = time.month.toString().padLeft(2, '0');
  final day = time.day.toString().padLeft(2, '0');
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$name${time.year}.$month.$day $hour:$minute';
}

DateTime _termUtc(int year, int index) {
  final roughMs =
      31556925974.7 * (year - 1900) +
      _roughMinutes[index] * 60000 +
      DateTime.utc(1900, 1, 6, 2, 5).millisecondsSinceEpoch;
  final rough = DateTime.fromMillisecondsSinceEpoch(
    roughMs.round(),
    isUtc: true,
  );
  final target = ((285 + index * 15) % 360).toDouble();
  var lo =
      rough.subtract(const Duration(days: 3)).millisecondsSinceEpoch /
          86400000.0 +
      2440587.5;
  var hi =
      rough.add(const Duration(days: 3)).millisecondsSinceEpoch / 86400000.0 +
      2440587.5;
  for (var i = 0; i < 40; i++) {
    final mid = (lo + hi) / 2;
    if (_isBefore(_sunLongitude(mid), target)) {
      lo = mid;
    } else {
      hi = mid;
    }
  }
  final millis = ((hi - 2440587.5) * 86400000).round();
  return DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);
}

bool _isBefore(double longitude, double target) {
  final ahead = _mod360(target - longitude);
  return ahead > 0 && ahead <= 180;
}

double _mod360(double value) {
  final mod = value % 360;
  return mod < 0 ? mod + 360 : mod;
}

double _sunLongitude(double jd) {
  final century = (jd - 2451545.0) / 36525.0;
  final mean =
      280.46646 + 36000.76983 * century + 0.0003032 * century * century;
  final anomaly =
      357.52911 + 35999.05029 * century - 0.0001537 * century * century;
  final anomalyRad = _mod360(anomaly) * math.pi / 180;
  var center =
      (1.914602 - 0.004817 * century - 0.000014 * century * century) *
      math.sin(anomalyRad);
  center += (0.019993 - 0.000101 * century) * math.sin(2 * anomalyRad);
  center += 0.000289 * math.sin(3 * anomalyRad);
  final omega = 125.04 - 1934.136 * century;
  final longitude =
      mean + center - 0.00569 - 0.00478 * math.sin(omega * math.pi / 180);
  return _mod360(longitude);
}
