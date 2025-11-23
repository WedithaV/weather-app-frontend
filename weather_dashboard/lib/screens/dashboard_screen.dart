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
  bool _isLoading = false, _isCached = false;

  @override
  void initState() {
    super.initState();
    _indexCtrl.addListener(_updateCoords);
    _loadCache();
  }

  @override
  void dispose() {
    _indexCtrl.dispose();
    super.dispose();
  }

  // Validate only when Fetch is pressed
  bool _isValidIndex(String index) {
    final regex = RegExp(r'^[0-9]{6}[A-Za-z]$');
    return regex.hasMatch(index);
  }

  void _updateCoords() {
    final coords = CoordsCalculator.fromIndex(_indexCtrl.text);
    setState(() {
      _lat = coords?['lat'];
      _lon = coords?['lon'];
    });
  }

  Future<void> _loadCache() async {
    final data = await WeatherService.loadCacheOnly();
    if (data != null) {
      _updateFromData(data, isCached: true);
    }
  }

  Future<void> _fetch() async {
    final index = _indexCtrl.text.trim();

    if (!_isValidIndex(index)) {
      _showSnack("Invalid index! Format must be: 6 digits + 1 letter (e.g. 224287X)");
      return;
    }

    if (_lat == null || _lon == null) {
      _showSnack('Enter a valid index');
      return;
    }

    setState(() => _isLoading = true);

    final data = await WeatherService.fetchWeather(_lat!, _lon!);

    if (data != null) {
      _updateFromData(data, isCached: false);
    } else {
      setState(() => _isCached = true);
      _showSnack('No internet – showing cached data');
    }

    setState(() => _isLoading = false);
  }

  void _updateFromData(Map<String, String> data, {required bool isCached}) {
    final temp = data['info']!.split('•')[0].trim();
    final wind = data['info']!.split('•')[1].trim();
    final code = data['code']!;
    final time = _formatTime(data['time']!);

    setState(() {
      _temp = temp;
      _wind = wind;
      _code = code;
      _time = time;
      _url = data['url'];
      _isCached = isCached;
    });
  }

  String _formatTime(String iso) {
    try {
      return DateFormat('HH:mm – d MMM yyyy').format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Widget _weatherIcon(int code) {
    if (code == 0) return const Icon(Icons.wb_sunny, size: 36, color: Colors.orange);
    if (code <= 3) return const Icon(Icons.cloud, size: 36, color: Colors.grey);
    if (code <= 48) return const Icon(Icons.grain, size: 36, color: Colors.blueGrey);
    if (code <= 67) return const Icon(Icons.umbrella, size: 36, color: Colors.blue);
    return const Icon(Icons.flash_on, size: 36, color: Colors.deepPurple);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canFetch = _lat != null && _lon != null && !_isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather Dashboard'),
        centerTitle: true,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // INPUT FIELD (no live errors now)
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _indexCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: 'Student Index',
                    hintText: 'e.g. 224287X',
                    border: const OutlineInputBorder(),
                    suffixIcon: _indexCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => setState(() => _indexCtrl.clear()),
                          )
                        : null,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            if (_lat != null && _lon != null)
              Card(
                elevation: 2,
                child: ListTile(
                  leading: const Icon(Icons.location_on, color: Colors.teal),
                  title: Text(
                    'Lat: ${_lat!.toStringAsFixed(2)}  •  Lon: ${_lon!.toStringAsFixed(2)}',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: canFetch ? _fetch : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 4,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Fetch Weather', style: TextStyle(fontSize: 16)),
            ),

            const SizedBox(height: 24),

            if (_temp != null && _wind != null && _code != null)
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _weatherIcon(int.tryParse(_code!) ?? 0),
                          const SizedBox(width: 12),
                          const Text('Current Weather',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const Spacer(),
                          if (_isCached)
                            Chip(
                              label: const Text('Cached', style: TextStyle(fontSize: 10)),
                              backgroundColor: Colors.redAccent,
                            ),
                        ],
                      ),
                      const Divider(height: 24),

                      _buildInfoRow(Icons.thermostat, 'Temperature', _temp!, Colors.redAccent),
                      const SizedBox(height: 12),
                      _buildInfoRow(Icons.air, 'Wind Speed', _wind!, Colors.blue),
                      const SizedBox(height: 12),
                      _buildInfoRow(Icons.tag, 'Weather Code', _code!, Colors.purple),

                      const SizedBox(height: 16),

                      Text(
                        'Last updated: $_time',
                        style: theme.textTheme.bodySmall!.copyWith(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            if (_url != null)
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: _url!));
                  _showSnack('Request URL copied!');
                },
                child: Chip(
                  avatar: const Icon(Icons.link, size: 16),
                  label: Text(
                    _url!,
                    style: const TextStyle(fontSize: 10),
                    overflow: TextOverflow.ellipsis,
                  ),
                  backgroundColor: Colors.grey.shade200,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 28, color: color),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }
}
