import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiService {
  // Use 10.0.2.2 for Android emulator (maps to host machine's localhost)
  // Change to your machine's LAN IP for physical devices
  // Physical device: use laptop's LAN IP. Emulator: use 10.0.2.2
  static const String baseUrl = 'http://192.168.1.110:5000/api';
  static const Duration _timeout = Duration(seconds: 15);

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<Map<String, String>> _headers() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, dynamic>> get(String path) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl$path'), headers: await _headers())
          .timeout(_timeout);
      return _handle(response);
    } on SocketException {
      throw ApiException('No internet connection. Check your network and try again.');
    } on TimeoutException {
      throw ApiException('Request timed out. The server took too long to respond.');
    }
  }

  static Future<Map<String, dynamic>> post(
      String path, Map<String, dynamic> body) async {
    try {
      final response = await http
          .post(Uri.parse('$baseUrl$path'),
              headers: await _headers(), body: jsonEncode(body))
          .timeout(_timeout);
      return _handle(response);
    } on SocketException {
      throw ApiException('No internet connection. Check your network and try again.');
    } on TimeoutException {
      throw ApiException('Request timed out. The server took too long to respond.');
    }
  }

  static Future<Map<String, dynamic>> patch(
      String path, Map<String, dynamic> body) async {
    try {
      final response = await http
          .patch(Uri.parse('$baseUrl$path'),
              headers: await _headers(), body: jsonEncode(body))
          .timeout(_timeout);
      return _handle(response);
    } on SocketException {
      throw ApiException('No internet connection. Check your network and try again.');
    } on TimeoutException {
      throw ApiException('Request timed out. The server took too long to respond.');
    }
  }

  static Future<Map<String, dynamic>> delete(String path) async {
    try {
      final response = await http
          .delete(Uri.parse('$baseUrl$path'), headers: await _headers())
          .timeout(_timeout);
      return _handle(response);
    } on SocketException {
      throw ApiException('No internet connection. Check your network and try again.');
    } on TimeoutException {
      throw ApiException('Request timed out. The server took too long to respond.');
    }
  }

  static Map<String, dynamic> _handle(http.Response response) {
    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode >= 500) {
        throw ApiException(
            data['message'] ?? 'Server error. Please try again later.',
            statusCode: response.statusCode);
      }
      // Return all other responses (including 4xx) as data so callers
      // can read data['success'] and data['message'] directly.
      return data;
    } on FormatException {
      throw ApiException('Received an unexpected response from the server.');
    }
  }
}
