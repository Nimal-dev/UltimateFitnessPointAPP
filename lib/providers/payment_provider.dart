import 'package:flutter/material.dart';
import '../services/api_service.dart';

class PaymentRequest {
  final String id;
  final String memberId;
  final String memberName;
  final double amount;
  final String transactionId;
  final String paymentApp;
  final String planName;
  final String status;
  final DateTime createdAt;

  PaymentRequest({
    required this.id,
    required this.memberId,
    required this.memberName,
    required this.amount,
    required this.transactionId,
    required this.paymentApp,
    required this.planName,
    required this.status,
    required this.createdAt,
  });

  factory PaymentRequest.fromJson(Map<String, dynamic> json) {
    return PaymentRequest(
      id: json['_id'] ?? '',
      memberId: json['memberId'] is Map ? json['memberId']['_id'] : (json['memberId'] ?? ''),
      memberName: json['memberId'] is Map ? json['memberId']['name'] : 'Unknown',
      amount: (json['amount'] ?? 0).toDouble(),
      transactionId: json['transactionId'] ?? '',
      paymentApp: json['paymentApp'] ?? '',
      planName: json['planName'] ?? '',
      status: json['status'] ?? 'Pending',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class PaymentProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  List<PaymentRequest> _pendingPayments = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<PaymentRequest> get pendingPayments => _pendingPayments;

  /// Submit a payment request (Member)
  Future<bool> submitPaymentRequest({
    required double amount,
    required String transactionId,
    required String paymentApp,
    required String planName,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.post('/api/payment/request', {
        'amount': amount,
        'transactionId': transactionId,
        'paymentApp': paymentApp,
        'planName': planName,
      });

      _isLoading = false;
      notifyListeners();
      return response['success'] == true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Fetch pending payments (Owner)
  Future<void> fetchPendingPayments() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.get('/api/payment/pending');
      if (response['success'] == true) {
        final List list = response['data'] ?? [];
        _pendingPayments = list.map((json) => PaymentRequest.fromJson(json)).toList();
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Verify (Approve/Reject) a payment (Owner)
  Future<bool> verifyPayment(String paymentId, String status, {String? notes}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.patch('/api/payment/$paymentId/verify', {
        'status': status,
        'notes': notes ?? '',
      });

      if (response['success'] == true) {
        _pendingPayments.removeWhere((p) => p.id == paymentId);
      }
      _isLoading = false;
      notifyListeners();
      return response['success'] == true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
