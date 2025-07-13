import 'package:flutter/material.dart';
import '../services/team_service.dart';
import 'login_screen.dart';

class EditTeamScreen extends StatefulWidget {
  final Map<String, dynamic>? time;
  
  EditTeamScreen({this.time});

  @override
  _EditTeamScreenState createState() => _EditTeamScreenState();
}

class _EditTeamScreenState extends State<EditTeamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _descricaoController = TextEditingController();
  
  final TeamService _teamService = TeamService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.time != null) {
      _nomeController.text = widget.time!['nome'] ?? '';
      _descricaoController.text = widget.time!['descricao'] ?? '';
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  Future<void> _salvarTime() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.time != null) {
        await _teamService.atualizarTime(
          idTime: widget.time!['id'],
          nome: _nomeController.text.trim(),
          descricao: _descricaoController.text.trim().isEmpty ? null : _descricaoController.text.trim(),
        );
      } else {
        await _teamService.criarTime(
          nome: _nomeController.text.trim(),
          descricao: _descricaoController.text.trim().isEmpty ? null : _descricaoController.text.trim(),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.time != null 
              ? 'Time atualizado com sucesso!' 
              : 'Time criado com sucesso! Você foi adicionado como membro do time.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
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
        title: Text(widget.time != null ? 'Editar Time' : 'Criar Time'),
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
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _nomeController,
                decoration: InputDecoration(labelText: 'Nome do Time'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Informe o nome do time';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),
              TextFormField(
                controller: _descricaoController,
                decoration: InputDecoration(labelText: 'Descrição (opcional)'),
                maxLines: 3,
              ),
              SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _salvarTime,
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
                          Text('Salvando...'),
                        ],
                      )
                    : Text(widget.time != null ? 'Atualizar Time' : 'Criar Time'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 