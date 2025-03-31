import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cirurgiapp/src/core/constants/app_colors.dart';
import 'package:cirurgiapp/src/features/surgery/widgets/surgery_card.dart';
import 'package:cirurgiapp/src/core/models/user_model.dart';
import 'package:cirurgiapp/src/services/auth_service.dart';
import 'package:cirurgiapp/src/features/auth/screens/login_screen.dart';

extension StringExtensions on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}

class ResidentDashboardScreen extends StatefulWidget {
  final HospitalUser user;
  const ResidentDashboardScreen({Key? key, required this.user})
      : super(key: key);

  @override
  State<ResidentDashboardScreen> createState() =>
      _ResidentDashboardScreenState();
}

class _ResidentDashboardScreenState extends State<ResidentDashboardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _selectedFilter = 'todas';

  Future<void> _logout() async {
    await AuthService().signOut();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  Stream<QuerySnapshot> _getSurgeriesStream() {
    List<String> statusList = _selectedFilter == 'todas'
        ? ['pendente', 'negada', 'confirmada']
        : [_selectedFilter];
    return _firestore
        .collection('surgeries')
        .where('status', whereIn: statusList)
        .orderBy('dateTime', descending: true)
        .where('requiredConfirmations', arrayContains: 'residente')
        .snapshots();
  }

  Future<void> _updateResidentConfirmation(
      String surgeryId, bool newValue) async {
    try {
      final surgeryRef =
          FirebaseFirestore.instance.collection('surgeries').doc(surgeryId);
      await FirebaseFirestore.instance.runTransaction((transaction) async {
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

        // Atualiza a confirmação do residente
        confirmations['residente'] = newValue;
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
          'confirmations.residente': newValue,
          'status': newStatus,
        };

        transaction.update(surgeryRef, updateData);
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              newValue ? 'Pré-operatório confirmado!' : 'Confirmação removida'),
        ),
      );
      setState(() {}); // Atualiza a UI se necessário
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _handleResidentConfirmation(
      String surgeryId, Map<String, dynamic> surgery) {
    final bool currentConfirmation =
        surgery['confirmations']?['residente'] ?? false;
    final bool newValue = !currentConfirmation;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(newValue
              ? 'Confirmar Pré-Operatório'
              : 'Desconfirmar Pré-Operatório'),
          content: Text(newValue
              ? 'Confirmar que o pré-operatório foi realizado conforme protocolo?'
              : 'Deseja retirar a confirmação do pré-operatório?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await _updateResidentConfirmation(surgeryId, newValue);
              },
              child: Text(newValue ? 'Confirmar' : 'Desconfirmar'),
            ),
          ],
        );
      },
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
            onPressed: _logout,
          ),
        ],
      ),
      body: Column(
        children: [
          // Seletor de filtro abaixo do AppBar
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
                debugPrint(
                    'Dados recebidos: ${snapshot.data?.docs.length ?? 0} cirurgias');
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Erro: ${snapshot.error}',
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
                      doc.id,
                      doc.data() as Map<String, dynamic>,
                    );
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
