import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/i18n/translations.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/section_card.dart';
import '../data/weather_repository.dart';

/// The website's weather card, with a real forecast (see WeatherRepository).
class WeatherCard extends ConsumerWidget {
  const WeatherCard({super.key});

  static (IconData, Color) _look(WeatherKind kind) => switch (kind) {
        WeatherKind.sunny => (LucideIcons.sun, AppColors.amber500),
        WeatherKind.partlyCloudy => (LucideIcons.cloudSun, AppColors.amber500),
        WeatherKind.cloudy => (LucideIcons.cloud, AppColors.gray500),
        WeatherKind.fog => (LucideIcons.cloudFog, AppColors.gray500),
        WeatherKind.drizzle => (LucideIcons.cloudDrizzle, AppColors.blue500),
        WeatherKind.rain => (LucideIcons.cloudRain, AppColors.blue500),
        WeatherKind.thunderstorm => (LucideIcons.cloudLightning, AppColors.purple500),
        WeatherKind.snow => (LucideIcons.snowflake, AppColors.sky500),
        WeatherKind.breezy => (LucideIcons.wind, AppColors.teal500),
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(trProvider);
    final weather = ref.watch(weatherProvider);
    final muted = AppColors.charcoal.withValues(alpha: 0.7);
    final title = SectionTitle(icon: LucideIcons.cloudRain, title: t.t('dashboard.weather'));
    final days = weather.value;
    if (days == null || days.isEmpty) {
      return SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            title,
            const SizedBox(height: 24),
            if (weather.hasError)
              Text(t.t('dashboard.app.weatherUnavailable'),
                  key: const Key('weatherUnavailable'),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: muted))
            else
              const Center(
                child: SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            const SizedBox(height: 24),
          ],
        ),
      );
    }
    final today = days.first;
    final (todayIcon, todayColor) = _look(today.kind);
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          title,
          const SizedBox(height: 16),
          Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(color: todayColor.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(todayIcon, size: 32, color: todayColor),
            ),
          ),
          const SizedBox(height: 12),
          Text(today.temp,
              textAlign: TextAlign.center,
              textDirection: TextDirection.ltr,
              style: const TextStyle(
                  fontSize: 36, fontWeight: FontWeight.w900, color: AppColors.charcoal, letterSpacing: -0.9)),
          const SizedBox(height: 4),
          Text(t.t(today.conditionKey).toUpperCase(),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: muted, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Divider(height: 1, color: AppColors.earth.withValues(alpha: 0.6)),
          const SizedBox(height: 20),
          for (final day in days.skip(1)) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(t.t(day.dayKey),
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: muted)),
                  ),
                  Icon(_look(day.kind).$1, size: 16, color: _look(day.kind).$2),
                  const SizedBox(width: 10),
                  Text(day.temp,
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.charcoal)),
                  Expanded(
                    child: Text(t.t(day.conditionKey),
                        textAlign: TextAlign.end,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: muted)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}
