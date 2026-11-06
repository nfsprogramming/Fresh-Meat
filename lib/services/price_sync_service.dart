import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PriceSyncService {
  static final PriceSyncService instance = PriceSyncService._();
  PriceSyncService._();

  static const String prefEndpointKey = 'fresh_meat_pricing_api_url';
  static const String prefCacheKey = 'fresh_meat_cached_prices';
  static const String prefLastSyncKey = 'fresh_meat_last_price_sync';

  // Default live endpoint connected to Google Sheets
  static String? defaultEndpoint =
      'https://script.google.com/macros/s/AKfycbyso5g4C2erayybtWs1mM8BIk-KgcYCbYGG0yWgEMOcaFkutQppW7hyohrlEe2XOzVO/exec';

  /// Fetches live prices from Google Sheets via Google Apps Script Web App
  Future<Map<String, double>> fetchLivePrices() async {
    final prefs = await SharedPreferences.getInstance();
    final url = prefs.getString(prefEndpointKey) ?? defaultEndpoint;

    if (url == null || url.trim().isEmpty) {
      // No endpoint configured yet, return cached prices if available
      return getCachedPrices();
    }

    try {
      final uri = Uri.parse(url.trim());
      final response = await http.get(uri).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is! Map) {
          throw const FormatException('Expected JSON map response from pricing endpoint');
        }
        final data = Map<String, dynamic>.from(decoded);
        final Map<String, double> result = {};

        // 1. Category level rates
        if (data['categories'] is Map) {
          final cats = Map<String, dynamic>.from(data['categories'] as Map);
          cats.forEach((k, v) {
            final p = (v as num?)?.toDouble();
            if (p != null) result[k.toLowerCase()] = p;
          });
        }

        // 2. Specific cut rates (e.g. m1, c2)
        if (data['prices'] is Map) {
          final cutPrices = Map<String, dynamic>.from(data['prices'] as Map);
          cutPrices.forEach((k, v) {
            final p = (v as num?)?.toDouble();
            if (p != null) result[k.toLowerCase()] = p;
          });
        }

        // Cache locally for offline reliability
        await prefs.setString(prefCacheKey, jsonEncode(result));
        await prefs.setString(prefLastSyncKey, DateTime.now().toIso8601String());

        debugPrint('✅ Synced ${result.length} live prices from Google Sheets.');
        return result;
      }
    } catch (e) {
      debugPrint('PriceSyncService.fetchLivePrices note (using cached/default): $e');
    }

    return getCachedPrices();
  }

  /// Returns cached prices from local storage
  Future<Map<String, double>> getCachedPrices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(prefCacheKey);
      if (str != null && str.isNotEmpty) {
        final decoded = jsonDecode(str);
        if (decoded is Map) {
          final map = Map<String, dynamic>.from(decoded);
          final Map<String, double> result = {};
          map.forEach((k, v) {
            final p = (v as num?)?.toDouble();
            if (p != null) result[k] = p;
          });
          return result;
        }
      }
    } catch (e) {
      debugPrint('Error reading cached prices: $e');
    }
    return {};
  }

  /// Save prices into local cache
  Future<void> saveCachedPrices(Map<String, double> prices) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefCacheKey, jsonEncode(prices));
    await prefs.setString(prefLastSyncKey, DateTime.now().toIso8601String());
  }

  /// Save custom Google Apps Script Web App URL
  Future<void> setEndpointUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefEndpointKey, url.trim());
  }

  /// Get currently configured endpoint URL
  Future<String?> getEndpointUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(prefEndpointKey) ?? defaultEndpoint;
  }

  /// Returns the timestamp of the last successful price sync
  Future<DateTime?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(prefLastSyncKey);
    if (str != null) return DateTime.tryParse(str);
    return null;
  }
}
