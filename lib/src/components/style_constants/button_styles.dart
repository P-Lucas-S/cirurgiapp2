import 'package:cirurgiapp/src/components/style_constants/colors.dart';
import 'package:flutter/material.dart';

/// basic style for elevated buttons
ButtonStyle buttonStyle = ElevatedButton.styleFrom(
  padding: const EdgeInsets.all(0),
  backgroundColor: MY_BLUE,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(5),
  ),
  elevation: 0.0,
);

/// basic style for elevated buttons
ButtonStyle buttonStyleDark = ElevatedButton.styleFrom(
  padding: const EdgeInsets.all(0),
  backgroundColor: MY_WHITE,
  side: BorderSide(
    color: MY_BLUE,
    width: 1,
  ),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(5),
  ),
  elevation: 0.0,
);

/// basic style for danger buttons
ButtonStyle dangerButtonStyle = ElevatedButton.styleFrom(
  padding: const EdgeInsets.all(0),
  backgroundColor: MY_WHITE,
  side: BorderSide(
    color: MY_RED,
    width: 1,
  ),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(5),
  ),
  elevation: 0.0,
);
