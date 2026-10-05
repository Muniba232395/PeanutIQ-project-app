import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/signup_screen.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/history/history_screen.dart';
import '../features/knowledge/article_screen.dart';
import '../features/knowledge/knowledge_screen.dart';
import '../features/maintenance/maintenance_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/scan/scan_kind.dart';
import '../features/scan/scan_screen.dart';
import '../features/shell/app_shell.dart';
import '../features/shell/more_screen.dart';
import 'maintenance_mode.dart';
import '../features/advisories/advisories_screen.dart';
import '../features/auth/auth_controller.dart';

abstract final class Routes {
  static const splash = '/splash';
  static const login = '/login';
  static const signup = '/signup';
  static const maintenance = '/maintenance';
  static const home = '/home';
  static const seed = '/seed';
  static const disease = '/disease';
  static const knowledge = '/kb';
  static const more = '/more';
  static const advisories = '/more/advisories';
  static const history = '/more/history';
  static const profile = '/more/profile';
}

const _signedOutRoutes = {Routes.login, Routes.signup};
const _authOnlyRoutes = {Routes.splash, ..._signedOutRoutes};

/// Decides where the user should be. Returns null to stay on [location].
String? appRedirect({
  required AuthState auth,
  required bool maintenance,
  required String location,
}) {
  if (maintenance) return location == Routes.maintenance ? null : Routes.maintenance;
  if (location == Routes.maintenance) {
    return auth.status == AuthStatus.signedIn ? Routes.home : Routes.login;
  }
  switch (auth.status) {
    case AuthStatus.unknown:
      return location == Routes.splash ? null : Routes.splash;
    case AuthStatus.signedOut:
      if (_signedOutRoutes.contains(location)) return null;
      // A phone that has never had an account starts on Create Account.
      return auth.firstLaunch ? Routes.signup : Routes.login;
    case AuthStatus.signedIn:
      return _authOnlyRoutes.contains(location) ? Routes.home : null;
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  // Re-run redirects whenever auth or maintenance state changes.
  final refresh = ValueNotifier<int>(0);
  ref.listen(authControllerProvider, (_, _) => refresh.value++);
  ref.listen(maintenanceModeProvider, (_, _) => refresh.value++);

  final router = GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: refresh,
    redirect: (context, state) => appRedirect(
      auth: ref.read(authControllerProvider),
      maintenance: ref.read(maintenanceModeProvider),
      location: state.matchedLocation,
    ),
    routes: [
      GoRoute(path: Routes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(
        path: Routes.login,
        builder: (_, state) => LoginScreen(
          // A new key per arrival from Create Account, so the email and toast are fresh.
          key: ValueKey(state.uri.toString()),
          initialEmail: state.uri.queryParameters['email'] ?? '',
          accountCreated: state.uri.queryParameters['created'] == '1',
        ),
      ),
      GoRoute(path: Routes.signup, builder: (_, _) => const SignupScreen()),
      GoRoute(path: Routes.maintenance, builder: (_, _) => const MaintenanceScreen()),
      StatefulShellRoute.indexedStack(
        builder: (_, state, shell) => AppShell(navigationShell: shell, location: state.uri.toString()),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: Routes.home, builder: (_, _) => const DashboardScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: Routes.seed, builder: (_, _) => const ScanScreen(kind: ScanKind.seed)),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: Routes.disease, builder: (_, _) => const ScanScreen(kind: ScanKind.disease)),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.knowledge,
              builder: (_, _) => const KnowledgeScreen(),
              routes: [
                GoRoute(path: ':id', builder: (_, state) => ArticleScreen(id: state.pathParameters['id']!)),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.more,
              builder: (_, _) => const MoreScreen(),
              routes: [
                GoRoute(path: 'advisories', builder: (_, _) => const AdvisoriesScreen()),
                GoRoute(path: 'history', builder: (_, _) => const HistoryScreen()),
                GoRoute(path: 'profile', builder: (_, _) => const ProfileScreen()),
              ],
            ),
          ]),
        ],
      ),
    ],
  );
  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});
