import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';

class EditUserDataScreen extends StatefulWidget {
  final Map<String, String> currentData;

  EditUserDataScreen({required this.currentData});

  @override
  _EditUserDataScreenState createState() => _EditUserDataScreenState();
}

class _EditUserDataScreenState extends State<EditUserDataScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _cpfController = TextEditingController();
  final _dataNascimentoController = TextEditingController();
  final _telefoneController = TextEditingController();
  
  final UserService _userService = UserService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _nomeController.text = widget.currentData['NOME'] ?? '';
    _cpfController.text = widget.currentData['CPF'] ?? '';
    _dataNascimentoController.text = widget.currentData['DATA DE NASCIMENTO'] ?? '';
    _telefoneController.text = widget.currentData['TELEFONE'] ?? '';
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _cpfController.dispose();
    _dataNascimentoController.dispose();
    _telefoneController.dispose();
    super.dispose();
  }

  String _formatarCPF(String value) {
    value = value.replaceAll(RegExp(r'[^\d]'), '');
    if (value.length <= 3) {
      return value;
    } else if (value.length <= 6) {
      return '${value.substring(0, 3)}.${value.substring(3)}';
    } else if (value.length <= 9) {
      return '${value.substring(0, 3)}.${value.substring(3, 6)}.${value.substring(6)}';
    } else {
      return '${value.substring(0, 3)}.${value.substring(3, 6)}.${value.substring(6, 9)}-${value.substring(9, 11)}';
    }
  }

  String _formatarTelefone(String value) {
    value = value.replaceAll(RegExp(r'[^\d]'), '');
    if (value.length <= 2) {
      return value;
    } else if (value.length <= 6) {
      return '(${value.substring(0, 2)}) ${value.substring(2)}';
    } else if (value.length <= 10) {
      return '(${value.substring(0, 2)}) ${value.substring(2, 6)}-${value.substring(6)}';
    } else {
      return '(${value.substring(0, 2)}) ${value.substring(2, 3)} ${value.substring(3, 7)}-${value.substring(7, 11)}';
    }
  }

  bool _validarCPF(String cpf) {
    cpf = cpf.replaceAll(RegExp(r'[^\d]'), '');
    if (cpf.length != 11) return false;
    
    if (cpf.split('').every((digit) => digit == cpf[0])) return false;
    
    int soma = 0;
    for (int i = 0; i < 9; i++) {
      soma += int.parse(cpf[i]) * (10 - i);
    }
    int resto = soma % 11;
    int digito1 = resto < 2 ? 0 : 11 - resto;
    
    soma = 0;
    for (int i = 0; i < 10; i++) {
      soma += int.parse(cpf[i]) * (11 - i);
    }
    resto = soma % 11;
    int digito2 = resto < 2 ? 0 : 11 - resto;
    
    return cpf[9] == digito1.toString() && cpf[10] == digito2.toString();
  }

  Future<void> _selecionarData() async {
    DateTime dataInicial = DateTime.now().subtract(Duration(days: 6570));
    
    if (_dataNascimentoController.text.isNotEmpty) {
      try {
        final partes = _dataNascimentoController.text.split('/');
        if (partes.length == 3) {
          final dia = int.parse(partes[0]);
          final mes = int.parse(partes[1]);
          final ano = int.parse(partes[2]);
          dataInicial = DateTime(ano, mes, dia);
        }
      } catch (e) {
        print('Erro ao converter data: $e');
      }
    }

    final DateTime? dataSelecionada = await showDatePicker(
      context: context,
      initialDate: dataInicial,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: Locale('pt', 'BR'),
    );

    if (dataSelecionada != null) {
      setState(() {
        _dataNascimentoController.text = 
          '${dataSelecionada.day.toString().padLeft(2, '0')}/'
          '${dataSelecionada.month.toString().padLeft(2, '0')}/'
          '${dataSelecionada.year}';
      });
    }
  }

  Future<void> _salvarDados() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final idUsuario = prefs.getString(AuthService.idUsu);
      
      if (idUsuario == null) {
        throw Exception('ID do usuário não encontrado');
      }

      await _userService.atualizarUsuario(
        idUsuario: int.parse(idUsuario),
        nome: _nomeController.text.trim(),
        cpf: _cpfController.text.trim(),
        dataNascimento: _dataNascimentoController.text.trim().isEmpty ? null : _dataNascimentoController.text.trim(),
        telefone: _telefoneController.text.trim().isEmpty ? null : _telefoneController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dados atualizados com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar dados: $e'),
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
        title: Text('Editar Dados'),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _nomeController,
                decoration: InputDecoration(labelText: 'Nome do Usuário'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Informe o nome';
                  }
                  if (value.trim().length < 2) {
                    return 'Nome deve ter pelo menos 2 caracteres';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),
              TextFormField(
                controller: _cpfController,
                decoration: InputDecoration(labelText: 'CPF do Usuário'),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                ],
                onChanged: (value) {
                  final formatted = _formatarCPF(value);
                  if (formatted != value) {
                    _cpfController.value = TextEditingValue(
                      text: formatted,
                      selection: TextSelection.collapsed(offset: formatted.length),
                    );
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Informe o CPF';
                  }
                  if (!_validarCPF(value)) {
                    return 'CPF inválido';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),
              TextFormField(
                controller: _dataNascimentoController,
                decoration: InputDecoration(
                  labelText: 'Data de Nascimento',
                  suffixIcon: IconButton(
                    icon: Icon(Icons.calendar_today),
                    onPressed: _selecionarData,
                  ),
                ),
                readOnly: true,
                onTap: _selecionarData,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return null;
                  }
                  final dateRegex = RegExp(r'^\d{2}/\d{2}/\d{4}$');
                  if (!dateRegex.hasMatch(value)) {
                    return 'Data deve estar no formato DD/MM/AAAA';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),
              TextFormField(
                controller: _telefoneController,
                decoration: InputDecoration(labelText: 'Telefone'),
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                ],
                onChanged: (value) {
                  final formatted = _formatarTelefone(value);
                  if (formatted != value) {
                    _telefoneController.value = TextEditingValue(
                      text: formatted,
                      selection: TextSelection.collapsed(offset: formatted.length),
                    );
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return null;
                  }
                  final phoneRegex = RegExp(r'^\(\d{2}\) \d \d{4}-\d{4}$');
                  if (!phoneRegex.hasMatch(value)) {
                    return 'Telefone deve estar no formato (85) 9 8620-2279';
                  }
                  return null;
                },
              ),
              SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _salvarDados,
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
                    : Text('Salvar Alterações'),
                ),
              ),
              SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
} 