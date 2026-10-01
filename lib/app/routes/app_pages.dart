import 'package:get/get.dart';
import '../modules/splash/splash_page.dart';
import '../modules/dashboard/dashboard_page.dart';
import '../modules/prediction_detail/prediction_detail_page.dart';
import '../modules/news/news_page.dart';
import '../modules/accuracy_log/accuracy_log_page.dart';
import '../bindings/app_binding.dart';
import 'app_routes.dart';

class AppPages {
  static final routes = [
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashPage(),
      binding: AppBinding(),
    ),
    GetPage(
      name: AppRoutes.dashboard,
      page: () => const DashboardPage(),
    ),
    GetPage(
      name: AppRoutes.predictionDetail,
      page: () => const PredictionDetailPage(),
    ),
    GetPage(
      name: AppRoutes.news,
      page: () => const NewsPage(),
    ),
    GetPage(
      name: AppRoutes.accuracyLog,
      page: () => const AccuracyLogPage(),
    ),
  ];
}
