import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:telvo/models/payment_model.dart';

class PaymentProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<PaymentModel> _payments = [];
  WalletModel? _wallet;
  bool _isLoading = false;
  String? _error;

  List<PaymentModel> get payments => _payments;
  WalletModel? get wallet => _wallet;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> processPayment(PaymentModel payment) async {
    try {
      _setLoading(true);
      _setError(null);

      if (payment.method != 'cash') {
        throw Exception('Only cash payments are supported at this time');
      }

      final docRef = await _firestore
          .collection('payments')
          .add(payment.toMap());
      final newPayment = payment.copyWith(id: docRef.id, status: 'completed');

      _payments.insert(0, newPayment);

      // Update job status
      await _firestore.collection('jobs').doc(payment.jobId).update({
        'isPaid': true,
        'paymentMethod': payment.method,
        'finalPrice': payment.amount,
      });

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  Future<void> loadWallet(String userId) async {
    try {
      _setLoading(true);
      _setError(null);

      final doc = await _firestore.collection('wallets').doc(userId).get();
      if (doc.exists) {
        _wallet = WalletModel.fromMap(doc.data()!);
      } else {
        _wallet = WalletModel(userId: userId);
        await _firestore
            .collection('wallets')
            .doc(userId)
            .set(_wallet!.toMap());
      }

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  /// Payments received by a professional (loadPayments above is
  /// customer-side - it filters by customerId, the wrong field here).
  Future<void> loadProfessionalPayments(String professionalId) async {
    try {
      _setLoading(true);
      _setError(null);

      final snapshot = await _firestore
          .collection('payments')
          .where('professionalId', isEqualTo: professionalId)
          .where('status', isEqualTo: 'completed')
          .orderBy('createdAt', descending: true)
          .get();

      _payments = snapshot.docs
          .map((doc) => PaymentModel.fromMap(doc.data()))
          .toList();

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  Future<void> loadPayments(String userId) async {
    try {
      _setLoading(true);
      _setError(null);

      final snapshot = await _firestore
          .collection('payments')
          .where('customerId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      _payments = snapshot.docs
          .map((doc) => PaymentModel.fromMap(doc.data()))
          .toList();

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  Future<void> requestRefund(String paymentId) async {
    try {
      _setLoading(true);
      _setError(null);

      await _firestore.collection('payments').doc(paymentId).update({
        'status': 'refund_requested',
      });

      final index = _payments.indexWhere((p) => p.id == paymentId);
      if (index != -1) {
        _payments[index] = _payments[index].copyWith(
          status: 'refund_requested',
        );
        notifyListeners();
      }

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
