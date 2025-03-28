import 'package:flutter/material.dart';
import 'package:cirurgiapp/src/core/models/user_model.dart';
import 'package:cirurgiapp/src/services/auth_service.dart';
import 'package:cirurgiapp/src/features/home/screens/role_confirmation_screen.dart';

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
      _ => RoleConfirmationScreen(
          role: widget.role,
          user: widget.user,
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.role),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: _buildRoleSpecificContent(),
    );
  }
}
