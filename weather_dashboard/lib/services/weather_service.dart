// lib/services/weather_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class WeatherService {
  static Future<Map<String, String>?> fetchWeather(double lat, double lon) async {
    final url =
        'https://api.open-meteo.com/v1/forecast?latitude=${lat.toStringAsFixed(2)}'
        '&longitude=${lon.toStringAsFixed(2)}&current_weather=true';

    try {
      final resp = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 12));

      if (resp.statusCode == 200) {
        final data = json.decode(resp.body)['current_weather'];

        final result = {
          'info': '${data['temperature']}°C • ${data['windspeed']} km/h',
          'time': DateTime.now().toIso8601String(),
          'url': url,
          'code': data['weathercode'].toString(),
          'lat': lat.toString(),
          'lon': lon.toString(),
        };

        await _save(result);
        return result;
      }
    } catch (e) {
      return await _load();
    }

    return null;
  }

  static Future<void> _save(Map<String, String> data) async {
    final prefs = await SharedPreferences.getInstance();
    data.forEach((key, value) => prefs.setString(key, value));
  }

  static Future<Map<String, String>?> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final info = prefs.getString('info');

    if (info != null) {
      return {
        'info': info,
        'time': prefs.getString('time')!,
        'url': prefs.getString('url')!,
        'code': prefs.getString('code')!,
        'lat': prefs.getString('lat')!,
        'lon': prefs.getString('lon')!,
      };
    }
    return null;
  }

  static Future<Map<String, String>?> loadCacheOnly() async {
    return await _load();
  }
}
