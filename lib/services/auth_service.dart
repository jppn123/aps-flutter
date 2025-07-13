import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl = 'https://web-production-25d6.up.railway.app';
  static const String tokenKey = 'auth_token';
  static const String userIdKey = 'user_id';
  static const String idUsu = 'id_usu';
  static const String userNameKey = 'user_name';
  static const String userEmailKey = 'user_email';

  Future<String> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login/entrar'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'senha': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final token = data['token'];
        final userId = data['id']?.toString();
        final userName = data['name'];
        final userEmail = data['email'];
        
        if (token == null) {
          throw Exception('Token não encontrado na resposta.');
        }
        
        await _saveToken(token);
        await _saveUserInfo(userId, userName, userEmail);
        await validarToken(token);
        return token;
      } else {
        throw Exception('Falha no login: ${response.body}');
      }
    } catch (e) {
      throw Exception('Erro ao fazer login: $e');
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
    await prefs.remove(userIdKey);
    await prefs.remove(userNameKey);
    await prefs.remove(userEmailKey);
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, token);
  }

  Future<void> _saveUserInfo(String? userId, String? userName, String? userEmail) async {
    final prefs = await SharedPreferences.getInstance();
    if (userId != null) await prefs.setString(userIdKey, userId);
    if (userName != null) await prefs.setString(userNameKey, userName);
    if (userEmail != null) await prefs.setString(userEmailKey, userEmail);
  }

  Future<void> saveToken(String token) async {
    await _saveToken(token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(tokenKey);
  }

  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(userIdKey);
  }

  Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(userNameKey);
  }

  Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(userEmailKey);
  }

  Future<Map<String, dynamic>> validarToken(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/login/validarToken'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(idUsu, data['id_usu'].toString());
      if (data['tp_login'] != null) {
        await prefs.setString('tp_login', data['tp_login'].toString());
      }
      return data;
    } else {
      throw Exception('Falha ao validar token: ${response.body}');
    }
  }
} 