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
  final TextEditingController _surgeonNameController = TextEditingController();
  final TextEditingController _anesthesiologistController =
      TextEditingController();
  final TextEditingController _bloodProductController = TextEditingController();
  final TextEditingController _opmeController = TextEditingController();

  // Serviços
  final SurgeryService _surgeryService = SurgeryService();
  final MedicalDataService _medicalService = MedicalDataService();

  // Variáveis para seleção (armazenando os IDs dos documentos)
  String? _selectedSurgeonId;
  String? _selectedProcedureId;
  String? _selectedOpmeId;
  String?
      _selectedAnesthesiologistId; // Caso venha a ser selecionado via diálogo
  DateTime _selectedDate = DateTime.now();
  bool _needsICU = false;
  bool _residentConfirmation = false; // Se necessário para outro fluxo

  bool _isLoading = false;

  // Seleciona um procedimento e atualiza o campo com o nome correspondente
  Future<void> _selectProcedure() async {
    final selectedId = await _medicalService.showSingleSelectionDialog(
      context: context,
      collection: 'procedures',
    );
    if (selectedId != null) {
      final name = await _medicalService.getItemName('procedures', selectedId);
      setState(() {
        _selectedProcedureId = selectedId;
        _procedureController.text = name;
      });
    }
  }

  // Seleciona um cirurgião e atualiza o campo com o nome correspondente
  Future<void> _selectSurgeon() async {
    final selectedId = await _medicalService.showSingleSelectionDialog(
      context: context,
      collection: 'surgeons',
    );
    if (selectedId != null) {
      final name = await _medicalService.getItemName('surgeons', selectedId);
      setState(() {
        _selectedSurgeonId = selectedId;
        _surgeonNameController.text = name;
      });
    }
  }

  // Seleciona OPMe e atualiza o campo (opcional: similar para anestesista)
  Future<void> _selectOpme() async {
    final selectedId = await _medicalService.showSingleSelectionDialog(
      context: context,
      collection: 'opme',
    );
    if (selectedId != null) {
      final name = await _medicalService.getItemName('opme', selectedId);
      setState(() {
        _selectedOpmeId = selectedId;
        _opmeController.text = name;
      });
    }
  }

  // Seleciona data da cirurgia via DatePicker
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

  // Submissão dos dados para criar a cirurgia
  Future<void> _submit() async {
    if (_patientController.text.isEmpty ||
        _selectedProcedureId == null ||
        _selectedSurgeonId == null) {
      _showSnackBar('Selecione cirurgião e procedimento');
      return;
    }

    setState(() => _isLoading = true);

    final surgeryData = {
      'patientName': _patientController.text.trim(),
      'procedure': _selectedProcedureId, // Armazena o ID do procedimento
      'surgeon': _selectedSurgeonId, // Armazena o ID do cirurgião
      'anesthesiologist': _selectedAnesthesiologistId,
      'opme': _selectedOpmeId,
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

  // Exibe um SnackBar com a mensagem informada
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
              // Seleção de cirurgião (campo não editável com botão de seleção)
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _surgeonNameController,
                      decoration: const InputDecoration(
                        labelText: 'Cirurgião',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      readOnly: true,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: _selectSurgeon,
                  ),
                ],
              ),
              const SizedBox(height: 15),
              // Anestesista (campo editável ou seleção similar, se necessário)
              TextFormField(
                controller: _anesthesiologistController,
                decoration: const InputDecoration(
                  labelText: 'Anestesista',
                  prefixIcon: Icon(Icons.medical_services_outlined),
                ),
              ),
              const SizedBox(height: 15),
              // Seleção de OPMe (campo não editável com botão de seleção)
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _opmeController,
                      decoration: const InputDecoration(
                        labelText: 'OPMe',
                        prefixIcon: Icon(Icons.search),
                      ),
                      readOnly: true,
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
