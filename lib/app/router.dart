import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/groups/presentation/group_list_screen.dart';
import '../features/groups/presentation/create_group_screen.dart';
import '../features/groups/presentation/group_detail_screen.dart';
import '../features/events/presentation/create_event_screen.dart';
import '../features/events/presentation/event_detail_screen.dart';
import '../features/events/presentation/create_next_kitty_screen.dart';
import '../features/events/presentation/host_schedule_screen.dart';
import '../features/events/presentation/theme_library_screen.dart';
import '../features/games/presentation/game_library_screen.dart';
import '../features/games/presentation/live_game_host_screen.dart';
import '../features/games/presentation/player_game_screen.dart';
import '../features/games/presentation/winner_declaration_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import 'main_navigation_shell.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/login',
  redirect: (context, state) {
    final isLoggedIn = AuthRepository().isUserAuthenticated;
    final isLoggingIn = state.matchedLocation == '/login';

    if (!isLoggedIn && !isLoggingIn) {
      return '/login';
    }
    if (isLoggedIn && isLoggingIn) {
      return '/home';
    }
    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => MainNavigationShell(child: child),
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/kitties',
          builder: (context, state) => const GroupListScreen(),
        ),
        GoRoute(
          path: '/games',
          builder: (context, state) => const GameLibraryScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/create-group',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const CreateGroupScreen(),
    ),
    GoRoute(
      path: '/group/:groupId',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final id = state.pathParameters['groupId'] ?? '';
        return GroupDetailScreen(groupId: id);
      },
    ),
    GoRoute(
      path: '/join/group/:groupId',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final id = state.pathParameters['groupId'] ?? '';
        return GroupDetailScreen(groupId: id);
      },
    ),
    GoRoute(
      path: '/create-event',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const CreateEventScreen(),
    ),
    GoRoute(
      path: '/event/:eventId',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final id = state.pathParameters['eventId'] ?? '';
        return EventDetailScreen(eventId: id);
      },
    ),
    GoRoute(
      path: '/create-next-kitty/:groupId',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final id = state.pathParameters['groupId'] ?? '';
        return CreateNextKittyScreen(groupId: id);
      },
    ),
    GoRoute(
      path: '/host-schedule/:groupId',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final id = state.pathParameters['groupId'] ?? '';
        return HostScheduleScreen(groupId: id);
      },
    ),
    GoRoute(
      path: '/live-game/:gameId',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final id = state.pathParameters['gameId'] ?? '';
        return LiveGameHostScreen(gameId: id);
      },
    ),
    GoRoute(
      path: '/player-game/:gameId',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final id = state.pathParameters['gameId'] ?? '';
        return PlayerGameScreen(gameId: id);
      },
    ),
    GoRoute(
      path: '/winners/:eventId',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final id = state.pathParameters['eventId'] ?? '';
        return WinnerDeclarationScreen(eventId: id);
      },
    ),
    GoRoute(
      path: '/themes',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ThemeLibraryScreen(),
    ),
  ],
);
