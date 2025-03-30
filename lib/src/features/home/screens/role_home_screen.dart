import 'package:flutter/material.dart';
import 'package:cirurgiapp/src/core/models/user_model.dart';
import 'package:cirurgiapp/src/services/auth_service.dart';
import 'package:cirurgiapp/src/features/home/screens/role_confirmation_screen.dart';
import 'package:cirurgiapp/src/features/roles/screens/surgical_center/surgical_center_confirmation.dart';
import 'package:cirurgiapp/src/features/roles/screens/blood_bank/blood_bank_confirmation_screen.dart';

// Stub para ResidentDashboardScreen, ajuste conforme a implementação real.
class ResidentDashboardScreen extends StatelessWidget {
  const ResidentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Dashboard do Residente de Cirurgia'));
  }
}

class RoleHomeScreen extends StatefulWidget {
  final String role;
  final HospitalUser user;

  const RoleHomeScreen({
    super.key,
    required this.role,
    required this.user,
  });

  @override
  State<RoleHomeScreen> createState() => _RoleHomeScreenState();
}

class _RoleHomeScreenState extends State<RoleHomeScreen> {
  Future<void> _logout() async {
    await AuthService().signOut();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  Widget _buildNIRDashboard() {
    return const Center(child: Text('Dashboard do NIR'));
  }

  Widget _buildRoleSpecificContent() {
    final hasRole = widget.user.roles.contains(widget.role);

    if (!hasRole) {
      return const Center(child: Text('Acesso não autorizado para este cargo'));
    }

    return switch (widget.role) {
      'NIR' => _buildNIRDashboard(),
      'Residente de Cirurgia' => const ResidentDashboardScreen(),
      'Centro Cirúrgico' => SurgicalCenterConfirmationScreen(user: widget.user),
      'Banco de Sangue' =>
        BloodBankConfirmationScreen(user: widget.user), // Novo
      _ => RoleConfirmationScreen(role: widget.role, user: widget.user),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _shouldShowAppBar()
          ? AppBar(
              title: Text(widget.role),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: _logout,
                ),
              ],
            )
          : null,
      body: _buildRoleSpecificContent(),
    );
  }

  bool _shouldShowAppBar() {
    return !widget.user.roles.contains('Centro Cirúrgico');
  }
}
