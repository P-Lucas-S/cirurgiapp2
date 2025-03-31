import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cirurgiapp/src/core/constants/app_colors.dart' as core_colors;
import 'package:cirurgiapp/src/components/style_constants/typography.dart';
import 'package:cirurgiapp/src/core/models/user_model.dart';
import 'package:cirurgiapp/src/features/surgery/widgets/surgery_card.dart';

extension StringExtensions on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}

class SurgicalCenterConfirmationScreen extends StatefulWidget {
  final HospitalUser user;

  const SurgicalCenterConfirmationScreen({
    Key? key,
    required this.user,
  }) : super(key: key);

  @override
  State<SurgicalCenterConfirmationScreen> createState() =>
      _SurgicalCenterConfirmationScreenState();
}

class _SurgicalCenterConfirmationScreenState
    extends State<SurgicalCenterConfirmationScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _selectedFilter = 'todas';

  Stream<QuerySnapshot> _getSurgeriesStream() {
    List<String> statusList = _selectedFilter == 'todas'
        ? ['pendente', 'negada', 'confirmada']
        : [_selectedFilter];
    return _firestore
        .collection('surgeries')
        .where('status', whereIn: statusList)
        .where('requiredConfirmations', arrayContains: 'centro_cirurgico')
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Centro Cirúrgico',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: core_colors.AppColors.primary,
        foregroundColor: core_colors.AppColors.onPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context, '/login', (route) => false),
          ),
        ],
      ),
      body: Column(
        children: [
          // Seletor de filtro logo abaixo do AppBar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: DropdownButton<String>(
              value: _selectedFilter,
              isExpanded: true,
              items:
                  ['todas', 'pendente', 'negada', 'confirmada'].map((status) {
                return DropdownMenuItem<String>(
                  value: status,
                  child: Text(
                    status == 'todas' ? 'Todas' : status.capitalize(),
                  ),
                );
              }).toList(),
              onChanged: (newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedFilter = newValue;
                  });
                }
              },
            ),
          ),
          // StreamBuilder com os cartões de cirurgia
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getSurgeriesStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                      child: Text('Erro ao carregar cirurgias'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final surgeries = snapshot.data!.docs;
                if (surgeries.isEmpty) {
                  return Center(
                    child: Text(
                      'Nenhuma cirurgia pendente',
                      style: H2(textColor: core_colors.AppColors.onSurface),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: surgeries.length,
                  itemBuilder: (context, index) {
                    final doc = surgeries[index];
                    final surgery = doc.data() as Map<String, dynamic>;
                    return SurgeryCard(
                      surgeryId: doc.id,
                      surgery: surgery,
                      userRole: 'Centro Cirúrgico',
                      canConfirm: true,
                      onConfirm: () => _handleSurgicalCenterConfirmation(
                          doc.id, surgery, context),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _handleSurgicalCenterConfirmation(
      String surgeryId, Map<String, dynamic> surgery, BuildContext context) {
    bool isConfirmed = surgery['confirmations']?['centro_cirurgico'] ?? false;
    String? selectedRoom = surgery['surgeryRoom'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Confirmar Centro Cirúrgico'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: const Text('Confirmar Cirurgia'),
                  value: isConfirmed,
                  activeColor: core_colors.AppColors.primary,
                  onChanged: (value) => setState(() => isConfirmed = value),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedRoom,
                  decoration: InputDecoration(
                    labelText: 'Selecionar Sala',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Sala 1', child: Text('Sala 1')),
                    DropdownMenuItem(value: 'Sala 2', child: Text('Sala 2')),
                    DropdownMenuItem(value: 'Sala 3', child: Text('Sala 3')),
                    DropdownMenuItem(value: 'Sala 4', child: Text('Sala 4')),
                  ],
                  onChanged: (value) => setState(() => selectedRoom = value),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: core_colors.AppColors.primary,
                ),
                onPressed: () async {
                  try {
                    final surgeryRef = FirebaseFirestore.instance
                        .collection('surgeries')
                        .doc(surgeryId);
                    await FirebaseFirestore.instance
                        .runTransaction((transaction) async {
                      DocumentSnapshot surgerySnapshot =
                          await transaction.get(surgeryRef);
                      if (!surgerySnapshot.exists) {
                        throw Exception('Cirurgia não encontrada');
                      }
                      Map<String, dynamic> surgeryData =
                          Map<String, dynamic>.from(
                              surgerySnapshot.data() as Map);
                      List<String> requiredConfirmations =
                          (surgeryData['requiredConfirmations']
                                      as List<dynamic>?)
                                  ?.map((e) => e.toString())
                                  .toList() ??
                              [];
                      Map<String, dynamic> confirmations =
                          Map<String, dynamic>.from(
                              surgeryData['confirmations'] ?? {});

                      // Atualiza a confirmação do centro cirúrgico
                      confirmations['centro_cirurgico'] = isConfirmed;
                      surgeryData['confirmations'] = confirmations;

                      bool anyDenied = requiredConfirmations.any((role) =>
                          confirmations.containsKey(role) &&
                          confirmations[role] == false);

                      bool allConfirmed = requiredConfirmations.every((role) =>
                          confirmations.containsKey(role) &&
                          confirmations[role] == true);

                      String newStatus;
                      if (anyDenied) {
                        newStatus = 'negada';
                      } else if (allConfirmed) {
                        newStatus = 'confirmada';
                      } else {
                        newStatus = 'pendente';
                      }

                      Map<String, dynamic> updateData = {
                        'confirmations.centro_cirurgico': isConfirmed,
                        'status': newStatus,
                        'surgeryRoom': selectedRoom,
                      };

                      transaction.update(surgeryRef, updateData);
                    });
                    if (ctx.mounted) Navigator.pop(ctx);
                  } catch (e) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(
                          content: Text('Erro: ${e.toString()}'),
                        ),
                      );
                    }
                  }
                },
                child:
                    const Text('Salvar', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }
}
