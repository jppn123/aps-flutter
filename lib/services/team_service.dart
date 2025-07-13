import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

class TeamService {
  final String baseUrl = AuthService.baseUrl;

  Future<List<Map<String, dynamic>>> getTimes() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AuthService.tokenKey);
    
    if (token == null) {
      throw Exception('Token de autenticação não encontrado');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/time/listar'),
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
      throw Exception(error['detail'] ?? 'Erro ao buscar times');
    }
  }

  Future<Map<String, dynamic>> getTimesUsuario(int idUsuario) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AuthService.tokenKey);
    final tipoUsuario = prefs.getString('tp_login');
    
    if (token == null) {
      throw Exception('Token de autenticação não encontrado');
    }

    if (tipoUsuario == 'func') {
      try {
        final response = await http.get(
          Uri.parse('$baseUrl/time/listar'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );

        if (response.statusCode == 200) {
          final allTimes = jsonDecode(response.body);
          
          return {
            'usuario': {'id': idUsuario, 'nome': 'Usuário', 'cpf': null},
            'times': []
          };
        } else {
          final error = jsonDecode(response.body);
          throw Exception(error['detail'] ?? 'Erro ao buscar times');
        }
      } catch (e) {
        throw Exception('Não foi possível buscar seus times. Entre em contato com um administrador.');
      }
    }

    final response = await http.get(
      Uri.parse('$baseUrl/usuario-time/getTimesUsuario/$idUsuario'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Erro ao buscar times do usuário');
    }
  }

  Future<Map<String, dynamic>> getTimesUsuarioFunc(int idUsuario) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AuthService.tokenKey);
    
    if (token == null) {
      throw Exception('Token de autenticação não encontrado');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/usuario-time/getTimesUsuario/$idUsuario'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Erro ao buscar times do usuário');
    }
  }

  Future<Map<String, dynamic>> getTimeById(int idTime) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AuthService.tokenKey);
    
    if (token == null) {
      throw Exception('Token de autenticação não encontrado');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/time/getTime/$idTime'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Erro ao buscar time');
    }
  }

  Future<Map<String, dynamic>> getTimeComUsuarios(int idTime) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AuthService.tokenKey);
    
    if (token == null) {
      throw Exception('Token de autenticação não encontrado');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/time/getTimeComUsuarios/$idTime'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Erro ao buscar time com usuários');
    }
  }

  Future<Map<String, dynamic>> getUsuariosTime(int idTime) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AuthService.tokenKey);
    
    if (token == null) {
      throw Exception('Token de autenticação não encontrado');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/usuario-time/getUsuariosTime/$idTime'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Erro ao buscar usuários do time');
    }
  }

  Future<void> adicionarUsuarioTime({
    required int idUsuario,
    required int idTime,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AuthService.tokenKey);
    
    if (token == null) {
      throw Exception('Token de autenticação não encontrado');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/usuario-time/adicionar'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'id_usuario': idUsuario,
        'id_time': idTime,
      }),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Erro ao adicionar usuário ao time');
    }
  }

  Future<void> removerUsuarioTime({
    required int idUsuario,
    required int idTime,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AuthService.tokenKey);
    
    if (token == null) {
      throw Exception('Token de autenticação não encontrado');
    }

    final response = await http.delete(
      Uri.parse('$baseUrl/usuario-time/remover?id_usuario=$idUsuario&id_time=$idTime'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Erro ao remover usuário do time');
    }
  }

  Future<Map<String, dynamic>> criarTime({
    required String nome,
    String? descricao,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AuthService.tokenKey);
    
    if (token == null) {
      throw Exception('Token de autenticação não encontrado');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/time/criar'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'nome': nome,
        'descricao': descricao,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      try {
        final idUsuario = await getIdUsuario();
        if (idUsuario != null) {
          await adicionarUsuarioTime(
            idUsuario: idUsuario,
            idTime: data['id'],
          );
        }
      } catch (e) {
        print('Aviso: Não foi possível adicionar o coordenador ao time criado: $e');
      }
      
      return data;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Erro ao criar time');
    }
  }

  Future<void> atualizarTime({
    required int idTime,
    required String nome,
    String? descricao,
    int? deletado,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AuthService.tokenKey);
    
    if (token == null) {
      throw Exception('Token de autenticação não encontrado');
    }

    final response = await http.put(
      Uri.parse('$baseUrl/time/atualizar/$idTime'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'nome': nome,
        'descricao': descricao,
        'deletado': deletado ?? 0,
      }),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Erro ao atualizar time');
    }
  }

  Future<void> deletarTime(int idTime) async {
    try {
      final timeData = await getTimeById(idTime);
      await atualizarTime(
        idTime: timeData['id'],
        nome: timeData['nome'],
        descricao: timeData['descricao'],
        deletado: 1,
      );
    } catch (e) {
      throw Exception('Erro ao deletar time: $e');
    }
  }

  Future<String?> getTipoUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("tp_login");
  }

  Future<int?> getIdUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    final idUsuario = prefs.getString(AuthService.idUsu);
    return idUsuario != null ? int.parse(idUsuario) : null;
  }

  Future<bool> podeGerenciarTime(int idTime) async {
    final tipoUsuario = await getTipoUsuario();
    
    if (tipoUsuario == 'admin') {
      return true;
    }

    if (tipoUsuario == 'coord') {
      try {
        final idUsuario = await getIdUsuario();
        if (idUsuario != null) {
          final timesData = await getTimesUsuarioFunc(idUsuario);
          final times = List<Map<String, dynamic>>.from(timesData['times'] ?? []);
          return times.any((time) => time['id'] == idTime);
        }
      } catch (e) {
        return false;
      }
    }
    
    return false;
  }
} 