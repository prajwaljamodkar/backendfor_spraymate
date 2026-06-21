import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  static String get baseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:8080/api';

  // ─── Auth ───

  static Future<Map<String, dynamic>> register(
      String email, String password, String name) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'name': name,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      await _saveToken(data['token']);
      await _saveUserInfo(data['email'] ?? email, data['name'] ?? name);
      return data;
    } else {
      throw Exception(data['error'] ?? 'Registration failed');
    }
  }

  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      await _saveToken(data['token']);
      await _saveUserInfo(data['email'] ?? email, data['name'] ?? '');
      return data;
    } else {
      throw Exception(data['error'] ?? 'Login failed');
    }
  }

  // ─── Weather ───

  static Future<Map<String, dynamic>> checkWeather(
      double lat, double lon) async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/weather/check?lat=$lat&lon=$lon'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to check weather conditions');
    }
  }

  // ─── Profile ───

  static Future<Map<String, dynamic>> getProfile() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/profile'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await _saveUserInfo(data['email'] ?? '', data['name'] ?? '');
      return data;
    } else {
      throw Exception('Failed to load profile');
    }
  }

  static Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? email,
    String? currentPassword,
    String? newPassword,
  }) async {
    final token = await getToken();
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (email != null) body['email'] = email;
    if (currentPassword != null) body['currentPassword'] = currentPassword;
    if (newPassword != null) body['newPassword'] = newPassword;

    final response = await http.put(
      Uri.parse('$baseUrl/profile'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      // Save new token and updated user info
      if (data['token'] != null) await _saveToken(data['token']);
      await _saveUserInfo(data['email'] ?? '', data['name'] ?? '');
      return data;
    } else {
      throw Exception(data['error'] ?? 'Failed to update profile');
    }
  }

  // ─── Token & User Info Management ───

  static Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
  }

  static Future<void> _saveUserInfo(String email, String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_email', email);
    await prefs.setString('user_name', name);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_name');
  }

  static Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_email');
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('user_email');
    await prefs.remove('user_name');
  }
}

