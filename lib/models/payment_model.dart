import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentModel {
  PaymentModel({
    this.id,
    this.jobId,
    this.customerId,
    this.professionalId,
    this.amount,
    this.currency = 'XAF',
    this.method,
    this.status = 'pending',
    this.transactionId,
    this.reference,
    this.metadata,
    this.createdAt,
    this.completedAt,
  });

  factory PaymentModel.fromMap(Map<String, dynamic> map) {
    return PaymentModel(
      id: map['id'],
      jobId: map['jobId'],
      customerId: map['customerId'],
      professionalId: map['professionalId'],
      amount: map['amount']?.toDouble(),
      currency: map['currency'] ?? 'XAF',
      method: map['method'],
      status: map['status'] ?? 'pending',
      transactionId: map['transactionId'],
      reference: map['reference'],
      metadata: map['metadata'],
      createdAt: map['createdAt']?.toDate(),
      completedAt: map['completedAt']?.toDate(),
    );
  }
  final String? id;
  final String? jobId;
  final String? customerId;
  final String? professionalId;
  final double? amount;
  final String? currency;
  final String? method; // 'cash', 'momo', 'orange', 'card', 'escrow'
  final String?
  status; // 'pending', 'processing', 'completed', 'failed', 'refunded'
  final String? transactionId;
  final String? reference;
  final Map<String, dynamic>? metadata;
  final DateTime? createdAt;
  final DateTime? completedAt;

  Map<String, dynamic> toMap() => {
    'id': id,
    'jobId': jobId,
    'customerId': customerId,
    'professionalId': professionalId,
    'amount': amount,
    'currency': currency,
    'method': method,
    'status': status,
    'transactionId': transactionId,
    'reference': reference,
    'metadata': metadata,
    'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    'completedAt': completedAt,
  };

  PaymentModel copyWith({
    String? id,
    String? jobId,
    String? customerId,
    String? professionalId,
    double? amount,
    String? currency,
    String? method,
    String? status,
    String? transactionId,
    String? reference,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? completedAt,
  }) => PaymentModel(
    id: id ?? this.id,
    jobId: jobId ?? this.jobId,
    customerId: customerId ?? this.customerId,
    professionalId: professionalId ?? this.professionalId,
    amount: amount ?? this.amount,
    currency: currency ?? this.currency,
    method: method ?? this.method,
    status: status ?? this.status,
    transactionId: transactionId ?? this.transactionId,
    reference: reference ?? this.reference,
    metadata: metadata ?? this.metadata,
    createdAt: createdAt ?? this.createdAt,
    completedAt: completedAt ?? this.completedAt,
  );
}

class WalletModel {
  WalletModel({
    this.userId,
    this.balance = 0,
    this.totalEarned = 0,
    this.totalSpent = 0,
    this.transactions,
  });

  factory WalletModel.fromMap(Map<String, dynamic> map) {
    return WalletModel(
      userId: map['userId'],
      balance: map['balance']?.toDouble() ?? 0,
      totalEarned: map['totalEarned']?.toDouble() ?? 0,
      totalSpent: map['totalSpent']?.toDouble() ?? 0,
      transactions: map['transactions'] != null
          ? List<TransactionModel>.from(
              map['transactions'].map((t) => TransactionModel.fromMap(t)),
            )
          : null,
    );
  }
  final String? userId;
  final double? balance;
  final double? totalEarned;
  final double? totalSpent;
  final List<TransactionModel>? transactions;

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'balance': balance,
    'totalEarned': totalEarned,
    'totalSpent': totalSpent,
    'transactions': transactions?.map((t) => t.toMap()).toList(),
  };
}

class TransactionModel {
  TransactionModel({
    this.id,
    this.userId,
    this.amount,
    this.type,
    this.status,
    this.description,
    this.createdAt,
  });

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'],
      userId: map['userId'],
      amount: map['amount']?.toDouble(),
      type: map['type'],
      status: map['status'],
      description: map['description'],
      createdAt: map['createdAt']?.toDate(),
    );
  }
  final String? id;
  final String? userId;
  final double? amount;
  final String? type; // 'deposit', 'withdrawal', 'payment', 'refund'
  final String? status;
  final String? description;
  final DateTime? createdAt;

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'amount': amount,
    'type': type,
    'status': status,
    'description': description,
    'createdAt': createdAt ?? FieldValue.serverTimestamp(),
  };
}
