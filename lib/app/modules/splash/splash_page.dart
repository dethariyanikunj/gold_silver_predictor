import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        duration: const Duration(milliseconds: 1200), vsync: this);
    _fade = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.6)));
    _scale = Tween<double>(begin: 0.8, end: 1).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _ctrl.forward();

    Future.delayed(const Duration(milliseconds: 2200), () {
      Get.offAllNamed(AppRoutes.dashboard);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, child) => FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(colors: [
                        AppColors.goldLight,
                        AppColors.goldPrimary,
                        AppColors.goldDark,
                      ]),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.goldPrimary.withValues(alpha: 0.4),
                          blurRadius: 30,
                          spreadRadius: 8,
                        )
                      ],
                    ),
                    child: const Icon(Icons.auto_graph_rounded,
                        color: Colors.white, size: 52),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Gold & Silver AI',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Price Prediction · Powered by Gemini',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
