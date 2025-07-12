import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'face_capture_screen.dart';
import '../services/face_service.dart';

class UserDataScreen extends StatefulWidget {
  @override
  _UserDataScreenState createState() => _UserDataScreenState();
}

class _UserDataScreenState extends State<UserDataScreen> {
  // Mock dos dados do usuário
  final Map<String, String> userData = const {
    'NOME': 'João da Silva',
    'CPF': '123.456.789-00',
    'DATA DE NASCIMENTO': '01/01/1990',
    'TELEFONE': '(11) 91234-5678',
  };
  bool _isFaceRegistered = false;

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
      body: Padding(
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
            Center(
              child: ElevatedButton.icon(
                onPressed: _showFaceRegistrationInstructions,
                icon: Icon(Icons.face),
                label: Text(_isFaceRegistered ? 'Face já cadastrada' : 'Cadastrar Face'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
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