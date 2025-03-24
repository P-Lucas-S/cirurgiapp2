import 'package:flutter/material.dart';
import 'package:cirurgiapp/src/core/constants/app_colors.dart';
import 'package:cirurgiapp/src/services/auth_service.dart';
import 'package:cirurgiapp/src/features/roles/screens/role_selection_screen.dart';
import 'package:cirurgiapp/src/components/text_fields/text_fields.dart';
import 'package:cirurgiapp/src/components/buttons/elevated_buttons.dart';
import 'package:cirurgiapp/src/components/style_constants/container_decoration.dart';
import 'package:cirurgiapp/src/components/style_constants/typography.dart';
import 'package:cirurgiapp/src/features/auth/screens/signup_screen.dart';
import 'package:cirurgiapp/src/core/models/user_model.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submitLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = await _auth.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (!mounted) return;
      if (user != null) {
        _navigateToRoleSelection(user); // ← Passa o usuário obtido
      } else {
        _showErrorSnackbar();
      }
    } catch (e) {
      _showErrorSnackbar();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateToRoleSelection(HospitalUser user) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const RoleSelectionScreen(),
        settings: RouteSettings(arguments: user),
      ),
    );
  }

  void _showErrorSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_auth.lastError ?? 'Falha no login'),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.surface))
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeaderSection(),
                  _buildLoginForm(),
                  _buildSignupSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeaderSection() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipPath(
          clipper: CustomShape(),
          child: Container(
            height: 346,
            width: double.infinity,
            color: AppColors.surface,
          ),
        ),
        Positioned.fill(
          top: 90,
          child: Center(
            child: Image.asset(
              "assets/logo/logo.png",
              width: 150,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            const SizedBox(height: 22),
            Text(
              "Faça seu login!",
              style: H1(textColor: AppColors.onPrimary),
            ),
            const SizedBox(height: 22),
            _buildEmailField(),
            const SizedBox(height: 22),
            _buildPasswordField(),
            const SizedBox(height: 25),
            _buildLoginButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    return SimpleTextField(
      dark: true,
      label: "E-mail",
      hintText: "Digite seu e-mail",
      controller: _emailController,
      errorMessage: "Digite um e-mail válido",
      isEmail: true,
    );
  }

  Widget _buildPasswordField() {
    return ObscureTextField(
      dark: true,
      label: "Senha",
      hintText: "Digite sua senha",
      controller: _passwordController,
      errorMessage: "Digite uma senha válida",
    );
  }

  Widget _buildLoginButton() {
    return SimpleButton(
      dark: true,
      title: "Entrar",
      onTap: _submitLogin,
      width: double.infinity,
    );
  }

  Widget _buildSignupSection() {
    return Padding(
      padding: const EdgeInsets.only(
        left: 25.0,
        right: 25.0,
        bottom: 40.0,
        top: 20,
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Não tem conta?",
              style: H2(textColor: AppColors.onPrimary),
            ),
          ),
          const SizedBox(height: 15),
          SimpleButton(
            dark: true,
            title: "Cadastre-se",
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SignUpScreen()),
            ),
          ),
        ],
      ),
    );
  }
}
