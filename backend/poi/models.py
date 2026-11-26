from django.contrib.gis.db import models


class Poi(models.Model):
    name = models.CharField(max_length=200)
    category = models.CharField(max_length=100)
    year = models.PositiveIntegerField(null=True, blank=True)
    description = models.TextField(blank=True)
    image = models.ImageField(upload_to='poi/', null=True, blank=True)
    # SRID 4326 = WGS84, el sistema del GPS. Orden: (lon, lat).
    location = models.PointField(srid=4326)
    # Caché del texto generado por Gemini, para no gastar cuota.
    ai_story = models.TextField(blank=True)
    # False hasta que el equipo confirme coordenadas y datos en campo.
    verified = models.BooleanField(default=False)

    class Meta:
        ordering = ['name']

    def __str__(self):
        return self.name
