import 'package:flutter/material.dart';
import 'package:cirurgiapp/src/core/constants/app_colors.dart';
import 'package:cirurgiapp/src/components/buttons/elevated_buttons.dart';
import 'package:cirurgiapp/src/components/text_fields/text_fields.dart';
import 'package:cirurgiapp/src/services/auth_service.dart';
import 'package:cirurgiapp/src/features/auth/screens/login_screen.dart';
import 'package:cirurgiapp/src/components/style_constants/typography.dart';
import 'package:cirurgiapp/src/components/style_constants/container_decoration.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final _nameController = TextEditingController();
  final _cpfController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final List<String> _availableRoles = [
    'NIR',
    'Residente de Cirurgia',
    'Centro Cirúrgico',
    'Banco de Sangue',
    'UTI',
    'Centro de Material Hospitalar',
  ];
  final Map<String, bool> _selectedRoles = {};

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final roles = _selectedRoles.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    if (roles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione pelo menos um cargo')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await _auth.signUpWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        fullName: _nameController.text.trim(),
        cpf: _cpfController.text.trim(),
        roles: roles,
      );

      if (!mounted) return;

      if (user != null) {
        _showSuccessMessage();
        _navigateToLogin();
      } else {
        _showErrorMessage();
      }
    } catch (e) {
      _showErrorMessage();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Cadastro realizado com sucesso!'),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_auth.lastError ?? 'Falha ao cadastrar'),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _navigateToLogin() {
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    });
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
                  _buildFormSection(),
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
            height: 306,
            width: MediaQuery.of(context).size.width,
            color: AppColors.surface,
          ),
        ),
        Positioned.fill(
          child: Align(
            alignment: Alignment.center,
            child: Container(
              margin: const EdgeInsets.only(top: 90),
              child: Image.asset(
                "assets/logo/logo.png",
                width: 145,
              ),
            ),
          ),
        ),
        SafeArea(
          child: IconButton(
            icon: const Icon(Icons.arrow_back),
            color: AppColors.primary,
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ],
    );
  }

  Widget _buildFormSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            const SizedBox(height: 22),
            Text(
              "Faça seu cadastro!",
              style: H1(
                  textColor:
                      AppColors.onPrimary), // Usar estilo H1 da tipografia
            ),
            const SizedBox(height: 30),
            _buildNameField(),
            const SizedBox(height: 18),
            _buildCpfField(),
            const SizedBox(height: 18),
            _buildEmailField(),
            const SizedBox(height: 18),
            _buildPasswordField(),
            const SizedBox(height: 25),
            Text(
              'Selecione seus cargos:',
              style: H2(
                  textColor: AppColors.onPrimary), // Usar estilo H2 aumentado
            ),
            ..._buildRoleCheckboxes(),
            const SizedBox(height: 35),
            _buildSubmitButton(),
            const SizedBox(height: 25),
            _buildLoginRedirect(),
          ],
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return SimpleTextField(
      dark: true, // Alterado para true
      label: "Nome Completo",
      hintText: "Digite seu nome completo",
      controller: _nameController,
      errorMessage: "Campo obrigatório",
      validation: _nameController.text.isEmpty,
    );
  }

  Widget _buildCpfField() {
    return SimpleTextField(
      dark: true,
      label: "CPF",
      hintText: "Digite seu CPF",
      controller: _cpfController,
      errorMessage: "CPF inválido",
      isCPF: true,
    );
  }

  Widget _buildEmailField() {
    return SimpleTextField(
      dark: true,
      label: "E-mail",
      hintText: "Digite seu e-mail",
      controller: _emailController,
      errorMessage: "E-mail inválido",
      isEmail: true,
    );
  }

  Widget _buildPasswordField() {
    return ObscureTextField(
      dark: true,
      label: "Senha",
      hintText: "Digite sua senha (mínimo 6 caracteres)",
      controller: _passwordController,
      errorMessage: "Senha inválida",
      validation: (value) => value!.length >= 6,
    );
  }

  List<Widget> _buildRoleCheckboxes() {
    return _availableRoles.map((role) {
      return CheckboxListTile(
        title: Text(
          role,
          style: BODY(
            textColor: AppColors.onPrimary,
            size: 16,
          ),
        ),
        value: _selectedRoles[role] ?? false,
        activeColor: AppColors.primary,
        checkColor: AppColors.onPrimary,
        side: BorderSide(color: AppColors.onPrimary),
        onChanged: (value) => setState(() => _selectedRoles[role] = value!),
      );
    }).toList();
  }

  Widget _buildSubmitButton() {
    return SimpleButton(
      dark: true,
      title: "Cadastrar",
      onTap: _submit,
      width: double.infinity,
    );
  }

  Widget _buildLoginRedirect() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Já tem conta?",
            style: BODY(textColor: AppColors.onPrimary),
          ),
          const SizedBox(height: 10),
          SimpleButton(
            dark: true,
            title: "Entrar",
            onTap: () => Navigator.pop(context),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 15),
          ),
        ],
      ),
    );
  }
}
