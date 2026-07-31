import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionHandler {
  static Future<bool> requestLocationPermission() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  static Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  static Future<bool> requestGalleryPermission() async {
    final status = await Permission.storage.request();
    return status.isGranted;
  }

  static Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  static Future<bool> requestNotificationPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  static Future<bool> requestContactsPermission() async {
    final status = await Permission.contacts.request();
    return status.isGranted;
  }

  static Future<bool> requestPhonePermission() async {
    final status = await Permission.phone.request();
    return status.isGranted;
  }

  static Future<bool> checkLocationPermission() async {
    final status = await Permission.location.status;
    return status.isGranted;
  }

  static Future<bool> checkCameraPermission() async {
    final status = await Permission.camera.status;
    return status.isGranted;
  }

  static Future<bool> checkGalleryPermission() async {
    final status = await Permission.storage.status;
    return status.isGranted;
  }

  static Future<bool> checkMicrophonePermission() async {
    final status = await Permission.microphone.status;
    return status.isGranted;
  }

  static Future<bool> checkNotificationPermission() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  static Future<bool> checkContactsPermission() async {
    final status = await Permission.contacts.status;
    return status.isGranted;
  }

  static Future<bool> checkPhonePermission() async {
    final status = await Permission.phone.status;
    return status.isGranted;
  }

  static Future<void> openAppSettings() async {
    await openAppSettings();
  }

  static Future<bool> checkLocationServices() async =>
      await Geolocator.isLocationServiceEnabled();

  static Future<bool> requestAllPermissions() async {
    final permissions = [
      Permission.location,
      Permission.camera,
      Permission.storage,
      Permission.microphone,
      Permission.notification,
    ];

    final statuses = await permissions.request();
    return statuses.values.every((status) => status.isGranted);
  }

  static Map<Permission, String> getPermissionDescriptions() => {
        Permission.location:
            'Location permission is needed to find professionals near you and for live tracking.',
        Permission.camera:
            'Camera permission is needed to take photos of issues and for verification.',
        Permission.storage:
            'Storage permission is needed to upload photos and documents.',
        Permission.microphone:
            'Microphone permission is needed for voice messages and calls.',
        Permission.notification:
            'Notification permission is needed to receive job updates and messages.',
        Permission.contacts:
            'Contacts permission is needed to add emergency contacts.',
        Permission.phone:
            'Phone permission is needed to call emergency contacts.',
      };

  static Future<bool> isPermissionPermanentlyDenied(
    Permission permission,
  ) async {
    final status = await permission.status;
    return status.isPermanentlyDenied;
  }
}
