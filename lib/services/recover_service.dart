import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class RecoverService {
  
  final AuthService _authService = AuthService();
  final String baseUrl = AuthService.baseUrl;
  String? _recoveryToken;

  Future<void> enviarEmail(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login/enviarEmail'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _recoveryToken = data['token'];
      print("email enviado, token de recuperação salvo");
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Erro ao enviar email');
    }
  }

  Future<void> validarCodigo(String codigo) async {
    if (_recoveryToken == null) {
      throw Exception('Token de recuperação não encontrado. Solicite o envio do email novamente.');
    }
    final response = await http.post(
      Uri.parse('$baseUrl/login/validarCodigo'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_recoveryToken',
      },
      body: jsonEncode({'codigo': codigo}),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Erro ao validar código');
    }
  }

  Future<void> mudarSenha({required String senhaAntiga, required String senhaNova, required String senhaNovaConfirmada}) async {
    if (_recoveryToken == null) {
      throw Exception('Token de recuperação não encontrado. Solicite o envio do email novamente.');
    }
    final response = await http.post(
      Uri.parse('$baseUrl/login/mudarSenha'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_recoveryToken',
      },
      body: jsonEncode({
        'senhaAntiga': senhaAntiga,
        'senhaNova': senhaNova,
        'senhaNovaConfirmada': senhaNovaConfirmada,
      }),
    );
    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Erro ao mudar senha');
    }
  }
}
