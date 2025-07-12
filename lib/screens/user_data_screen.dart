import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'face_capture_screen.dart';
import '../services/face_service.dart';
import '../services/user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import 'edit_user_data_screen.dart';

class UserDataScreen extends StatefulWidget {
  @override
  _UserDataScreenState createState() => _UserDataScreenState();
}

class _UserDataScreenState extends State<UserDataScreen> {
  final UserService _userService = UserService();
  Map<String, String> userData = {};
  bool _isLoading = true;
  bool _isFaceRegistered = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final prefs = await SharedPreferences.getInstance();
      final idUsuario = prefs.getString(AuthService.idUsu);
      
      if (idUsuario == null) {
        throw Exception('ID do usuário não encontrado');
      }

      final userDataResponse = await _userService.getUsuario(int.parse(idUsuario));
      
      setState(() {
        userData = {
          'NOME': userDataResponse['nome'] ?? 'Não informado',
          'CPF': userDataResponse['cpf'] ?? 'Não informado',
          'DATA DE NASCIMENTO': userDataResponse['data_nascimento'] ?? 'Não informado',
          'TELEFONE': userDataResponse['telefone'] ?? 'Não informado',
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _navigateToEditScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditUserDataScreen(currentData: userData),
      ),
    ).then((updated) {
      if (updated == true) {
        _loadUserData();
      }
    });
  }

  void _showFaceRegistrationInstructions() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Dicas para Cadastro Facial'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Para um melhor cadastro:'),
              SizedBox(height: 8),
              Text('• Certifique-se de que sua face está bem iluminada'),
              Text('• Olhe diretamente para a câmera'),
              Text('• Mantenha uma distância adequada'),
              Text('• Evite óculos escuros ou bonés'),
              Text('• Certifique-se de que sua face está visível'),
              SizedBox(height: 8),
              Text('Esta foto será usada para reconhecimento futuro.', 
                style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _navigateToFaceRegistration();
              },
              child: Text('Cadastrar'),
            ),
          ],
        );
      },
    );
  }

  void _navigateToFaceRegistration() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FaceCaptureScreen(
          isRegistration: true,
          onSuccess: (message) {
            setState(() {
              _isFaceRegistered = true;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Face cadastrada com sucesso!'),
                backgroundColor: Colors.green,
              ),
            );
          },
          onError: (error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erro ao cadastrar face: $error'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 5),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dados do Usuário'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      drawer: AppDrawer(),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Carregando dados do usuário...'),
                ],
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, color: Colors.red, size: 64),
                      SizedBox(height: 16),
                      Text(
                        'Erro ao carregar dados',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadUserData,
                        child: Text('Tentar Novamente'),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...userData.entries.map((entry) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            Text('${entry.key}: ', style: TextStyle(fontWeight: FontWeight.bold)),
                            Expanded(child: Text(entry.value)),
                          ],
                        ),
                      )),
                      SizedBox(height: 32),
                      Container(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _navigateToEditScreen,
                          child: Text('Editar Dados'),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      SizedBox(height: 25),
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: _showFaceRegistrationInstructions,
                          icon: Icon(Icons.face),
                          label: Text(_isFaceRegistered ? 'Face já cadastrada' : 'Cadastrar Face'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
} 