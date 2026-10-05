import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';
import '../../auth/auth_controller.dart';

enum WeatherKind { sunny, partlyCloudy, cloudy, fog, drizzle, rain, thunderstorm, snow, breezy }

class WeatherDay {
  const WeatherDay({
    required this.dayKey,
    required this.temp,
    required this.conditionKey,
    required this.kind,
  });

  /// Translation key: today, tomorrow, or a weekday.
  final String dayKey;
  final String temp;
  final String conditionKey;
  final WeatherKind kind;
}

/// Real forecast for the farmer's district: GET /dashboard/weather (Open-Meteo on the backend).
/// Today's row is the current temperature; the next two days show their highs.
class WeatherRepository {
  WeatherRepository(this._api);

  final ApiClient _api;

  static const _weekdays = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];

  Future<List<WeatherDay>> forecast() async {
    final data = await _api.get('/dashboard/weather') as Map<String, dynamic>;
    final current = data['current'] as Map<String, dynamic>;
    final days = (data['days'] as List).cast<Map<String, dynamic>>();
    return [
      _day('dashboard.weatherData.today', current['temp_c'], current['condition']),
      for (var i = 1; i < days.length && i < 3; i++)
        _day(
          i == 1
              ? 'dashboard.weatherData.tomorrow'
              : 'dashboard.app.weekdays.${_weekdays[DateTime.parse(days[i]['date'] as String).weekday - 1]}',
          days[i]['max_c'],
          days[i]['condition'],
        ),
    ];
  }

  static WeatherDay _day(String dayKey, Object? temp, Object? condition) {
    final kind = WeatherKind.values.firstWhere((k) => k.name == condition, orElse: () => WeatherKind.sunny);
    return WeatherDay(dayKey: dayKey, temp: '${(temp as num).round()}°C', conditionKey: conditionKey(kind), kind: kind);
  }

  /// The website's three labels where they exist; the rest are new app keys.
  static String conditionKey(WeatherKind kind) => switch (kind) {
        WeatherKind.sunny => 'dashboard.weatherData.sunny',
        WeatherKind.rain => 'dashboard.weatherData.rainExpected',
        WeatherKind.breezy => 'dashboard.weatherData.breezy',
        _ => 'dashboard.app.weather.${kind.name}',
      };
}

final weatherRepositoryProvider =
    Provider<WeatherRepository>((ref) => WeatherRepository(ref.watch(apiClientProvider)));

final weatherProvider = FutureProvider.autoDispose<List<WeatherDay>>((ref) {
  ref.watch(currentUserIdProvider);
  return ref.watch(weatherRepositoryProvider).forecast();
});
