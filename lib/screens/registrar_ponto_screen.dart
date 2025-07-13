import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../services/attendance_service.dart';
import '../widgets/app_drawer.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import '../services/loja_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/foto_ponto_service.dart';

class RegistrarPontoScreen extends StatefulWidget {
  @override
  _RegistrarPontoScreenState createState() => _RegistrarPontoScreenState();
}

class _RegistrarPontoScreenState extends State<RegistrarPontoScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  final FotoPontoService _fotoPontoService = FotoPontoService();
  final LojaService _lojaService = LojaService();
  File? _image;
  final ImagePicker _picker = ImagePicker();
  bool _hasEntryRegistered = false;
  bool _hasExitRegistered = false;
  String? _address;
  bool _isLoading = false;
  List<Map<String, dynamic>> _lojasHoje = [];
  bool _escalaLoading = false;
  Map<int, Map<String, bool>> _statusPontoLojas = {};
  Map<int, File?> _imagesByLoja = {};
  Map<int, String?> _addressesByLoja = {};
  String? _userType;
  File? _coordinatorImage;
  String? _coordinatorAddress;

  @override
  void initState() {
    super.initState();
    _loadUserType();
    _checkAttendanceStatus();
    _loadLojasHoje();
  }

  Future<void> _loadUserType() async {
    final prefs = await SharedPreferences.getInstance();
    final userType = prefs.getString('tp_login');
    setState(() {
      _userType = userType;
    });
  }

  Future<void> _checkAttendanceStatus() async {
    if (_userType == 'coord') {
      final prefs = await SharedPreferences.getInstance();
      final idUsuario = prefs.getString('id_usu');
      if (idUsuario != null) {
        final now = DateTime.now();
        final data = "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}";
        try {
          final pontos = await _attendanceService.getPontosByDay(int.parse(idUsuario), data);
          setState(() {
            _hasEntryRegistered = pontos.any((p) => p['tipo'] == 'entrada');
            _hasExitRegistered = pontos.any((p) => p['tipo'] == 'saida');
          });
        } catch (e) {
          print('Erro ao verificar status: $e');
        }
      }
    }
  }

  Future<void> _ensureLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Permissão de localização negada');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Permissão de localização permanentemente negada. Vá nas configurações do app para liberar.');
    }
  }

  Future<String> _getAddressFromLatLng(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        return "${place.street}, ${place.subLocality}, ${place.locality}, ${place.administrativeArea}, ${place.country}";
      } else {
        return "Endereço não encontrado";
      }
    } catch (e) {
      return "Erro ao buscar endereço: $e";
    }
  }

  Future<void> _takePicture(int idLoja) async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        await _ensureLocationPermission();
        Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        String address = await _getAddressFromLatLng(position.latitude, position.longitude);
        setState(() {
          _imagesByLoja[idLoja] = File(photo.path);
          _addressesByLoja[idLoja] = address;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao tirar foto: $e')),
      );
    }
  }

  Future<void> _sendImage(String tipo, int idLoja) async {
    final image = _imagesByLoja[idLoja];
    final address = _addressesByLoja[idLoja];
    if (image == null || address == null) return;
    setState(() {
      _isLoading = true;
    });
    try {
      await _ensureLocationPermission();
      final idPonto = await _attendanceService.registerAttendance(address, tipo, idLoja);
      await _fotoPontoService.adicionarFotoPonto(idPonto, image);
      
      String message = tipo == 'entrada' ? 'Entrada registrada com sucesso!' : 'Saída registrada com sucesso!';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      setState(() {
        _imagesByLoja.remove(idLoja);
        _addressesByLoja.remove(idLoja);
      });
      
      await _loadStatusPontoLojas(_lojasHoje);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getButtonText() {
    if (!_hasEntryRegistered) {
      return 'Registrar Entrada';
    } else if (!_hasExitRegistered) {
      return 'Registrar Saída';
    } else {
      return 'Ponto Completo';
    }
  }

  String _getTipo() {
    if (!_hasEntryRegistered) {
      return 'entrada';
    } else if (!_hasExitRegistered) {
      return 'saida';
    } else {
      return '';
    }
  }

  bool _canRegister() {
    return !_hasExitRegistered;
  }

  Future<void> _loadStatusPontoLojas(List<Map<String, dynamic>> lojasHoje) async {
    final prefs = await SharedPreferences.getInstance();
    final idUsuario = prefs.getString('id_usu');
    if (idUsuario == null) return;
    final now = DateTime.now();
    final data = "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}";
    Map<int, Map<String, bool>> status = {};
    for (final loja in lojasHoje) {
      final pontos = await _attendanceService.getPontosByDay(int.parse(idUsuario), data);
      final pontosLoja = pontos.where((p) => p['id_loja'] == loja['id']).toList();
      bool entrada = pontosLoja.any((p) => p['tipo'] == 'entrada');
      bool saida = pontosLoja.any((p) => p['tipo'] == 'saida');
      status[loja['id']] = {'entrada': entrada, 'saida': saida};
    }
    setState(() {
      _statusPontoLojas = status;
    });
  }

  Future<void> _loadLojasHoje() async {
    setState(() {
      _escalaLoading = true;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final idUsuario = prefs.getString('id_usu');
      if (idUsuario == null) {
        setState(() {
          _lojasHoje = [];
          _escalaLoading = false;
        });
        return;
      }
      final lojasUsuario = await _lojaService.getLojasUsuario(int.parse(idUsuario));
      final now = DateTime.now();
      final diaSemana = now.weekday - 1;
      List<Map<String, dynamic>> lojasHoje = [];
      for (final loja in lojasUsuario) {
        final agenda = await _lojaService.getAgendaUsuarioLoja(idUsuario: int.parse(idUsuario), idLoja: loja['id']);
        for (final item in agenda) {
          final dia = int.tryParse(item['dia_semana'].toString()) ?? 0;
          if (dia == diaSemana) {
            lojasHoje.add(loja);
            break;
          }
        }
      }
      setState(() {
        _lojasHoje = lojasHoje;
        _escalaLoading = false;
      });
      await _loadStatusPontoLojas(lojasHoje);
    } catch (e) {
      setState(() {
        _lojasHoje = [];
        _escalaLoading = false;
      });
    }
  }

  Future<void> _takePictureForCoordinator() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        await _ensureLocationPermission();
        Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        String address = await _getAddressFromLatLng(position.latitude, position.longitude);
        setState(() {
          _coordinatorImage = File(photo.path);
          _coordinatorAddress = address;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao tirar foto: $e')),
      );
    }
  }

  Future<void> _sendImageForCoordinator(String tipo) async {
    if (_coordinatorImage == null || _coordinatorAddress == null) return;
    setState(() {
      _isLoading = true;
    });
    try {
      await _ensureLocationPermission();
      final idPonto = await _attendanceService.registerAttendance(_coordinatorAddress!, tipo, null);
      await _fotoPontoService.adicionarFotoPonto(idPonto, _coordinatorImage!);
      
      String message = tipo == 'entrada' ? 'Entrada registrada com sucesso!' : 'Saída registrada com sucesso!';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      setState(() {
        _coordinatorImage = null;
        _coordinatorAddress = null;
        if (tipo == 'entrada') {
          _hasEntryRegistered = true;
        } else {
          _hasExitRegistered = true;
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getCoordinatorButtonText() {
    if (!_hasEntryRegistered) {
      return 'Registrar Entrada';
    } else if (!_hasExitRegistered) {
      return 'Registrar Saída';
    } else {
      return 'Ponto Completo';
    }
  }

  String _getCoordinatorTipo() {
    if (!_hasEntryRegistered) {
      return 'entrada';
    } else if (!_hasExitRegistered) {
      return 'saida';
    } else {
      return '';
    }
  }

  bool _canCoordinatorRegister() {
    return !_hasExitRegistered;
  }

  Widget _buildCoordinatorInterface() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(16),
          margin: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Text(
                'Status do Ponto',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatusItem('Entrada', _hasEntryRegistered),
                  _buildStatusItem('Saída', _hasExitRegistered),
                ],
              ),
            ],
          ),
        ),
        if (_coordinatorImage != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              children: [
                Image.file(
                  _coordinatorImage!,
                  height: 200,
                  width: 200,
                  fit: BoxFit.cover,
                ),
                if (_coordinatorAddress != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      _coordinatorAddress!,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ),
              ],
            ),
          ),
        if (_canCoordinatorRegister())
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _takePictureForCoordinator,
              icon: Icon(_isLoading ? Icons.hourglass_empty : Icons.camera_alt),
              label: Text(_isLoading ? 'Processando...' : _getCoordinatorButtonText()),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ),
        if (_coordinatorImage != null && _canCoordinatorRegister())
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : () => _sendImageForCoordinator(_getCoordinatorTipo()),
              icon: Icon(_isLoading ? Icons.hourglass_empty : Icons.send),
              label: Text(_isLoading ? 'Enviando...' : 'Enviar ${_getCoordinatorTipo() == 'entrada' ? 'Entrada' : 'Saída'}'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _getCoordinatorTipo() == 'entrada' ? Colors.green : Colors.orange,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFuncionarioInterface() {
    return Column(
      children: [
        if (_image != null)
          Image.file(
            _image!,
            height: 300,
            width: 300,
            fit: BoxFit.cover,
          ),
        if (_address != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
            child: Text(
              _address!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
        SizedBox(height: 20),
        _buildLojasHoje(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Registrar Ponto'),
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
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 20),
              if (_userType == 'coord')
                _buildCoordinatorInterface()
              else
                _buildFuncionarioInterface(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLojasHoje() {
    if (_escalaLoading) return Center(child: CircularProgressIndicator());
    if (_lojasHoje.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.store_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Nenhuma loja agendada para hoje',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Você não possui lojas agendadas para hoje.\nEntre em contato com seu coordenador.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }
    final diasSemana = ['Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado'];
    final now = DateTime.now();
    final diaSemanaIndex = now.weekday - 1;
    final nomeDia = (diaSemanaIndex >= 0 && diaSemanaIndex < diasSemana.length) ? diasSemana[diaSemanaIndex] : '';
    final dataFormatada = "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}";
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Lojas do dia $dataFormatada (${nomeDia.toLowerCase()}):', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        ..._lojasHoje.map((loja) => Card(
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              leading: Icon(Icons.store, color: Colors.blue),
              title: Text(loja['nome'] ?? ''),
              subtitle: Text(loja['endereco'] ?? ''),
              tilePadding: EdgeInsets.symmetric(horizontal: 16.0),
              childrenPadding: EdgeInsets.zero,
              children: [
                Container(
                  color: Colors.transparent,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildStatusItem('Entrada', _statusPontoLojas[loja['id']]?['entrada'] ?? false),
                            SizedBox(width: 24),
                            _buildStatusItem('Saída', _statusPontoLojas[loja['id']]?['saida'] ?? false),
                          ],
                        ),
                      ),
                      if (_canRegisterForLoja(loja['id']))
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : () => _takePicture(loja['id']),
                            icon: Icon(_isLoading ? Icons.hourglass_empty : Icons.camera_alt),
                            label: Text(_isLoading ? 'Processando...' : _getButtonTextForLoja(loja['id'])),
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                          ),
                        ),
                      if (_imagesByLoja[loja['id']] != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Column(
                            children: [
                              Image.file(
                                _imagesByLoja[loja['id']]!,
                                height: 200,
                                width: 200,
                                fit: BoxFit.cover,
                              ),
                              if (_addressesByLoja[loja['id']] != null)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Text(
                                    _addressesByLoja[loja['id']]!,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      if (_imagesByLoja[loja['id']] != null && _canRegisterForLoja(loja['id']))
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : () => _sendImage(_getTipoForLoja(loja['id']), loja['id']),
                            icon: Icon(_isLoading ? Icons.hourglass_empty : Icons.send),
                            label: Text(_isLoading ? 'Enviando...' : 'Enviar ${_getTipoForLoja(loja['id']) == 'entrada' ? 'Entrada' : 'Saída'}'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _getTipoForLoja(loja['id']) == 'entrada' ? Colors.green : Colors.orange,
                              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        )),
        SizedBox(height: 16),
      ],
    );
  }

  Widget _buildStatusItem(String label, bool registered) {
    return Column(
      children: [
        Icon(
          registered ? Icons.check_circle : Icons.radio_button_unchecked,
          color: registered ? Colors.green : Colors.grey,
        ),
        SizedBox(height: 4),
        Text(label),
      ],
    );
  }

  String _getButtonTextForLoja(int idLoja) {
    final status = _statusPontoLojas[idLoja];
    if (status == null) return 'Registrar Entrada';
    
    if (!status['entrada']!) {
      return 'Registrar Entrada';
    } else if (!status['saida']!) {
      return 'Registrar Saída';
    } else {
      return 'Ponto Completo';
    }
  }

  String _getTipoForLoja(int idLoja) {
    final status = _statusPontoLojas[idLoja];
    if (status == null) return 'entrada';
    
    if (!status['entrada']!) {
      return 'entrada';
    } else if (!status['saida']!) {
      return 'saida';
    } else {
      return '';
    }
  }

  bool _canRegisterForLoja(int idLoja) {
    final status = _statusPontoLojas[idLoja];
    if (status == null) return true;
    return !status['saida']!;
  }
} 