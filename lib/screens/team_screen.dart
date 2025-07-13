import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import '../services/team_service.dart';
import 'edit_team_screen.dart';
import 'team_details_screen.dart';

class TeamScreen extends StatefulWidget {
  @override
  _TeamScreenState createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  final TeamService _teamService = TeamService();
  List<Map<String, dynamic>> _times = [];
  String? _tipoUsuario;
  bool _isLoading = true;
  String? _errorMessage;

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

      if (tipoUsuario == 'admin') {
        // Administradores veem todos os times
        final times = await _teamService.getTimes();
        setState(() {
          _times = times;
          _isLoading = false;
        });
      } else if (tipoUsuario == 'coord') {
        // Coordenadores veem apenas os times que criaram
        final idUsuario = await _teamService.getIdUsuario();
        if (idUsuario != null) {
          final timesData = await _teamService.getTimesUsuarioFunc(idUsuario);
          final times = List<Map<String, dynamic>>.from(timesData['times'] ?? []);
          setState(() {
            _times = times;
            _isLoading = false;
          });
        } else {
          setState(() {
            _times = [];
            _isLoading = false;
          });
        }
      } else {
        // Funcionários veem apenas seus times
        final idUsuario = await _teamService.getIdUsuario();
        if (idUsuario != null) {
          try {
            final timesData = await _teamService.getTimesUsuarioFunc(idUsuario);
            final times = List<Map<String, dynamic>>.from(timesData['times'] ?? []);
            setState(() {
              _times = times;
              _isLoading = false;
            });
          } catch (e) {
            setState(() {
              _errorMessage = e.toString().replaceAll('Exception: ', '');
              _isLoading = false;
            });
          }
        } else {
          setState(() {
            _times = [];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _deletarTime(int idTime) async {
    try {
      await _teamService.deletarTime(idTime);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Time deletado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao deletar time: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _confirmarDeletar(Map<String, dynamic> time) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmar Exclusão'),
          content: Text('Tem certeza que deseja deletar o time "${time['nome']}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deletarTime(time['id']);
              },
              child: Text('Deletar'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Minha Equipe'),
        actions: [
          if (_tipoUsuario == 'admin' || _tipoUsuario == 'coord')
            IconButton(
              icon: Icon(Icons.add),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => EditTeamScreen()),
                );
                if (result == true) {
                  _loadData();
                }
              },
            ),
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
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Carregando times...'),
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
                        'Erro ao carregar times',
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
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_tipoUsuario == 'func') {
      if (_times.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.group, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Você ainda não está em um time',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Aguarde um administrador ou coordenador te adicionar a um time.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        );
      }
    }

    if (_times.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Nenhum time encontrado',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              _tipoUsuario == 'admin'
                  ? 'Crie seu primeiro time clicando no botão + no canto superior direito.'
                  : _tipoUsuario == 'coord'
                      ? 'Você ainda não criou nenhum time. Crie seu primeiro time clicando no botão + no canto superior direito.'
                      : 'Você ainda não foi adicionado a nenhum time.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _times.length,
      itemBuilder: (context, index) {
        final time = _times[index];
        return Card(
          margin: EdgeInsets.only(bottom: 16),
          child: ListTile(
            title: Text(
              time['nome'] ?? 'Sem nome',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: time['descricao'] != null && time['descricao'].isNotEmpty
                ? Text(time['descricao'])
                : null,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TeamDetailsScreen(time: time),
                ),
              );
            },
            trailing: (_tipoUsuario == 'admin' || _tipoUsuario == 'coord')
                ? FutureBuilder<bool>(
                    future: _teamService.podeGerenciarTime(time['id']),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return SizedBox(width: 48, height: 48, child: CircularProgressIndicator(strokeWidth: 2));
                      }
                      
                      final podeGerenciar = snapshot.data ?? false;
                      
                      if (podeGerenciar) {
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit),
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditTeamScreen(time: time),
                                  ),
                                );
                                if (result == true) {
                                  _loadData();
                                }
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _confirmarDeletar(time),
                            ),
                          ],
                        );
                      } else {
                        return SizedBox.shrink();
                      }
                    },
                  )
                : null,
          ),
        );
      },
    );
  }
} 