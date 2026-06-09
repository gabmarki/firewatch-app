// pubspec.yaml
/*
name: firewatch
description: Monitoramento de queimadas via satélite

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0
  google_maps_flutter: ^2.5.0
  geolocator: ^10.1.0
  flutter_bloc: ^8.1.3
  sqflite: ^2.3.0
  flutter_local_notifications: ^16.3.0
  intl: ^0.18.1
  fl_chart: ^0.65.0

flutter:
  uses-material-design: true
*/

// ============================================================
// lib/main.dart
// ============================================================
import 'package:flutter/material.dart';
import 'presentation/pages/home_page.dart';

void main() {
  runApp(const FireWatchApp());
}

class FireWatchApp extends StatelessWidget {
  const FireWatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FireWatch',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE53935),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

// ============================================================
// lib/data/models/fire_focus_model.dart
// ============================================================
class FireFocus {
  final double latitude;
  final double longitude;
  final double brightness;
  final String acquisitionDate;
  final String acquisitionTime;
  final double confidence;
  final String satellite;

  FireFocus({
    required this.latitude,
    required this.longitude,
    required this.brightness,
    required this.acquisitionDate,
    required this.acquisitionTime,
    required this.confidence,
    required this.satellite,
  });

  factory FireFocus.fromCsv(String line) {
    final parts = line.split(',');
    return FireFocus(
      latitude: double.tryParse(parts[0]) ?? 0,
      longitude: double.tryParse(parts[1]) ?? 0,
      brightness: double.tryParse(parts[2]) ?? 0,
      acquisitionDate: parts.length > 5 ? parts[5] : '',
      acquisitionTime: parts.length > 6 ? parts[6] : '',
      confidence: double.tryParse(parts.length > 8 ? parts[8] : '0') ?? 0,
      satellite: parts.length > 7 ? parts[7] : 'MODIS',
    );
  }
}

// ============================================================
// lib/data/datasources/firms_api.dart
// ============================================================
import 'package:http/http.dart' as http;

class FirmsApiDatasource {
  // API key gratuita em: https://firms.modaps.eosdis.nasa.gov/api/
  static const String _apiKey = 'SUA_API_KEY_AQUI';
  static const String _baseUrl = 'https://firms.modaps.eosdis.nasa.gov/api';

  /// Busca focos de incêndio no Brasil nos últimos N dias
  Future<List<FireFocus>> getFireFocuses({int days = 1}) async {
    final url = Uri.parse(
      '$_baseUrl/country/csv/$_apiKey/VIIRS_SNPP_NRT/BRA/$days',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final lines = response.body.split('\n');
        // Pula o cabeçalho (primeira linha)
        return lines
            .skip(1)
            .where((line) => line.trim().isNotEmpty)
            .map((line) => FireFocus.fromCsv(line))
            .toList();
      }
    } catch (e) {
      // Em caso de erro, retorna dados mockados para demo
      return _getMockData();
    }
    return [];
  }

  List<FireFocus> _getMockData() {
    return [
      FireFocus(
        latitude: -15.77,
        longitude: -47.93,
        brightness: 320.0,
        acquisitionDate: '2026-06-09',
        acquisitionTime: '1345',
        confidence: 85,
        satellite: 'VIIRS',
      ),
      FireFocus(
        latitude: -12.97,
        longitude: -56.10,
        brightness: 345.0,
        acquisitionDate: '2026-06-09',
        acquisitionTime: '1400',
        confidence: 92,
        satellite: 'VIIRS',
      ),
      FireFocus(
        latitude: -10.45,
        longitude: -55.23,
        brightness: 298.0,
        acquisitionDate: '2026-06-09',
        acquisitionTime: '1420',
        confidence: 78,
        satellite: 'MODIS',
      ),
    ];
  }
}

// ============================================================
// lib/presentation/pages/home_page.dart
// ============================================================
import 'package:flutter/material.dart';
import 'map_page.dart';
import 'dashboard_page.dart';
import 'alerts_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    MapPage(),
    DashboardPage(),
    AlertsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Mapa',
          ),
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: 'Alertas',
          ),
        ],
      ),
    );
  }
}

// ============================================================
// lib/presentation/pages/map_page.dart
// ============================================================
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  GoogleMapController? _controller;
  final Set<Marker> _markers = {};
  int _selectedFilter = 0;
  bool _isLoading = true;

  static const CameraPosition _brazil = CameraPosition(
    target: LatLng(-14.2350, -51.9253),
    zoom: 4.5,
  );

  @override
  void initState() {
    super.initState();
    _loadFireFocuses();
  }

  Future<void> _loadFireFocuses() async {
    final api = FirmsApiDatasource();
    final days = [1, 2, 7][_selectedFilter];
    final focuses = await api.getFireFocuses(days: days);

    setState(() {
      _markers.clear();
      for (final focus in focuses) {
        _markers.add(
          Marker(
            markerId: MarkerId('${focus.latitude}_${focus.longitude}'),
            position: LatLng(focus.latitude, focus.longitude),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              focus.confidence > 80
                  ? BitmapDescriptor.hueRed
                  : BitmapDescriptor.hueOrange,
            ),
            infoWindow: InfoWindow(
              title: '🔥 Foco de Incêndio',
              snippet:
                  'Satélite: ${focus.satellite} | Confiança: ${focus.confidence.toInt()}%',
            ),
          ),
        );
      }
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.local_fire_department, color: Colors.red),
            SizedBox(width: 8),
            Text('FireWatch'),
          ],
        ),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                setState(() => _isLoading = true);
                _loadFireFocuses();
              },
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SegmentedButton<int>(
              selected: {_selectedFilter},
              onSelectionChanged: (selection) {
                setState(() {
                  _selectedFilter = selection.first;
                  _isLoading = true;
                });
                _loadFireFocuses();
              },
              segments: const [
                ButtonSegment(value: 0, label: Text('24h')),
                ButtonSegment(value: 1, label: Text('48h')),
                ButtonSegment(value: 2, label: Text('7 dias')),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _brazil,
            onMapCreated: (controller) => _controller = controller,
            markers: _markers,
            mapType: MapType.hybrid,
            myLocationButtonEnabled: true,
            myLocationEnabled: true,
          ),
          if (_markers.isNotEmpty)
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red.shade900.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 4),
                    Text(
                      '${_markers.length} focos ativos',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Centraliza no Brasil
          _controller?.animateCamera(
            CameraUpdate.newCameraPosition(_brazil),
          );
        },
        icon: const Icon(Icons.center_focus_strong),
        label: const Text('Brasil'),
      ),
    );
  }
}

