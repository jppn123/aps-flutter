import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../services/user_service.dart';

class UserFuncionarioDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> usuario;

  const UserFuncionarioDetailsScreen({Key? key, required this.usuario}) : super(key: key);

  @override
  _UserFuncionarioDetailsScreenState createState() => _UserFuncionarioDetailsScreenState();
}

class _UserFuncionarioDetailsScreenState extends State<UserFuncionarioDetailsScreen> {
  Map<String, dynamic>? userData;
  String? userEmail;
  String? userTipo;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final data = await UserService().getUsuario(widget.usuario['id']);
      final loginData = await UserService().getLoginUsuario(widget.usuario['id']);
      setState(() {
        userData = data;
        userEmail = loginData['email'];
        userTipo = loginData['tipo'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mock de lojas
    final lojas = [
      {
        'id': 1,
        'nome': 'Loja Central',
        'endereco': 'Rua Principal, 123',
        'imagem': null, // base64 ou null
      },
      {
        'id': 2,
        'nome': 'Loja Norte',
        'endereco': 'Avenida Norte, 456',
        'imagem': null,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Detalhes do ' + _getTipoExibicao(userTipo)),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userData?['nome'] ?? 'Sem nome',
                                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 8),
                              Text(
                                _getTipoExibicao(userTipo),
                                style: TextStyle(fontSize: 16, color: Colors.grey[600], fontStyle: FontStyle.italic),
                              ),
                              if ((userEmail?.isNotEmpty ?? false)) ...[
                                SizedBox(height: 8),
                                Row(
                                  children: [
                                    Text(
                                      'Email: ',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    Expanded(
                                      child: Text(
                                        userEmail!,
                                        style: TextStyle(fontSize: 16, color: Colors.black87),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              SizedBox(height: 16),
                              _buildUserField('CPF', userData?['cpf']),
                              _buildUserField('Data de Nascimento', userData?['data_nascimento']),
                              _buildUserField('Telefone', userData?['telefone']),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 24),
                      if (_getTipoExibicao(userTipo) == 'Funcionário') ...[
                        Text(
                          'Lojas do usuário',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 16),
                        if (lojas.isEmpty)
                          Center(
                            child: Text('Nenhuma loja cadastrada para este usuário.'),
                          )
                        else
                          Column(
                            children: lojas.map((loja) {
                              return Card(
                                margin: EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  leading: loja['imagem'] != null
                                      ? Image.memory(
                                          Uint8List(0),
                                          width: 48,
                                          height: 48,
                                          fit: BoxFit.cover,
                                        )
                                      : Icon(Icons.store, size: 40, color: Colors.grey),
                                  title: Text(loja['nome']?.toString() ?? 'Sem nome'),
                                  subtitle: Text(loja['endereco']?.toString() ?? ''),
                                ),
                              );
                            }).toList(),
                          ),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildUserField(String label, dynamic value) {
    if (value == null || value.toString().isEmpty) return SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(value.toString()),
          ),
        ],
      ),
    );
  }

  String _getTipoExibicao(dynamic tipo) {
    switch ((tipo ?? '').toString().toLowerCase()) {
      case 'admin':
        return 'Administrador';
      case 'coord':
        return 'Coordenador';
      case 'func':
        return 'Funcionário';
      default:
        return tipo?.toString() ?? '';
    }
  }
} 