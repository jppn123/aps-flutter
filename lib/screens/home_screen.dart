import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../services/attendance_service.dart';
import '../services/face_service.dart';
import '../providers/auth_provider.dart';
import 'face_capture_screen.dart';
import '../widgets/app_drawer.dart';
import 'login_screen.dart';
import '../screens/user_data_screen.dart';
import '../screens/team_screen.dart';
import '../screens/registrar_ponto_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'criar_usuario_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final String userName = 'João da Silva';
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
              'Olá, $userName',
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
                        SizedBox(
                          width: double.infinity,
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
                              padding: EdgeInsets.symmetric(vertical: 28),
                              textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
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