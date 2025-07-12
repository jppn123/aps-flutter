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

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  final FaceService _faceService = FaceService();
  File? _image;
  final ImagePicker _picker = ImagePicker();
  bool _hasEntryRegistered = false;
  bool _hasExitRegistered = false;
  String? _address;
  bool _isLoading = false;
  bool _isFaceRegistered = false;

  @override
  void initState() {
    super.initState();
    _checkAttendanceStatus();
  }

  Future<void> _checkAttendanceStatus() async {
    // Aqui você pode implementar uma verificação com o backend
    // para ver se o usuário já registrou entrada hoje
    // Por enquanto, vamos assumir que não há registros
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

  Future<void> _registerFace() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (photo != null) {
        await _faceService.registerFace(File(photo.path));
        setState(() {
          _isFaceRegistered = true;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Face cadastrada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao cadastrar face: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 20), // Espaço extra no topo
              // Status do ponto
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
              
              // Cadastro de Face
              if (!_isFaceRegistered)
                Container(
                  width: double.infinity,
                  margin: EdgeInsets.symmetric(horizontal: 16),
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _showFaceRegistrationInstructions,
                    icon: Icon(_isLoading ? Icons.hourglass_empty : Icons.face),
                    label: Text(_isLoading ? 'Cadastrando...' : 'Cadastrar Face'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
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
              
              // Botão principal
              if (_canRegister())
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _takePicture,
                  icon: Icon(_isLoading ? Icons.hourglass_empty : Icons.camera_alt),
                  label: Text(_isLoading ? 'Processando...' : _getButtonText()),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              
              // Botão de enviar (quando há foto)
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
              
              // Mensagem quando ponto está completo
              if (!_canRegister())
                Container(
                  padding: EdgeInsets.all(16),
                  margin: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Ponto registrado com sucesso!',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green[800]),
                  ),
                ),
              SizedBox(height: 20), // Espaço extra no final
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusItem(String label, bool isCompleted) {
    return Column(
      children: [
        Icon(
          isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
          color: isCompleted ? Colors.green : Colors.grey,
          size: 24,
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isCompleted ? Colors.green : Colors.grey,
            fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}