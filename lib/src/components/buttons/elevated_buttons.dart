// ignore_for_file: non_constant_identifier_names

import 'package:cirurgiapp/src/components/style_constants/button_styles.dart';
import 'package:cirurgiapp/src/components/style_constants/colors.dart';
import 'package:cirurgiapp/src/components/style_constants/tipography.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Botão quadrado com imagem de fundo
Widget HomeButton({
  required String title,
  required String imagePath,
  required VoidCallback onTap,
  double? width = 134,
  double? height = 134,
}) {
  return ElevatedButton(
    style: buttonStyle,
    onPressed: onTap,
    child: SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          Positioned(
            bottom: -20,
            right: -25,
            child: Opacity(
              opacity: 0.2,
              child: Image.asset(
                imagePath,
                width: 120,
              ),
            ),
          ),
          Positioned(
            top: 15,
            left: 15,
            child: SizedBox(
              width: 100.0,
              child: Text(
                title,
                style: H2(textColor: MY_WHITE),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Botão simples com texto
Widget SimpleButton({
  required bool dark,
  required String title,
  required VoidCallback onTap,
  double? width,
  EdgeInsetsGeometry? padding,
}) {
  return ElevatedButton(
    style: dark
        ? buttonStyleDark.copyWith(
            backgroundColor: WidgetStateProperty.all(AppColors.primary),
          )
        : buttonStyle,
    onPressed: onTap,
    child: Padding(
      padding: padding ?? const EdgeInsets.symmetric(vertical: 15),
      child: SizedBox(
        width: width,
        child: Center(
          child: Text(
            title.toUpperCase(),
            style: GoogleFonts.mulish(
              fontSize: 14, // Aumentado de 12 para 14
              fontWeight: FontWeight.w700,
              color: dark ? AppColors.surface : AppColors.primary,
            ),
          ),
        ),
      ),
    ),
  );
}

/// Botão para ações perigosas
Widget DangerButton({
  required String title,
  required VoidCallback onTap,
  double? width,
}) {
  return ElevatedButton(
    style: dangerButtonStyle,
    onPressed: onTap,
    child: SizedBox(
      width: width,
      child: Center(
        child: Text(
          title.toUpperCase(),
          style: GoogleFonts.mulish(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: MY_WHITE, // Alterado para melhor legibilidade
          ),
        ),
      ),
    ),
  );
}

/// Botão para listagem de categorias
Widget ButtonContainer({
  required String title,
  required String imagePath,
  required VoidCallback onTap,
  double? height = 100,
  double? width,
}) {
  return ElevatedButton(
    style: buttonStyle,
    onPressed: onTap,
    child: SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          Positioned(
            bottom: -20,
            right: -25,
            child: Opacity(
              opacity: 0.2,
              child: Image.asset(
                imagePath,
                width: 100,
              ),
            ),
          ),
          Positioned(
            top: 15,
            left: 15,
            child: Text(
              title,
              style: H2(textColor: MY_WHITE),
            ),
          ),
        ],
      ),
    ),
  );
}
