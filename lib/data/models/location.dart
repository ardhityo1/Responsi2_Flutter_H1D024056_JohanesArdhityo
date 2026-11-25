import '../../core/utils/json_parser.dart';

/// Lokasi hasil pencarian atau lokasi tersimpan.
class Location {
  final int? id;
  final String name;
  final double latitude;
  final double longitude;
  final String? country;
  final String? admin1;
  final String? timezone;

  const Location({
    this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.country,
    this.admin1,
    this.timezone,
  });

  factory Location.fromGeocodingJson(Map<String, dynamic> json) {
    return Location(
      id: asIntOrNull(json['id']),
      name: asStringOrNull(json['name']) ?? 'Tanpa nama',
      latitude: asDouble(json['latitude']),
      longitude: asDouble(json['longitude']),
      country: asStringOrNull(json['country']),
      admin1: asStringOrNull(json['admin1']),
      timezone: asStringOrNull(json['timezone']),
    );
  }

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      id: asIntOrNull(json['id']),
      name: asStringOrNull(json['name']) ?? 'Tanpa nama',
      latitude: asDouble(json['latitude']),
      longitude: asDouble(json['longitude']),
      country: asStringOrNull(json['country']),
      admin1: asStringOrNull(json['admin1']),
      timezone: asStringOrNull(json['timezone']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'country': country,
      'admin1': admin1,
      'timezone': timezone,
    };
  }

  /// Contoh: "Purwokerto, Jawa Tengah, Indonesia".
  String get displayName {
    final parts = [name, admin1, country]
        .whereType<String>()
        .where((part) => part.trim().isNotEmpty)
        .toList();
    return parts.join(', ');
  }

  /// Dua lokasi dianggap sama jika koordinatnya sama.
  @override
  bool operator ==(Object other) {
    return other is Location &&
        other.latitude == latitude &&
        other.longitude == longitude;
  }

  @override
  int get hashCode => Object.hash(latitude, longitude);

  @override
  String toString() => 'Location($name, $latitude, $longitude)';
}
