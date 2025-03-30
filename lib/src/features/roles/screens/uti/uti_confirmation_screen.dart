// lib/src/features/roles/screens/uti/uti_confirmation_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cirurgiapp/src/core/constants/app_colors.dart' as core_colors;
import 'package:cirurgiapp/src/components/style_constants/typography.dart';
import 'package:cirurgiapp/src/core/models/user_model.dart';
import 'package:cirurgiapp/src/features/surgery/widgets/surgery_card.dart';

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

  Stream<QuerySnapshot> get _surgeriesStream => _firestore
      .collection('surgeries')
      .where('needsICU', isEqualTo: true)
      .where('status', isEqualTo: 'pendente')
      .snapshots();

  Future<void> _confirmUTI(String surgeryId, bool confirmed) async {
    try {
      final updateData = {
        'confirmations.uti': confirmed,
        'status': confirmed ? 'confirmada' : 'negada',
        'denialReason': confirmed ? null : 'UTI não disponível',
      };

      await _firestore
          .collection('surgeries')
          .doc(surgeryId)
          .update(updateData);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro na confirmação: ${e.toString()}')),
        );
      }
    }
  }

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
      body: StreamBuilder<QuerySnapshot>(
        stream: _surgeriesStream,
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
    );
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
      builder: (context) => AlertDialog(
        title: const Text('Confirmar UTI'),
        content: Text('Confirmar disponibilidade de leito na UTI para '
            '${surgery['patientName']}?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _confirmUTI(surgeryId, false);
            },
            child: const Text('Negar', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
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
}
