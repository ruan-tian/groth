enum CalendarFestivalType { solar, lunar }

class CalendarFestival {
  const CalendarFestival({required this.name, required this.type});

  final String name;
  final CalendarFestivalType type;
}

class LunarDateInfo {
  const LunarDateInfo({
    required this.year,
    required this.month,
    required this.day,
    required this.isLeapMonth,
  });

  final int year;
  final int month;
  final int day;
  final bool isLeapMonth;

  String get monthName => '${isLeapMonth ? '闰' : ''}${_monthNames[month - 1]}';
  String get dayName => _dayNames[day - 1];
  String get shortLabel => day == 1 ? monthName : dayName;
  String get fullLabel => '$monthName$dayName';

  static const _monthNames = [
    '正月',
    '二月',
    '三月',
    '四月',
    '五月',
    '六月',
    '七月',
    '八月',
    '九月',
    '十月',
    '冬月',
    '腊月',
  ];

  static const _dayNames = [
    '初一',
    '初二',
    '初三',
    '初四',
    '初五',
    '初六',
    '初七',
    '初八',
    '初九',
    '初十',
    '十一',
    '十二',
    '十三',
    '十四',
    '十五',
    '十六',
    '十七',
    '十八',
    '十九',
    '二十',
    '廿一',
    '廿二',
    '廿三',
    '廿四',
    '廿五',
    '廿六',
    '廿七',
    '廿八',
    '廿九',
    '三十',
  ];
}

class CalendarDayInfo {
  const CalendarDayInfo({
    required this.date,
    required this.lunar,
    required this.festivals,
    required this.isToday,
  });

  final DateTime date;
  final LunarDateInfo lunar;
  final List<CalendarFestival> festivals;
  final bool isToday;

  String get primarySubLabel =>
      festivals.isNotEmpty ? festivals.first.name : lunar.shortLabel;
}

class CalendarService {
  const CalendarService();

  static final _baseDate = DateTime(1900, 1, 31);

  static const _minYear = 1900;
  static const _maxYear = 2100;

