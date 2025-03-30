import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cirurgiapp/src/core/constants/app_colors.dart' as core_colors;
import 'package:cirurgiapp/src/components/style_constants/typography.dart';
import 'package:cirurgiapp/src/core/models/user_model.dart';
import 'package:cirurgiapp/src/features/surgery/widgets/surgery_card.dart';

class SurgicalCenterConfirmationScreen extends StatelessWidget {
  final HospitalUser user;

  const SurgicalCenterConfirmationScreen({
    Key? key,
    required this.user,
  }) : super(key: key);

  // Getter para obter o stream das cirurgias pendentes
  Stream<QuerySnapshot> get _surgeriesStream => FirebaseFirestore.instance
      .collection('surgeries')
      .where('status', isEqualTo: 'pendente')
      .snapshots();

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
            return const Center(child: Text('Erro ao carregar cirurgias'));
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
              );
            },
          );
        },
      ),
    );
  }
}
