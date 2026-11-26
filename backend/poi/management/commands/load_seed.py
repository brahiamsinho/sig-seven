from django.contrib.gis.geos import Point
from django.core.management.base import BaseCommand

from poi.models import Poi

# COORDENADAS PROVISORIAS (aprox.). Verificar en campo antes de marcar verified=True.
# No se cargan años ni descripciones históricas hasta contrastarlos con una fuente.
SEED = [
    ('Plaza 24 de Septiembre', 'Plaza', -63.18204, -17.78395),
    ('Catedral Metropolitana', 'Religioso', -63.18198, -17.78373),
    ('Casa de la Cultura Raúl Otero Reiche', 'Cultural', -63.18142, -17.78360),
    ('Parque El Arenal', 'Parque', -63.18537, -17.78158),
]


class Command(BaseCommand):
    help = 'Carga los puntos semilla (idempotente).'

    def handle(self, *args, **options):
        for name, category, lon, lat in SEED:
            # Point(x=lon, y=lat): longitud primero
            _, created = Poi.objects.update_or_create(
                name=name,
                defaults={
                    'category': category,
                    'location': Point(lon, lat, srid=4326),
                },
            )
            self.stdout.write(f"{'creado' if created else 'actualizado'}: {name}")
