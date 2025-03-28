import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cirurgiapp/src/core/constants/app_colors.dart';
import 'package:cirurgiapp/src/features/surgery/widgets/surgery_card.dart';
import 'package:cirurgiapp/src/core/models/user_model.dart';
import 'package:cirurgiapp/src/services/auth_service.dart';
import 'package:cirurgiapp/src/features/auth/screens/login_screen.dart';

class ResidentDashboardScreen extends StatelessWidget {
  final HospitalUser user;
  const ResidentDashboardScreen({super.key, required this.user});

  void _logout(BuildContext context) async {
    await AuthService().signOut();
    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Residente',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('surgeries')
            .where('status', isEqualTo: 'pendente')
            .orderBy('dateTime', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          // Debug para verificar os dados
          debugPrint(
              'Dados recebidos: ${snapshot.data?.docs.length ?? 0} cirurgias');
          if (snapshot.hasError) debugPrint('Erro: ${snapshot.error}');

          if (snapshot.hasError) {
            return Center(
              child: Text('Erro: ${snapshot.error.toString()}',
                  style: const TextStyle(color: Colors.red)),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Nenhuma cirurgia pendente'));
          }

          final surgeries = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemCount: surgeries.length,
            itemBuilder: (context, index) {
              final doc = surgeries[index];
              return SurgeryCard(
                surgery: doc.data() as Map<String, dynamic>,
                surgeryId: doc.id,
                userRole: 'Residente de Cirurgia',
                canConfirm: true,
                canCancel: false,
              );
            },
          );
        },
      ),
    );
  }
}
