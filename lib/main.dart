import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app/bindings/app_binding.dart';
import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';
import 'app/theme/app_theme.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/services/hive_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService.init();
  try {
    await dotenv.load(fileName: ".env");
  } catch (_) {
    // Graceful fallback if .env is missing
  }
  runApp(const GoldSilverApp());
}

class GoldSilverApp extends StatelessWidget {
  const GoldSilverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Gold & Silver AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialBinding: AppBinding(),
      initialRoute: AppRoutes.splash,
      getPages: AppPages.routes,
      defaultTransition: Transition.fade,
    );
  }
}
