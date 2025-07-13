import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/login_screen.dart';
import '../screens/home_screen.dart';
import '../screens/registrar_ponto_screen.dart';
import '../screens/user_data_screen.dart';
import '../screens/team_screen.dart';
import '../screens/criar_usuario_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/loja_crud_screen.dart';

class AppDrawer extends StatelessWidget {
  final VoidCallback? onLogout;

  const AppDrawer({Key? key, this.onLogout}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: FutureBuilder<String?>(
        future: _getTpLogin(),
        builder: (context, snapshot) {
          final tpLogin = snapshot.data;
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                ),
                child: Text(
                  'Bem-vindo!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
              ),
              ListTile(
                leading: Icon(Icons.home),
                title: Text('Início'),
                onTap: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => HomeScreen()),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.person),
                title: Text('Meus Dados'),
                onTap: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => UserDataScreen()),
                  );
                },
              ),
              ListTile(
                leading: Icon(tpLogin == 'admin' ? Icons.person_add : Icons.camera_alt),
                title: Text(tpLogin == 'admin' ? 'Criar Usuário' : 'Registrar Ponto'),
                onTap: () {
                  if (tpLogin == 'admin') {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => CriarUsuarioScreen()),
                    );
                  } else {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => RegistrarPontoScreen()),
                    );
                  }
                },
              ),
              ListTile(
                leading: Icon(Icons.group),
                title: Text('Minha Equipe'),
                onTap: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => TeamScreen()),
                  );
                },
              ),
              if (tpLogin == 'admin' || tpLogin == 'coord')
                ListTile(
                  leading: Icon(Icons.store),
                  title: Text('Lojas'),
                  onTap: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => LojaCrudScreen()),
                    );
                  },
                ),
              ListTile(
                leading: Icon(Icons.logout),
                title: Text('Sair'),
                onTap: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                    (route) => false,
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Future<String?> _getTpLogin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('tp_login');
  }
} 