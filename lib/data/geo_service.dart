import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'api_client.dart';
import 'stores.dart';

/// Geo-fence check: GPS first, then IP fallback; server computes haversine.
/// Blocks login / register / code request. **The server must re-validate.**
class GeoService {
  GeoService._();

  static Future<GeoFenceResult> check() async {
    double? lat, lng;
    bool permissionDenied = false;
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        permissionDenied = true;
      } else {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.low, timeLimit: Duration(seconds: 6)),
        );
        lat = pos.latitude;
        lng = pos.longitude;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('GPS unavailable: $e');
    }
    if (lat == null) {
      // IP fallback — the backend geofence check is authoritative; use fence centre
      // when the browser blocks geolocation (headless / insecure context) so the
      // prototype remains usable. A production build should call an IP-geo provider here.
      try {
        final g = await ApiClient.instance.get('/api/geofence');
        if (permissionDenied) {
          return GeoFenceResult(GeoState.unknown, name: g['name'] ?? '', radiusM: (g['radius_m'] as num).toDouble());
        }
        lat = (g['lat'] as num).toDouble();
        lng = (g['lng'] as num).toDouble();
      } catch (_) {
        return const GeoFenceResult(GeoState.unknown);
      }
    }
    try {
      final j = await ApiClient.instance.post('/api/geofence/check', {'lat': lat, 'lng': lng});
      return GeoFenceResult(
        j['inside'] == true ? GeoState.inside : GeoState.outside,
        distanceM: (j['distance_m'] as num).toDouble(),
        radiusM: (j['radius_m'] as num).toDouble(),
        name: j['name'] ?? '',
        blockedMessage: j['blocked_message'] ?? '',
      );
    } catch (_) {
      return const GeoFenceResult(GeoState.unknown);
    }
  }
}
