import 'package:dio/dio.dart';

class ReverseGeocodeResult {
  ReverseGeocodeResult({
    required this.displayName,
    this.country,
    this.city,
    this.neighbourhood,
  });

  final String displayName;
  final String? country;
  final String? city;
  final String? neighbourhood;
}

/// OpenStreetMap Nominatim (same approach as ikigai-dashboard shop form).
abstract final class ReverseGeocode {
  static final _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 12),
      headers: const {'Accept-Language': 'fr,en', 'User-Agent': 'IkigaiProviderApp/1.0'},
    ),
  );

  static Future<ReverseGeocodeResult?> reverse(double lat, double lon) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {'lat': lat, 'lon': lon, 'format': 'json'},
      );
      final data = res.data;
      if (data == null) return null;
      final addr = data['address'];
      Map<String, dynamic>? am;
      if (addr is Map) am = Map<String, dynamic>.from(addr);
      final display = '${data['display_name'] ?? ''}';
      return ReverseGeocodeResult(
        displayName: display,
        country: am?['country']?.toString(),
        city: am?['city']?.toString() ?? am?['town']?.toString() ?? am?['village']?.toString(),
        neighbourhood: am?['suburb']?.toString() ?? am?['neighbourhood']?.toString(),
      );
    } catch (_) {
      return null;
    }
  }
}
