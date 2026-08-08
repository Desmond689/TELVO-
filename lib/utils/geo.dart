import 'dart:math';

String encodeGeoHash(double lat, double lng, {int precision = 9}) {
  const String _base32 = '0123456789bcdefghjkmnpqrstuvwxyz';
  List<double> latInterval = [-90.0, 90.0];
  List<double> lonInterval = [-180.0, 180.0];
  bool isEven = true;
  int bit = 0;
  int ch = 0;
  final StringBuffer geohash = StringBuffer();

  while (geohash.length < precision) {
    double mid;
    if (isEven) {
      mid = (lonInterval[0] + lonInterval[1]) / 2;
      if (lng > mid) {
        ch = (ch << 1) + 1;
        lonInterval[0] = mid;
      } else {
        ch = (ch << 1) + 0;
        lonInterval[1] = mid;
      }
    } else {
      mid = (latInterval[0] + latInterval[1]) / 2;
      if (lat > mid) {
        ch = (ch << 1) + 1;
        latInterval[0] = mid;
      } else {
        ch = (ch << 1) + 0;
        latInterval[1] = mid;
      }
    }

    isEven = !isEven;
    bit++;

    if (bit == 5) {
      geohash.write(_base32[ch]);
      bit = 0;
      ch = 0;
    }
  }

  return geohash.toString();
}

/// Haversine distance in kilometers between two points
double haversineDistanceKm(double lat1, double lon1, double lat2, double lon2) {
  const R = 6371; // Earth's radius in km
  final dLat = _deg2rad(lat2 - lat1);
  final dLon = _deg2rad(lon2 - lon1);
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_deg2rad(lat1)) * cos(_deg2rad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return R * c;
}

double _deg2rad(double deg) => deg * (pi / 180);
