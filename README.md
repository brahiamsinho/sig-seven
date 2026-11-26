# Apunta y Descubre

App móvil que muestra la información de un lugar patrimonial de Santa Cruz de la Sierra al apuntar el celular hacia él. Proyecto de Sistemas de Información Geográfica.

Stack: Flutter + flutter_map · Django/DRF/GeoDjango · PostgreSQL/PostGIS · Docker.

## Backend

```bash
cp .env.example .env        # y completar los valores
docker compose up -d --build
docker compose exec web python manage.py migrate
docker compose exec web python manage.py load_seed
docker compose exec web python manage.py createsuperuser
```

- Admin: http://localhost:8000/admin/
- API: http://localhost:8000/api/poi/

| Endpoint | Descripción |
|---|---|
| `GET /api/poi/` | Lista en GeoJSON |
| `GET /api/poi/{id}/` | Ficha completa |
| `GET /api/poi/nearby/?lat=&lon=&radius=` | Cercanos con `distance_m` y `bearing` |

Tests: `docker compose exec web python manage.py test poi`

## Mobile

Requiere un celular Android físico (GPS y brújula no funcionan en emulador) en la misma red que la PC.

```bash
cd mobile
flutter run --dart-define=API_URL=http://<IP-de-tu-PC>:8000
```

Tests: `flutter test`

## Datos

Las coordenadas de `load_seed` son **provisorias**. Verificar en campo y marcar `verified` en el admin. Los datos históricos se cargan solo tras contrastarlos con una fuente.

## Convenciones

- PostGIS usa orden **longitud, latitud**.
- La `GEMINI_API_KEY` vive solo en el backend (`.env`), nunca en el repo ni en Flutter.
