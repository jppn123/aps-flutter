import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import '../services/user_service.dart';

class CriarUsuarioScreen extends StatefulWidget {
  @override
  _CriarUsuarioScreenState createState() => _CriarUsuarioScreenState();
}

class _CriarUsuarioScreenState extends State<CriarUsuarioScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _nomeController = TextEditingController();
  final _cpfController = TextEditingController();
  final _userService = UserService();
  String _tipoUsuario = 'admin';
  final String _senhaPadrao = '12345678';
  bool _isLoading = false;
  bool _loginCriado = false;
  int? _idLogin;

  Future<void> _criarLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final resultado = await _userService.criarLogin(
        email: _emailController.text,
        tipo: _tipoUsuario,
        senha: _senhaPadrao,
      );
      
      if (mounted) {
        setState(() {
          _idLogin = resultado['id'];
          _loginCriado = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login criado com sucesso! Agora preencha os dados do usuário.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao criar login: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _criarUsuario() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _userService.criarUsuario(
        nome: _nomeController.text,
        cpf: _cpfController.text,
        idLogin: _idLogin!,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Usuário criado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        // Limpar formulário e voltar ao estado inicial
        _emailController.clear();
        _nomeController.clear();
        _cpfController.clear();
        setState(() {
          _loginCriado = false;
          _idLogin = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao criar usuário: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Criar Usuário'),
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
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!_loginCriado) ...[
                // Primeiro passo: Criar login
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(labelText: 'Email do Usuário'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Informe o email';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 24),
                TextFormField(
                  initialValue: _senhaPadrao,
                  enabled: false,
                  decoration: InputDecoration(labelText: 'Senha (padrão)'),
                ),
                SizedBox(height: 24),
                DropdownButtonFormField<String>(
                  value: _tipoUsuario,
                  decoration: InputDecoration(labelText: 'Tipo de Usuário'),
                  items: [
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    DropdownMenuItem(value: 'coord', child: Text('Coord')),
                    DropdownMenuItem(value: 'func', child: Text('Func')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _tipoUsuario = value!;
                    });
                  },
                ),
              ] else ...[
                // Segundo passo: Criar usuário
                TextFormField(
                  controller: _nomeController,
                  decoration: InputDecoration(labelText: 'Nome do Usuário'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Informe o nome';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 24),
                TextFormField(
                  controller: _cpfController,
                  decoration: InputDecoration(labelText: 'CPF do Usuário'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Informe o CPF';
                    }
                    return null;
                  },
                ),
              ],
              SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : (_loginCriado ? _criarUsuario : _criarLogin),
                  child: _isLoading 
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text(_loginCriado ? 'Criando...' : 'Criando login...'),
                        ],
                      )
                    : Text(_loginCriado ? 'Criar Usuário' : 'Prosseguir'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 