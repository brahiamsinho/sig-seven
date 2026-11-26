from django.contrib.gis import admin

from .models import Poi


@admin.register(Poi)
class PoiAdmin(admin.GISModelAdmin):
    list_display = ('name', 'category', 'year', 'verified')
    list_filter = ('category', 'verified')
    search_fields = ('name',)
    # Mapa del admin centrado en el casco viejo de Santa Cruz
    gis_widget_kwargs = {
        'attrs': {
            'default_lon': -63.182,
            'default_lat': -17.7839,
            'default_zoom': 16,
        }
    }
