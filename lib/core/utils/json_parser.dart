/// Helper parsing JSON. Open-Meteo bisa mengirim int atau double,
/// jadi semua angka selalu dilewatkan lewat `num` terlebih dahulu.
double asDouble(dynamic value, [double fallback = 0]) {
  if (value is num) return value.toDouble();
  return fallback;
}

double? asDoubleOrNull(dynamic value) {
  if (value is num) return value.toDouble();
  return null;
}

int asInt(dynamic value, [int fallback = 0]) {
  if (value is num) return value.toInt();
  return fallback;
}

int? asIntOrNull(dynamic value) {
  if (value is num) return value.toInt();
  return null;
}

String? asStringOrNull(dynamic value) {
  if (value is String && value.trim().isNotEmpty) return value;
  return null;
}

DateTime? asDateOrNull(dynamic value) {
  if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
  return null;
}
