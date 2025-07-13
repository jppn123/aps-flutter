import 'package:flutter/material.dart';
import '../services/team_service.dart';
import '../services/user_service.dart';
import 'login_screen.dart';

class TeamDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> time;

  TeamDetailsScreen({required this.time});

  @override
  _TeamDetailsScreenState createState() => _TeamDetailsScreenState();
}

class _TeamDetailsScreenState extends State<TeamDetailsScreen> {
  final TeamService _teamService = TeamService();
  final UserService _userService = UserService();
  Map<String, dynamic> _timeData = {};
  List<Map<String, dynamic>> _usuarios = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _tipoUsuario;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final tipoUsuario = await _teamService.getTipoUsuario();
      setState(() {
        _tipoUsuario = tipoUsuario;
      });

      final timeData = await _teamService.getUsuariosTime(widget.time['id']);
      
      setState(() {
        _timeData = timeData;
        _usuarios = List<Map<String, dynamic>>.from(timeData['usuarios'] ?? []);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _adicionarUsuario() async {
    final TextEditingController emailController = TextEditingController();
    
    final result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Adicionar Usuário ao Time'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Digite o email do usuário que deseja adicionar:'),
                SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Email do usuário',
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (emailController.text.trim().isNotEmpty) {
                  Navigator.of(context).pop(emailController.text.trim());
                }
              },
              child: Text('Adicionar'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      await _processarAdicaoUsuario(result);
    }
  }

  Future<void> _processarAdicaoUsuario(String email) async {
    try {
      final usuario = await _userService.getUsuarioPorEmail(email);
      await _teamService.adicionarUsuarioTime(
        idUsuario: usuario['id'],
        idTime: widget.time['id'],
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Usuário adicionado ao time com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
      
      await _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao adicionar usuário: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _removerUsuario(Map<String, dynamic> usuario) async {
    // Verificar se o coordenador está tentando remover um administrador
    if (_tipoUsuario == 'coord' && usuario['tipo'] == 'admin') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Coordenadores não podem remover administradores do time.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Remover Usuário'),
          content: Text('Tem certeza que deseja remover ${usuario['nome']} do time?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Remover'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
          ],
        );
      },
    );

    if (result == true) {
      try {
        await _teamService.removerUsuarioTime(
          idUsuario: usuario['id'],
          idTime: widget.time['id'],
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Usuário removido do time com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        
        await _loadData();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao remover usuário: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalhes do Time'),
        
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Carregando detalhes do time...'),
                ],
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, color: Colors.red, size: 64),
                      SizedBox(height: 16),
                      Text(
                        'Erro ao carregar detalhes do time',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: Text('Tentar Novamente'),
                      ),
                    ],
                  ),
                )
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
                                'Nome do Time',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                _timeData['time']?['nome'] ?? widget.time['nome'] ?? 'Sem nome',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 16),
                              if (_timeData['time']?['descricao'] != null && 
                                  _timeData['time']['descricao'].isNotEmpty) ...[
                                Text(
                                  'Descrição',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  _timeData['time']['descricao'],
                                  style: TextStyle(fontSize: 16),
                                ),
                                SizedBox(height: 16),
                              ],
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Membros do Time (${_usuarios.length})',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          FutureBuilder<bool>(
                            future: _teamService.podeGerenciarTime(widget.time['id']),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return SizedBox(width: 120, height: 40, child: CircularProgressIndicator(strokeWidth: 2));
                              }
                              
                              final podeGerenciar = snapshot.data ?? false;
                              
                              return podeGerenciar
                                  ? ElevatedButton.icon(
                                      onPressed: _adicionarUsuario,
                                      icon: Icon(Icons.person_add),
                                      label: Text('Adicionar'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        foregroundColor: Colors.white,
                                      ),
                                    )
                                  : SizedBox.shrink();
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      if (_usuarios.isEmpty)
                        Center(
                          child: Column(
                            children: [
                              Icon(Icons.people, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'Nenhum membro no time',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                _tipoUsuario == 'admin' || _tipoUsuario == 'coord'
                                    ? 'Adicione usuários ao time clicando no botão "Adicionar".'
                                    : 'Este time ainda não possui membros.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        )
                      else
                        Column(
                          children: _usuarios.map((usuario) {
                            return Card(
                              margin: EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  child: Text(
                                    (usuario['nome'] ?? 'U')[0].toUpperCase(),
                                  ),
                                ),
                                title: Text(usuario['nome'] ?? 'Sem nome'),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (usuario['tipo'] != null) ...[
                                      Text(
                                        _getTipoExibicao(usuario['tipo']),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                    if (usuario['cpf'] != null)
                                      Text('CPF: ${usuario['cpf']}'),
                                    if (usuario['telefone'] != null)
                                      Text('Telefone: ${usuario['telefone']}'),
                                  ],
                                ),
                                trailing: FutureBuilder<bool>(
                                  future: _teamService.podeGerenciarTime(widget.time['id']),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState == ConnectionState.waiting) {
                                      return SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2));
                                    }
                                    
                                    final podeGerenciar = snapshot.data ?? false;
                                    
                                    if (podeGerenciar) {
                                      return FutureBuilder<int?>(
                                        future: _teamService.getIdUsuario(),
                                        builder: (context, userSnapshot) {
                                          if (userSnapshot.connectionState == ConnectionState.waiting) {
                                            return SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2));
                                          }
                                          
                                          final idUsuarioLogado = userSnapshot.data;
                                          final idUsuarioMembro = usuario['id'];
                                          final tipoUsuarioLogado = _tipoUsuario;
                                          final tipoUsuarioMembro = usuario['tipo'];
                                          
                                          if (idUsuarioLogado == idUsuarioMembro) {
                                            return SizedBox.shrink();
                                          }
                                          
                                          if (tipoUsuarioLogado == 'coord' && tipoUsuarioMembro == 'admin') {
                                            return SizedBox.shrink();
                                          }
                                          
                                          return IconButton(
                                            icon: Icon(Icons.remove_circle, color: Colors.red),
                                            onPressed: () => _removerUsuario(usuario),
                                          );
                                        },
                                      );
                                    } else {
                                      return SizedBox.shrink();
                                    }
                                  },
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
    );
  }

  String _getTipoExibicao(String tipo) {
    String tipoExibicao = '';
    switch (tipo.toLowerCase()) {
      case 'admin':
        tipoExibicao = 'administrador';
        break;
      case 'coord':
        tipoExibicao = 'coordenador';
        break;
      case 'func':
        tipoExibicao = 'funcionário';
        break;
      default:
        tipoExibicao = tipo;
    }
    return tipoExibicao;
  }
} 