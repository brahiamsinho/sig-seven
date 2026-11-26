from django.contrib.gis.geos import Point
from django.test import TestCase

from .geo import bearing
from .models import Poi


class BearingTests(TestCase):
    def test_cardinal_directions(self):
        self.assertAlmostEqual(bearing(0, 0, 1, 0), 0, places=3)      # norte
        self.assertAlmostEqual(bearing(0, 0, 0, 1), 90, places=3)     # este
        self.assertAlmostEqual(bearing(0, 0, -1, 0), 180, places=3)   # sur
        self.assertAlmostEqual(bearing(0, 0, 0, -1), 270, places=3)   # oeste


class NearbyApiTests(TestCase):
    def setUp(self):
        # ~55 m al norte del usuario, y otro a ~2 km
        Poi.objects.create(name='Cerca', category='x',
                           location=Point(-63.182, -17.7835, srid=4326))
        Poi.objects.create(name='Lejos', category='x',
                           location=Point(-63.182, -17.7655, srid=4326))

    def test_nearby_returns_only_points_in_radius_with_distance_and_bearing(self):
        r = self.client.get('/api/poi/nearby/',
                            {'lat': -17.784, 'lon': -63.182, 'radius': 150})
        self.assertEqual(r.status_code, 200)
        features = r.json()['features']
        self.assertEqual([f['properties']['name'] for f in features], ['Cerca'])
        props = features[0]['properties']
        self.assertAlmostEqual(props['distance_m'], 55, delta=3)
        self.assertAlmostEqual(props['bearing'], 0, delta=1)

    def test_missing_params_returns_400(self):
        r = self.client.get('/api/poi/nearby/', {'lon': -63.182})
        self.assertEqual(r.status_code, 400)
        self.assertIn('lat', r.json())

    def test_list_and_detail_are_geojson(self):
        r = self.client.get('/api/poi/')
        self.assertEqual(r.json()['type'], 'FeatureCollection')
        pk = Poi.objects.get(name='Cerca').pk
        d = self.client.get(f'/api/poi/{pk}/').json()
        self.assertEqual(d['geometry']['type'], 'Point')
