import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/poi.dart';

/// URL base del backend. En un celular físico NO sirve "localhost":
/// hay que pasar la IP de la PC en la red Wi-Fi:
///   flutter run --dart-define=API_URL=http://192.168.1.50:8000
const String apiUrl =
    String.fromEnvironment('API_URL', defaultValue: 'http://10.0.2.2:8000');

class Api {
  final http.Client _client;
  Api([http.Client? client]) : _client = client ?? http.Client();

  Future<List<Poi>> all() => _fetch(Uri.parse('$apiUrl/api/poi/'));

  Future<List<Poi>> nearby(double lat, double lon, {double radius = 150}) =>
      _fetch(Uri.parse('$apiUrl/api/poi/nearby/').replace(queryParameters: {
        'lat': '$lat',
        'lon': '$lon',
        'radius': '$radius',
      }));

  Future<List<Poi>> _fetch(Uri uri) async {
    final r = await _client.get(uri).timeout(const Duration(seconds: 10));
    if (r.statusCode != 200) {
      throw Exception('API ${r.statusCode}: ${r.body}');
    }
    final data = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
    return (data['features'] as List)
        .map((f) => Poi.fromFeature(f as Map<String, dynamic>))
        .toList();
  }
}
