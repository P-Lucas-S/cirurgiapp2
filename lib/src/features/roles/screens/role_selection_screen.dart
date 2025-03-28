import 'package:flutter/material.dart';
import 'package:cirurgiapp/src/core/constants/app_colors.dart';
import 'package:cirurgiapp/src/core/models/user_model.dart';
import 'package:cirurgiapp/src/components/buttons/elevated_buttons.dart';
import 'package:cirurgiapp/src/features/home/screens/role_home_screen.dart';
import 'package:cirurgiapp/src/features/roles/screens/nir/nir_dashboard_screen.dart';
import 'package:cirurgiapp/src/features/roles/screens/resident/resident_dashboard_screen.dart'
    as resident;

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  void _selectRole(String role, BuildContext context) {
    final user = ModalRoute.of(context)!.settings.arguments as HospitalUser;

    Widget screen = switch (role) {
      'NIR' => const NIRDashboardScreen(),
      'Residente de Cirurgia' => resident.ResidentDashboardScreen(user: user),
      _ => RoleHomeScreen(role: role, user: user),
    };

    // Alterado de pushReplacement para push
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ModalRoute.of(context)!.settings.arguments as HospitalUser;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        centerTitle: true,
        title: const Text(
          'Selecione seu Cargo',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 20.0),
        child: ListView.separated(
          itemCount: user.roles.length,
          separatorBuilder: (context, index) => const SizedBox(height: 15),
          itemBuilder: (context, index) {
            final role = user.roles[index];
            return SimpleButton(
              dark: true,
              title: role,
              onTap: () => _selectRole(role, context),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
            );
          },
        ),
      ),
    );
  }
}
