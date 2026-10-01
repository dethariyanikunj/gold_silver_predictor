class NewsArticleModel {
  final String title;
  final String? source;
  final String? url;
  final DateTime? publishedAt;
  final String? category;
  final List<String> metalsAffected;
  final String? impactDirection; // BULLISH / BEARISH / NEUTRAL
  final int? impactStrength; // 1-10
  final String? impactHorizon; // SHORT / MEDIUM / LONG
  final String? summary;

  const NewsArticleModel({
    required this.title,
    this.source,
    this.url,
    this.publishedAt,
    this.category,
    this.metalsAffected = const [],
    this.impactDirection,
    this.impactStrength,
    this.impactHorizon,
    this.summary,
  });

  factory NewsArticleModel.fromMap(Map<String, dynamic> map) {
    return NewsArticleModel(
      title: map['title'] ?? '',
      source: map['source'],
      url: map['url'],
      publishedAt: map['publishedAt'] != null
          ? DateTime.tryParse(map['publishedAt'])
          : null,
      category: map['category'],
      metalsAffected: List<String>.from(map['metalsAffected'] ?? []),
      impactDirection: map['impactDirection'],
      impactStrength: map['impactStrength'],
      impactHorizon: map['impactHorizon'],
      summary: map['summary'],
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'source': source,
        'url': url,
        'publishedAt': publishedAt?.toIso8601String(),
        'category': category,
        'metalsAffected': metalsAffected,
        'impactDirection': impactDirection,
        'impactStrength': impactStrength,
        'impactHorizon': impactHorizon,
        'summary': summary,
      };

  /// Classify news by keyword matching
  static String classifyCategory(String title) {
    final t = title.toLowerCase();
    if (t.contains('fed') ||
        t.contains('fomc') ||
        t.contains('federal reserve') ||
        t.contains('rate cut') ||
        t.contains('rate hike') ||
        t.contains('powell')) {
      return 'Fed / Monetary Policy';
    }
    if (t.contains('inflation') ||
        t.contains('cpi') ||
        t.contains('pce') ||
        t.contains('deflation')) {
      return 'Inflation';
    }
    if (t.contains('dollar') || t.contains('dxy') || t.contains('usd')) {
      return 'Dollar / DXY';
    }
    if (t.contains('geopolit') ||
        t.contains('war') ||
        t.contains('iran') ||
        t.contains('russia') ||
        t.contains('china') ||
        t.contains('ukraine') ||
        t.contains('middle east') ||
        t.contains('israel') ||
        t.contains('conflict') ||
        t.contains('sanction')) {
      return 'Geopolitics';
    }
    if (t.contains('central bank') ||
        t.contains('pboc') ||
        t.contains('rbi') ||
        t.contains('reserve') ||
        t.contains('gold reserves')) {
      return 'Central Banks';
    }
    if (t.contains('oil') ||
        t.contains('crude') ||
        t.contains('opec') ||
        t.contains('energy')) {
      return 'Oil / Energy';
    }
    if (t.contains('india') ||
        t.contains('mcx') ||
        t.contains('rupee') ||
        t.contains('inr') ||
        t.contains('dhanteras') ||
        t.contains('diwali')) {
      return 'India';
    }
    if (t.contains('silver') && !t.contains('gold')) {
      return 'Silver';
    }
    if (t.contains('gold')) {
      return 'Gold';
    }
    if (t.contains('solar') ||
        t.contains('ev') ||
        t.contains('semiconductor') ||
        t.contains('industrial')) {
      return 'Industrial / Silver';
    }
    if (t.contains('mine') || t.contains('mining')) {
      return 'Mining';
    }
    if (t.contains('stock') ||
        t.contains('market') ||
        t.contains('s&p') ||
        t.contains('nifty')) {
      return 'Stock Markets';
    }
    return 'Markets';
  }

  static List<String> detectMetals(String title) {
    final t = title.toLowerCase();
    final metals = <String>[];
    if (t.contains('gold')) metals.add('Gold');
    if (t.contains('silver')) metals.add('Silver');
    return metals.isEmpty ? ['Gold', 'Silver'] : metals;
  }
}
