// lib/utils/coords_calculator.dart
class CoordsCalculator {
  static Map<String, double>? fromIndex(String index) {
    if (index.length < 4) return null;
    try {
      final a = int.parse(index.substring(0, 2));
      final b = int.parse(index.substring(2, 4));
      return {
        'lat': 5 + a / 10.0,
        'lon': 79 + b / 10.0,
      };
    } catch (_) {
      return null;
    }
  }
}