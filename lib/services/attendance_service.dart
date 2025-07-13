import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AttendanceService {
  final AuthService _authService = AuthService();

  Future<int> registerAttendance(String address, String tipo, int? idLoja) async {
    try {
      
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      String? token = await _authService.getToken();
      if (token == null) {
        throw Exception('Usuário não autenticado');
      }

      final prefs = await SharedPreferences.getInstance();
      final idUsuarioStr = prefs.getString(AuthService.idUsu);
      if (idUsuarioStr == null) {
        throw Exception('ID do usuário não encontrado');
      }
      final idUsuario = int.parse(idUsuarioStr);

      Map<String, dynamic> payload = {
        'id_usuario': idUsuario,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'horario': DateTime.now().toIso8601String(),
        'endereco': address,
        'tipo': tipo,
      };

      if (idLoja != null) {
        payload['id_loja'] = idLoja;
      }

      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/ponto/registrar'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(payload),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['id']; 
      } else {
        throw Exception('Erro ao registrar ponto: ${response.body}');
      }
    } catch (e) {
      throw Exception('Erro ao registrar ponto: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getPontosByDay(int idUsuario, String data) async {
    try {
      String? token = await _authService.getToken();
      if (token == null) {
        throw Exception('Usuário não autenticado');
      }

      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/ponto/getPontos/$idUsuario?data=$data'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Erro ao buscar pontos: ${response.body}');
      }
    } catch (e) {
      throw Exception('Erro ao buscar pontos: $e');
    }
  }

  Future<Map<String, dynamic>> getPonto(int idPonto) async {
    try {
      String? token = await _authService.getToken();
      if (token == null) {
        throw Exception('Usuário não autenticado');
      }

      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/ponto/getPonto/$idPonto'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Erro ao buscar ponto: ${response.body}');
      }
    } catch (e) {
      throw Exception('Erro ao buscar ponto: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getPontosUsuario(int idUsuario) async {
    try {
      String? token = await _authService.getToken();
      if (token == null) {
        throw Exception('Usuário não autenticado');
      }

      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/ponto/usuario/$idUsuario'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Erro ao buscar pontos do usuário: ${response.body}');
      }
    } catch (e) {
      throw Exception('Erro ao buscar pontos do usuário: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getPontosLoja(int idLoja) async {
    try {
      String? token = await _authService.getToken();
      if (token == null) {
        throw Exception('Usuário não autenticado');
      }

      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/ponto/loja/$idLoja'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Erro ao buscar pontos da loja: ${response.body}');
      }
    } catch (e) {
      throw Exception('Erro ao buscar pontos da loja: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getPontosLojaData(int idLoja, String data) async {
    try {
      String? token = await _authService.getToken();
      if (token == null) {
        throw Exception('Usuário não autenticado');
      }

      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/ponto/loja/$idLoja/data/$data'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Erro ao buscar pontos da loja na data: ${response.body}');
      }
    } catch (e) {
      throw Exception('Erro ao buscar pontos da loja na data: $e');
    }
  }

  Future<Map<String, dynamic>> atualizarPonto(int idPonto, Map<String, dynamic> dados) async {
    try {
      String? token = await _authService.getToken();
      if (token == null) {
        throw Exception('Usuário não autenticado');
      }

      final response = await http.put(
        Uri.parse('${AuthService.baseUrl}/ponto/atualizar/$idPonto'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(dados),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Erro ao atualizar ponto: ${response.body}');
      }
    } catch (e) {
      throw Exception('Erro ao atualizar ponto: $e');
    }
  }

  Future<void> registrarPonto() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AuthService.tokenKey);
      
      if (token == null) {
        throw Exception('Token de autenticação não encontrado');
      }

      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/ponto/registrar'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Ponto registrado com sucesso: ${data['message']}');
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['detail'] ?? 'Erro ao registrar ponto');
      }
    } catch (e) {
      throw Exception('Erro ao registrar ponto: $e');
    }
  }
} 