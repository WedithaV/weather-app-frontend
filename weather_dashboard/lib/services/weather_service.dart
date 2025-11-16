// lib/services/weather_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class WeatherService {
  static Future<Map<String, String>?> fetchWeather(double lat, double lon) async {
    final url = 'https://api.open-meteo.com/v1/forecast?latitude=${lat.toStringAsFixed(2)}&longitude=${lon.toStringAsFixed(2)}&current_weather=true';
    
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body)['current_weather'];
        final result = {
          'info': '${data['temperature']}°C • ${data['windspeed']} km/h',
          'time': DateTime.now().toIso8601String(),
          'url': url,
        };
        await _saveCache(result);
        return result;
      }
    } catch (e) {
      return await _loadCache();
    }
    return null;
  }

  static Future<void> _saveCache(Map<String, String> data) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('info', data['info']!);
    prefs.setString('time', data['time']!);
    prefs.setString('url', data['url']!);
  }

  static Future<Map<String, String>?> _loadCache() async {
    final prefs = await SharedPreferences.getInstance();
    final info = prefs.getString('info');
    if (info != null) {
      return {
        'info': info,
        'time': prefs.getString('time')!,
        'url': prefs.getString('url')!,
      };
    }
    return null;
  }
}