  static const _lunarInfo = [
    0x04bd8,
    0x04ae0,
    0x0a570,
    0x054d5,
    0x0d260,
    0x0d950,
    0x16554,
    0x056a0,
    0x09ad0,
    0x055d2,
    0x04ae0,
    0x0a5b6,
    0x0a4d0,
    0x0d250,
    0x1d255,
    0x0b540,
    0x0d6a0,
    0x0ada2,
    0x095b0,
    0x14977,
    0x04970,
    0x0a4b0,
    0x0b4b5,
    0x06a50,
    0x06d40,
    0x1ab54,
    0x02b60,
    0x09570,
    0x052f2,
    0x04970,
    0x06566,
    0x0d4a0,
    0x0ea50,
    0x06e95,
    0x05ad0,
    0x02b60,
    0x186e3,
    0x092e0,
    0x1c8d7,
    0x0c950,
    0x0d4a0,
    0x1d8a6,
    0x0b550,
    0x056a0,
    0x1a5b4,
    0x025d0,
    0x092d0,
    0x0d2b2,
    0x0a950,
    0x0b557,
    0x06ca0,
    0x0b550,
    0x15355,
    0x04da0,
    0x0a5d0,
    0x14573,
    0x052d0,
    0x0a9a8,
    0x0e950,
    0x06aa0,
    0x0aea6,
    0x0ab50,
    0x04b60,
    0x0aae4,
    0x0a570,
    0x05260,
    0x0f263,
    0x0d950,
    0x05b57,
    0x056a0,
    0x096d0,
    0x04dd5,
    0x04ad0,
    0x0a4d0,
    0x0d4d4,
    0x0d250,
    0x0d558,
    0x0b540,
    0x0b5a0,
    0x195a6,
    0x095b0,
    0x049b0,
    0x0a974,
    0x0a4b0,
    0x0b27a,
    0x06a50,
    0x06d40,
    0x0af46,
    0x0ab60,
    0x09570,
    0x04af5,
    0x04970,
    0x064b0,
    0x074a3,
    0x0ea50,
    0x06b58,
    0x055c0,
    0x0ab60,
    0x096d5,
    0x092e0,
    0x0c960,
    0x0d954,
    0x0d4a0,
    0x0da50,
    0x07552,
    0x056a0,
    0x0abb7,
    0x025d0,
    0x092d0,
    0x0cab5,
    0x0a950,
    0x0b4a0,
    0x0baa4,
    0x0ad50,
    0x055d9,
    0x04ba0,
    0x0a5b0,
    0x15176,
    0x052b0,
    0x0a930,
    0x07954,
    0x06aa0,
    0x0ad50,
    0x05b52,
    0x04b60,
    0x0a6e6,
    0x0a4e0,
    0x0d260,
    0x0ea65,
    0x0d530,
    0x05aa0,
    0x076a3,
    0x096d0,
    0x04bd7,
    0x04ad0,
    0x0a4d0,
    0x1d0b6,
    0x0d250,
    0x0d520,
    0x0dd45,
    0x0b5a0,
    0x056d0,
    0x055b2,
    0x049b0,
    0x0a577,
    0x0a4b0,
    0x0aa50,
    0x1b255,
    0x06d20,
    0x0ada0,
    0x14b63,
    0x09370,
    0x049f8,
    0x04970,
    0x064b0,
    0x168a6,
    0x0ea50,
    0x06b20,
    0x1a6c4,
    0x0aae0,
    0x0a2e0,
    0x0d2e3,
    0x0c960,
    0x0d557,
    0x0d4a0,
    0x0da50,
    0x05d55,
    0x056a0,
    0x0a6d0,
    0x055d4,
    0x052d0,
    0x0a9b8,
    0x0a950,
    0x0b4a0,
    0x0b6a6,
    0x0ad50,
    0x055a0,
    0x0aba4,
    0x0a5b0,
    0x052b0,
    0x0b273,
    0x06930,
    0x07337,
    0x06aa0,
    0x0ad50,
    0x14b55,
    0x04b60,
    0x0a570,
    0x054e4,
    0x0d160,
    0x0e968,
    0x0d520,
    0x0daa0,
    0x16aa6,
    0x056d0,
    0x04ae0,
    0x0a9d4,
    0x0a2d0,
    0x0d150,
    0x0f252,
    0x0d520,
  ];

  static const _solarFestivals = {
    '01-01': '元旦',
    '02-14': '情人节',
    '03-08': '妇女节',
    '03-12': '植树节',
    '04-05': '清明节',
    '05-01': '劳动节',
    '05-04': '青年节',
    '06-01': '儿童节',
    '07-01': '建党节',
    '08-01': '建军节',
    '09-10': '教师节',
    '10-01': '国庆节',
    '12-24': '平安夜',
    '12-25': '圣诞节',
  };

  static const _lunarFestivals = {
    '01-01': '春节',
    '01-15': '元宵节',
    '02-02': '龙抬头',
    '05-05': '端午节',
    '07-07': '七夕',
    '07-15': '中元节',
    '08-15': '中秋节',
    '09-09': '重阳节',
    '12-08': '腊八节',
    '12-23': '北方小年',
    '12-24': '南方小年',
  };

  CalendarDayInfo getDayInfo(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    final lunar = getLunarDate(normalized);
    final festivals = <CalendarFestival>[
      ..._solarFestivalsFor(normalized),
      ..._lunarFestivalsFor(lunar, normalized),
    ];

    final now = DateTime.now();
    return CalendarDayInfo(
      date: normalized,
      lunar: lunar,
      festivals: festivals,
      isToday:
          normalized.year == now.year &&
          normalized.month == now.month &&
          normalized.day == now.day,
    );
  }

