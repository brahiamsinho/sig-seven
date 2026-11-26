class Poi {
  final int id;
  final String name;
  final String category;
  final int? year;
  final String description;
  final String? imageUrl;
  final bool verified;
  final double lat;
  final double lon;
  final double? distanceM;

  const Poi({
    required this.id,
    required this.name,
    required this.category,
    this.year,
    this.description = '',
    this.imageUrl,
    this.verified = false,
    required this.lat,
    required this.lon,
    this.distanceM,
  });

  /// Construye desde un Feature GeoJSON.
  /// GeoJSON usa [lon, lat]: longitud primero.
  factory Poi.fromFeature(Map<String, dynamic> f) {
    final props = f['properties'] as Map<String, dynamic>;
    final coords = (f['geometry']['coordinates'] as List).cast<num>();
    return Poi(
      id: f['id'] as int,
      name: props['name'] as String,
      category: props['category'] as String,
      year: props['year'] as int?,
      description: (props['description'] as String?) ?? '',
      imageUrl: props['image'] as String?,
      verified: (props['verified'] as bool?) ?? false,
      lon: coords[0].toDouble(),
      lat: coords[1].toDouble(),
      distanceM: (props['distance_m'] as num?)?.toDouble(),
    );
  }
}
