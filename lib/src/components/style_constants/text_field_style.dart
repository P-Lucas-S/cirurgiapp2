import 'package:cirurgiapp/src/components/style_constants/colors.dart';
import 'package:flutter/material.dart';

InputDecoration lightTextFieldDecor = InputDecoration(
  enabledBorder: OutlineInputBorder(
    borderSide: const BorderSide(
      color: Colors.transparent,
    ),
    borderRadius: BorderRadius.circular(5),
  ),
  errorBorder: OutlineInputBorder(
    borderSide: const BorderSide(
      color: Colors.red,
    ),
    borderRadius: BorderRadius.circular(5),
  ),
  focusedBorder: OutlineInputBorder(
    borderSide: const BorderSide(
      color: Color(0xFF949494),
    ),
    borderRadius: BorderRadius.circular(5),
  ),
  focusedErrorBorder: OutlineInputBorder(
    borderSide: const BorderSide(
      color: Colors.red,
    ),
    borderRadius: BorderRadius.circular(5),
  ),
  filled: true,
  fillColor: TEXT_FIELD_COLOR_LIGHT,
  floatingLabelBehavior: FloatingLabelBehavior.auto,
);

InputDecoration darkTextFieldDecor = InputDecoration(
  enabledBorder: OutlineInputBorder(
    borderSide: const BorderSide(
      color: Colors.transparent,
    ),
    borderRadius: BorderRadius.circular(5),
  ),
  errorBorder: OutlineInputBorder(
    borderSide: const BorderSide(
      color: Colors.red,
    ),
    borderRadius: BorderRadius.circular(5),
  ),
  focusedBorder: OutlineInputBorder(
    borderSide: const BorderSide(
      color: Color(0xFF949494),
    ),
    borderRadius: BorderRadius.circular(5),
  ),
  focusedErrorBorder: OutlineInputBorder(
    borderSide: const BorderSide(
      color: Colors.red,
    ),
    borderRadius: BorderRadius.circular(5),
  ),
  filled: true,
  fillColor: TEXT_FIELD_COLOR_DARK,
  floatingLabelBehavior: FloatingLabelBehavior.auto,
);

InputDecoration chatDecor = InputDecoration(
  enabledBorder: OutlineInputBorder(
    borderSide: const BorderSide(
      color: Colors.transparent,
    ),
    borderRadius: BorderRadius.circular(50),
  ),
  errorBorder: OutlineInputBorder(
    borderSide: const BorderSide(
      color: Colors.red,
    ),
    borderRadius: BorderRadius.circular(50),
  ),
  focusedBorder: OutlineInputBorder(
    borderSide: const BorderSide(
      color: Color(0xFF949494),
    ),
    borderRadius: BorderRadius.circular(50),
  ),
  focusedErrorBorder: OutlineInputBorder(
    borderSide: const BorderSide(
      color: Colors.red,
    ),
    borderRadius: BorderRadius.circular(50),
  ),
  filled: true,
  fillColor: MY_WHITE,
  hintText: 'Mensagem...',
);
