import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/liquid_motion.dart';

class C {
  static const ember = Color(0xFFFF5A3C);
  static const crimson = Color(0xFFC2182F);
  static const wine = Color(0xFF5A0716);
  static const cream = Color(0xFFFFF3E8);
  static const gold = Color(0xFFF3C98B);
  static const ink = Color(0xFF3A1A14);
  static const brown = Color(0xFF8A6A60);
  static const blush = Color(0xFFFFE3D8);
}

Color op(Color c, double o) => c.withAlpha((o * 255).round());

const emberGradient = LinearGradient(colors: [Color(0xFFFF8A5C), Color(0xFFFF4D2E)]);

const darkBg = RadialGradient(
  center: Alignment(0, -.25),
  radius: 1.1,
  colors: [Color(0xFF6E0F1C), Color(0xFF25060D), Color(0xFF0B0306)],
  stops: [0, .45, .85],
);

TextStyle display(double size, {Color color = Colors.white, FontWeight w = FontWeight.w800, double? h}) =>
    GoogleFonts.unbounded(fontSize: size, fontWeight: w, color: color, height: h);

TextStyle body(double size, {Color color = Colors.white, FontWeight w = FontWeight.w500, double? h}) =>
    GoogleFonts.manrope(fontSize: size, fontWeight: w, color: color, height: h);

ThemeData buildTheme() => ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0B0306),
      colorScheme: ColorScheme.fromSeed(seedColor: C.ember, brightness: Brightness.dark),
      textTheme: GoogleFonts.manropeTextTheme(ThemeData.dark().textTheme),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: LiquidPageTransitionsBuilder(),
          TargetPlatform.iOS: LiquidPageTransitionsBuilder(),
          TargetPlatform.windows: LiquidPageTransitionsBuilder(),
        },
      ),
    );
