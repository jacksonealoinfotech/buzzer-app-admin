import 'package:buzzer_app_admin/features/all_games/presenation/screen/all_games_screen.dart';
import 'package:buzzer_app_admin/features/dashboard/presenation/screen/dashboard_screen.dart';
import 'package:buzzer_app_admin/features/onboarding/login/presenation/screen/login_screen.dart';
import 'package:buzzer_app_admin/features/onboarding/splash/presenation/screen/splash_screen.dart';
import 'package:buzzer_app_admin/features/player_directory/presenation/screen/player_directory_screen.dart';
import 'package:buzzer_app_admin/features/reports_moderation/presenation/screen/reports_moderation_screen.dart';
import 'package:buzzer_app_admin/features/settings/presenation/screen/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:buzzer_app_admin/core/responsive/adaptive_scaffold.dart';
import 'package:buzzer_app_admin/core/security/security_check_screen.dart';

part 'app_routes.g.dart';

@TypedGoRoute<SplashRoute>(path: '/splash')
class SplashRoute extends GoRouteData with $SplashRoute {
  const SplashRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => SplashScreen(
    onFinished: () {
      const LoginRoute().go(context);
    },
  );
}

@TypedGoRoute<LoginRoute>(path: '/login')
class LoginRoute extends GoRouteData with $LoginRoute {
  const LoginRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => LoginScreen(
    onSuccess: () {
      const DashboardRoute().go(context);
    },
  );
}

@TypedGoRoute<SecurityCheckRoute>(path: '/security-check')
class SecurityCheckRoute extends GoRouteData with $SecurityCheckRoute {
  const SecurityCheckRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const SecurityCheckScreen();
}

@TypedStatefulShellRoute<AppShellRouteData>(
  branches: <TypedStatefulShellBranch<StatefulShellBranchData>>[
    TypedStatefulShellBranch<DashBoardBranchData>(
      routes: <TypedRoute<RouteData>>[TypedGoRoute<DashboardRoute>(path: '/')],
    ),
    TypedStatefulShellBranch<GamesBranchData>(
      routes: <TypedRoute<RouteData>>[
        TypedGoRoute<GamesRoute>(path: '/all-games'),
      ],
    ),
    TypedStatefulShellBranch<PlayersBranchData>(
      routes: <TypedRoute<RouteData>>[
        TypedGoRoute<PlayersRoute>(path: '/all-players'),
      ],
    ),
    TypedStatefulShellBranch<ReportsBranchData>(
      routes: <TypedRoute<RouteData>>[
        TypedGoRoute<ReportsRoute>(path: '/reports'),
      ],
    ),
    TypedStatefulShellBranch<SettingsBranchData>(
      routes: <TypedRoute<RouteData>>[
        TypedGoRoute<SettingsRoute>(path: '/settings'),
      ],
    ),
  ],
)
class AppShellRouteData extends StatefulShellRouteData {
  const AppShellRouteData();

  @override
  Widget builder(
    BuildContext context,
    GoRouterState state,
    StatefulNavigationShell navigationShell,
  ) {
    return AdaptiveNavigationScaffold(
      selectedIndex: navigationShell.currentIndex,
      onDestinationSelected: (index) {
        navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        );
      },
      destinations: const [
        AdaptiveNavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: 'Dashboard',
        ),
        AdaptiveNavigationDestination(
          icon: Icon(Icons.games_outlined),
          label: 'Games',
          selectedIcon: Icon(Icons.games),
        ),
        AdaptiveNavigationDestination(
          icon: Icon(Icons.group_outlined),
          selectedIcon: Icon(Icons.group),
          label: 'Players',
        ),
        AdaptiveNavigationDestination(
          icon: Icon(Icons.assignment_outlined),
          selectedIcon: Icon(Icons.assessment),
          label: 'Reports',
        ),
        AdaptiveNavigationDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings_rounded),
          label: 'Settings',
        ),
      ],
      body: navigationShell,
    );
  }
}

class DashBoardBranchData extends StatefulShellBranchData {
  const DashBoardBranchData();
}

class GamesBranchData extends StatefulShellBranchData {
  const GamesBranchData();
}

class PlayersBranchData extends StatefulShellBranchData {
  const PlayersBranchData();
}

class ReportsBranchData extends StatefulShellBranchData {
  const ReportsBranchData();
}

class SettingsBranchData extends StatefulShellBranchData {
  const SettingsBranchData();
}

class DashboardRoute extends GoRouteData with $DashboardRoute {
  const DashboardRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const DashboardScreen();
}

class GamesRoute extends GoRouteData with $GamesRoute {
  const GamesRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const AllGamesScreen();
}

class PlayersRoute extends GoRouteData with $PlayersRoute {
  const PlayersRoute();
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const PlayerDirectoryScreen();
}

class ReportsRoute extends GoRouteData with $ReportsRoute {
  const ReportsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const ReportsModerationScreen();
}

class SettingsRoute extends GoRouteData with $SettingsRoute {
  const SettingsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const SettingsScreen();
}
