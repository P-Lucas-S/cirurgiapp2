// ignore_for_file: non_constant_identifier_names

import 'package:cirurgiapp/src/components/style_constants/tipography.dart';
import 'package:flutter/material.dart';

SnackBar ErrorMessage({required String error}) {
  return SnackBar(
    elevation: 0,
    behavior: SnackBarBehavior.floating,
    backgroundColor: const Color(0xFFFCBDBD),
    dismissDirection: DismissDirection.startToEnd,
    content: Row(
      children: [
        const Icon(
          Icons.error_outline,
          color: Color(0xFF7D2E2E),
        ),
        const SizedBox(width: 5),
        Text(
          error,
          style: BODY(
            textColor: const Color(0xFF7D2E2E),
          ).copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    ),
  );
}
