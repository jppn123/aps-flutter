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
import '../services/loja_service.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final UserService _userService = UserService();
  final LojaService _lojaService = LojaService();
  String _userName = '';
  bool _isLoading = true;
  String? _tpLogin;
  int? _idUsuario;
  List<Map<String, dynamic>> _lojasUsuario = [];
  Map<int, Map<int, Map<String, dynamic>>> _agendaPorDiaPeriodo = {};
  bool _escalaLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _loadEscala();
  }

  Future<void> _loadUserName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final idUsuario = prefs.getString(AuthService.idUsu);
      final tpLogin = prefs.getString('tp_login');
      setState(() {
        _tpLogin = tpLogin;
        _idUsuario = idUsuario != null ? int.tryParse(idUsuario) : null;
      });
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

  Future<void> _loadEscala() async {
    setState(() {
      _escalaLoading = true;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final idUsuario = prefs.getString(AuthService.idUsu);
      if (idUsuario == null) {
        setState(() {
          _lojasUsuario = [];
          _agendaPorDiaPeriodo = {};
          _escalaLoading = false;
        });
        return;
      }
      final lojasUsuario = await _lojaService.getLojasUsuario(int.parse(idUsuario));
      Map<int, Map<int, Map<String, dynamic>>> agendaPorDiaPeriodo = {};
      for (int periodo = 0; periodo < 4; periodo++) {
        agendaPorDiaPeriodo[periodo] = {};
      }
      for (final loja in lojasUsuario) {
        final agenda = await _lojaService.getAgendaUsuarioLoja(idUsuario: int.parse(idUsuario), idLoja: loja['id']);
        for (final item in agenda) {
          final dia = int.tryParse(item['dia_semana'].toString()) ?? 0;
          final periodo = int.tryParse(item['periodo'].toString()) ?? 0;
          agendaPorDiaPeriodo[periodo] ??= {};
          agendaPorDiaPeriodo[periodo]![dia] = {...item, 'loja': loja};
        }
      }
      setState(() {
        _lojasUsuario = lojasUsuario;
        _agendaPorDiaPeriodo = agendaPorDiaPeriodo;
        _escalaLoading = false;
      });
    } catch (e) {
      setState(() {
        _lojasUsuario = [];
        _agendaPorDiaPeriodo = {};
        _escalaLoading = false;
      });
    }
  }

  Widget _buildEscalaTabela() {
    if ((_tpLogin?.toLowerCase() ?? '') != 'func') return SizedBox.shrink();
    if (_lojasUsuario.isEmpty) return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Text('Nenhuma escala cadastrada para você ainda.', style: TextStyle(color: Colors.grey[700])),
    );
    const diasSemana = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];
    const periodos = ['Loja 1', 'Loja 2', 'Loja 3', 'Loja 4'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Minha Escala Semanal', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        SizedBox(height: 12),
        _escalaLoading
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: [
                    DataColumn(label: Text('Semana')),
                    ...diasSemana.map((d) => DataColumn(label: Text(d))).toList(),
                  ],
                  rows: [
                    for (int periodo = 0; periodo < periodos.length; periodo++)
                      DataRow(
                        cells: [
                          DataCell(Text(periodos[periodo])),
                          ...List.generate(6, (dia) {
                            final agenda = _agendaPorDiaPeriodo[periodo]?[dia];
                            return DataCell(
                              agenda != null
                                  ? Text(agenda['loja']['nome'] ?? '', overflow: TextOverflow.ellipsis)
                                  : SizedBox.shrink(),
                            );
                          }),
                        ],
                      ),
                  ],
                ),
              ),
        SizedBox(height: 24),
      ],
    );
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
            _buildEscalaTabela(),
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
                                label: Flexible(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(tpLogin == 'admin' ? 'Criar Usuário' : 'Registrar Ponto'),
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(vertical: 24),
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