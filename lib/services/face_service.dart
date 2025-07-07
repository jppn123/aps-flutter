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
      // Validar se o arquivo existe e não está vazio
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
      
      // Determinar o tipo MIME correto baseado na extensão do arquivo
      String contentType = 'image/jpeg'; // padrão
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
        print('✅ Face cadastrada com sucesso: ${data['msg']}');
      } else {
        final error = jsonDecode(responseBody);
        String errorMessage = error['detail'] ?? 'Erro ao cadastrar face';
        
        // Tratar erros específicos do backend InsightFace
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
        throw e; // Re-throw se já é uma Exception formatada
      }
      throw Exception('Erro ao cadastrar face: $e');
    }
  }

  Future<String> loginFace(File imageFile) async {
    try {
      print('🔍 Iniciando login facial...');
      
      // Teste de conectividade
      try {
        print('🌐 Testando conectividade com o backend...');
        final testResponse = await http.get(Uri.parse('$baseUrl/'));
        print('✅ Backend acessível: ${testResponse.statusCode}');
      } catch (e) {
        print('❌ Erro de conectividade: $e');
        throw Exception('Não foi possível conectar ao servidor. Verifique se o backend está rodando.');
      }
      
      // Validar se o arquivo existe e não está vazio
      if (!await imageFile.exists()) {
        print('❌ Arquivo não existe: ${imageFile.path}');
        throw Exception('Arquivo de imagem não encontrado');
      }
      
      final fileSize = await imageFile.length();
      print('📁 Tamanho do arquivo: $fileSize bytes');
      if (fileSize == 0) {
        print('❌ Arquivo vazio');
        throw Exception('Arquivo de imagem está vazio');
      }

      print('🌐 Enviando requisição para: $baseUrl/face/login');
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/face/login'),
      );

      // Determinar o tipo MIME correto baseado na extensão do arquivo
      String contentType = 'image/jpeg'; // padrão
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

      print('📤 Adicionando arquivo ao request...');
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
          contentType: MediaType.parse(contentType),
        ),
      );

      print('🚀 Enviando requisição...');
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      
      print('📥 Resposta recebida: ${response.statusCode}');
      print('📄 Corpo da resposta: $responseBody');

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
        final token = data['token'];
        if (token == null) {
          print('❌ Token não encontrado na resposta');
          throw Exception('Token não encontrado na resposta');
        }
        
        print('✅ Login facial realizado com sucesso usando InsightFace');
        // Salvar o token retornado pelo backend
        await _authService.saveToken(token);
        return token;
      } else {
        final error = jsonDecode(responseBody);
        String errorMessage = error['detail'] ?? 'Erro no login facial';
        
        print('❌ Erro no login: $errorMessage');
        
        // Tratar erros específicos do backend InsightFace
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
      print('💥 Erro no login facial: $e');
      if (e.toString().contains('Exception:')) {
        throw e; // Re-throw se já é uma Exception formatada
      }
      throw Exception('Erro no login facial: $e');
    }
  }
} 