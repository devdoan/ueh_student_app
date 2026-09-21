import 'package:go_router/go_router.dart';

import '../widgets/home_screen.dart';
import '../widgets/splash_screen.dart';

class AppRoutes {
  static const splash = '/';
  static const home = '/home';
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const HomeScreen(),
    ),
  ],
);
