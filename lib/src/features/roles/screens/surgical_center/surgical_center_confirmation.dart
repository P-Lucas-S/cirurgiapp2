// lib/src/features/roles/screens/surgical_center/surgical_center_confirmation.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cirurgiapp/src/core/constants/app_colors.dart' as core_colors;
import 'package:cirurgiapp/src/components/style_constants/typography.dart';
import 'package:cirurgiapp/src/core/models/user_model.dart';
import 'package:cirurgiapp/src/features/surgery/widgets/surgery_card.dart'; // Certifique-se de que o caminho esteja correto

class SurgicalCenterConfirmationScreen extends StatefulWidget {
  final HospitalUser user;

  const SurgicalCenterConfirmationScreen({
    super.key,
    required this.user,
  });

  @override
  State<SurgicalCenterConfirmationScreen> createState() =>
      _SurgicalCenterConfirmationScreenState();
}

class _SurgicalCenterConfirmationScreenState
    extends State<SurgicalCenterConfirmationScreen> {
  final List<String> _surgeryRooms = ['Sala 1', 'Sala 2', 'Sala 3', 'Sala 4'];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Getter para obter o stream das cirurgias pendentes
  Stream<QuerySnapshot> get _surgeriesStream => _firestore
      .collection('surgeries')
      .where('status', isEqualTo: 'pendente')
      .snapshots();

  Future<void> _confirmSurgery(String surgeryId, bool value) async {
    try {
      await _firestore.collection('surgeries').doc(surgeryId).update({
        'confirmations.centro_cirurgico': value,
        'confirmedBy.centro_cirurgico': widget.user.uid,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro na confirmação: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _updateSurgeryRoom(String surgeryId, String? room) async {
    if (room == null) return;
    try {
      await _firestore.collection('surgeries').doc(surgeryId).update({
        'surgeryRoom': room,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar sala: ${e.toString()}')),
        );
      }
    }
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
      body: StreamBuilder<QuerySnapshot>(
        stream: _surgeriesStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Erro ao carregar cirurgias'));
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
              return _buildSurgeryCard(doc.id, surgery);
            },
          );
        },
      ),
    );
  }

  Widget _buildSurgeryCard(String surgeryId, Map<String, dynamic> surgery) {
    return SurgeryCard(
      surgeryId: surgeryId,
      surgery: surgery,
      userRole: 'Centro Cirúrgico',
      canConfirm: true,
    );
  }

  Color _getStatusColor(Map<String, dynamic> surgery) {
    return surgery['confirmations']['centro_cirurgico'] ?? false
        ? core_colors.AppColors.success
        : core_colors.AppColors.error;
  }

  void _showConfirmationDialog(String surgeryId, Map<String, dynamic> surgery) {
    String? selectedRoom = surgery['surgeryRoom'];
    bool isConfirmed = surgery['confirmations']['centro_cirurgico'] ?? false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Confirmar Centro Cirúrgico'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildPatientInfo(surgery),
                const SizedBox(height: 20),
                _buildConfirmationSwitch(isConfirmed, (value) {
                  setState(() => isConfirmed = value);
                  _confirmSurgery(surgeryId, value);
                }),
                const SizedBox(height: 15),
                _buildRoomDropdown(selectedRoom, (value) {
                  setState(() => selectedRoom = value);
                  _updateSurgeryRoom(surgeryId, value);
                }),
                const SizedBox(height: 15),
                // Novo widget para exibir os produtos sanguíneos
                _buildBloodProducts(surgery),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fechar'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPatientInfo(Map<String, dynamic> surgery) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          surgery['patientName'] ?? 'Paciente não informado',
          style: H2(textColor: core_colors.AppColors.onSurface),
        ),
        const SizedBox(height: 8),
        FutureBuilder<DocumentSnapshot>(
          future: (surgery['procedure'] as DocumentReference).get(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox();
            final procedure = snapshot.data!.data() as Map<String, dynamic>;
            return Text(
              procedure['name'] ?? 'Procedimento não informado',
              style: BODY(textColor: core_colors.AppColors.onSurface),
            );
          },
        ),
      ],
    );
  }

  Widget _buildConfirmationSwitch(bool value, ValueChanged<bool> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Confirmar:',
          style: BODY(textColor: core_colors.AppColors.onSurface),
        ),
        Switch(
          value: value,
          activeColor: core_colors.AppColors.success,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildRoomDropdown(String? value, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: 'Selecionar Sala',
        border: OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      ),
      items: _surgeryRooms
          .map((room) => DropdownMenuItem(
                value: room,
                child: Text(room),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }

  // Novo widget para exibir os produtos sanguíneos
  Widget _buildBloodProducts(Map<String, dynamic> surgery) {
    final products = surgery['bloodProducts'] as Map<String, dynamic>? ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Produtos Sanguíneos:'),
        ...products.entries.map((entry) => FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('blood_products')
                  .doc(entry.key)
                  .get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();
                final product = snapshot.data!.data() as Map<String, dynamic>;
                return Text('${product['name']}: ${entry.value}');
              },
            )),
      ],
    );
  }
}
