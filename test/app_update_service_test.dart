import 'package:flutter_test/flutter_test.dart';
import 'package:telvo/services/app_update_service.dart';

void main() {
  group('AppUpdateService', () {
    test('reports update when remote version code is higher', () {
      final service = AppUpdateService();
      expect(
        service.shouldUpdate(installedVersionCode: 100, remoteVersionCode: 101),
        isTrue,
      );
    });

    test('does not report update when remote version code is lower or equal', () {
      final service = AppUpdateService();
      expect(
        service.shouldUpdate(installedVersionCode: 101, remoteVersionCode: 100),
        isFalse,
      );
      expect(
        service.shouldUpdate(installedVersionCode: 101, remoteVersionCode: 101),
        isFalse,
      );
    });
  });
}
