import 'dart:math' as math;

import '../models/poi.dart';

/// Tolerancia angular: un punto está "apuntado" si el celular
/// está orientado a menos de este ángulo de su rumbo.
const double pointingToleranceDeg = 15;

/// Rumbo inicial (0-360°, 0 = norte, sentido horario) del punto 1 al 2.
/// Misma fórmula que el backend (poi/geo.py).
double bearingBetween(double lat1, double lon1, double lat2, double lon2) {
  final p1 = lat1 * math.pi / 180;
  final p2 = lat2 * math.pi / 180;
  final dl = (lon2 - lon1) * math.pi / 180;
  final y = math.sin(dl) * math.cos(p2);
  final x = math.cos(p1) * math.sin(p2) -
      math.sin(p1) * math.cos(p2) * math.cos(dl);
  return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
}

/// Diferencia angular mínima entre dos rumbos, en [0, 180].
/// Maneja el cruce 359° -> 0°.
double angleDiff(double a, double b) {
  final d = (a - b).abs() % 360;
  return d > 180 ? 360 - d : d;
}

/// Suavizado circular (media móvil exponencial) para estabilizar la brújula.
/// Interpola por el camino corto, así 359° -> 1° no pasa por 180°.
double smoothHeading(double previous, double current, {double alpha = 0.25}) {
  var delta = ((current - previous + 540) % 360) - 180;
  return (previous + alpha * delta + 360) % 360;
}

/// Devuelve el punto apuntado, o null si ninguno está en el cono.
/// Entre varios gana el de menor diferencia angular; el empate lo
/// resuelve la distancia.
Poi? findPointed(
  List<Poi> pois,
  double userLat,
  double userLon,
  double heading, {
  double toleranceDeg = pointingToleranceDeg,
}) {
  Poi? best;
  double bestDiff = double.infinity;
  double bestDist = double.infinity;
  for (final p in pois) {
    final b = bearingBetween(userLat, userLon, p.lat, p.lon);
    final diff = angleDiff(heading, b);
    if (diff > toleranceDeg) continue;
    final dist = p.distanceM ?? double.infinity;
    if (diff < bestDiff || (diff == bestDiff && dist < bestDist)) {
      best = p;
      bestDiff = diff;
      bestDist = dist;
    }
  }
  return best;
}
