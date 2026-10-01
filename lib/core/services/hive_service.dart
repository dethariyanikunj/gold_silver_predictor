import 'package:hive_flutter/hive_flutter.dart';

class HiveService {
  static const String _priceBox = 'price_cache';
  static const String _predictionBox = 'prediction_cache';
  static const String _newsBox = 'news_cache';
  static const String _macroBox = 'macro_cache';
  static const String _accuracyBox = 'accuracy_log';
  static const String _cftcBox = 'cftc_cache';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Future.wait([
      Hive.openBox<String>(_priceBox),
      Hive.openBox<String>(_predictionBox),
      Hive.openBox<String>(_newsBox),
      Hive.openBox<String>(_macroBox),
      Hive.openBox<Map>(_accuracyBox),
      Hive.openBox<String>(_cftcBox),
    ]);
  }

  // ── Generic cache helpers ────────────────────────────────────────────────────

  static Future<void> setWithTtl(
    String boxName,
    String key,
    String value,
    int ttlMinutes,
  ) async {
    final box = Hive.box<String>(boxName);
    final expiry = DateTime.now().add(Duration(minutes: ttlMinutes));
    await box.put(key, value);
    await box.put('${key}_expiry', expiry.toIso8601String());
  }

  static String? getIfFresh(String boxName, String key) {
    final box = Hive.box<String>(boxName);
    final expiryStr = box.get('${key}_expiry');
    if (expiryStr == null) return null;
    final expiry = DateTime.parse(expiryStr);
    if (DateTime.now().isAfter(expiry)) return null;
    return box.get(key);
  }

  static Future<void> delete(String boxName, String key) async {
    final box = Hive.box<String>(boxName);
    await box.delete(key);
    await box.delete('${key}_expiry');
  }

  // ── Accuracy log (append-only) ───────────────────────────────────────────────

  static Box<Map> get accuracyBox => Hive.box<Map>(_accuracyBox);

  static Future<void> appendAccuracyEntry(Map<String, dynamic> entry) async {
    await accuracyBox.add(entry);
  }

  static List<Map> getAllAccuracyEntries() {
    return accuracyBox.values.toList();
  }

  static Future<void> updateAccuracyEntry(
      int key, Map<String, dynamic> updated) async {
    await accuracyBox.put(key, updated);
  }

  // ── Box name constants (public) ─────────────────────────────────────────────

  static String get priceBox => _priceBox;
  static String get predictionBox => _predictionBox;
  static String get newsBox => _newsBox;
  static String get macroBox => _macroBox;
  static String get cftcBox => _cftcBox;
}
