import 'package:telvo/models/payment_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<PaymentModel> processPayment(PaymentModel payment) async {
    if (payment.method != 'cash') {
      throw Exception('Only cash payments are supported at this time');
    }

    final docRef = await _firestore.collection('payments').add(payment.toMap());
    final newPayment = payment.copyWith(id: docRef.id, status: 'completed');

    // Update job payment status
    await _firestore.collection('jobs').doc(payment.jobId).update({
      'isPaid': true,
      'paymentMethod': payment.method,
      'finalPrice': payment.amount,
    });

    return newPayment;
  }

  Future<PaymentModel> getPayment(String paymentId) async {
    final doc = await _firestore.collection('payments').doc(paymentId).get();
    if (!doc.exists) {
      throw Exception('Payment not found');
    }
    return PaymentModel.fromMap(doc.data()!);
  }

  Future<List<PaymentModel>> getPaymentsByUser(String userId) async {
    final snapshot = await _firestore
        .collection('payments')
        .where('customerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => PaymentModel.fromMap(doc.data()))
        .toList();
  }

  Future<PaymentModel> requestRefund(String paymentId) async {
    await _firestore.collection('payments').doc(paymentId).update({
      'status': 'refund_requested',
    });

    return getPayment(paymentId);
  }

  Future<WalletModel> getWallet(String userId) async {
    final doc = await _firestore.collection('wallets').doc(userId).get();
    if (doc.exists) {
      return WalletModel.fromMap(doc.data()!);
    } else {
      final wallet = WalletModel(userId: userId);
      await _firestore.collection('wallets').doc(userId).set(wallet.toMap());
      return wallet;
    }
  }

  Future<void> updateWallet(String userId, double amount, String type) async {
    final wallet = await getWallet(userId);
    final newBalance = type == 'credit'
        ? (wallet.balance ?? 0) + amount
        : (wallet.balance ?? 0) - amount;

    await _firestore.collection('wallets').doc(userId).update({
      'balance': newBalance,
      if (type == 'credit') 'totalEarned': (wallet.totalEarned ?? 0) + amount,
      if (type == 'debit') 'totalSpent': (wallet.totalSpent ?? 0) + amount,
    });
  }
}
