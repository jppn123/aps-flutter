import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../services/user_service.dart';
import '../services/loja_service.dart';
import 'historico_pontos_funcionario_screen.dart';

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
  List<Map<String, dynamic>> _lojasUsuario = [];
  List<Map<String, dynamic>> _todasLojas = [];
  final LojaService _lojaService = LojaService();
  Map<int, Map<int, Map<String, dynamic>>> _agendaPorDiaPeriodo = {};
  bool _agendaLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _agendaLoading = true;
    });
    try {
      final data = await UserService().getUsuario(widget.usuario['id']);
      final loginData = await UserService().getLoginUsuario(widget.usuario['id']);
      final lojasUsuario = await _lojaService.getLojasUsuario(widget.usuario['id']);
      final todasLojas = await _lojaService.listarLojas();
      Map<int, Map<int, Map<String, dynamic>>> agendaPorDiaPeriodo = {};
      for (int periodo = 0; periodo < 4; periodo++) {
        agendaPorDiaPeriodo[periodo] = {};
      }
      for (final loja in lojasUsuario) {
        final agenda = await _lojaService.getAgendaUsuarioLoja(idUsuario: widget.usuario['id'], idLoja: loja['id']);
        for (final item in agenda) {
          final dia = int.tryParse(item['dia_semana'].toString()) ?? 0;
          final periodo = int.tryParse(item['periodo'].toString()) ?? 0;
          agendaPorDiaPeriodo[periodo] ??= {};
          agendaPorDiaPeriodo[periodo]![dia] = {...item, 'loja': loja};
        }
      }
      setState(() {
        userData = data;
        userEmail = loginData['email'];
        userTipo = loginData['tipo'];
        _lojasUsuario = lojasUsuario;
        _todasLojas = todasLojas;
        _agendaPorDiaPeriodo = agendaPorDiaPeriodo;
        _isLoading = false;
        _agendaLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
        _agendaLoading = false;
      });
    }
  }

  Future<void> _adicionarLojaDialog() async {
    final lojasDisponiveis = _todasLojas.where((l) => !_lojasUsuario.any((lu) => lu['id'] == l['id'])).toList();
    int? idLojaSelecionada;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Vincular Loja ao Usuário'),
        content: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = MediaQuery.of(context).size.width * 0.8;
            return ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: DropdownButtonFormField<int>(
                isExpanded: true,
                items: lojasDisponiveis.map<DropdownMenuItem<int>>((loja) => DropdownMenuItem<int>(
                  value: loja['id'] as int,
                  child: Text(loja['nome'] ?? ''),
                )).toList(),
                onChanged: (value) => idLojaSelecionada = value,
                decoration: InputDecoration(labelText: 'Selecione a loja'),
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (idLojaSelecionada == null) return;
              try {
                await _lojaService.adicionarUsuarioLoja(
                  idUsuario: widget.usuario['id'],
                  idLoja: idLojaSelecionada!,
                );
                Navigator.of(context).pop(true);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erro ao vincular loja: $e'), backgroundColor: Colors.red),
                );
              }
            },
            child: Text('Vincular'),
          ),
        ],
      ),
    );
    if (result == true) {
      _loadAll();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Loja vinculada com sucesso!'), backgroundColor: Colors.green),
      );
    }
  }

  Future<void> _removerVinculoLoja(int idLoja, String nomeLoja) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remover vínculo'),
        content: Text('Deseja remover o vínculo com a loja "$nomeLoja"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _lojaService.removerUsuarioLoja(
                  idUsuario: widget.usuario['id'],
                  idLoja: idLoja,
                );
                Navigator.of(context).pop(true);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erro ao remover vínculo: $e'), backgroundColor: Colors.red),
                );
              }
            },
            child: Text('Remover'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    );
    if (result == true) {
      _loadAll();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vínculo removido com sucesso!'), backgroundColor: Colors.green),
      );
    }
  }

  Widget _buildAgendaCalendario() {
    if (_lojasUsuario.isEmpty) return SizedBox.shrink();
    const diasSemana = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];
    const periodos = ['Loja 1', 'Loja 2', 'Loja 3', 'Loja 4'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Agenda semanal', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: [
              DataColumn(label: Text('Semana')),
              ...diasSemana.map((d) => DataColumn(label: Text(d))).toList(),
            ],
            rows: [
              for (int periodo = 0; periodo < periodos.length; periodo++)
                DataRow(
                  cells: [
                    DataCell(Text(periodos[periodo])),
                    ...List.generate(6, (dia) {
                      final agenda = _agendaPorDiaPeriodo[periodo]?[dia];
                      return DataCell(
                        agenda != null
                          ? Row(
                              children: [
                                Flexible(child: Text(agenda['loja']['nome'] ?? '', overflow: TextOverflow.ellipsis)),
                                IconButton(
                                  icon: Icon(Icons.remove_circle, color: Colors.red, size: 18),
                                  tooltip: 'Remover vínculo',
                                  onPressed: () async {
                                    await _lojaService.removerAgendaUsuarioLoja(
                                      idUsuario: widget.usuario['id'],
                                      idLoja: agenda['loja']['id'],
                                      diaSemana: dia,
                                      periodo: periodo,
                                    );
                                    _loadAll();
                                  },
                                ),
                              ],
                            )
                          : IconButton(
                              icon: Icon(Icons.add, color: Colors.blue, size: 18),
                              tooltip: 'Vincular loja',
                              onPressed: _lojasUsuario.isEmpty ? null : () async {
                                final lojaSelecionada = await showDialog<Map<String, dynamic>>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text('Vincular loja'),
                                    content: DropdownButtonFormField<int>(
                                      isExpanded: true,
                                      items: _lojasUsuario.map<DropdownMenuItem<int>>((l) => DropdownMenuItem<int>(
                                        value: l['id'] as int,
                                        child: Text(l['nome'] ?? ''),
                                      )).toList(),
                                      onChanged: (id) {
                                        Navigator.of(context).pop(_lojasUsuario.firstWhere((l) => l['id'] == id));
                                      },
                                      decoration: InputDecoration(labelText: 'Selecione a loja para ${periodos[periodo]} em ${diasSemana[dia]}'),
                                    ),
                                  ),
                                );
                                if (lojaSelecionada != null) {
                                  await _lojaService.adicionarAgendaUsuarioLoja(
                                    idUsuario: widget.usuario['id'],
                                    idLoja: lojaSelecionada['id'],
                                    diaSemana: dia,
                                    periodo: periodo,
                                  );
                                  _loadAll();
                                }
                              },
                            ),
                      );
                    }),
                  ],
                ),
            ],
          ),
        ),
        SizedBox(height: 24),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Lojas do usuário',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            ElevatedButton.icon(
                              onPressed: _adicionarLojaDialog,
                              icon: Icon(Icons.store),
                              label: Text('Adicionar'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        if (_lojasUsuario.isEmpty)
                          Center(
                            child: Text('Nenhuma loja cadastrada para este usuário.'),
                          )
                        else
                          Column(
                            children: _lojasUsuario.map((loja) {
                              return Card(
                                margin: EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  leading: Icon(Icons.store, size: 40, color: Colors.grey),
                                  title: Text(loja['nome']?.toString() ?? 'Sem nome'),
                                  subtitle: Text(loja['endereco']?.toString() ?? ''),
                                  trailing: IconButton(
                                    icon: Icon(Icons.remove_circle, color: Colors.red),
                                    tooltip: 'Remover vínculo',
                                    onPressed: () => _removerVinculoLoja(loja['id'], loja['nome']?.toString() ?? ''),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        SizedBox(height: 24),
                        Container(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => HistoricoPontosFuncionarioScreen(
                                    idFuncionario: widget.usuario['id'],
                                    nomeFuncionario: userData?['nome'] ?? 'Funcionário',
                                  ),
                                ),
                              );
                            },
                            icon: Icon(Icons.history),
                            label: Text('Ver Histórico de Pontos'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ],
                      SizedBox(height: 20),
                      if (_getTipoExibicao(userTipo) == 'Funcionário') _buildAgendaCalendario(),
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