import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:timezone/data/latest_10y.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'i18n/translations.dart';

/// Loads the timezone database once at startup (and in tests).
void initTimeZones() => tzdata.initializeTimeZones();

/// The profile's time zone choice that matches the phone's current UTC offset. A new account
/// starts with it, so times aren't shown in UTC (5 hours off in Pakistan) until it's changed.
String timezoneForOffset(Duration offset) => switch (offset.inMinutes) {
      300 => 'Asia/Karachi',
      180 => 'Asia/Riyadh',
      0 || 60 => 'Europe/London',
      -300 || -240 => 'America/New_York',
      _ => 'UTC',
    };

final deviceTimezoneProvider =
    Provider<String>((ref) => timezoneForOffset(DateTime.now().timeZoneOffset));

final _hasZone = RegExp(r'(Z|[+-]\d{2}:?\d{2})$');

/// The backend sends naive UTC datetimes; the website appends 'Z' before parsing. Same here.
DateTime parseServerTime(String value) =>
    DateTime.parse(_hasZone.hasMatch(value) ? value : '${value}Z').toUtc();

/// Port of utils/date.js formatDate: en-US `MM/DD/YYYY, HH:mm:ss` (24h) in [timezone],
/// falling back to UTC when the zone is unknown.
String formatDate(DateTime utc, String timezone) {
  DateTime local;
  try {
    final location = tz.getLocation(timezone);
    local = tz.TZDateTime.from(utc, location);
  } on Object {
    local = utc.toUtc();
  }
  return DateFormat('MM/dd/yyyy, HH:mm:ss', 'en_US').format(local);
}

/// Matches the website's `new Date(due_date).toLocaleDateString()` in en-US.
String formatDueDate(DateTime date) => DateFormat('M/d/yyyy', 'en_US').format(date.toLocal());

/// Port of the dashboard's getTimeAgo, translated.
String timeAgo(DateTime utc, Translations t, {DateTime? now}) {
  final seconds = (now ?? DateTime.now().toUtc()).difference(utc).inSeconds;
  if (seconds < 60) return t.t('common.timeAgo.justNow');
  final minutes = seconds ~/ 60;
  if (minutes < 60) return t.t(minutes == 1 ? 'common.timeAgo.minute' : 'common.timeAgo.minutes', args: {'count': minutes});
  final hours = minutes ~/ 60;
  if (hours < 24) return t.t(hours == 1 ? 'common.timeAgo.hour' : 'common.timeAgo.hours', args: {'count': hours});
  final days = hours ~/ 24;
  return t.t(days == 1 ? 'common.timeAgo.day' : 'common.timeAgo.days', args: {'count': days});
}
