import 'package:flutter/material.dart';
import 'package:cirurgiapp/src/core/constants/app_colors.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        backgroundColor: AppColors.primary,
      ),
      body: const Center(child: Text('Tela Inicial')),
    );
  }
}
