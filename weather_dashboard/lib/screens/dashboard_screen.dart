// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../services/weather_service.dart';
import '../utils/coords_calculator.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _indexCtrl = TextEditingController();

  double? _lat, _lon;
  String? _temp, _wind, _code, _time, _url;

  bool _isLoading = false;
  bool _isCached = false;

  // Only one error variable — shown inside TextField
  String? _indexError;

  @override
  void initState() {
    super.initState();
    _loadCache();
  }

  @override
  void dispose() {
    _indexCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCache() async {
    final data = await WeatherService.loadCacheOnly();
    if (data != null) {
      _updateFromData(data, isCached: true);
    }
  }

  bool _isValidIndex(String index) {
    final regex = RegExp(r'^[0-9]{6}[A-Za-z]$');
    return regex.hasMatch(index);
  }

  // MAIN FETCH METHOD — Updated as per your request
  Future<void> _fetch() async {
    final index = _indexCtrl.text.trim().toUpperCase();

    // Always clear error first
    setState(() => _indexError = null);

    if (!_isValidIndex(index)) {
      setState(() {
        _indexError = "Invalid format! Use 6 digits + 1 letter (e.g. 224287X)";
      });
      return;
    }

    final coords = CoordsCalculator.fromIndex(index.substring(0, 4));
    if (coords == null) {
      setState(() {
        _indexError = "Invalid coordinates from index";
      });
      return;
    }

    final lat = coords['lat']!;
    final lon = coords['lon']!;

    setState(() => _isLoading = true);

    final data = await WeatherService.fetchWeather(lat, lon);

    if (data != null) {
      // Online → success
      _updateFromData(data, isCached: false);
      setState(() => _indexError = null); // Clear any error
    } else {
      // OFFLINE
      final cached = await WeatherService.loadCacheOnly();
      if (cached != null) {
        _updateFromData(cached, isCached: true);
        setState(() {
          _indexError = "You are offline — showing cached data";
        });
      } else {
        setState(() {
          _indexError = "You are offline and no previous data";
        });
      }
    }

    setState(() => _isLoading = false);
  }

  void _updateFromData(Map<String, String> data, {required bool isCached}) {
    setState(() {
      _temp = data['info']!.split('•')[0].trim();
      _wind = data['info']!.split('•')[1].trim();
      _code = data['code']!;
      _time = _formatTime(data['time']!);
      _url = data['url'];
      _isCached = isCached;
      _lat = double.tryParse(data['lat']!);
      _lon = double.tryParse(data['lon']!);
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
    if (code == 0) return const Icon(Icons.wb_sunny, size: 42, color: Colors.orange);
    if (code <= 3) return const Icon(Icons.cloud, size: 42, color: Colors.grey);
    if (code <= 48) return const Icon(Icons.grain, size: 42, color: Colors.blueGrey);
    if (code <= 67) return const Icon(Icons.umbrella, size: 42, color: Colors.blue);
    if (code <= 99) return const Icon(Icons.flash_on, size: 42, color: Colors.deepPurple);
    return const Icon(Icons.help_outline, size: 42);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Personalized Weather Dashboard"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // INPUT FIELD
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _indexCtrl,
                  inputFormatters: [UpperCaseTextFormatter()],
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: "Enter Student Index",
                    hintText: "e.g. 224287X",
                    border: const OutlineInputBorder(),
                    errorText: _indexError, // ← Offline message appears HERE in red
                    errorMaxLines: 2,
                    prefixIcon: const Icon(Icons.school),
                    suffixIcon: _indexCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _indexCtrl.clear();
                              setState(() {
                                _indexError = null;
                                _lat = _lon = _temp = _wind = _code = _time = _url = null;
                                _isCached = false;
                              });
                            },
                          )
                        : null,
                  ),
                  onSubmitted: (_) => _fetch(),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // FETCH BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _fetch,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Fetch Weather", style: TextStyle(fontSize: 16)),
              ),
            ),

            const SizedBox(height: 20),

            // LOCATION
            if (_lat != null && _lon != null)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.location_on, color: Colors.teal),
                  title: Text("Location: ${_lat!.toStringAsFixed(2)}, ${_lon!.toStringAsFixed(2)}"),
                ),
              ),

            const SizedBox(height: 20),

            // WEATHER CARD
            if (_temp != null)
              Card(
                elevation: 5,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _weatherIcon(int.tryParse(_code ?? "0") ?? 0),
                          const SizedBox(width: 12),
                          const Text("Current Weather", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          const Spacer(),
                          if (_isCached)
                            const Chip(
                              label: Text("CACHED", style: TextStyle(fontSize: 10, color: Colors.white)),
                              backgroundColor: Colors.redAccent,
                            ),
                        ],
                      ),
                      const Divider(height: 32),
                      _infoRow(Icons.thermostat, "Temperature", _temp!, Colors.redAccent),
                      const SizedBox(height: 12),
                      _infoRow(Icons.air, "Wind Speed", _wind!, Colors.blue),
                      const SizedBox(height: 12),
                      _infoRow(Icons.tag, "Weather Code", _code!, Colors.purple),
                      const SizedBox(height: 20),
                      Text("Last updated: $_time", style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // API URL (optional debug)
            if (_url != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      const Icon(Icons.link, size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_url!, style: const TextStyle(fontSize: 10))),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 32, color: color),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }
}

// Auto-uppercase input
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}