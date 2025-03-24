// Box Shadow
// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';

List<BoxShadow> MY_BOXSHADOW = [
  const BoxShadow(
    color: Color(0x40000000),
    blurRadius: 5.0,
    offset: Offset(0, 0),
  ),
];

class CustomShape extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final double radius = 150;
    final path = Path();

    path.moveTo(0, 0);
    path.lineTo(0, size.height - radius);
    path.arcToPoint(
      Offset(radius, size.height),
      radius: Radius.circular(radius),
      clockwise: false,
    );
    path.lineTo(size.width - radius, size.height);
    path.arcToPoint(
      Offset(size.width, size.height - radius),
      radius: Radius.circular(radius),
      clockwise: false,
    );
    path.lineTo(size.width, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
}
