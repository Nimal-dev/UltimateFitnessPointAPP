import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  bool _isLoading = true;
  String? _error;
  bool _needsMpinReset = false;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;
  bool get needsMpinReset => _needsMpinReset;

  AuthProvider() {
    _tryAutoLogin();
  }

  Future<void> _tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token != null) {
      try {
        final data = await ApiService.get('/auth/me');
        if (data['success'] == true) {
          _user = UserModel.fromJson(data['user']);
        } else {
          await prefs.remove('token');
        }
      } catch (_) {
        await prefs.remove('token');
      }
    }
    _isLoading = false;
    notifyListeners();
  }

  /// Login with mobile number + 4-digit MPIN.
  /// If the backend signals [requiresMpinReset], the token is saved but
  /// [needsMpinReset] is set to true — the router will gate the user to
  /// ForceMpinResetScreen instead of Home.
  Future<bool> login(String mobile, String mpin) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await ApiService.post('/auth/login', {
        'mobile': mobile,
        'mpin': mpin,
      });

      if (data['success'] == true) {
        final token = data['token'];
        if (token != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', token.toString());
        }
        _user = UserModel.fromJson(data['user']);
        // Check if user must reset their default MPIN
        _needsMpinReset = data['requiresMpinReset'] == true;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = data['message'] ?? 'Invalid mobile or MPIN';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Whoops, dropped the dumbbell! Something went wrong.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Calls [PATCH /api/auth/reset-mpin] to change the user's MPIN.
  /// On success, clears the [needsMpinReset] flag and grants access to Home.
  Future<bool> resetMpin(String newMpin) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await ApiService.patch('/auth/reset-mpin', {'mpin': newMpin});
      if (data['success'] == true) {
        _needsMpinReset = false;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = data['message'] ?? 'Failed to update MPIN';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Whoops, dropped the dumbbell! Something went wrong.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    _user = null;
    _needsMpinReset = false;
    notifyListeners();
  }
}
