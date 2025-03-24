import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cirurgiapp/src/services/medical_data_service.dart';
import 'package:cirurgiapp/src/services/surgery_service.dart';

class CreateSurgeryScreen extends StatefulWidget {
  const CreateSurgeryScreen({super.key});

  @override
  State<CreateSurgeryScreen> createState() => _CreateSurgeryScreenState();
}

class _CreateSurgeryScreenState extends State<CreateSurgeryScreen> {
  // Controladores de texto para os campos
  final TextEditingController _patientController = TextEditingController();
  final TextEditingController _procedureController = TextEditingController();
  final TextEditingController _anesthesiologistController =
      TextEditingController();
  final TextEditingController _bloodProductController = TextEditingController();

  // Serviços
  final SurgeryService _surgeryService = SurgeryService();
  final MedicalDataService _medicalService = MedicalDataService();

  // Variáveis para seleção de dados
  String _selectedSurgeon = '';
  String _selectedOpme = '';
  DateTime _selectedDate = DateTime.now();
  bool _needsICU = false;
  bool _residentConfirmation = false; // Se for necessário para outro fluxo

  bool _isLoading = false;

  // Método para selecionar procedimento via diálogo
  Future<void> _selectProcedure() async {
    final selected = await _medicalService.showSelectionDialog(
      context: context,
      collection: 'procedures',
    );
    if (selected.isNotEmpty) {
      setState(() => _procedureController.text = selected.first);
    }
  }

  // Método para selecionar data (DatePicker)
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Simula a seleção de um cirurgião
  Future<void> _selectSurgeon() async {
    final selected = await _medicalService.showSelectionDialog(
      context: context,
      collection: 'surgeons',
    );
    if (selected.isNotEmpty) {
      setState(() => _selectedSurgeon = selected.first);
    }
  }

  // Simula a seleção de OPMe
  Future<void> _selectOpme() async {
    final selected = await _medicalService.showSelectionDialog(
      context: context,
      collection: 'opme',
    );
    if (selected.isNotEmpty) {
      setState(() => _selectedOpme = selected.first);
    }
  }

  Future<void> _submit() async {
    if (_patientController.text.isEmpty ||
        _procedureController.text.isEmpty ||
        _selectedSurgeon.isEmpty) {
      _showSnackBar('Preencha todos os campos obrigatórios');
      return;
    }

    setState(() => _isLoading = true);

    final surgeryData = {
      'patientName': _patientController.text.trim(),
      'procedure': _procedureController.text.trim(),
      'surgeon': _selectedSurgeon,
      'anesthesiologist': _anesthesiologistController.text.trim(),
      'opme': _selectedOpme,
      'bloodProducts': _bloodProductController.text.trim(),
      'needsICU': _needsICU,
      'dateTime': Timestamp.fromDate(_selectedDate),
      'confirmations': {
        'residente': _residentConfirmation,
      },
    };

    try {
      await _surgeryService.createSurgery(surgeryData);
      _showSnackBar('Cirurgia criada com sucesso!');
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showSnackBar('Erro ao criar cirurgia.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Criar Cirurgia')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Nome do paciente
              TextFormField(
                controller: _patientController,
                decoration: const InputDecoration(
                  labelText: 'Nome do Paciente',
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 15),
              // Procedimento (campo não editável com botão de seleção)
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _procedureController,
                      decoration: const InputDecoration(
                        labelText: 'Procedimento',
                        prefixIcon: Icon(Icons.medical_services),
                      ),
                      readOnly: true,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: _selectProcedure,
                  ),
                ],
              ),
              const SizedBox(height: 15),
              // Seleção de cirurgião
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedSurgeon.isEmpty
                          ? 'Selecione o cirurgião'
                          : 'Cirurgião: $_selectedSurgeon',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: _selectSurgeon,
                  ),
                ],
              ),
              const SizedBox(height: 15),
              // Anestesista
              TextFormField(
                controller: _anesthesiologistController,
                decoration: const InputDecoration(
                  labelText: 'Anestesista',
                  prefixIcon: Icon(Icons.medical_services_outlined),
                ),
              ),
              const SizedBox(height: 15),
              // Seleção de OPMe
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedOpme.isEmpty
                          ? 'Selecione OPMe'
                          : 'OPMe: $_selectedOpme',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: _selectOpme,
                  ),
                ],
              ),
              const SizedBox(height: 15),
              // Produtos Sanguíneos
              TextFormField(
                controller: _bloodProductController,
                decoration: const InputDecoration(
                  labelText: 'Produto Sanguíneo',
                  prefixIcon: Icon(Icons.bloodtype),
                ),
              ),
              const SizedBox(height: 15),
              // Necessidade de UTI
              CheckboxListTile(
                title: const Text('Necessita UTI'),
                value: _needsICU,
                onChanged: (value) {
                  setState(() {
                    _needsICU = value ?? false;
                  });
                },
              ),
              const SizedBox(height: 15),
              // Data da cirurgia
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Data: ${_selectedDate.toLocal().toString().split(' ')[0]}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: _selectDate,
                  ),
                ],
              ),
              const SizedBox(height: 25),
              // Botão de envio
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _submit,
                icon: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Icon(Icons.save),
                label: Text(_isLoading ? 'Enviando...' : 'Criar Cirurgia'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  backgroundColor: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
