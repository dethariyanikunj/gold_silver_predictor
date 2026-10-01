import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:xml/xml.dart';
import '../../../core/services/dio_service.dart';
import '../../../core/services/hive_service.dart';
import '../../../core/config/app_config.dart';
import '../models/news_article_model.dart';

class RssService {
  final Dio _dio = DioService.generic;

  static const List<Map<String, String>> _feeds = [
    {
      'url': 'https://feeds.reuters.com/reuters/businessNews',
      'source': 'Reuters',
    },
    {
      'url': 'https://economictimes.indiatimes.com/markets/rss.cms',
      'source': 'Economic Times',
    },
    {
      'url': 'https://economictimes.indiatimes.com/commodities-rss.cms',
      'source': 'ET Commodities',
    },
    {
      'url': 'https://www.moneycontrol.com/rss/commodity.xml',
      'source': 'Moneycontrol',
    },
    {
      'url': 'https://www.kitco.com/rss/kitco-news-gold-silver.rss',
      'source': 'Kitco',
    },
    {
      'url': 'https://www.mining.com/feed/',
      'source': 'Mining.com',
    },
  ];

  static const List<String> _relevantKeywords = [
    'gold', 'silver', 'precious metal', 'bullion', 'commodity',
    'fed', 'federal reserve', 'interest rate', 'inflation', 'cpi',
    'dollar', 'usd', 'rupee', 'inr', 'mcx',
    'geopolit', 'war', 'iran', 'russia', 'ukraine', 'china',
    'oil', 'crude', 'opec',
    'central bank', 'pboc', 'rbi', 'gold reserve',
    'etf', 'comex', 'futures',
    'dhanteras', 'diwali', 'akshaya', 'festival',
    'solar', 'semiconductor', 'industrial demand',
    'mine', 'mining',
  ];

  Future<List<NewsArticleModel>> fetchAllNews() async {
    const cacheKey = 'all_news';
    final cached = HiveService.getIfFresh(HiveService.newsBox, cacheKey);
    if (cached != null) {
      final list = jsonDecode(cached) as List;
      return list
          .map((e) => NewsArticleModel.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    }

    final allArticles = <NewsArticleModel>[];
    await Future.wait(
      _feeds.map((feed) => _fetchFeed(feed['url']!, feed['source']!, allArticles)),
    );

    // Sort by date (newest first) and take top 40
    allArticles.sort((a, b) {
      if (a.publishedAt == null) return 1;
      if (b.publishedAt == null) return -1;
      return b.publishedAt!.compareTo(a.publishedAt!);
    });

    final filtered = allArticles.take(40).toList();

    await HiveService.setWithTtl(
      HiveService.newsBox,
      cacheKey,
      jsonEncode(filtered.map((a) => a.toMap()).toList()),
      AppConfig.newsTtlMin,
    );
    return filtered;
  }

  Future<void> _fetchFeed(
    String url,
    String source,
    List<NewsArticleModel> output,
  ) async {
    try {
      final response = await _dio.get(
        url,
        options: Options(
          responseType: ResponseType.plain,
          headers: {'Accept': 'application/rss+xml,application/xml,text/xml'},
        ),
      );
      final document = XmlDocument.parse(response.data.toString());
      final items = document.findAllElements('item');

      for (final item in items.take(10)) {
        final title = item.findElements('title').firstOrNull?.innerText ?? '';
        final link = item.findElements('link').firstOrNull?.innerText ??
            item.findElements('guid').firstOrNull?.innerText ?? '';
        final pubDate = item.findElements('pubDate').firstOrNull?.innerText;
        final description =
            item.findElements('description').firstOrNull?.innerText ?? '';

        final fullText = '$title $description'.toLowerCase();
        final isRelevant = _relevantKeywords.any((kw) => fullText.contains(kw));
        if (!isRelevant) continue;

        DateTime? parsedDate;
        if (pubDate != null) {
          try {
            parsedDate = _parseRssDate(pubDate);
          } catch (_) {}
        }

        final category = NewsArticleModel.classifyCategory(title);
        final metals = NewsArticleModel.detectMetals(title);

        output.add(NewsArticleModel(
          title: _cleanText(title),
          source: source,
          url: link.trim(),
          publishedAt: parsedDate,
          category: category,
          metalsAffected: metals,
        ));
      }
    } catch (_) {
      // Silently skip failed feeds
    }
  }

  static String _cleanText(String text) {
    return text
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .trim();
  }

  static DateTime? _parseRssDate(String dateStr) {
    // RFC 2822 format: "Mon, 22 Aug 2026 12:30:00 GMT"
    try {
      final cleaned = dateStr
          .replaceAll(' GMT', 'Z')
          .replaceAll(' +0000', 'Z')
          .replaceAll(' UT', 'Z');
      return DateTime.parse(cleaned);
    } catch (_) {
      // Try common patterns
      final months = {
        'Jan': '01', 'Feb': '02', 'Mar': '03', 'Apr': '04',
        'May': '05', 'Jun': '06', 'Jul': '07', 'Aug': '08',
        'Sep': '09', 'Oct': '10', 'Nov': '11', 'Dec': '12',
      };
      final pattern = RegExp(
          r'(\d{1,2})\s+(\w{3})\s+(\d{4})\s+(\d{2}:\d{2}:\d{2})');
      final match = pattern.firstMatch(dateStr);
      if (match != null) {
        final day = match.group(1)!.padLeft(2, '0');
        final month = months[match.group(2)] ?? '01';
        final year = match.group(3)!;
        final time = match.group(4)!;
        return DateTime.parse('$year-$month-${day}T${time}Z');
      }
      return null;
    }
  }
}
