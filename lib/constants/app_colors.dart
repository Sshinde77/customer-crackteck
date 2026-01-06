import 'package:flutter/material.dart';

/// App-wide color constants
class AppColors {
  AppColors._(); // Private constructor to prevent instantiation

  // Primary Colors
  static const Color primary = Color(0xFF007C2F);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color darkGreen = Color(0xFF267910);
  static const Color lightGrey = Color(0xFF9E9E9E);
  static const Color borderGrey = Color(0xFFE0E0E0);

  // Button Colors
  static const Color buttonBackground = darkGreen;
  static const Color buttonText = white;
  static const Color buttonIcon = white;

  // Input Field Colors
  static const Color inputBackground = white;
  static const Color inputBorder = borderGrey;
  static const Color inputFocusedBorder = darkGreen;
  static const Color inputText = black;
  static const Color inputLabel = lightGrey;

  //Badge Colors
  static const Color badgeBackground = Colors.red;
}
