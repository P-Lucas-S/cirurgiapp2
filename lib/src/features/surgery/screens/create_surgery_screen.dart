import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

  final SurgeryService _surgeryService = SurgeryService();
  final MedicalDataService _medicalService = MedicalDataService();

  // Seleção única
  DocumentReference? _selectedProcedureRef;
  DocumentReference? _selectedSurgeonRef;
  DocumentReference? _selectedAnesthesiologistRef;

  // Seleção múltipla de OPME (lista com objetos que contêm materialId e quantity)
  List<dynamic> _selectedOpme = [];

  // Produtos sanguíneos: mapa (id do produto -> quantidade)
  Map<String, int> _selectedBloodProducts = {};

  // Data e hora da cirurgia
  DateTime _selectedDateTime = DateTime.now();
  bool _needsICU = false;

  bool _isLoading = false;

  Future<void> _selectProcedure() async {
    final selectedId = await _medicalService.showSingleSelectionDialog(
      context: context,
      collection: 'procedures',
    );
    if (!mounted) return;
    if (selectedId != null) {
      final docRef =
          FirebaseFirestore.instance.collection('procedures').doc(selectedId);
      final name = await _medicalService.getItemName(docRef);
      if (!mounted) return;
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
    if (!mounted) return;
    if (selectedId != null) {
      final docRef =
          FirebaseFirestore.instance.collection('surgeons').doc(selectedId);
      final name = await _medicalService.getItemName(docRef);
      if (!mounted) return;
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
    if (!mounted) return;
    if (selectedId != null) {
      final docRef = FirebaseFirestore.instance
          .collection('anesthesiologists')
          .doc(selectedId);
      final name = await _medicalService.getItemName(docRef);
      if (!mounted) return;
      setState(() {
        _selectedAnesthesiologistRef = docRef;
        _anesthesiologistController.text = name;
      });
    }
  }

  Future<void> _selectOpme() async {
    final selected = await _medicalService.showOpmeSelectionDialog(context);
    if (!mounted) return;
    if (selected != null) {
      setState(() {
        _selectedOpme = selected;
      });
    }
  }

  Future<void> _selectBloodProducts() async {
    final selected =
        await _medicalService.showBloodProductSelectionDialog(context);
    if (!mounted) return;
    if (selected != null) {
      setState(() {
        _selectedBloodProducts = selected;
      });
    }
  }

  // Widget para exibir os produtos sanguíneos selecionados
  Widget _buildBloodProductsField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Produtos Sanguíneos',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        InkWell(
          onTap: _selectBloodProducts,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4),
            ),
            child: _selectedBloodProducts.isEmpty
                ? const Text('Clique para selecionar produtos')
                : Wrap(
                    spacing: 8,
                    children: _selectedBloodProducts.entries.map((entry) {
                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('blood_products')
                            .doc(entry.key)
                            .get(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            final product =
                                snapshot.data!.data() as Map<String, dynamic>;
                            return Chip(
                              label: Text('${product['name']}: ${entry.value}'),
                              onDeleted: () => setState(() {
                                _selectedBloodProducts.remove(entry.key);
                              }),
                            );
                          }
                          return const CircularProgressIndicator();
                        },
                      );
                    }).toList(),
                  ),
          ),
        ),
      ],
    );
  }

  // Novo widget para exibir os materiais OPME selecionados
  Widget _buildOpmeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Materiais OPME',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        InkWell(
          onTap: _selectOpme,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4),
            ),
            child: _selectedOpme.isEmpty
                ? const Text('Clique para selecionar materiais')
                : Wrap(
                    spacing: 8,
                    children: _selectedOpme.map((item) {
                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('opme')
                            .doc(item['materialId'])
                            .get(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            final material =
                                snapshot.data!.data() as Map<String, dynamic>;
                            return Chip(
                              label: Text(
                                  '${material['name']}: ${item['quantity']}'),
                              deleteIcon: const Icon(Icons.edit),
                              onDeleted: () => setState(() {
                                _selectedOpme.remove(item);
                              }),
                            );
                          }
                          return const CircularProgressIndicator();
                        },
                      );
                    }).toList(),
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (!mounted) return;
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      );
      if (!mounted) return;
      if (pickedTime != null) {
        setState(() {
          _selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
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

    // Criação da lista de requiredConfirmations (movida para antes do uso)
    List<String> requiredConfirmations = ['residente', 'centro_cirurgico'];

    // Cria um mapa para as confirmações
    final confirmations = <String, bool>{};
    for (var role in requiredConfirmations) {
      confirmations[role] = false;
    }

    // Adicionar confirmações condicionais
    if (_selectedOpme.isNotEmpty) {
      requiredConfirmations.add('material_hospitalar');
      confirmations['material_hospitalar'] = false;
    } else {
      confirmations['material_hospitalar'] = true;
    }

    if (_selectedBloodProducts.isNotEmpty) {
      requiredConfirmations.add('banco_sangue');
      confirmations['banco_sangue'] = false;
    } else {
      confirmations['banco_sangue'] = true;
    }

    if (_needsICU) {
      requiredConfirmations.add('uti');
      confirmations['uti'] = false;
    } else {
      confirmations['uti'] = true;
    }

    final surgeryData = {
      'patientName': _patientController.text.trim(),
      'procedure': _selectedProcedureRef,
      'surgeon': _selectedSurgeonRef,
      'anesthesiologist': _selectedAnesthesiologistRef,
      'opme': _selectedOpme,
      'bloodProducts':
          _selectedBloodProducts.map((key, value) => MapEntry(key, value)),
      'needsICU': _needsICU,
      'dateTime': _selectedDateTime,
      'confirmations': confirmations,
      'bloodProductsConfirmation': {},
      'requiredConfirmations': requiredConfirmations,
    };

    try {
      await _surgeryService.createSurgery(surgeryData);
      _showSnackBar('Cirurgia criada com sucesso!');
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
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
              // Seleção de materiais OPME
              _buildOpmeField(),
              const SizedBox(height: 15),
              // Seleção de produtos sanguíneos
              _buildBloodProductsField(),
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
              // Data e Hora da cirurgia
              TextFormField(
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Data e Hora da Cirurgia',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: _selectDateTime,
                  ),
                ),
                controller: TextEditingController(
                  text:
                      DateFormat('dd/MM/yyyy HH:mm').format(_selectedDateTime),
                ),
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
