import 'package:flutter/material.dart';
import 'package:cirurgiapp/src/core/models/user_model.dart';
import 'package:cirurgiapp/src/services/auth_service.dart';
import 'package:cirurgiapp/src/features/home/screens/role_confirmation_screen.dart';
import 'package:cirurgiapp/src/features/roles/screens/surgical_center/surgical_center_confirmation.dart';
import 'package:cirurgiapp/src/features/roles/screens/blood_bank/blood_bank_dashboard_screen.dart';
import 'package:cirurgiapp/src/features/roles/screens/uti/uti_confirmation_screen.dart';
import 'package:cirurgiapp/src/features/roles/screens/opme/opme_confirmation_screen.dart';

class ResidentDashboardScreen extends StatelessWidget {
  final HospitalUser user;

  const ResidentDashboardScreen({Key? key, required this.user})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Dashboard do Residente de Cirurgia'));
  }
}

class RoleHomeScreen extends StatefulWidget {
  final String role;
  final HospitalUser user;

  const RoleHomeScreen({
    Key? key,
    required this.role,
    required this.user,
  }) : super(key: key);

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
      'Residente de Cirurgia' => ResidentDashboardScreen(user: widget.user),
      'Centro Cirúrgico' => SurgicalCenterConfirmationScreen(user: widget.user),
      'Banco de Sangue' => BloodBankConfirmationScreen(user: widget.user),
      'UTI' => UTIConfirmationScreen(user: widget.user),
      'Centro de Material Hospitalar' =>
        OpmeConfirmationScreen(user: widget.user),
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
