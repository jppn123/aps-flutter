import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import '../services/face_service.dart';
import '../widgets/app_drawer.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'dart:math' as math;

class FaceCaptureScreen extends StatefulWidget {
  final bool isRegistration;
  final Function(String)? onSuccess;
  final Function(String)? onError;

  FaceCaptureScreen({
    required this.isRegistration,
    this.onSuccess,
    this.onError,
  });

  @override
  _FaceCaptureScreenState createState() => _FaceCaptureScreenState();
}

class _FaceCaptureScreenState extends State<FaceCaptureScreen> with WidgetsBindingObserver {
  final ImagePicker _picker = ImagePicker();
  final FaceService _faceService = FaceService();
  bool _isLoading = false;
  File? _capturedImage;
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isCameraInitializing = false;
  bool _isCapturing = false;
  String _errorMessage = '';
  String _successMessage = '';
  String _processingMessage = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeCamera();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _disposeCamera();
    } else if (state == AppLifecycleState.resumed && _capturedImage == null) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    if (_isCameraInitialized || _isCameraInitializing) return;
    _isCameraInitializing = true;
    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      print('Erro ao inicializar câmera: $e');
    } finally {
      _isCameraInitializing = false;
    }
  }

  Future<void> _disposeCamera() async {
    if (_cameraController != null) {
      await _cameraController!.dispose();
      _cameraController = null;
      if (mounted) {
        setState(() {
          _isCameraInitialized = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isRegistration ? 'Cadastrar Face' : 'Login Facial'),
        backgroundColor: widget.isRegistration ? Colors.purple : Colors.blue,
        actions: [
          if(widget.isRegistration)
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Área de captura com câmera em tempo real
            LayoutBuilder(
              builder: (context, constraints) {
                final double previewWidth = constraints.maxWidth - 32; // 16 de margem de cada lado
                final double aspectRatio = 3 / 4; // Proporção comum de câmera frontal
                final double previewHeight = previewWidth / aspectRatio;
                return Column(
                  children: [
                    Container(
                      width: previewWidth,
                      height: previewHeight,
                      margin: EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (_cameraController != null && _isCameraInitialized)
                              Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.rotationY(math.pi),
                                child: AspectRatio(
                                  aspectRatio: aspectRatio,
                                  child: CameraPreview(_cameraController!),
                                ),
                              ),
                            if (_isCameraInitialized)
                              _buildPositioningOverlay(),
                            if (_isCameraInitializing)
                              Container(
                                color: Colors.black54,
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        'Inicializando câmera...',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            if (_processingMessage.isNotEmpty)
                              Container(
                                color: Colors.black54,
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        _processingMessage,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            if (_successMessage.isNotEmpty)
                              Container(
                                color: Colors.green.withOpacity(0.9),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: Colors.white,
                                        size: 64,
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        _successMessage,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            if (_errorMessage.isNotEmpty)
                              Positioned(
                                top: 50,
                                left: 20,
                                right: 20,
                                child: Container(
                                  padding: EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.error, color: Colors.white),
                                          SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Erro',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.close, color: Colors.white),
                                            onPressed: () {
                                              setState(() {
                                                _errorMessage = '';
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        _errorMessage,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    // Botão de captura fora da área da câmera
                    if (_isCameraInitialized && _capturedImage == null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
                        child: Center(
                          child: FloatingActionButton(
                            onPressed: _isCapturing ? null : _captureAndRegister,
                            backgroundColor: widget.isRegistration ? Colors.purple : Colors.blue,
                            child: _isCapturing
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Icon(Icons.camera_alt, color: Colors.white),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            
            // Área de controles
            Container(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  // Instruções detalhadas
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dicas para melhor detecção:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 8),
                        _buildTip('• Mantenha boa iluminação'),
                        _buildTip('• Olhe diretamente para a câmera'),
                        _buildTip('• Mantenha distância de 30-50cm'),
                        _buildTip('• Evite sombras no rosto'),
                        _buildTip('• Certifique-se de que o rosto está centralizado'),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 16),
                  
                  // Botões de ação
                  if (_capturedImage != null)
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _processImage,
                            icon: Icon(_isLoading ? Icons.hourglass_empty : Icons.check),
                            label: Text(_isLoading ? 'Processando...' : 'Confirmar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : () {
                              setState(() {
                                _capturedImage = null;
                              });
                            },
                            icon: Icon(Icons.refresh),
                            label: Text('Tirar Nova Foto'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  
                  // Espaço extra no final para evitar overflow
                  SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTip(String tip) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4),
      child: Text(
        tip,
        style: TextStyle(fontSize: 14),
      ),
    );
  }

  Future<void> _captureAndRegister() async {
    if (!_cameraController!.value.isInitialized) {
      _showError('Câmera não inicializada. Aguarde um momento.');
      return;
    }

    setState(() {
      _isCapturing = true;
      _errorMessage = '';
      _successMessage = '';
    });

    try {
      // Capturar imagem
      final image = await _cameraController!.takePicture();
      if (image == null) {
        throw Exception('Falha ao capturar imagem');
      }

      // Mostrar feedback de processamento
      setState(() {
        _processingMessage = widget.isRegistration 
          ? 'Processando cadastro facial...'
          : 'Processando reconhecimento facial...';
      });

      // Processar baseado no tipo (login ou registro)
      if (widget.isRegistration) {
        // Cadastrar face
        await _faceService.registerFace(File(image.path));
        
        // Sucesso
        setState(() {
          _successMessage = 'Face cadastrada com sucesso!';
          _processingMessage = '';
        });

        // Aguardar um pouco para mostrar a mensagem de sucesso
        await Future.delayed(Duration(milliseconds: 1500));

        // Voltar para a tela anterior
        if (mounted) {
          Navigator.pop(context, true);
          if (widget.onSuccess != null) {
            widget.onSuccess!('Face cadastrada com sucesso!');
          }
        }
      } else {
        // Fazer login facial
        final token = await _faceService.loginFace(File(image.path));
        
        // Sucesso
        setState(() {
          _successMessage = 'Login realizado com sucesso!';
          _processingMessage = '';
        });

        // Aguardar um pouco para mostrar a mensagem de sucesso
        await Future.delayed(Duration(milliseconds: 1500));

        // Voltar para a tela anterior
        if (mounted) {
          Navigator.pop(context, true);
          if (widget.onSuccess != null) {
            widget.onSuccess!('Login facial realizado com sucesso!');
          }
        }
      }

    } catch (e) {
      String errorMessage = e.toString().replaceAll('Exception: ', '');
      
      // Melhorar mensagens de erro específicas do InsightFace
      if (errorMessage.contains('Nenhum rosto detectado')) {
        errorMessage = 'Nenhum rosto detectado. Certifique-se de que:\n• Sua face está visível na câmera\n• A iluminação está boa\n• Você está centralizado no frame\n• Não há obstáculos na frente do rosto';
      } else if (errorMessage.contains('Erro ao processar imagem')) {
        errorMessage = 'Erro ao processar a imagem. Verifique se:\n• A foto está nítida e bem iluminada\n• Sua face está bem posicionada\n• Não há reflexos ou sombras excessivas';
      } else if (errorMessage.contains('Token de autenticação inválido')) {
        errorMessage = 'Sessão expirada. Faça login novamente.';
      } else if (errorMessage.contains('Usuário não encontrado')) {
        errorMessage = 'Usuário não encontrado. Verifique se você está logado corretamente.';
      } else if (errorMessage.contains('Arquivo vazio')) {
        errorMessage = 'Erro ao capturar imagem. Tente novamente.';
      } else if (errorMessage.contains('Face não reconhecida')) {
        errorMessage = 'Face não reconhecida. Verifique se:\n• Você já cadastrou sua face\n• A iluminação está adequada\n• Sua face está bem posicionada';
      } else if (errorMessage.contains('Nenhuma face cadastrada')) {
        errorMessage = 'Nenhuma face cadastrada no sistema.\nFaça login tradicional primeiro e cadastre sua face.';
      }

      setState(() {
        _errorMessage = errorMessage;
        _processingMessage = '';
      });
      
      // Chamar callback de erro
      if (widget.onError != null) {
        widget.onError!(errorMessage);
      }
    } finally {
      setState(() {
        _isCapturing = false;
      });
    }
  }

  Future<void> _processImage() async {
    if (_capturedImage == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.isRegistration) {
        await _faceService.registerFace(_capturedImage!);
        _showSuccess('Face cadastrada com sucesso!');
      } else {
        final token = await _faceService.loginFace(_capturedImage!);
        _showSuccess('Login facial realizado com sucesso!');
      }
      
      // Aguardar um pouco para mostrar a mensagem
      await Future.delayed(Duration(seconds: 2));
      
      // Fechar a tela e chamar callback
      Navigator.of(context).pop();
      if (widget.onSuccess != null) {
        widget.onSuccess!('Sucesso');
      }
    } catch (e) {
      _showError('Erro: $e');
      if (widget.onError != null) {
        widget.onError!(e.toString());
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 5),
      ),
    );
  }

  Widget _buildPositioningOverlay() {
    return Stack(
      children: [
        // Guias visuais para posicionamento
        Positioned.fill(
          child: CustomPaint(
            painter: FaceGuidePainter(),
          ),
        ),
        
        // Overlay com instruções
        Positioned(
          bottom: 0,
          left: 20,
          right: 20,
          child: Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              widget.isRegistration 
                ? 'Posicione sua face dentro da área oval para cadastro'
                : 'Posicione sua face dentro da área oval para login',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}

// CustomPainter para desenhar os guias visuais
class FaceGuidePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    // Desenhar oval para guiar posicionamento
    final center = Offset(size.width / 2, size.height / 2);
    final radiusX = size.width * 0.35;
    final radiusY = size.height * 0.4;
    
    canvas.drawOval(
      Rect.fromCenter(center: center, width: radiusX * 2, height: radiusY * 2),
      paint,
    );

    // Desenhar pontos de referência
    final dotPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    // Pontos nos cantos da oval
    final dots = [
      Offset(center.dx - radiusX * 0.8, center.dy - radiusY * 0.8),
      Offset(center.dx + radiusX * 0.8, center.dy - radiusY * 0.8),
      Offset(center.dx - radiusX * 0.8, center.dy + radiusY * 0.8),
      Offset(center.dx + radiusX * 0.8, center.dy + radiusY * 0.8),
    ];

    for (final dot in dots) {
      canvas.drawCircle(dot, 4, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 