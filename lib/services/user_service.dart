import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

class UserService {
  final String baseUrl = AuthService.baseUrl;

  Future<Map<String, dynamic>> criarLogin({
    required String email,
    required String tipo,
    String senha = '12345678',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AuthService.tokenKey);
    
    if (token == null) {
      throw Exception('Token de autenticação não encontrado');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/login/criar'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'email': email,
        'tipo': tipo,
        'senha': senha,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Erro ao criar login');
    }
  }

  Future<void> criarUsuario({
    required String nome,
    required String cpf,
    required int idLogin,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AuthService.tokenKey);
    
    if (token == null) {
      throw Exception('Token de autenticação não encontrado');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/usuario/criar'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'nome': nome,
        'cpf': cpf,
        'id_login': idLogin,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Erro ao criar usuário');
    }
  }
} 