import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AppUpdateInfo {
  const AppUpdateInfo({
    required this.version,
    required this.versionCode,
    required this.apkUrl,
    required this.releaseNotes,
    required this.isForceUpdate,
  });

  final String version;
  final int versionCode;
  final String apkUrl;
  final String releaseNotes;
  final bool isForceUpdate;
}

class AppUpdateService {
  AppUpdateService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  bool shouldUpdate({required int installedVersionCode, required int remoteVersionCode}) {
    return remoteVersionCode > installedVersionCode;
  }

  Future<AppUpdateInfo?> checkForUpdate() async {
    if (!Platform.isAndroid) return null;

    try {
      final snapshot = await _firestore
          .collection('app_config')
          .doc('latest_app')
          .get();

      if (!snapshot.exists) return null;

      final data = snapshot.data();
      if (data == null) return null;

      final remoteVersion = data['version']?.toString() ?? '';
      final remoteVersionCode = data['versionCode'];
      final apkUrl = data['apkUrl']?.toString() ?? '';
      final releaseNotes = data['releaseNotes']?.toString() ?? '';
      final isForceUpdate = data['isForceUpdate'] == true;

      if (remoteVersionCode is! int || remoteVersionCode <= 0 || apkUrl.isEmpty) {
        return null;
      }

      final packageInfo = await PackageInfo.fromPlatform();
      final installedVersionCode = int.tryParse(packageInfo.buildNumber);
      if (installedVersionCode == null) return null;

      if (!shouldUpdate(
        installedVersionCode: installedVersionCode,
        remoteVersionCode: remoteVersionCode,
      )) {
        return null;
      }

      return AppUpdateInfo(
        version: remoteVersion,
        versionCode: remoteVersionCode,
        apkUrl: apkUrl,
        releaseNotes: releaseNotes,
        isForceUpdate: isForceUpdate,
      );
    } catch (e) {
      debugPrint('App update check failed: $e');
      return null;
    }
  }

  Future<void> openDownloadUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch update URL');
    }
  }
}
