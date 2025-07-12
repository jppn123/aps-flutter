import 'package:flutter/material.dart';
import '../services/recover_service.dart';

class RecoverLoginScreen extends StatefulWidget {
  @override
  _RecoverLoginScreenState createState() => _RecoverLoginScreenState();
}

class _RecoverLoginScreenState extends State<RecoverLoginScreen> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _senhaAntigaController = TextEditingController();
  final _senhaNovaController = TextEditingController();
  final _senhaNovaConfirmadaController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _recoverService = RecoverService();

  String? _token;
  String? _emailError;
  String? _codeError;
  String? _senhaError;
  String? _senhaSuccess;
  bool _emailSent = false;
  bool _codigoValidado = false;

  Future<void> _enviarEmail() async {
    setState(() {
      _emailError = null;
    });
    try {
      await _recoverService.enviarEmail(_emailController.text);
      setState(() {
        _emailSent = true;
      });
    } catch (e) {
      setState(() {
        _emailError = e.toString();
      });
    }
  }

  Future<void> _validarCodigo() async {
    setState(() {
      _codeError = null;
    });
    try {
      await _recoverService.validarCodigo(_codeController.text);
      setState(() {
        _codigoValidado = true;
      });
    } catch (e) {
      setState(() {
        _codeError = e.toString();
      });
    }
  }

  Future<void> _mudarSenha() async {
    setState(() {
      _senhaError = null;
      _senhaSuccess = null;
    });
    try {
      await _recoverService.mudarSenha(
        senhaAntiga: _senhaAntigaController.text,
        senhaNova: _senhaNovaController.text,
        senhaNovaConfirmada: _senhaNovaConfirmadaController.text,
      );
      setState(() {
        _senhaSuccess = 'Senha alterada com sucesso!';
      });
    } catch (e) {
      setState(() {
        _senhaError = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Recuperar Senha')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!_emailSent) ...[
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    errorText: _emailError,
                  ),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _enviarEmail,
                  child: Text('Enviar Email'),
                ),
              ] else if (!_codigoValidado) ...[
                TextFormField(
                  controller: _codeController,
                  decoration: InputDecoration(
                    labelText: 'Código',
                    errorText: _codeError,
                  ),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _validarCodigo,
                  child: Text('Validar Código'),
                ),
              ] else ...[
                TextFormField(
                  controller: _senhaAntigaController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Senha anterior',
                  ),
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _senhaNovaController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Nova senha',
                  ),
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _senhaNovaConfirmadaController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Confirmar nova senha',
                  ),
                ),
                SizedBox(height: 16),
                if (_senhaError != null)
                  Text(_senhaError!, style: TextStyle(color: Colors.red)),
                if (_senhaSuccess != null)
                  Text(_senhaSuccess!, style: TextStyle(color: Colors.green)),
                ElevatedButton(
                  onPressed: _mudarSenha,
                  child: Text('Alterar Senha'),
                ),
              ],
              SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Voltar ao login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
