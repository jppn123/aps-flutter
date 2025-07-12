import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AttendanceService {
  final AuthService _authService = AuthService();

  Future<void> registerAttendance(File photo, String address, String tipo) async {
    try {
      
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      String? token = await _authService.getToken();
      if (token == null) {
        throw Exception('Usuário não autenticado');
      }

      // String? userId = await _authService.getUserId();
      // if (userId == null) {
      //   throw Exception('ID do usuário não encontrado');
      // }

      List<int> imageBytes = await photo.readAsBytes();
      String base64Image = base64Encode(imageBytes);

      Map<String, dynamic> payload = {
        'id_usuario': 1,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'horario': DateTime.now().toIso8601String(),
        'endereco': address,
        'foto': base64Image,
        'tipo': tipo,
      };

      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/ponto/registrar'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(payload),
      );

      if (response.statusCode != 200) {
        throw Exception('Erro ao registrar ponto: ${response.body}');
      }
    } catch (e) {
      throw Exception('Erro ao registrar ponto: $e');
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