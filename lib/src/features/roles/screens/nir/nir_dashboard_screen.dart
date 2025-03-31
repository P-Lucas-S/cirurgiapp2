import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cirurgiapp/src/core/constants/app_colors.dart';
import 'package:cirurgiapp/src/services/auth_service.dart';
import 'package:cirurgiapp/src/features/auth/screens/login_screen.dart';
import 'package:cirurgiapp/src/features/surgery/screens/create_surgery_screen.dart';
import 'package:cirurgiapp/src/features/surgery/widgets/surgery_card.dart';

extension StringExtensions on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}

class NIRDashboardScreen extends StatefulWidget {
  const NIRDashboardScreen({super.key});

  @override
  State<NIRDashboardScreen> createState() => _NIRDashboardScreenState();
}

class _NIRDashboardScreenState extends State<NIRDashboardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _selectedFilter = 'todas';

  Stream<QuerySnapshot> _getSurgeriesStream() {
    List<String> statusList = _selectedFilter == 'todas'
        ? ['pendente', 'negada', 'confirmada']
        : [_selectedFilter];

    return _firestore
        .collection('surgeries')
        .orderBy('dateTime', descending: true)
        .where('status', whereIn: statusList)
        .snapshots();
  }

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
          'NIR',
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
      body: Column(
        children: [
          // Seletor de filtro posicionado abaixo do AppBar
          Padding(
            padding: const EdgeInsets.all(16),
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
          // Lista de cirurgias
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getSurgeriesStream(),
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
          ),
        ],
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
          userRole: 'NIR',
          canCancel: true,
          canConfirm: false,
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
