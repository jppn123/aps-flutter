import 'package:flutter/material.dart';
import '../services/attendance_service.dart';
import '../services/foto_ponto_service.dart';
import '../widgets/app_drawer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:typed_data';

class HistoricoPontosFuncionarioScreen extends StatefulWidget {
  final int idFuncionario;
  final String nomeFuncionario;

  const HistoricoPontosFuncionarioScreen({
    Key? key, 
    required this.idFuncionario, 
    required this.nomeFuncionario
  }) : super(key: key);

  @override
  _HistoricoPontosFuncionarioScreenState createState() => _HistoricoPontosFuncionarioScreenState();
}

class _HistoricoPontosFuncionarioScreenState extends State<HistoricoPontosFuncionarioScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  final FotoPontoService _fotoPontoService = FotoPontoService();
  List<Map<String, dynamic>> _pontos = [];
  bool _isLoading = false;
  String? _selectedDate;

  @override
  void initState() {
    super.initState();
    _loadPontos();
  }

  Future<void> _loadPontos() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final pontos = await _attendanceService.getPontosUsuario(widget.idFuncionario);
      setState(() {
        _pontos = pontos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar pontos: $e')),
      );
    }
  }

  Future<void> _loadPontosByDate(String data) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final pontos = await _attendanceService.getPontosByDay(widget.idFuncionario, data);
      setState(() {
        _pontos = pontos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar pontos: $e')),
      );
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      final formattedDate = DateFormat('dd/MM/yyyy').format(picked);
      setState(() {
        _selectedDate = formattedDate;
      });
      await _loadPontosByDate(formattedDate);
    }
  }

  String _formatHorario(String horario) {
    try {
      final DateTime dateTime = DateTime.parse(horario);
      return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
    } catch (e) {
      return horario;
    }
  }

  String _getTipoText(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'entrada':
        return 'Entrada';
      case 'saida':
        return 'Saída';
      default:
        return tipo;
    }
  }

  Color _getTipoColor(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'entrada':
        return Colors.green;
      case 'saida':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Histórico de Pontos - ${widget.nomeFuncionario}'),
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today),
            onPressed: _selectDate,
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadPontos,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_selectedDate != null)
            Container(
              padding: EdgeInsets.all(16),
              color: Colors.blue[50],
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: Colors.blue),
                  SizedBox(width: 8),
                  Text(
                    'Filtrando por: $_selectedDate',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Spacer(),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedDate = null;
                      });
                      _loadPontos();
                    },
                    child: Text('Limpar'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _pontos.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'Nenhum ponto registrado',
                              style: TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _pontos.length,
                        itemBuilder: (context, index) {
                          final ponto = _pontos[index];
                          return Card(
                            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getTipoColor(ponto['tipo'] ?? ''),
                                child: Icon(
                                  ponto['tipo'] == 'entrada' ? Icons.login : Icons.logout,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(_getTipoText(ponto['tipo'] ?? '')),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_formatHorario(ponto['horario'] ?? '')),
                                  if (ponto['endereco'] != null)
                                    Text(
                                      'Endereço: ${ponto['endereco']}',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  if (ponto['id_loja'] != null)
                                    Text(
                                      'Loja ID: ${ponto['id_loja']}',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                ],
                              ),
                              trailing: Icon(Icons.arrow_forward_ios),
                              onTap: () {
                                _showPontoDetails(ponto);
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _showPontoDetails(Map<String, dynamic> ponto) async {
    List<Map<String, dynamic>> fotos = [];
    try {
      fotos = await _fotoPontoService.getFotosPonto(ponto['id']);
    } catch (e) {
      print('Erro ao buscar fotos: $e');
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detalhes do Ponto'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Tipo', _getTipoText(ponto['tipo'] ?? '')),
              _buildDetailRow('Data/Hora', _formatHorario(ponto['horario'] ?? '')),
              if (ponto['endereco'] != null)
                _buildDetailRow('Endereço', ponto['endereco']),
              if (ponto['latitude'] != null)
                _buildDetailRow('Latitude', ponto['latitude'].toString()),
              if (ponto['longitude'] != null)
                _buildDetailRow('Longitude', ponto['longitude'].toString()),
              if (ponto['id_loja'] != null)
                _buildDetailRow('ID da Loja', ponto['id_loja'].toString()),
              if (fotos.isNotEmpty) ...[
                SizedBox(height: 16),
                Text(
                  'Foto:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 8),
                ...fotos.map((foto) => _buildFotoWidget(foto)).toList(),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Widget _buildFotoWidget(Map<String, dynamic> foto) {
    try {
      final String base64String = foto['foto'] ?? '';
      if (base64String.isEmpty) return SizedBox.shrink();
      
      final Uint8List bytes = base64Decode(base64String);
      
      return Container(
        margin: EdgeInsets.only(bottom: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(
            bytes,
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
      );
    } catch (e) {
      return Container(
        margin: EdgeInsets.only(bottom: 8),
        child: Text(
          'Erro ao carregar imagem',
          style: TextStyle(color: Colors.red, fontSize: 12),
        ),
      );
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
} 