import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class FotoPontoService {
  final AuthService _authService = AuthService();

  Future<Map<String, dynamic>> adicionarFotoPonto(int idPonto, File foto) async {
    try {
      String? token = await _authService.getToken();
      if (token == null) {
        throw Exception('Usuário não autenticado');
      }

      List<int> imageBytes = await foto.readAsBytes();
      String base64Image = base64Encode(imageBytes);

      Map<String, dynamic> payload = {
        'id_ponto': idPonto,
        'foto': base64Image,
      };

      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/foto-ponto/adicionar'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(payload),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Erro ao adicionar foto: ${response.body}');
      }
    } catch (e) {
      throw Exception('Erro ao adicionar foto: $e');
    }
  }

  Future<Map<String, dynamic>> removerFotoPonto(int idFoto) async {
    try {
      String? token = await _authService.getToken();
      if (token == null) {
        throw Exception('Usuário não autenticado');
      }

      final response = await http.delete(
        Uri.parse('${AuthService.baseUrl}/foto-ponto/remover/$idFoto'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Erro ao remover foto: ${response.body}');
      }
    } catch (e) {
      throw Exception('Erro ao remover foto: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getFotosPonto(int idPonto) async {
    try {
      String? token = await _authService.getToken();
      if (token == null) {
        throw Exception('Usuário não autenticado');
      }

      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/foto-ponto/getFotosPonto/$idPonto'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Erro ao buscar fotos do ponto: ${response.body}');
      }
    } catch (e) {
      throw Exception('Erro ao buscar fotos do ponto: $e');
    }
  }

  Future<Map<String, dynamic>> getFotoPonto(int idFoto) async {
    try {
      String? token = await _authService.getToken();
      if (token == null) {
        throw Exception('Usuário não autenticado');
      }

      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/foto-ponto/getFoto/$idFoto'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Erro ao buscar foto: ${response.body}');
      }
    } catch (e) {
      throw Exception('Erro ao buscar foto: $e');
    }
  }

  Future<Map<String, dynamic>> atualizarFotoPonto(int idFoto, Map<String, dynamic> dados) async {
    try {
      String? token = await _authService.getToken();
      if (token == null) {
        throw Exception('Usuário não autenticado');
      }

      final response = await http.put(
        Uri.parse('${AuthService.baseUrl}/foto-ponto/atualizar/$idFoto'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(dados),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Erro ao atualizar foto: ${response.body}');
      }
    } catch (e) {
      throw Exception('Erro ao atualizar foto: $e');
    }
  }
} 