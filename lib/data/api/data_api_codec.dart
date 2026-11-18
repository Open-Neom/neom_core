import 'dart:convert';
import 'package:geolocator/geolocator.dart';

/// Explicit JSON conversion: never stringify arbitrary domain objects.
dynamic dataApiValue(dynamic value) {
  if (value == null || value is String || value is num || value is bool) {
    return value;
  }
  if (value is Enum) return value.name;
  if (value is Position) return value.toJson();
  if (value is List) return value.map(dataApiValue).toList();
  if (value is Map) {
    return value.map((k, v) => MapEntry(k.toString(), dataApiValue(v)));
  }
  throw const FormatException('Unsupported data API argument');
}

T dataApiScalar<T>(dynamic value) {
  if (value is! T) {
    throw const FormatException('Unexpected data API value type');
  }
  return value;
}

Map<String, dynamic> profileApiMap(Map value) {
  final data = Map<String, dynamic>.from(value);
  // The existing model stores Position as a JSON string. Accept native JSON
  // from HTTP without changing Firestore/Hive serialization for other apps.
  if (data['position'] is Map) data['position'] = jsonEncode(data['position']);
  return data;
}
