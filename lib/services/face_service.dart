import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'auth_service.dart';

class FaceService {
  final AuthService _authService = AuthService();
  final String baseUrl = AuthService.baseUrl;

  Future<void> registerFace(File imageFile) async {
    try {
      if (!await imageFile.exists()) {
        throw Exception('Arquivo de imagem não encontrado');
      }
      
      final fileSize = await imageFile.length();
      if (fileSize == 0) {
        throw Exception('Arquivo de imagem está vazio');
      }

      String? token = await _authService.getToken();
      if (token == null) {
        throw Exception('Usuário não autenticado');
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/face/register'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      
      
      String contentType = 'image/jpeg';
      String extension = imageFile.path.split('.').last.toLowerCase();
      if (extension == 'png') {
        contentType = 'image/png';
      } else if (extension == 'jpg' || extension == 'jpeg') {
        contentType = 'image/jpeg';
      } else if (extension == 'gif') {
        contentType = 'image/gif';
      } else if (extension == 'webp') {
        contentType = 'image/webp';
      }

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
          contentType: MediaType.parse(contentType),
        ),
      );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
      } else {
        final error = jsonDecode(responseBody);
        String errorMessage = error['detail'] ?? 'Erro ao cadastrar face';
        
        if (response.statusCode == 400) {
          if (errorMessage.contains('Nenhum rosto detectado')) {
            errorMessage = 'Nenhum rosto detectado na imagem. Certifique-se de que sua face está visível, bem iluminada e centralizada.';
          } else if (errorMessage.contains('Arquivo vazio')) {
            errorMessage = 'O arquivo de imagem está vazio ou corrompido.';
          } else if (errorMessage.contains('Erro ao processar imagem')) {
            errorMessage = 'Erro ao processar a imagem. Verifique se a foto está nítida e bem iluminada.';
          }
        } else if (response.statusCode == 403) {
          errorMessage = 'Token de autenticação inválido. Faça login novamente.';
        } else if (response.statusCode == 404) {
          errorMessage = 'Usuário não encontrado. Verifique se você está logado corretamente.';
        }
        
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        throw e; 
      }
      throw Exception('Erro ao cadastrar face: $e');
    }
  }

  Future<String> loginFace(File imageFile) async {
    try {
    
      try {
        final testResponse = await http.get(Uri.parse('$baseUrl/'));
      } catch (e) {
        
        throw Exception('Não foi possível conectar ao servidor. Verifique se o backend está rodando.');
      }
      
      if (!await imageFile.exists()) {
        throw Exception('Arquivo de imagem não encontrado');
      }
      
      final fileSize = await imageFile.length();
      
      if (fileSize == 0) {
        throw Exception('Arquivo de imagem está vazio');
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/face/login'),
      );

      
      String contentType = 'image/jpeg';
      String extension = imageFile.path.split('.').last.toLowerCase();
      if (extension == 'png') {
        contentType = 'image/png';
      } else if (extension == 'jpg' || extension == 'jpeg') {
        contentType = 'image/jpeg';
      } else if (extension == 'gif') {
        contentType = 'image/gif';
      } else if (extension == 'webp') {
        contentType = 'image/webp';
      }

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
          contentType: MediaType.parse(contentType),
        ),
      );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      
      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
        final token = data['token'];
        if (token == null) {
          
          throw Exception('Token não encontrado na resposta');
        }
        
        await _authService.saveToken(token);
        await _authService.validarToken(token);

        return token;
      } else {
        final error = jsonDecode(responseBody);
        String errorMessage = error['detail'] ?? 'Erro no login facial';
        
        if (response.statusCode == 400) {
          if (errorMessage.contains('Nenhum rosto detectado')) {
            errorMessage = 'Nenhum rosto detectado na imagem. Certifique-se de que sua face está visível, bem iluminada e centralizada.';
          } else if (errorMessage.contains('Arquivo vazio')) {
            errorMessage = 'O arquivo de imagem está vazio ou corrompido.';
          } else if (errorMessage.contains('Erro ao processar imagem')) {
            errorMessage = 'Erro ao processar a imagem. Verifique se a foto está nítida e bem iluminada.';
          }
        } else if (response.statusCode == 401) {
          errorMessage = 'Face não reconhecida. Verifique se você já cadastrou sua face ou tente novamente com melhor iluminação.';
        } else if (response.statusCode == 404) {
          errorMessage = 'Nenhuma face cadastrada no sistema. Faça login tradicional e cadastre sua face primeiro.';
        } else if (response.statusCode == 500) {
          errorMessage = 'Erro interno do servidor. Tente novamente em alguns instantes.';
        }
        
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        throw e;
      }
      throw Exception('Erro no login facial: $e');
    }
  }
} 