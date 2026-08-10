import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:telvo/utils/geo.dart';

class GeoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Finds professionals in the same city and within [radiusKm] of [lat,lng].
  /// This is a simple, reliable fallback that works without a full geohash
  /// prefix indexing setup. For larger scale use geohash prefix queries.
  Future<List<Map<String, dynamic>>> findNearbyProfessionals({
    required double lat,
    required double lng,
    required String category,
    required String city,
    double radiusKm = 10,
  }) async {
    final snapshot = await _firestore
        .collection('users')
        .where('userType', whereIn: ['professional', 'both'])
        .where('city', isEqualTo: city)
        .get();

    final results = <Map<String, dynamic>>[];
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final dLat = (data['latitude'] as num?)?.toDouble();
      final dLng = (data['longitude'] as num?)?.toDouble();
      final profCategory = data['category'] as String?;
      if (dLat == null || dLng == null) continue;
      if (category.isNotEmpty && profCategory != null && !profCategory.toLowerCase().contains(category.toLowerCase())) continue;

      final distance = haversineDistanceKm(lat, lng, dLat, dLng);
      if (distance <= radiusKm) {
        results.add({...data, 'distanceKm': distance});
      }
    }

    results.sort((a, b) => (a['distanceKm'] as double).compareTo(b['distanceKm'] as double));
    return results;
  }
}
