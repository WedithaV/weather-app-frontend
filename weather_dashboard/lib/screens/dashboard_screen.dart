// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import '../services/weather_service.dart';
import '../utils/coords_calculator.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _ctrl = TextEditingController();
  double? _lat, _lon;
  String? _info, _time, _url;
  bool _loading = false, _cached = false;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() {
      final coords = CoordsCalculator.fromIndex(_ctrl.text);
      setState(() {
        _lat = coords?['lat'];
        _lon = coords?['lon'];
      });
    });
    _loadCache();
  }

  Future<void> _loadCache() async {
    final data = await WeatherService.fetchWeather(0, 0); // dummy call to load cache
    if (data != null) {
      setState(() {
        _info = data['info'];
        _time = data['time'];
        _url = data['url'];
        _cached = true;
      });
    }
  }

  Future<void> _fetch() async {
    if (_lat == null) return;
    setState(() => _loading = true);
    final data = await WeatherService.fetchWeather(_lat!, _lon!);
    if (data != null) {
      setState(() {
        _info = data['info'];
        _time = DateFormat('HH:mm – d MMM').format(DateTime.now());
        _url = data['url'];
        _cached = false;
      });
    } else {
      setState(() => _cached = true);
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    // ... (same beautiful UI as before, just use _fetch(), _info, etc.)
  }
}