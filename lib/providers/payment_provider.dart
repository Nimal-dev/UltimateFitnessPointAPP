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
  final String? notes;
  final DateTime createdAt;
  final DateTime? verifiedAt;

  PaymentRequest({
    required this.id,
    required this.memberId,
    required this.memberName,
    required this.amount,
    required this.transactionId,
    required this.paymentApp,
    required this.planName,
    required this.status,
    this.notes,
    required this.createdAt,
    this.verifiedAt,
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
      notes: json['notes'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      verifiedAt: json['verifiedAt'] != null ? DateTime.parse(json['verifiedAt']) : null,
    );
  }
}

class PaymentProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  List<PaymentRequest> _pendingPayments = [];
  List<PaymentRequest> _paymentHistory = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<PaymentRequest> get pendingPayments => _pendingPayments;
  List<PaymentRequest> get paymentHistory => _paymentHistory;

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
      final response = await ApiService.post('/payment/request', {
        'amount': amount,
        'transactionId': transactionId,
        'paymentApp': paymentApp,
        'planName': planName,
      });

      _isLoading = false;
      if (response['success'] == true) {
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Submission failed';
        notifyListeners();
        return false;
      }
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
      final response = await ApiService.get('/payment/pending');
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

  /// Fetch payment history (Owner)
  Future<void> fetchPaymentHistory() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.get('/payment/history');
      if (response['success'] == true) {
        final List list = response['data'] ?? [];
        _paymentHistory = list.map((json) => PaymentRequest.fromJson(json)).toList();
      } else {
        _error = response['message'] ?? 'Failed to load history';
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
      final response = await ApiService.patch('/payment/$paymentId/verify', {
        'status': status,
        'notes': notes ?? '',
      });

      _isLoading = false;
      if (response['success'] == true) {
        _pendingPayments.removeWhere((p) => p.id == paymentId);
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Verification failed';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
