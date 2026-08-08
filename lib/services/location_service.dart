import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  static Future<bool> requestPermissions() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  static Future<Position?> getCurrentLocation() async {
    try {
      final hasPermission = await requestPermissions();
      if (!hasPermission) return null;

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (e) {
      return null;
    }
  }

  static Future<double> calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) async =>
      Geolocator.distanceBetween(lat1, lon1, lat2, lon2);

  static Future<Position?> getLocationFromAddress(String address) async {
    try {
      // Use geocoding to get coordinates from address
      // This would require a geocoding service
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<String?> getAddressFromLocation(double lat, double lon) async {
    try {
      return 'Lat: ${lat.toStringAsFixed(4)}, Lon: ${lon.toStringAsFixed(4)}';
    } catch (e) {
      return null;
    }
  }
}
