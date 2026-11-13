class LunarDate {
  const LunarDate({
    required this.year,
    required this.month,
    required this.day,
    required this.isLeapMonth,
  });

  final int year;
  final int month;
  final int day;
  final bool isLeapMonth;

  String get yearGanzhi {
    final stem = stems[(year - 4) % 10];
    final branch = branches[(year - 4) % 12];
    return '$stem$branch';
  }

  /// 地支序数，子为一。
  int get yearBranchNumber => ((year - 4) % 12) + 1;

  String get monthText {
    final name = _monthNames[month - 1];
    final prefix = isLeapMonth ? '闰' : '';
    return '$prefix$name月';
  }

  String get dayText => _dayText(day);

  String get dateLabel => '农历$yearGanzhi年$monthText$dayText';

  String labelWithHour(int hour) {
    return '$dateLabel · ${hourBranchName(hour)}时';
  }
}

const stems = ['甲', '乙', '丙', '丁', '戊', '己', '庚', '辛', '壬', '癸'];
const branches = ['子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥'];

const _monthNames = ['正', '二', '三', '四', '五', '六', '七', '八', '九', '十', '冬', '腊'];

/// 子时从 23 点起，序数从 1 到 12。
int hourBranchNumber(int hour) => ((hour + 1) ~/ 2) % 12 + 1;

String hourBranchName(int hour) => branches[hourBranchNumber(hour) - 1];

/// 1900-01-01 为甲戌日，甲的序号是 0。
int dayStemIndex(DateTime date) {
  final offset = DateTime.utc(date.year, date.month, date.day)
      .difference(DateTime.utc(1900, 1, 1))
      .inDays;
  return offset % 10;
}

String formatSolar(DateTime date) {
  const weeks = ['一', '二', '三', '四', '五', '六', '日'];
  return '${date.year}年${date.month}月${date.day}日 周${weeks[date.weekday - 1]}';
}

String formatMoment(DateTime date) {
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '${date.month}月${date.day}日 $hour:$minute';
}

String _dayText(int day) {
  const numerals = ['一', '二', '三', '四', '五', '六', '七', '八', '九', '十'];
  if (day <= 10) {
    return '初${numerals[day - 1]}';
  }
  if (day < 20) {
    return '十${numerals[day - 11]}';
  }
  if (day == 20) {
    return '二十';
  }
  if (day < 30) {
    return '廿${numerals[day - 21]}';
  }
  return '三十';
}

abstract final class LunarCalendar {
  /// 1900 到 2100 的公历日期可换算，范围外返回 null。
  static LunarDate? fromSolar(DateTime date) {
    if (date.year < 1900 || date.year > 2100) {
      return null;
    }

    final solar = DateTime.utc(date.year, date.month, date.day);
    var offset = solar.difference(DateTime.utc(1900, 1, 31)).inDays;

    var year = 1900;
    var yearDays = 0;
    while (year < 2101 && offset > 0) {
      yearDays = _yearDays(year);
      offset -= yearDays;
      year++;
    }
    if (offset < 0) {
      offset += yearDays;
      year--;
    }

    final leap = _leapMonth(year);
    var isLeap = false;
    var month = 1;
    var monthDays = 0;
    for (month = 1; month < 13 && offset > 0; month++) {
      if (leap > 0 && month == leap + 1 && !isLeap) {
        month--;
        isLeap = true;
        monthDays = _leapDays(year);
      } else {
        monthDays = _monthDays(year, month);
      }
      if (isLeap && month == leap + 1) {
        isLeap = false;
      }
      offset -= monthDays;
    }

    if (offset == 0 && leap > 0 && month == leap + 1) {
      if (isLeap) {
        isLeap = false;
      } else {
        isLeap = true;
        month--;
      }
    }
    if (offset < 0) {
      offset += monthDays;
      month--;
    }

    final day = offset + 1;
    if (month < 1 || month > 12 || day < 1 || day > 30) {
      return null;
    }
    return LunarDate(
      year: year,
      month: month,
      day: day,
      isLeapMonth: isLeap,
    );
  }

  static int _yearDays(int year) {
    var sum = 348;
    final info = _lunarInfo[year - 1900];
    for (var mask = 0x8000; mask > 0x8; mask >>= 1) {
      if ((info & mask) != 0) {
        sum += 1;
      }
    }
    return sum + _leapDays(year);
  }

  static int _leapMonth(int year) => _lunarInfo[year - 1900] & 0xf;

  static int _leapDays(int year) {
    if (_leapMonth(year) == 0) {
      return 0;
    }
    return (_lunarInfo[year - 1900] & 0x10000) != 0 ? 30 : 29;
  }

