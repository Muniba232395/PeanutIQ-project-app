import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import 'dashboard_providers.dart';
import 'widgets/crop_health_card.dart';
import 'widgets/crop_lifecycle_card.dart';
import 'widgets/daily_tip_card.dart';
import 'widgets/latest_advisory_card.dart';
import 'widgets/quick_actions_card.dart';
import 'widgets/recent_activity_card.dart';
import 'widgets/upcoming_actions_card.dart';
import 'widgets/weather_card.dart';
import 'widgets/welcome_banner.dart';
import '../../core/layout.dart';
import 'data/weather_repository.dart';

/// Port of the website's UserDashboard, in the same order.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    try {
      await Future.wait<Object?>([
        ref.refresh(activitiesProvider.future),
        ref.refresh(latestAlertProvider.future),
        ref.refresh(dailyTipProvider.future),
        ref.refresh(cropProfileProvider.future),
        ref.refresh(actionsProvider.future),
        ref.refresh(weatherProvider.future).catchError((Object _) => <WeatherDay>[]),
      ]);
    } on Object {
      // Failed sections show their own Retry.
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const sections = [
      WelcomeBanner(),
      DailyTipCard(),
      UpcomingActionsCard(),
      WeatherCard(),
      LatestAdvisoryCard(),
      CropHealthCard(),
      CropLifecycleCard(),
      QuickActionsCard(),
      RecentActivityCard(),
    ];
    return RefreshIndicator(
      color: AppColors.forest,
      onRefresh: () => _refresh(ref),
      child: ListView.separated(
        key: const Key('dashboardScroll'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, pageBottomPadding),
        itemCount: sections.length,
        separatorBuilder: (_, _) => const SizedBox(height: 16),
        itemBuilder: (_, i) => sections[i],
      ),
    );
  }
}
