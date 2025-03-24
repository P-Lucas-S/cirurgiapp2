// TODO Implement this library.
import 'package:flutter/material.dart';
import 'package:cirurgiapp/src/core/models/user_model.dart';

class RoleConfirmationScreen extends StatelessWidget {
  final String role;
  final HospitalUser user;

  const RoleConfirmationScreen(
      {super.key, required this.role, required this.user});

  @override
  Widget build(BuildContext context) {
    // Implemente o conteúdo específico para a confirmação de função aqui
    return Scaffold(
      appBar: AppBar(
        title: Text('Confirmação de Função: $role'),
      ),
      body: Center(
        child: Text('Conteúdo de confirmação para $role'),
      ),
    );
  }
}
