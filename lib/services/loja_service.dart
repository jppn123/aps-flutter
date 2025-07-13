import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

class LojaService {
  final String baseUrl = AuthService.baseUrl;

  Future<List<Map<String, dynamic>>> listarLojas() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AuthService.tokenKey);
    if (token == null) {
      throw Exception('Token de autenticação não encontrado');
    }
    final response = await http.get(
      Uri.parse('$baseUrl/loja/listar'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Erro ao listar lojas');
    }
  }

  Future<Map<String, dynamic>> getLoja(int idLoja) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AuthService.tokenKey);
    if (token == null) {
      throw Exception('Token de autenticação não encontrado');
    }
    final response = await http.get(
      Uri.parse('$baseUrl/loja/getLoja/$idLoja'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Erro ao buscar loja');
    }
  }

  Future<Map<String, dynamic>> criarLoja({required String nome, required String endereco}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AuthService.tokenKey);
    if (token == null) {
      throw Exception('Token de autenticação não encontrado');
    }
    final response = await http.post(
      Uri.parse('$baseUrl/loja/criar'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'nome': nome,
        'endereco': endereco,
      }),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Erro ao criar loja');
    }
  }

  Future<Map<String, dynamic>> atualizarLoja({required int id, String? nome, String? endereco}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AuthService.tokenKey);
    if (token == null) {
      throw Exception('Token de autenticação não encontrado');
    }
    final response = await http.put(
      Uri.parse('$baseUrl/loja/atualizar/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        if (nome != null) 'nome': nome,
        if (endereco != null) 'endereco': endereco,
      }),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Erro ao atualizar loja');
    }
  }

  Future<void> deletarLoja(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AuthService.tokenKey);
    if (token == null) {
      throw Exception('Token de autenticação não encontrado');
    }
    final response = await http.delete(
      Uri.parse('$baseUrl/loja/deletar/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Erro ao deletar loja');
    }
  }

  Future<List<Map<String, dynamic>>> getLojasUsuario(int idUsuario) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AuthService.tokenKey);
    if (token == null) {
      throw Exception('Token de autenticação não encontrado');
    }
    final response = await http.get(
      Uri.parse('$baseUrl/usuario-loja/getLojasUsuario/$idUsuario'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['lojas'] ?? []);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Erro ao buscar lojas do usuário');
    }
  }

  Future<void> adicionarUsuarioLoja({required int idUsuario, required int idLoja}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AuthService.tokenKey);
    if (token == null) {
      throw Exception('Token de autenticação não encontrado');
    }
    final response = await http.post(
      Uri.parse('$baseUrl/usuario-loja/adicionar'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'id_usuario': idUsuario,
        'id_loja': idLoja,
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Erro ao vincular usuário à loja');
    }
  }

  Future<void> removerUsuarioLoja({required int idUsuario, required int idLoja}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AuthService.tokenKey);
    if (token == null) {
      throw Exception('Token de autenticação não encontrado');
    }
    final response = await http.delete(
      Uri.parse('$baseUrl/usuario-loja/remover?id_usuario=$idUsuario&id_loja=$idLoja'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Erro ao remover vínculo usuário-loja');
    }
  }
} 