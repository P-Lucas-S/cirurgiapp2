// lib/src/features/roles/screens/uti/uti_confirmation_screen.dart
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

class UTIConfirmationScreen extends StatefulWidget {
  final HospitalUser user;

  const UTIConfirmationScreen({
    super.key,
    required this.user,
  });

  @override
  State<UTIConfirmationScreen> createState() => _UTIConfirmationScreenState();
}

class _UTIConfirmationScreenState extends State<UTIConfirmationScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _selectedFilter = 'todas';

  Stream<QuerySnapshot> _getSurgeriesStream() {
    List<String> statusList = _selectedFilter == 'todas'
        ? ['pendente', 'negada', 'confirmada']
        : [_selectedFilter];

    return _firestore
        .collection('surgeries')
        .where('status', whereIn: statusList)
        .where('requiredConfirmations',
            arrayContains: 'uti') // Ajustado para UTI
        .snapshots();
  }

  Future<void> _confirmUTI(String surgeryId, bool confirmed) async {
    try {
      final surgeryRef = _firestore.collection('surgeries').doc(surgeryId);
      await _firestore.runTransaction((transaction) async {
        final surgerySnapshot = await transaction.get(surgeryRef);
        if (!surgerySnapshot.exists) {
          throw Exception('Cirurgia não encontrada');
        }
        final surgeryData =
            Map<String, dynamic>.from(surgerySnapshot.data() as Map);
        final requiredConfirmations =
            (surgeryData['requiredConfirmations'] as List<dynamic>?)
                    ?.map((e) => e.toString())
                    .toList() ??
                [];
        final confirmations =
            Map<String, dynamic>.from(surgeryData['confirmations'] ?? {});

        // Atualiza a confirmação para UTI
        confirmations['uti'] = confirmed;
        surgeryData['confirmations'] = confirmations;

        bool anyDenied = requiredConfirmations.any((role) =>
            confirmations.containsKey(role) && confirmations[role] == false);

        bool allConfirmed = requiredConfirmations.every((role) =>
            confirmations.containsKey(role) && confirmations[role] == true);

        String newStatus;
        if (anyDenied) {
          newStatus = 'negada';
        } else if (allConfirmed) {
          newStatus = 'confirmada';
        } else {
          newStatus = 'pendente';
        }

        final updateData = {
          'confirmations.uti': confirmed,
          'status': newStatus,
          'denialReason': confirmed ? null : 'UTI não disponível',
        };

        transaction.update(surgeryRef, updateData);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro na confirmação: ${e.toString()}')),
        );
      }
    }
  }

  Widget _buildSurgeryCard(String surgeryId, Map<String, dynamic> surgery) {
    return SurgeryCard(
      surgeryId: surgeryId,
      surgery: surgery,
      userRole: 'UTI',
      canConfirm: true,
      onConfirm: () => _showConfirmationDialog(surgeryId, surgery),
    );
  }

  void _showConfirmationDialog(String surgeryId, Map<String, dynamic> surgery) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar UTI'),
        content: Text(
            'Confirmar disponibilidade de leito na UTI para ${surgery['patientName']}?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _confirmUTI(surgeryId, false);
            },
            child: const Text('Negar', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _confirmUTI(surgeryId, true);
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() =>
      const Center(child: CircularProgressIndicator());

  Widget _buildErrorWidget() => Center(
        child: Text(
          'Erro ao carregar cirurgias',
          style: H2(textColor: core_colors.AppColors.onSurface),
        ),
      );

  Widget _buildEmptyListWidget() => Center(
        child: Text(
          'Nenhuma cirurgia pendente requer UTI',
          style: H2(textColor: core_colors.AppColors.onSurface),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('UTI'),
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
              isExpanded: true,
              value: _selectedFilter,
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
                  setState(() => _selectedFilter = newValue);
                }
              },
            ),
          ),
          // Lista de SurgeryCards
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getSurgeriesStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return _buildErrorWidget();
                if (!snapshot.hasData) return _buildLoadingIndicator();

                final surgeries = snapshot.data!.docs;
                if (surgeries.isEmpty) return _buildEmptyListWidget();

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
          ),
        ],
      ),
    );
  }
}
