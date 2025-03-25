import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cirurgiapp/src/core/constants/app_colors.dart'; // Importe suas cores
import 'package:cirurgiapp/src/services/surgery_service.dart';
import 'package:cirurgiapp/src/features/surgery/screens/create_surgery_screen.dart';
import 'package:cirurgiapp/src/features/surgery/widgets/surgery_card.dart';

class NIRDashboardScreen extends StatelessWidget {
  const NIRDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final SurgeryService surgeryService = SurgeryService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard do NIR'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            color: AppColors.onPrimary,
            onPressed: () => surgeryService.generateDailyReport(),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('surgeries')
            .orderBy('dateTime', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Erro ao carregar dados'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final surgeries = snapshot.data!.docs;

          if (surgeries.isEmpty) {
            return Center(
              child: Text(
                'Nenhuma cirurgia agendada',
                style: TextStyle(
                  fontSize: 18,
                  color: AppColors.onSurface,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemCount: surgeries.length,
            itemBuilder: (context, index) {
              final doc = surgeries[index];
              try {
                final surgery = doc.data() as Map<String, dynamic>;
                return SurgeryCard(
                  surgery: surgery,
                  surgeryId: doc.id,
                  canCancel: true,
                );
              } catch (e) {
                return _buildErrorCard(
                    'Formato de dados inválido na cirurgia ${doc.id}');
              }
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        child: const Icon(Icons.add),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const CreateSurgeryScreen(),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard(String message) => Card(
        color: AppColors.error,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.error, color: AppColors.onPrimary),
              const SizedBox(width: 8),
              Flexible(child: Text(message)),
            ],
          ),
        ),
      );
}
