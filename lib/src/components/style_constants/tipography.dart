// ignore_for_file: non_constant_identifier_names

import 'package:cirurgiapp/src/components/style_constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// **Font**: Mulish; **Size**: 22; **Weight**: Bold
TextStyle TITLE({
  Color? textColor,
}) {
  return GoogleFonts.mulish(
    fontSize: 22,
    color: textColor ?? MY_BLACK,
    fontWeight: FontWeight.w700,
  );
}

/// **Font**: Mulish; **Size**: 18; **Weight**: Bold
TextStyle TITLE_02({
  Color? textColor,
}) {
  return GoogleFonts.mulish(
    fontSize: 18,
    color: textColor ?? MY_BLACK,
    fontWeight: FontWeight.w700,
  );
}

/// **Font**: Mulish; **Size**: 20; **Weight**: Bold
TextStyle H1({Color textColor = Colors.black}) => TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: textColor,
    );

/// **Font**: Mulish; **Size**: 16; **Weight**: Bold
TextStyle H2({
  Color? textColor,
}) {
  return GoogleFonts.mulish(
    fontSize: 16,
    color: textColor ?? MY_BLACK,
    fontWeight: FontWeight.w700,
  );
}

/// **Font**: Mulish; **Size**: 18; **Weight**: ExtraBold
TextStyle H3({
  Color? textColor,
}) {
  return GoogleFonts.mulish(
    fontSize: 18,
    color: textColor ?? MY_BLACK,
    fontWeight: FontWeight.w800,
  );
}

/// **Font**: Mulish; **Size**: 16; **Weight**: Bold
TextStyle APP_BAR({
  Color? textColor,
}) {
  return H2(textColor: textColor ?? MY_WHITE);
}

/// **Font**: Mulish; **Size**: 14; **Weight**: Regular
TextStyle BODY({
  Color? textColor,
  double? size,
}) {
  return GoogleFonts.mulish(
    fontSize: size ?? 14,
    color: textColor ?? MY_BLACK,
    fontWeight: FontWeight.w400,
  );
}

/// **Font**: Mulish; **Size**: 12; **Weight**: Medium
TextStyle SUBTITLE({Color textColor = Colors.black}) => TextStyle(
      fontSize: 16,
      color: textColor,
    );

/// **Font**: Mulish; **Size**: 10; **Weight**: Medium
TextStyle DETAILS({
  Color? textColor,
}) {
  return GoogleFonts.mulish(
    fontSize: 10,
    color: textColor ?? MY_BLACK,
    fontWeight: FontWeight.w500,
  );
}
