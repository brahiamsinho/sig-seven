import 'package:apunta_descubre/logic/pointing.dart';
import 'package:apunta_descubre/models/poi.dart';
import 'package:flutter_test/flutter_test.dart';

Poi poi(int id, double lat, double lon, {double? dist}) => Poi(
    id: id, name: 'p$id', category: 'x', lat: lat, lon: lon, distanceM: dist);

void main() {
  group('bearingBetween', () {
    test('puntos cardinales', () {
      expect(bearingBetween(0, 0, 1, 0), closeTo(0, 0.001));
      expect(bearingBetween(0, 0, 0, 1), closeTo(90, 0.001));
      expect(bearingBetween(0, 0, -1, 0), closeTo(180, 0.001));
      expect(bearingBetween(0, 0, 0, -1), closeTo(270, 0.001));
    });
  });

  group('angleDiff', () {
    test('cruza el 0°/360°', () {
      expect(angleDiff(359, 1), closeTo(2, 0.001));
      expect(angleDiff(1, 359), closeTo(2, 0.001));
    });
    test('máximo 180', () {
      expect(angleDiff(0, 180), 180);
      expect(angleDiff(90, 270), 180);
    });
  });

  group('smoothHeading', () {
    test('toma el camino corto por el norte', () {
      final r = smoothHeading(350, 10, alpha: 0.5);
      expect(angleDiff(r, 0), lessThan(0.001));
    });
  });

  group('findPointed', () {
    // Usuario en (0,0). Norte: (0.001, 0). Este: (0, 0.001).
    final north = poi(1, 0.001, 0, dist: 111);
    final east = poi(2, 0, 0.001, dist: 111);

    test('apuntando al norte elige el del norte', () {
      expect(findPointed([north, east], 0, 0, 0)?.id, 1);
    });
    test('tolera heading de 350° hacia un punto al norte (cruce 360°)', () {
      expect(findPointed([north, east], 0, 0, 350)?.id, 1);
    });
    test('fuera de la tolerancia no devuelve nada', () {
      expect(findPointed([north, east], 0, 0, 45), isNull);
    });
    test('entre dos en el cono gana la menor diferencia angular', () {
      // a ~10° del norte y otro justo al norte
      final off = poi(3, 0.001, 0.000176, dist: 50); // ~10°
      expect(findPointed([off, north], 0, 0, 0)?.id, 1);
    });
    test('lista vacía devuelve null', () {
      expect(findPointed([], 0, 0, 0), isNull);
    });
  });

  group('Poi.fromFeature', () {
    test('lee lon,lat en el orden GeoJSON y los extras de nearby', () {
      final p = Poi.fromFeature({
        'id': 7,
        'geometry': {
          'type': 'Point',
          'coordinates': [-63.182, -17.784],
        },
        'properties': {
          'name': 'Plaza',
          'category': 'Plaza',
          'year': null,
          'description': '',
          'image': null,
          'verified': false,
          'distance_m': 12.5,
        },
      });
      expect(p.lon, -63.182);
      expect(p.lat, -17.784);
      expect(p.distanceM, 12.5);
      expect(p.year, isNull);
    });
  });
}
