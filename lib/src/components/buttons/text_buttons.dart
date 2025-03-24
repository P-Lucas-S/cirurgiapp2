// ignore_for_file: non_constant_identifier_names

import 'package:cirurgiapp/src/components/style_constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A simple text button to be used. <br/>
/// <br/>
/// There is a dark and a light version to be **used accordingly**.
Widget CustomTextButton({
  required bool dark,
  required String title,
  required VoidCallback onTap,
}) {
  return TextButton(
    style: TextButton.styleFrom(
      foregroundColor: dark ? MY_WHITE : MY_BLUE,
      surfaceTintColor: const Color(0xFF25578B),
    ),
    onPressed: onTap,
    child: Text(
      title,
      style: GoogleFonts.mulish(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: dark ? MY_WHITE : MY_BLUE,
      ),
    ),
  );
}

Widget CustomActionTextButton({
  required String title,
  required VoidCallback onTap,
}) {
  return TextButton(
    style: TextButton.styleFrom(
      foregroundColor: MY_RED,
      surfaceTintColor: const Color(0xFF25578B),
    ),
    onPressed: onTap,
    child: Text(
      title,
      style: GoogleFonts.mulish(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: MY_RED,
      ),
    ),
  );
}

/// A simple text button to be used. There is a dark and a light version
/// to be used accordingly. <br/>
/// <br/>
/// There is a dark and a light version to be **used accordingly**.
Widget LabeledRadio({
  required String label,
  required int groupValue,
  required int value,
  required Function(int) onChanged,
  required bool dark,
}) {
  return Padding(
    padding: const EdgeInsets.all(0),
    child: Row(
      children: <Widget>[
        Theme(
          data: ThemeData(
            unselectedWidgetColor: dark ? MY_WHITE : MY_BLUE,
          ),
          child: Radio<int>(
            activeColor: dark ? MY_WHITE : MY_BLUE,
            value: value,
            groupValue: groupValue,
            onChanged: (value) => onChanged(value!),
          ),
        ),
        Text(
          label,
          style: GoogleFonts.mulish(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: dark ? MY_WHITE : MY_BLUE,
          ),
        ),
      ],
    ),
  );
}
