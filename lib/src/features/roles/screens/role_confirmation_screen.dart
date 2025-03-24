import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cirurgiapp/src/core/models/user_model.dart';
import 'package:cirurgiapp/src/services/surgery_service.dart';

/// Extensão para adicionar o método [capitalize] à classe [String]
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}

class RoleConfirmationScreen extends StatelessWidget {
  final String role;
  final HospitalUser user;

  const RoleConfirmationScreen({
    super.key,
    required this.role,
    required this.user,
  });

  String _getConfirmationField() {
    return switch (role) {
      'Residente de Cirurgia' => 'residente',
      'Centro Cirúrgico' => 'centro_cirurgico',
      'Banco de Sangue' => 'banco_sangue',
      'UTI' => 'uti',
      'Centro de Material Hospitalar' => 'material_hospitalar',
      _ => '',
    };
  }

  Widget _buildConfirmationUI(Map<String, dynamic> surgery, String docId) {
    final confirmationField = _getConfirmationField();
    final SurgeryService surgeryService = SurgeryService();

    return ListTile(
      title: Text(surgery['patientName']),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Procedimento: ${surgery['procedure']}'),
          Text('Status: ${surgery['status']?.toString().capitalize()}'),
        ],
      ),
      trailing: Switch(
        value: surgery['confirmations'][confirmationField] ?? false,
        onChanged: (value) async {
          await surgeryService.confirmRequirement(docId, confirmationField);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Confirmações - $role'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('surgeries')
            .where('status', isEqualTo: 'pendente')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return const Center(child: Text('Erro ao carregar dados'));
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              return Card(
                margin: const EdgeInsets.all(8),
                child: _buildConfirmationUI(
                    doc.data() as Map<String, dynamic>, doc.id),
              );
            },
          );
        },
      ),
    );
  }
}
