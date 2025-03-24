import 'package:flutter/material.dart';
import 'package:cirurgiapp/src/core/models/user_model.dart';
import 'package:cirurgiapp/src/services/auth_service.dart';
import 'package:cirurgiapp/src/features/home/screens/role_confirmation_screen.dart'; // Certifique-se de que o caminho está correto

class RoleHomeScreen extends StatefulWidget {
  final String role;
  final HospitalUser user;

  const RoleHomeScreen({super.key, required this.role, required this.user});

  @override
  _RoleHomeScreenState createState() => _RoleHomeScreenState();
}

class _RoleHomeScreenState extends State<RoleHomeScreen> {
  Future<void> _logout() async {
    await AuthService().signOut();
    if (!mounted) return; // Verifica se o widget ainda está montado
    Navigator.pushReplacementNamed(context, '/login');
  }

  Widget _buildNIRDashboard() {
    return const Center(child: Text('Dashboard do NIR'));
  }

  Widget _buildRoleSpecificContent() {
    final confirmationRoles = {
      'Residente de Cirurgia',
      'Centro Cirúrgico',
      'Banco de Sangue',
      'UTI',
      'Centro de Material Hospitalar'
    };

    if (confirmationRoles.contains(widget.role)) {
      return RoleConfirmationScreen(role: widget.role, user: widget.user);
    }

    return switch (widget.role) {
      'NIR' => _buildNIRDashboard(),
      _ => const Center(child: Text('Visualização não implementada')),
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
