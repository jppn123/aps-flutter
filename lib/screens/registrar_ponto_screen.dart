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

class RegistrarPontoScreen extends StatefulWidget {
  @override
  _RegistrarPontoScreenState createState() => _RegistrarPontoScreenState();
}

class _RegistrarPontoScreenState extends State<RegistrarPontoScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  File? _image;
  final ImagePicker _picker = ImagePicker();
  bool _hasEntryRegistered = false;
  bool _hasExitRegistered = false;
  String? _address;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkAttendanceStatus();
  }

  Future<void> _checkAttendanceStatus() async {
    setState(() {
      _hasEntryRegistered = false;
      _hasExitRegistered = false;
    });
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

  Future<void> _takePicture() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        await _ensureLocationPermission();
        Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        String address = await _getAddressFromLatLng(position.latitude, position.longitude);
        setState(() {
          _image = File(photo.path);
          _address = address;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao tirar foto: $e')),
      );
    }
  }

  Future<void> _sendImage(String tipo) async {
    if (_image == null || _address == null) return;
    setState(() {
      _isLoading = true;
    });
    try {
      await _ensureLocationPermission();
      await _attendanceService.registerAttendance(_image!, _address!, tipo);
      String message = tipo == 'entrada' ? 'Entrada registrada com sucesso!' : 'Saída registrada com sucesso!';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      setState(() {
        _image = null;
        _address = null;
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
              if (_canRegister())
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _takePicture,
                  icon: Icon(_isLoading ? Icons.hourglass_empty : Icons.camera_alt),
                  label: Text(_isLoading ? 'Processando...' : _getButtonText()),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              if (_image != null && _canRegister())
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : () => _sendImage(_getTipo()),
                    icon: Icon(_isLoading ? Icons.hourglass_empty : Icons.send),
                    label: Text(_isLoading ? 'Enviando...' : 'Enviar ${_getTipo() == 'entrada' ? 'Entrada' : 'Saída'}'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _getTipo() == 'entrada' ? Colors.green : Colors.orange,
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
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
} 