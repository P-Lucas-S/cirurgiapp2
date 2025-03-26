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
  final TextEditingController _patientController = TextEditingController();
  final TextEditingController _procedureController = TextEditingController();
  final TextEditingController _surgeonNameController = TextEditingController();
  final TextEditingController _anesthesiologistController =
      TextEditingController();
  // Removemos os controllers de OPME e Produto Sanguíneo, pois usaremos seleção múltipla

  final SurgeryService _surgeryService = SurgeryService();
  final MedicalDataService _medicalService = MedicalDataService();

  // Seleção única
  DocumentReference? _selectedProcedureRef;
  DocumentReference? _selectedSurgeonRef;
  DocumentReference? _selectedAnesthesiologistRef;

  // Seleção múltipla
  List<DocumentReference> _selectedOpme = [];
  List<DocumentReference> _selectedBloodProducts = [];

  DateTime _selectedDate = DateTime.now();
  bool _needsICU = false;
  final bool _residentConfirmation = false; // Tornado final

  bool _isLoading = false;

  Future<void> _selectProcedure() async {
    final selectedId = await _medicalService.showSingleSelectionDialog(
      context: context,
      collection: 'procedures',
    );

    if (selectedId != null) {
      final docRef =
          FirebaseFirestore.instance.collection('procedures').doc(selectedId);
      final name = await _medicalService.getItemName(docRef);

      setState(() {
        _selectedProcedureRef = docRef;
        _procedureController.text = name;
      });
    }
  }

  Future<void> _selectSurgeon() async {
    final selectedId = await _medicalService.showSingleSelectionDialog(
      context: context,
      collection: 'surgeons',
    );

    if (selectedId != null) {
      final docRef =
          FirebaseFirestore.instance.collection('surgeons').doc(selectedId);
      final name = await _medicalService.getItemName(docRef);

      setState(() {
        _selectedSurgeonRef = docRef;
        _surgeonNameController.text = name;
      });
    }
  }

  Future<void> _selectAnesthesiologist() async {
    final selectedId = await _medicalService.showSingleSelectionDialog(
      context: context,
      collection: 'anesthesiologists',
    );

    if (selectedId != null) {
      final docRef = FirebaseFirestore.instance
          .collection('anesthesiologists')
          .doc(selectedId);
      final name = await _medicalService.getItemName(docRef);

      setState(() {
        _selectedAnesthesiologistRef = docRef;
        _anesthesiologistController.text = name;
      });
    }
  }

  Future<void> _selectOpme() async {
    final selectedIds = await _medicalService.showMultiSelectionDialog(
      context: context,
      collection: 'opme',
    );

    if (selectedIds != null && selectedIds.isNotEmpty) {
      final docRefs = selectedIds
          .map((id) => FirebaseFirestore.instance.collection('opme').doc(id))
          .toList();
      setState(() {
        _selectedOpme = docRefs;
      });
    }
  }

  Future<void> _selectBloodProducts() async {
    final selectedIds = await _medicalService.showMultiSelectionDialog(
      context: context,
      collection: 'blood_products',
    );

    if (selectedIds != null && selectedIds.isNotEmpty) {
      final docRefs = selectedIds
          .map((id) =>
              FirebaseFirestore.instance.collection('blood_products').doc(id))
          .toList();
      setState(() {
        _selectedBloodProducts = docRefs;
      });
    }
  }

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

  Future<void> _submit() async {
    if (_patientController.text.isEmpty ||
        _selectedProcedureRef == null ||
        _selectedSurgeonRef == null) {
      _showSnackBar('Selecione cirurgião e procedimento');
      return;
    }

    setState(() => _isLoading = true);

    final surgeryData = {
      'patientName': _patientController.text.trim(),
      'procedure': _selectedProcedureRef, // Usando a referência diretamente
      'surgeon': _selectedSurgeonRef,
      'anesthesiologist': _selectedAnesthesiologistRef,
      'opme': _selectedOpme, // Lista de referências selecionadas
      'bloodProducts':
          _selectedBloodProducts, // Lista de referências selecionadas
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
      _showSnackBar('Erro ao criar cirurgia: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildMultiSelectField({
    required BuildContext context,
    required String label,
    required List<DocumentReference> items,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4),
            ),
            child: items.isEmpty
                ? Text('Clique para selecionar $label')
                : Wrap(
                    spacing: 8,
                    children: items
                        .map(
                          (ref) => Chip(
                            label: FutureBuilder<DocumentSnapshot>(
                              future: ref.get(),
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  final data = snapshot.data!.data()
                                      as Map<String, dynamic>?;
                                  return Text(data?['name'] ?? 'Sem nome');
                                }
                                return const Text('Carregando...');
                              },
                            ),
                            onDeleted: () => setState(() => items.remove(ref)),
                          ),
                        )
                        .toList(),
                  ),
          ),
        ),
      ],
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
                      decoration: InputDecoration(
                        labelText: 'Procedimento',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: _selectProcedure,
                        ),
                      ),
                      readOnly: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              // Seleção de cirurgião
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
              // Seleção de anestesista
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _anesthesiologistController,
                      decoration: const InputDecoration(
                        labelText: 'Anestesista',
                        prefixIcon: Icon(Icons.medical_services_outlined),
                      ),
                      readOnly: true,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: _selectAnesthesiologist,
                  ),
                ],
              ),
              const SizedBox(height: 15),
              // Seleção múltipla de OPME
              _buildMultiSelectField(
                context: context,
                label: 'OPMe',
                items: _selectedOpme,
                onTap: _selectOpme,
              ),
              const SizedBox(height: 15),
              // Seleção múltipla de Produtos Sanguíneos
              _buildMultiSelectField(
                context: context,
                label: 'Produtos Sanguíneos',
                items: _selectedBloodProducts,
                onTap: _selectBloodProducts,
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
