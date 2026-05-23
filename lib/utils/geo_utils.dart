import 'dart:convert';
import 'dart:math' as math;

/// Max distance from checkpoint center to accept a patrol scan (meters).
const double checkpointScanRadiusM = 5;

/// Reject scans when GPS accuracy is worse than this (meters).
const double maxPatrolGpsAccuracyM = 5;

double distanceMeters(double lat1, double lng1, double lat2, double lng2) {
  const earth = 6371000.0;
  double rad(double deg) => deg * math.pi / 180;
  final dLat = rad(lat2 - lat1);
  final dLng = rad(lng2 - lng1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(rad(lat1)) *
          math.cos(rad(lat2)) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  return earth * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

bool isInsideCircularGeofence(
  Map<String, dynamic> site,
  double lat,
  double lng,
) {
  final radius = double.tryParse(site['geofenceRadiusM']?.toString() ?? '');
  final centerLat = double.tryParse(site['centerLat']?.toString() ?? '');
  final centerLng = double.tryParse(site['centerLng']?.toString() ?? '');
  if (radius == null || centerLat == null || centerLng == null) return true;
  return distanceMeters(lat, lng, centerLat, centerLng) <= radius;
}

List<({double lat, double lng})>? _normalizePolygon(dynamic raw) {
  if (raw == null) return null;
  dynamic value = raw;
  if (value is String) {
    try {
      value = jsonDecode(value);
    } catch (_) {
      return null;
    }
  }
  if (value is! Map && value is! List) return null;
  List<dynamic>? points;
  if (value is Map) {
    if (value['coordinates'] is List) {
      points = value['coordinates'] as List;
    } else if (value['points'] is List) {
      points = value['points'] as List;
    }
  } else {
    points = value;
  }
  if (points == null || points.length < 3) return null;
  final out = <({double lat, double lng})>[];
  for (final p in points) {
    if (p is List && p.length >= 2) {
      final lat = double.tryParse(p[0].toString());
      final lng = double.tryParse(p[1].toString());
      if (lat != null && lng != null) out.add((lat: lat, lng: lng));
    } else if (p is Map) {
      final lat = double.tryParse(
          (p['lat'] ?? p['latitude'])?.toString() ?? '');
      final lng = double.tryParse(
          (p['lng'] ?? p['longitude'])?.toString() ?? '');
      if (lat != null && lng != null) out.add((lat: lat, lng: lng));
    }
  }
  return out.length >= 3 ? out : null;
}

bool isInsidePolygon(List<({double lat, double lng})> polygon, double lat, double lng) {
  var inside = false;
  for (var i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
    final yi = polygon[i].lat;
    final xi = polygon[i].lng;
    final yj = polygon[j].lat;
    final xj = polygon[j].lng;
    final intersects =
        yi > lat != yj > lat && lng < ((xj - xi) * (lat - yi)) / (yj - yi) + xi;
    if (intersects) inside = !inside;
  }
  return inside;
}

bool isInsideGeofence(Map<String, dynamic> site, double lat, double lng) {
  final polygon = _normalizePolygon(site['geofencePolygon']);
  if (polygon != null) return isInsidePolygon(polygon, lat, lng);
  return isInsideCircularGeofence(site, lat, lng);
}

String? validateCheckpointScan({
  required double lat,
  required double lng,
  required double? checkpointLat,
  required double? checkpointLng,
  double? accuracyM,
}) {
  if (checkpointLat == null || checkpointLng == null) {
    return 'Checkpoint has no GPS coordinates configured.';
  }
  if (accuracyM != null && accuracyM > maxPatrolGpsAccuracyM) {
    return 'GPS accuracy too low (${accuracyM.round()}m). '
        'Wait for a stronger signal (need ≤${maxPatrolGpsAccuracyM.round()}m).';
  }
  final meters = distanceMeters(lat, lng, checkpointLat, checkpointLng);
  if (meters > checkpointScanRadiusM) {
    return 'You must be within ${checkpointScanRadiusM.round()}m of the checkpoint '
        '(${meters.round()}m away).';
  }
  return null;
}
