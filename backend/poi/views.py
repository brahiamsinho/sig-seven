from django.contrib.gis.db.models.functions import Distance
from django.contrib.gis.geos import Point
from django.contrib.gis.measure import D
from rest_framework import viewsets
from rest_framework.decorators import action
from rest_framework.exceptions import ValidationError
from rest_framework.response import Response

from .models import Poi
from .serializers import PoiNearbySerializer, PoiSerializer

DEFAULT_RADIUS_M = 150
MAX_RADIUS_M = 1000


def _float_param(params, name, low, high):
    raw = params.get(name)
    if raw is None:
        raise ValidationError({name: 'Parámetro requerido.'})
    try:
        value = float(raw)
    except ValueError:
        raise ValidationError({name: 'Debe ser un número.'})
    if not low <= value <= high:
        raise ValidationError({name: f'Debe estar entre {low} y {high}.'})
    return value


class PoiViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Poi.objects.all()
    serializer_class = PoiSerializer

    @action(detail=False, methods=['get'])
    def nearby(self, request):
        params = request.query_params
        lat = _float_param(params, 'lat', -90, 90)
        lon = _float_param(params, 'lon', -180, 180)
        if 'radius' in params:
            radius = _float_param(params, 'radius', 1, MAX_RADIUS_M)
        else:
            radius = DEFAULT_RADIUS_M

        # Point(x=lon, y=lat): longitud primero
        user = Point(lon, lat, srid=4326)
        qs = (
            Poi.objects
            .annotate(distance=Distance('location', user))
            .filter(distance__lte=D(m=radius))
            .order_by('distance')
        )
        serializer = PoiNearbySerializer(
            qs, many=True,
            context={'request': request, 'lat': lat, 'lon': lon},
        )
        return Response(serializer.data)
