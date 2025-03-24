import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cirurgiapp/src/core/extensions/string_extensions.dart'; // Caminho corrigido

class SurgeryListScreen extends StatelessWidget {
  final String statusFilter;

  const SurgeryListScreen({super.key, required this.statusFilter});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Cirurgias ${statusFilter.capitalize()}')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('surgeries')
            .where('status', isEqualTo: statusFilter)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final surgeries = snapshot.data!.docs;

          if (surgeries.isEmpty) {
            return const Center(child: Text('Nenhuma cirurgia encontrada'));
          }

          return ListView.builder(
            itemCount: surgeries.length,
            itemBuilder: (context, index) {
              final surgery = surgeries[index].data() as Map<String, dynamic>;
              return ListTile(
                title: Text(surgery['patientName'] ?? 'Paciente desconhecido'),
                subtitle: Text(
                  surgery['procedure'] ?? 'Procedimento não especificado',
                ),
              );
            },
          );
        },
      ),
    );
  }
}
