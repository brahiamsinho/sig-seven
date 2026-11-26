import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../logic/pointing.dart';
import '../models/poi.dart';
import '../services/api.dart';

/// Centro del casco viejo, hasta tener el primer fix de GPS.
const _defaultCenter = LatLng(-17.7839, -63.182);
const _fetchRadiusM = 150.0;
const _refetchAfterMovingM = 40.0;

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _api = Api();
  final _mapController = MapController();

  StreamSubscription<Position>? _posSub;
  StreamSubscription<CompassEvent>? _compassSub;

  Position? _pos;
  Position? _lastFetchPos;
  double? _heading; // 0-360°, ya suavizado
  List<Poi> _nearby = [];
  Poi? _pointed;
  String? _error;
  bool _centered = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      setState(() => _error = 'Activá el GPS del celular.');
      return;
    }
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      setState(() => _error = 'Se necesita permiso de ubicación.');
      return;
    }

    _posSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 2,
      ),
    ).listen(_onPosition, onError: (e) => setState(() => _error = '$e'));

    final compass = FlutterCompass.events;
    if (compass == null) {
      setState(() => _error = 'Este dispositivo no tiene brújula.');
    } else {
      _compassSub = compass.listen(_onCompass);
    }
  }

  void _onPosition(Position p) {
    setState(() {
      _pos = p;
      _recompute();
    });
    if (!_centered) {
      _centered = true;
      _mapController.move(LatLng(p.latitude, p.longitude), 18);
    }
    _maybeRefetch(p);
  }

  void _onCompass(CompassEvent e) {
    final raw = e.heading;
    if (raw == null) return;
    final h = (raw + 360) % 360; // el plugin entrega -180..180
    final prev = _heading;
    final next = prev == null ? h : smoothHeading(prev, h);
    // Evita reconstruir el mapa por variaciones de décimas de grado.
    if (prev != null && angleDiff(prev, next) < 1) return;
    setState(() {
      _heading = next;
      _recompute();
    });
  }

  /// El apuntado se calcula local: sin red, fluido.
  void _recompute() {
    final p = _pos;
    final h = _heading;
    _pointed = (p == null || h == null)
        ? null
        : findPointed(_nearby, p.latitude, p.longitude, h);
  }

  /// Trae los cercanos al inicio y cuando el usuario se movió lo suficiente.
  Future<void> _maybeRefetch(Position p) async {
    final last = _lastFetchPos;
    if (last != null &&
        Geolocator.distanceBetween(
                last.latitude, last.longitude, p.latitude, p.longitude) <
            _refetchAfterMovingM) {
      return;
    }
    _lastFetchPos = p;
    try {
      final pois =
          await _api.nearby(p.latitude, p.longitude, radius: _fetchRadiusM);
      if (!mounted) return;
      setState(() {
        _nearby = pois;
        _error = null;
        _recompute();
      });
    } catch (e) {
      _lastFetchPos = null; // reintentar en la próxima actualización
      if (mounted) setState(() => _error = 'No se pudo contactar la API: $e');
    }
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _compassSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildMap(),
          SafeArea(child: _buildStatusBar()),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(child: _buildCard()),
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    final p = _pos;
    return FlutterMap(
      mapController: _mapController,
      options: const MapOptions(
        initialCenter: _defaultCenter,
        initialZoom: 17,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          // OSM exige identificar la app; sin esto bloquea los tiles.
          userAgentPackageName: 'bo.edu.sig.apunta_descubre',
        ),
        MarkerLayer(
          markers: [
            for (final poi in _nearby)
              Marker(
                point: LatLng(poi.lat, poi.lon),
                width: 44,
                height: 44,
                child: Icon(
                  Icons.location_on,
                  size: poi.id == _pointed?.id ? 44 : 32,
                  color: poi.id == _pointed?.id ? Colors.orange : Colors.red,
                ),
              ),
            if (p != null)
              Marker(
                point: LatLng(p.latitude, p.longitude),
                width: 48,
                height: 48,
                // El ícono apunta al norte; lo rotamos según la brújula.
                child: Transform.rotate(
                  angle: (_heading ?? 0) * math.pi / 180,
                  child: const Icon(Icons.navigation,
                      size: 40, color: Colors.blue),
                ),
              ),
          ],
        ),
        const RichAttributionWidget(
          attributions: [TextSourceAttribution('© OpenStreetMap contributors')],
        ),
      ],
    );
  }

  Widget _buildStatusBar() {
    final p = _pos;
    final lines = <String>[
      if (p != null)
        'GPS ${p.latitude.toStringAsFixed(5)}, ${p.longitude.toStringAsFixed(5)}'
            ' (±${p.accuracy.round()} m)'
      else
        'Buscando GPS…',
      'Rumbo: ${_heading?.round() ?? '--'}°   Cercanos: ${_nearby.length}',
      if (_error != null) _error!,
    ];
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        lines.join('\n'),
        style: TextStyle(
          color: _error != null ? Colors.amber : Colors.white,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildCard() {
    final poi = _pointed;
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: poi == null
            ? const Text(
                'Apuntá el celular hacia un lugar patrimonial.',
                textAlign: TextAlign.center,
              )
            : _PoiCard(poi: poi),
      ),
    );
  }
}

class _PoiCard extends StatelessWidget {
  final Poi poi;
  const _PoiCard({required this.poi});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final meta = [
      poi.category,
      if (poi.year != null) '${poi.year}',
      if (poi.distanceM != null) '${poi.distanceM!.round()} m',
    ].join(' · ');
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (poi.imageUrl != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.network(
              poi.imageUrl!,
              height: 110,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
        Text(poi.name, style: theme.textTheme.titleLarge),
        Text(meta, style: theme.textTheme.bodySmall),
        if (poi.description.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(poi.description, maxLines: 4, overflow: TextOverflow.ellipsis),
        ],
        if (!poi.verified)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text('Datos sin verificar',
                style: TextStyle(color: Colors.orange, fontSize: 12)),
          ),
      ],
    );
  }
}
