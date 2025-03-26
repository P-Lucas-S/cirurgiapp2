import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cirurgiapp/src/core/constants/app_colors.dart';
import 'package:cirurgiapp/src/features/auth/screens/login_screen.dart';
import 'firebase_options.dart';
import 'package:cirurgiapp/src/firestore_init/firestore_initializer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Inicializa dados padrão do Firestore
    await FirestoreInitializer().initializeProcedures();
  } catch (error) {
    // Caso ocorra um erro na inicialização, ele é logado no console.
    print('Erro na inicialização do Firebase/Firestore: $error');
    // Aqui você pode também exibir uma tela de erro, se preferir.
  }

  runApp(const Cirurgiapp());
}

class Cirurgiapp extends StatelessWidget {
  const Cirurgiapp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cirurgiapp',
      debugShowCheckedModeBanner: false,
      theme: _buildAppTheme(),
      home: const LoginScreen(),
    );
  }

  ThemeData _buildAppTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        error: AppColors.error,
        surface: AppColors.surface,
        onPrimary: AppColors.onPrimary,
        onSecondary: AppColors.onSecondary,
        onSurface: AppColors.onSurface,
      ),
      textTheme: GoogleFonts.mulishTextTheme(),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: const BorderSide(color: AppColors.outline),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}