// ============================================================
// lib/presentation/pages/dashboard_page.dart
// ============================================================
import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cards de resumo
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Focos Hoje',
                    value: '1.247',
                    icon: Icons.local_fire_department,
                    color: Colors.red,
                    trend: '+12%',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Esta Semana',
                    value: '8.934',
                    icon: Icons.calendar_today,
                    color: Colors.orange,
                    trend: '-5%',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _StatCard(
              title: 'Estado Mais Afetado',
              value: 'Mato Grosso',
              icon: Icons.location_on,
              color: Colors.deepOrange,
              trend: '345 focos',
            ),
            const SizedBox(height: 24),

            // Gráfico simplificado (barras com Container)
            Text(
              'Focos por dia – Últimos 7 dias',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            const _SimpleBarChart(),
            const SizedBox(height: 24),

            // Top municípios
            Text(
              'Top 5 Municípios com Mais Focos',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...[
              ('Colniza, MT', 89),
              ('Aripuanã, MT', 67),
              ('Lábrea, AM', 54),
              ('Porto Velho, RO', 43),
              ('Altamira, PA', 38),
            ].map(
              (item) => ListTile(
                leading: const Icon(Icons.local_fire_department,
                    color: Colors.orange),
                title: Text(item.$1),
                trailing: Chip(
                  label: Text('${item.$2} focos'),
                  backgroundColor: Colors.red.shade900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String trend;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.trend,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(title,
                      style: Theme.of(context).textTheme.bodySmall),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(value,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            Text(trend,
                style: TextStyle(color: color, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _SimpleBarChart extends StatelessWidget {
  const _SimpleBarChart();

  @override
  Widget build(BuildContext context) {
    final data = [820, 1100, 950, 1300, 1150, 980, 1247];
    final days = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
    final max = data.reduce((a, b) => a > b ? a : b).toDouble();

    return SizedBox(
      height: 160,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(7, (i) {
          final height = (data[i] / max) * 120;
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 32,
                height: height,
                decoration: BoxDecoration(
                  color: i == 6 ? Colors.red : Colors.orange.shade700,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(days[i], style: const TextStyle(fontSize: 11)),
            ],
          );
        }),
      ),
    );
  }
}

// ============================================================
// lib/presentation/pages/alerts_page.dart
// ============================================================
import 'package:flutter/material.dart';

class AlertsPage extends StatefulWidget {
  const AlertsPage({super.key});

  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> {
  bool _alertsEnabled = true;
  double _radius = 50.0;

  final List<Map<String, String>> _alerts = [
    {
      'title': 'Foco detectado a 23 km',
      'description': 'Satélite VIIRS detectou foco com 91% de confiança',
      'time': 'Há 15 minutos',
      'severity': 'high',
    },
    {
      'title': 'Foco detectado a 47 km',
      'description': 'Satélite MODIS detectou foco com 78% de confiança',
      'time': 'Há 2 horas',
      'severity': 'medium',
    },
    {
      'title': 'Alerta regional – MT',
      'description': 'Aumento de 34% nos focos em Mato Grosso nas últimas 24h',
      'time': 'Há 5 horas',
      'severity': 'low',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Alertas')),
      body: Column(
        children: [
          // Configurações de alerta
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Alertas por proximidade'),
                      Switch(
                        value: _alertsEnabled,
                        onChanged: (value) =>
                            setState(() => _alertsEnabled = value),
                      ),
                    ],
                  ),
                  if (_alertsEnabled) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Raio de alerta'),
                        Text('${_radius.toInt()} km',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Slider(
                      value: _radius,
                      min: 10,
                      max: 200,
                      divisions: 19,
                      onChanged: (value) => setState(() => _radius = value),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Lista de alertas
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _alerts.length,
              itemBuilder: (context, index) {
                final alert = _alerts[index];
                final color = alert['severity'] == 'high'
                    ? Colors.red
                    : alert['severity'] == 'medium'
                        ? Colors.orange
                        : Colors.yellow.shade700;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: color.withOpacity(0.2),
                      child: Icon(Icons.local_fire_department, color: color),
                    ),
                    title: Text(alert['title']!,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(alert['description']!),
                        Text(alert['time']!,
                            style: TextStyle(
                                color: Colors.grey.shade500, fontSize: 12)),
                      ],
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
