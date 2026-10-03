import 'package:go_router/go_router.dart';

import '../screens/home_screen.dart';
import '../widgets/splash_screen.dart';
import '../screens/news_detail_screen.dart';
import '../models/news_item.dart';

class AppRoutes {
  static const splash = '/';
  static const home = '/home';
  static const newsDetail = '/news_detail';
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
    GoRoute(
      path: AppRoutes.newsDetail,
      builder: (context, state) {
        final item = state.extra as NewsItemModel;
        return NewsDetailScreen(newsItem: item);
      },
    ),
  ],
);
