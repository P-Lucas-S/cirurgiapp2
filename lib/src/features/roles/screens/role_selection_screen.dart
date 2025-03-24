import 'package:cirurgiapp/src/features/roles/screens/nir/nir_dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:cirurgiapp/src/core/models/user_model.dart';
import 'package:cirurgiapp/src/features/home/screens/role_home_screen.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  void _selectRole(String role, BuildContext context) {
    final user = ModalRoute.of(context)!.settings.arguments as HospitalUser;

    // Usando a expressão switch para definir a tela com base no cargo selecionado
    Widget screen = switch (role) {
      'NIR' => const NIRDashboardScreen(),
      _ => RoleHomeScreen(role: role, user: user),
    };

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ModalRoute.of(context)!.settings.arguments as HospitalUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecione seu Cargo'),
      ),
      body: ListView.builder(
        itemCount: user.roles.length,
        itemBuilder: (context, index) {
          final role = user.roles[index];
          return ListTile(
            title: Text(role),
            onTap: () => _selectRole(role, context),
          );
        },
      ),
    );
  }
}
