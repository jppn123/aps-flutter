import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';

class CriarUsuarioScreen extends StatefulWidget {
  @override
  _CriarUsuarioScreenState createState() => _CriarUsuarioScreenState();
}

class _CriarUsuarioScreenState extends State<CriarUsuarioScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  String _tipoUsuario = 'admin';
  final String _senhaPadrao = '12345678';

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
              SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      // Aqui você pode implementar a chamada ao backend para criar o usuário
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Usuário criado (mock)!')),
                      );
                    }
                  },
                  child: Text('Criar Usuário'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 