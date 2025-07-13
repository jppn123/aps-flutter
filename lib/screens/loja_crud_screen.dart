import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../services/loja_service.dart';
import '../widgets/app_drawer.dart';
import 'login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LojaCrudScreen extends StatefulWidget {
  @override
  State<LojaCrudScreen> createState() => _LojaCrudScreenState();
}

class _LojaCrudScreenState extends State<LojaCrudScreen> {
  final LojaService _lojaService = LojaService();
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _lojas = [];
  String? _tipoUsuario;

  @override
  void initState() {
    super.initState();
    _loadTipoUsuario();
    _loadLojas();
  }

  Future<void> _loadTipoUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _tipoUsuario = prefs.getString('tp_login');
    });
  }

  Future<void> _loadLojas() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final lojas = await _lojaService.listarLojas();
      setState(() {
        _lojas = lojas;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _removerLoja(int id) async {
    try {
      await _lojaService.deletarLoja(id);
      await _loadLojas();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Loja removida com sucesso!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao remover loja: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _removerLojaConfirm(int id, String nome) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmar Remoção'),
        content: Text('Tem certeza que deseja remover a loja "$nome"?'),
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
      ),
    );
    if (result == true) {
      await _removerLoja(id);
    }
  }

  Future<void> _adicionarLojaDialog() async {
    final nomeController = TextEditingController();
    final enderecoController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Adicionar Loja'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nomeController,
              decoration: InputDecoration(labelText: 'Nome da loja'),
            ),
            SizedBox(height: 16),
            TextField(
              controller: enderecoController,
              decoration: InputDecoration(labelText: 'Endereço'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nomeController.text.trim().isEmpty || enderecoController.text.trim().isEmpty) return;
              try {
                await _lojaService.criarLoja(
                  nome: nomeController.text.trim(),
                  endereco: enderecoController.text.trim(),
                );
                Navigator.of(context).pop(true);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erro ao adicionar loja: $e'), backgroundColor: Colors.red),
                );
              }
            },
            child: Text('Adicionar'),
          ),
        ],
      ),
    );
    if (result == true) {
      _loadLojas();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Loja adicionada com sucesso!'), backgroundColor: Colors.green),
      );
    }
  }

  Future<void> _editarLojaDialog(Map<String, dynamic> loja) async {
    final nomeController = TextEditingController(text: loja['nome']?.toString() ?? '');
    final enderecoController = TextEditingController(text: loja['endereco']?.toString() ?? '');
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Editar Loja'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nomeController,
              decoration: InputDecoration(labelText: 'Nome da loja'),
            ),
            SizedBox(height: 16),
            TextField(
              controller: enderecoController,
              decoration: InputDecoration(labelText: 'Endereço'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nomeController.text.trim().isEmpty || enderecoController.text.trim().isEmpty) return;
              try {
                await _lojaService.atualizarLoja(
                  id: loja['id'],
                  nome: nomeController.text.trim(),
                  endereco: enderecoController.text.trim(),
                );
                Navigator.of(context).pop(true);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erro ao atualizar loja: $e'), backgroundColor: Colors.red),
                );
              }
            },
            child: Text('Salvar'),
          ),
        ],
      ),
    );
    if (result == true) {
      _loadLojas();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Loja atualizada com sucesso!'), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gerenciar Lojas'),
        actions: [
          if (_tipoUsuario == 'admin' || _tipoUsuario == 'coord')
            IconButton(
              icon: Icon(Icons.add),
              tooltip: 'Adicionar Loja',
              onPressed: _adicionarLojaDialog,
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Lojas cadastradas',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            if (_isLoading)
              Center(child: CircularProgressIndicator())
            else if (_errorMessage != null)
              Center(child: Text(_errorMessage!))
            else if (_lojas.isEmpty)
              Center(child: Text('Nenhuma loja cadastrada.'))
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _lojas.length,
                  itemBuilder: (context, index) {
                    final loja = _lojas[index];
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
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _editarLojaDialog(loja),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removerLojaConfirm(loja['id'], loja['nome']?.toString() ?? ''),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
} 