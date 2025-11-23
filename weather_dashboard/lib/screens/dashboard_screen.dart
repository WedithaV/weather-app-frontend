// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/weather_service.dart';
import '../utils/coords_calculator.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TextEditingController _indexCtrl = TextEditingController();
  double? _lat, _lon;
  String? _temp, _wind, _code, _time;
  bool _isLoading = false;
  String? _indexError;
  String? _requestUrl;
  bool _isCached = false;

  @override
  void initState() {
    super.initState();
    _loadCache();
  }

  Future<void> _loadCache() async {
    final cached = await WeatherService.loadCacheOnly();
    if (cached != null) {
      _updateFromData(cached, isCached: true);
    }
  }

  bool _isValidIndex(String index) {
    final regex = RegExp(r'^[0-9]{6}[A-Za-z]$');
    return regex.hasMatch(index);
  }

  Future<void> _fetch() async {
    final index = _indexCtrl.text.trim();
    setState(() {
      _indexError = null;
      _requestUrl = null;
      _isCached = false;
    });

    if (!_isValidIndex(index)) {
      setState(() => _indexError = "Invalid index (e.g., 224287X)");
      return;
    }

    final coords = CoordsCalculator.fromIndex(index);
    if (coords == null) {
      setState(() => _indexError = "Invalid index");
      return;
    }

    final lat = coords['lat']!;
    final lon = coords['lon']!;

    // Build and display the request URL
    final url = 'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current_weather=true';
    
    setState(() {
      _isLoading = true;
      _lat = lat;
      _lon = lon;
      _requestUrl = url;
    });

    final data = await WeatherService.fetchWeather(lat, lon);
    setState(() => _isLoading = false);

    if (data == null) {
      setState(() {
        _indexError = "Unable to fetch weather data. Please check your internet connection and try again.";
        _lat = null;
        _lon = null;
        _requestUrl = null;
      });
      return;
    }

    final bool isOffline = data['source'] == 'cache';
    setState(() => _isCached = isOffline);
    
    if (isOffline) {
      setState(() {
        _indexError = "You are offline";
      });
    } else {
      setState(() => _indexError = null);
    }

    _updateFromData(data, isCached: isOffline);
  }

  void _updateFromData(Map<String, String> data, {required bool isCached}) {
    setState(() {
      _temp = data['info']!.split('•')[0].trim();
      _wind = data['info']!.split('•')[1].trim();
      _code = data['code'];
      _time = _formatTime(data['time']!);
      _lat = double.tryParse(data['lat']!) ?? _lat;
      _lon = double.tryParse(data['lon']!) ?? _lon;
      _isCached = isCached;
      
      // Reconstruct URL if we have coordinates
      if (_lat != null && _lon != null) {
        _requestUrl = 'https://api.open-meteo.com/v1/forecast?latitude=$_lat&longitude=$_lon&current_weather=true';
      }
    });
  }

  String _formatTime(String iso) {
    try {
      return DateFormat('HH:mm – d MMM yyyy').format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }

  Widget _weatherIcon(int code) {
    if (code == 0) return const Icon(Icons.wb_sunny, size: 64, color: Colors.orange);
    if (code <= 3) return const Icon(Icons.cloud, size: 64, color: Colors.grey);
    if (code <= 48) return const Icon(Icons.grain, size: 64, color: Colors.blueGrey);
    return const Icon(Icons.cloudy_snowing, size: 64, color: Colors.blueGrey);
  }

  Color _getWeatherColor(int code) {
    if (code == 0) return Colors.orange.shade50;
    if (code <= 3) return Colors.grey.shade50;
    if (code <= 48) return Colors.blueGrey.shade50;
    return Colors.blueGrey.shade50;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          "Weather Dashboard",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Enter Student Index",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _indexCtrl,
                      decoration: InputDecoration(
                        labelText: "Student Index",
                        hintText: "e.g., 224287X",
                        prefixIcon: const Icon(Icons.badge),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        errorText: _indexError,
                        errorMaxLines: 2,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _fetch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cloud_download, size: 20),
                          SizedBox(width: 8),
                          Text(
                            "Fetch Weather",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 12),
            if (_lat != null && _lon != null)
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.location_on, color: Colors.teal.shade700, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Location",
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Lat: ${_lat!.toStringAsFixed(2)} • Lon: ${_lon!.toStringAsFixed(2)}",
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (_lat != null && _lon != null) const SizedBox(height: 12),
            if (_temp != null)
              Expanded(
                child: Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          _getWeatherColor(int.tryParse(_code ?? "0") ?? 0),
                          Colors.white,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_isCached)
                            Align(
                              alignment: Alignment.topRight,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade100,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.orange.shade300, width: 1),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.offline_bolt, size: 12, color: Colors.orange.shade800),
                                    const SizedBox(width: 4),
                                    Text(
                                      "CACHED",
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.orange.shade800,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          _weatherIcon(int.tryParse(_code ?? "0") ?? 0),
                          const SizedBox(height: 12),
                          const Text(
                            "Current Weather",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.shade200,
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                _buildWeatherRow(
                                  Icons.thermostat,
                                  "Temperature",
                                  _temp!,
                                  Colors.red.shade400,
                                ),
                                const Divider(height: 20),
                                _buildWeatherRow(
                                  Icons.air,
                                  "Wind Speed",
                                  _wind!,
                                  Colors.blue.shade400,
                                ),
                                const Divider(height: 20),
                                _buildWeatherRow(
                                  Icons.tag,
                                  "Weather Code",
                                  _code!,
                                  Colors.purple.shade400,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 14,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    "Updated: $_time",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            if (_requestUrl != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.link, size: 12, color: Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _requestUrl!,
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey.shade700,
                          fontFamily: 'monospace',
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}