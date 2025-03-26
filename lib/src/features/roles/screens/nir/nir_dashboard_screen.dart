import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cirurgiapp/src/core/constants/app_colors.dart';
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
            return _buildErrorWidget('Erro ao carregar cirurgias');
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingIndicator();
          }
          final surgeries = snapshot.data!.docs;
          return _buildSurgeriesList(surgeries);
        },
      ),
      floatingActionButton: _buildAddSurgeryButton(context),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: CircularProgressIndicator(color: AppColors.primary),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Center(
      child: Text(
        message,
        style: TextStyle(fontSize: 18, color: AppColors.onSurface),
      ),
    );
  }

  Widget _buildSurgeriesList(List<QueryDocumentSnapshot> surgeries) {
    if (surgeries.isEmpty) {
      return _buildErrorWidget('Nenhuma cirurgia agendada');
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemCount: surgeries.length,
      itemBuilder: (context, index) {
        final doc = surgeries[index];
        return SurgeryCard(
          surgery: doc.data() as Map<String, dynamic>,
          surgeryId: doc.id,
          canCancel: true,
        );
      },
    );
  }

  Widget _buildAddSurgeryButton(BuildContext context) {
    return FloatingActionButton(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.onPrimary,
      child: const Icon(Icons.add),
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const CreateSurgeryScreen(),
        ),
      ),
    );
  }
}
