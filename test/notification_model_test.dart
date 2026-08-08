import 'package:flutter_test/flutter_test.dart';
import 'package:telvo/models/notification_model.dart';

void main() {
  test('NotificationModel.fromMap preserves explicit ids as strings', () {
    final model = NotificationModel.fromMap({
      'id': 42,
      'title': 'New job',
      'body': 'A professional accepted your request',
      'isRead': false,
    });

    expect(model.id, '42');
    expect(model.title, 'New job');
    expect(model.body, 'A professional accepted your request');
    expect(model.isRead, isFalse);
  });
}
