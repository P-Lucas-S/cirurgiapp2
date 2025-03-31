import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cirurgiapp/src/core/constants/app_colors.dart';
import 'package:cirurgiapp/src/features/surgery/widgets/surgery_card.dart';
import 'package:cirurgiapp/src/core/models/user_model.dart';
import 'package:cirurgiapp/src/services/auth_service.dart';
import 'package:cirurgiapp/src/features/auth/screens/login_screen.dart';
import 'package:cirurgiapp/src/services/surgery_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ResidentDashboardScreen extends StatefulWidget {
  final HospitalUser user;
  const ResidentDashboardScreen({super.key, required this.user});

  @override
  State<ResidentDashboardScreen> createState() =>
      _ResidentDashboardScreenState();
}

class _ResidentDashboardScreenState extends State<ResidentDashboardScreen> {
  void _logout(BuildContext context) async {
    await AuthService().signOut();
    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  void _handleResidentConfirmation(
      String surgeryId, Map<String, dynamic> surgery) {
    final newValue = !(surgery['confirmations']?['residente'] ?? false);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(newValue
            ? 'Confirmar Pré-Operatório'
            : 'Desconfirmar Pré-Operatório'),
        content: Text(newValue
            ? 'Confirmar que o pré-operatório foi realizado conforme protocolo?'
            : 'Deseja retirar a confirmação do pré-operatório?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await SurgeryService().confirmRequirement(
                  surgeryId,
                  'residente',
                  FirebaseAuth.instance.currentUser!.uid,
                  newValue,
                );
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(newValue
                          ? 'Pré-operatório confirmado!'
                          : 'Confirmação removida'),
                    ),
                  );
                }
                setState(() {});
              } catch (e) {
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erro: ${e.toString()}'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: Text(newValue ? 'Confirmar' : 'Desconfirmar'),
          ),
        ],
      ),
    );
  }

  Widget _buildSurgeryCard(String surgeryId, Map<String, dynamic> surgery) {
    return SurgeryCard(
      surgeryId: surgeryId,
      surgery: surgery,
      userRole: 'Residente de Cirurgia',
      canConfirm: true,
      onConfirm: () => _handleResidentConfirmation(surgeryId, surgery),
      canCancel: false,
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
          debugPrint(
              'Dados recebidos: ${snapshot.data?.docs.length ?? 0} cirurgias');
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Erro: ${snapshot.error.toString()}',
                style: const TextStyle(color: Colors.red),
              ),
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
              return _buildSurgeryCard(
                  doc.id, doc.data() as Map<String, dynamic>);
            },
          );
        },
      ),
    );
  }
}
