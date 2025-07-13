import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../services/attendance_service.dart';
import '../services/face_service.dart';
import '../services/user_service.dart';
import '../providers/auth_provider.dart';
import 'face_capture_screen.dart';
import '../widgets/app_drawer.dart';
import 'login_screen.dart';
import '../screens/user_data_screen.dart';
import '../screens/team_screen.dart';
import '../screens/registrar_ponto_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import 'criar_usuario_screen.dart';
import '../screens/loja_crud_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final UserService _userService = UserService();
  String _userName = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final idUsuario = prefs.getString(AuthService.idUsu);
      
      if (idUsuario != null) {
        final userData = await _userService.getUsuario(int.parse(idUsuario));
        setState(() {
          _userName = userData['nome'] ?? 'Usuário';
          _isLoading = false;
        });
      } else {
        setState(() {
          _userName = 'Usuário';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _userName = 'Usuário';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Página Inicial'),
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
        padding: EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 30),
            Text(
              'Olá, ${_isLoading ? '...' : _userName}',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: Center(
                child: FutureBuilder<String?>(
                  future: _getTpLogin(),
                  builder: (context, snapshot) {
                    final tpLogin = snapshot.data;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (context) => UserDataScreen()),
                                  );
                                },
                                icon: Icon(Icons.person),
                                label: Text('Meus Dados'),
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(vertical: 24),
                                ),
                              ),
                            ),
                            SizedBox(width: 15),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (context) => TeamScreen()),
                                  );
                                },
                                icon: Icon(Icons.group),
                                label: Text('Minha Equipe'),
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(vertical: 24),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 15),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  if (tpLogin == 'admin') {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(builder: (context) => CriarUsuarioScreen()),
                                    );
                                  } else {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(builder: (context) => RegistrarPontoScreen()),
                                    );
                                  }
                                },
                                icon: Icon(tpLogin == 'admin' ? Icons.person_add : Icons.camera_alt),
                                label: Text(tpLogin == 'admin' ? 'Criar Usuário' : 'Registrar Ponto'),
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(vertical: 24),
                                  textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            if (tpLogin == 'admin' || tpLogin == 'coord') ...[
                              SizedBox(width: 15),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(builder: (context) => LojaCrudScreen()),
                                    );
                                  },
                                  icon: Icon(Icons.store),
                                  label: Text('Lojas'),
                                  style: ElevatedButton.styleFrom(
                                    padding: EdgeInsets.symmetric(vertical: 24),
                                    textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _getTpLogin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('tp_login');
  }
}