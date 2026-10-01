import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/prediction_controller.dart';
import '../../theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../data/models/news_article_model.dart';

class NewsPage extends StatefulWidget {
  const NewsPage({super.key});

  @override
  State<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  String _selectedCategory = 'All';

  static const categories = [
    'All',
    'Fed / Monetary Policy',
    'Inflation',
    'Geopolitics',
    'India',
    'Gold',
    'Silver',
    'Central Banks',
    'Oil / Energy',
    'Stock Markets',
    'Mining',
    'Industrial / Silver',
  ];

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<PredictionController>();

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Market News')),
      body: Obx(() {
        final allNews = ctrl.news;
        final filtered = _selectedCategory == 'All'
            ? allNews
            : allNews.where((a) => a.category == _selectedCategory).toList();

        return Column(
          children: [
            // Category chips
            SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: categories.length,
                itemBuilder: (_, i) {
                  final cat = categories[i];
                  final isSelected = cat == _selectedCategory;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.goldPrimary
                            : AppColors.bgCardLight,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.goldPrimary
                              : AppColors.border,
                        ),
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          color: isSelected ? Colors.black : AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Article list
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.newspaper_rounded,
                              color: AppColors.textMuted, size: 40),
                          const SizedBox(height: 12),
                          Text(
                            ctrl.state.value.name == 'idle'
                                ? 'Tap "Predict Now" on dashboard to fetch news'
                                : 'No articles in this category',
                            style: const TextStyle(
                                color: AppColors.textMuted, fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) => _NewsCard(article: filtered[i]),
                    ),
            ),
          ],
        );
      }),
    );
  }
}

class _NewsCard extends StatelessWidget {
  final NewsArticleModel article;
  const _NewsCard({required this.article});

  @override
  Widget build(BuildContext context) {
    final color = _categoryColor(article.category);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 60,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        article.category ?? 'Markets',
                        style: TextStyle(
                            color: color, fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (article.metalsAffected.isNotEmpty)
                      ...article.metalsAffected.map((m) => Container(
                            margin: const EdgeInsets.only(right: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: m == 'Gold'
                                  ? AppColors.goldGlow
                                  : AppColors.silverGlow,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              m,
                              style: TextStyle(
                                color: m == 'Gold'
                                    ? AppColors.goldPrimary
                                    : AppColors.silverPrimary,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  article.title,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1.4),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      article.source ?? '',
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 11),
                    ),
                    const Text(' · ',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                    Text(
                      CurrencyFormatter.timeAgo(article.publishedAt),
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _categoryColor(String? cat) {
    if (cat == null) return AppColors.textMuted;
    if (cat.contains('Fed') || cat.contains('Inflation')) return AppColors.uncertainty;
    if (cat.contains('Geopolit')) return AppColors.bearish;
    if (cat.contains('India')) return const Color(0xFF6366F1);
    if (cat.contains('Central')) return AppColors.bullish;
    if (cat.contains('Gold')) return AppColors.goldPrimary;
    if (cat.contains('Silver') || cat.contains('Industrial')) return AppColors.silverPrimary;
    if (cat.contains('Oil')) return const Color(0xFFEF8C3B);
    if (cat.contains('Mining')) return const Color(0xFFA78BFA);
    return AppColors.textMuted;
  }
}
