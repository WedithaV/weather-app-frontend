// lib/services/weather_service.dart
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class WeatherService {
  static Future<Map<String, String>?> fetchWeather(double lat, double lon) async {
    final url =
        'https://api.open-meteo.com/v1/forecast?latitude=${lat.toStringAsFixed(2)}'
        '&longitude=${lon.toStringAsFixed(2)}&current_weather=true';

    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = json.decode(response.body)['current_weather'];

        final result = {
          'info': '${data['temperature']}°C • ${data['windspeed']} km/h',
          'time': DateTime.now().toIso8601String(),
          'url': url,
          'code': data['weathercode'].toString(),
          'lat': lat.toStringAsFixed(4),
          'lon': lon.toStringAsFixed(4),
          'source': 'live', // ← Marks fresh data
        };

        await _save(result);
        return result;
      }
    } on TimeoutException catch (_) {
      // Timeout = likely offline
    } on SocketException catch (_) {
      // No internet (airplane mode, no Wi-Fi, etc.)
    } on HttpException catch (_) {
      // HTTP-related error
    } catch (e) {
      // Any other network error
    }

    // If we get here → offline or error → return cache with source='cache'
    final cached = await _load();
    if (cached != null) {
      cached['source'] = 'cache';
    }
    return cached;
  }

  static Future<void> _save(Map<String, String> data) async {
    final prefs = await SharedPreferences.getInstance();
    for (var entry in data.entries) {
      prefs.setString(entry.key, entry.value);
    }
  }

  static Future<Map<String, String>?> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final info = prefs.getString('info');
    if (info == null) return null;

    return {
      'info': info,
      'time': prefs.getString('time') ?? DateTime.now().toIso8601String(),
      'url': prefs.getString('url') ?? '',
      'code': prefs.getString('code') ?? '0',
      'lat': prefs.getString('lat') ?? '0.0',
      'lon': prefs.getString('lon') ?? '0.0',
    };
  }

  static Future<Map<String, String>?> loadCacheOnly() async => await _load();
}