  static int _monthDays(int year, int month) {
    return (_lunarInfo[year - 1900] & (0x10000 >> month)) != 0 ? 30 : 29;
  }
}

/// 1900–2100 农历编码：低 4 位为闰月，bit4–15 为十二个月大小，bit16 为闰月大小。
const _lunarInfo = <int>[
  0x04bd8, 0x04ae0, 0x0a570, 0x054d5, 0x0d260, 0x0d950, 0x16554, 0x056a0, 0x09ad0, 0x055d2, // 1900-1909
  0x04ae0, 0x0a5b6, 0x0a4d0, 0x0d250, 0x1d255, 0x0b540, 0x0d6a0, 0x0ada2, 0x095b0, 0x14977, // 1910-1919
  0x04970, 0x0a4b0, 0x0b4b5, 0x06a50, 0x06d40, 0x1ab54, 0x02b60, 0x09570, 0x052f2, 0x04970, // 1920-1929
  0x06566, 0x0d4a0, 0x0ea50, 0x06e95, 0x05ad0, 0x02b60, 0x186e3, 0x092e0, 0x1c8d7, 0x0c950, // 1930-1939
  0x0d4a0, 0x1d8a6, 0x0b550, 0x056a0, 0x1a5b4, 0x025d0, 0x092d0, 0x0d2b2, 0x0a950, 0x0b557, // 1940-1949
  0x06ca0, 0x0b550, 0x15355, 0x04da0, 0x0a5b0, 0x14573, 0x052b0, 0x0a9a8, 0x0e950, 0x06aa0, // 1950-1959
  0x0aea6, 0x0ab50, 0x04b60, 0x0aae4, 0x0a570, 0x05260, 0x0f263, 0x0d950, 0x05b57, 0x056a0, // 1960-1969
  0x096d0, 0x04dd5, 0x04ad0, 0x0a4d0, 0x0d4d4, 0x0d250, 0x0d558, 0x0b540, 0x0b6a0, 0x195a6, // 1970-1979
  0x095b0, 0x049b0, 0x0a974, 0x0a4b0, 0x0b27a, 0x06a50, 0x06d40, 0x0af46, 0x0ab60, 0x09570, // 1980-1989
  0x04af5, 0x04970, 0x064b0, 0x074a3, 0x0ea50, 0x06b58, 0x05ac0, 0x0ab60, 0x096d5, 0x092e0, // 1990-1999
  0x0c960, 0x0d954, 0x0d4a0, 0x0da50, 0x07552, 0x056a0, 0x0abb7, 0x025d0, 0x092d0, 0x0cab5, // 2000-2009
  0x0a950, 0x0b4a0, 0x0baa4, 0x0ad50, 0x055d9, 0x04ba0, 0x0a5b0, 0x15176, 0x052b0, 0x0a930, // 2010-2019
  0x07954, 0x06aa0, 0x0ad50, 0x05b52, 0x04b60, 0x0a6e6, 0x0a4e0, 0x0d260, 0x0ea65, 0x0d530, // 2020-2029
  0x05aa0, 0x076a3, 0x096d0, 0x04afb, 0x04ad0, 0x0a4d0, 0x1d0b6, 0x0d250, 0x0d520, 0x0dd45, // 2030-2039
  0x0b5a0, 0x056d0, 0x055b2, 0x049b0, 0x0a577, 0x0a4b0, 0x0aa50, 0x1b255, 0x06d20, 0x0ada0, // 2040-2049
  0x14b63, 0x09370, 0x049f8, 0x04970, 0x064b0, 0x168a6, 0x0ea50, 0x06b20, 0x1a6c4, 0x0aae0, // 2050-2059
  0x0a2e0, 0x0d2e3, 0x0c960, 0x0d557, 0x0d4a0, 0x0da50, 0x05d55, 0x056a0, 0x0a6d0, 0x055d4, // 2060-2069
  0x052d0, 0x0a9b8, 0x0a950, 0x0b4a0, 0x0b6a6, 0x0ad50, 0x055a0, 0x0aba4, 0x0a5b0, 0x052b0, // 2070-2079
  0x0b273, 0x06930, 0x07337, 0x06aa0, 0x0ad50, 0x14b55, 0x04b60, 0x0a570, 0x054e4, 0x0d160, // 2080-2089
  0x0e968, 0x0d520, 0x0daa0, 0x16aa6, 0x056d0, 0x04ae0, 0x0a9d4, 0x0a2d0, 0x0d150, 0x0f252, // 2090-2099
  0x0d520, // 2100
];
