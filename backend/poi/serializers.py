from rest_framework import serializers
from rest_framework_gis.serializers import GeoFeatureModelSerializer

from .geo import bearing
from .models import Poi

FIELDS = (
    'id', 'name', 'category', 'year', 'description',
    'image', 'ai_story', 'verified',
)


class PoiSerializer(GeoFeatureModelSerializer):
    class Meta:
        model = Poi
        geo_field = 'location'
        fields = FIELDS


class PoiNearbySerializer(PoiSerializer):
    """Agrega distancia (m) y bearing (°) respecto al usuario.

    Espera en el contexto 'lat' y 'lon' del usuario, y que el queryset
    venga anotado con 'distance'.
    """
    distance_m = serializers.SerializerMethodField()
    bearing = serializers.SerializerMethodField()

    class Meta(PoiSerializer.Meta):
        fields = FIELDS + ('distance_m', 'bearing')

    def get_distance_m(self, obj):
        return round(obj.distance.m, 1)

    def get_bearing(self, obj):
        # location.x = longitud, location.y = latitud
        return round(bearing(
            self.context['lat'], self.context['lon'],
            obj.location.y, obj.location.x,
        ), 1)