  List<CalendarDayInfo> getRange(DateTime start, DateTime end) {
    final startDate = DateTime(start.year, start.month, start.day);
    final endDate = DateTime(end.year, end.month, end.day);
    final days = endDate.difference(startDate).inDays + 1;
    if (days <= 0) return const [];
    return List.generate(
      days,
      (index) => getDayInfo(startDate.add(Duration(days: index))),
    );
  }

  LunarDateInfo getLunarDate(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    if (normalized.isBefore(_baseDate) || normalized.year > _maxYear) {
      throw RangeError('Lunar calendar supports $_minYear-$_maxYear only.');
    }

    var offset = normalized.difference(_baseDate).inDays;
    var year = _minYear;
    var yearDays = 0;
    while (year <= _maxYear && offset > 0) {
      yearDays = _lunarYearDays(year);
      offset -= yearDays;
      year++;
    }
    if (offset < 0) {
      offset += yearDays;
      year--;
    }

    final leapMonth = _leapMonth(year);
    var isLeapMonth = false;
    var month = 1;
    var monthDays = 0;

    while (month <= 12 && offset > 0) {
      if (leapMonth > 0 && month == leapMonth + 1 && !isLeapMonth) {
        month--;
        isLeapMonth = true;
        monthDays = _leapDays(year);
      } else {
        monthDays = _lunarMonthDays(year, month);
      }

      if (isLeapMonth && month == leapMonth + 1) {
        isLeapMonth = false;
      }

      offset -= monthDays;
      month++;
    }

    if (offset == 0 && leapMonth > 0 && month == leapMonth + 1) {
      if (isLeapMonth) {
        isLeapMonth = false;
      } else {
        isLeapMonth = true;
        month--;
      }
    }

    if (offset < 0) {
      offset += monthDays;
      month--;
    }

    return LunarDateInfo(
      year: year,
      month: month,
      day: offset + 1,
      isLeapMonth: isLeapMonth,
    );
  }

  List<CalendarFestival> _solarFestivalsFor(DateTime date) {
    final key =
        '${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final festival = _solarFestivals[key];
    if (festival == null) return const [];
    return [CalendarFestival(name: festival, type: CalendarFestivalType.solar)];
  }

  List<CalendarFestival> _lunarFestivalsFor(
    LunarDateInfo lunar,
    DateTime date,
  ) {
    if (lunar.isLeapMonth) return const [];

    final festivals = <CalendarFestival>[];
    final key =
        '${lunar.month.toString().padLeft(2, '0')}-${lunar.day.toString().padLeft(2, '0')}';
    final fixedFestival = _lunarFestivals[key];
    if (fixedFestival != null) {
      festivals.add(
        CalendarFestival(name: fixedFestival, type: CalendarFestivalType.lunar),
      );
    }

    if (lunar.month == 12 && lunar.day == _lunarMonthDays(lunar.year, 12)) {
      festivals.add(
        const CalendarFestival(name: '除夕', type: CalendarFestivalType.lunar),
      );
    }

    return festivals;
  }

  int _lunarYearDays(int year) {
    var sum = 348;
    final info = _yearInfo(year);
    for (var bit = 0x8000; bit > 0x8; bit >>= 1) {
      if ((info & bit) != 0) sum++;
    }
    return sum + _leapDays(year);
  }

  int _leapDays(int year) {
    if (_leapMonth(year) == 0) return 0;
    return (_yearInfo(year) & 0x10000) != 0 ? 30 : 29;
  }

  int _leapMonth(int year) => _yearInfo(year) & 0xf;

  int _lunarMonthDays(int year, int month) {
    return (_yearInfo(year) & (0x10000 >> month)) != 0 ? 30 : 29;
  }

  int _yearInfo(int year) {
    if (year < _minYear || year > _maxYear) {
      throw RangeError('Lunar calendar supports $_minYear-$_maxYear only.');
    }
    return _lunarInfo[year - _minYear];
  }
}
