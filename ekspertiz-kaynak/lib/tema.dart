import 'package:flutter/material.dart';

/// Turuncu Explainer: turuncu ana renk, gece mavisi zemin, camgöbeği tamamlayıcı.
/// Açık tema varsayılan, sistem koyu ise koyu tema. En küçük metin 17, düğmeler en az 56 yükseklik.
class Renk {
  static const turuncu = Color(0xFFFF6A1A);
  static const turuncuYazi = Color(0xFFB54708); // açık zeminde yazı için, 4.5:1 üstü
  static const geceMavisi = Color(0xFF0B1426);
  static const geceYuzey = Color(0xFF15213A);
  static const camgobegi = Color(0xFF22D3EE);
  static const camgobegiYazi = Color(0xFF0E7490);
  static const acikZemin = Color(0xFFFAF7F2);

  // Etiket renkleri
  static const temiz = Color(0xFF1F8A4C);
  static const pazarlik = Color(0xFFB7791F);
  static const dikkat = Color(0xFFD9480F);
  static const risk = Color(0xFFC92A2A);
}

FontVariation _w(double w) => FontVariation('wght', w);

TextTheme _yazilar(Color murekkep) => TextTheme(
      headlineLarge: TextStyle(fontFamily: 'Archivo', fontSize: 32, fontVariations: [_w(800)], color: murekkep, height: 1.15),
      headlineSmall: TextStyle(fontFamily: 'Archivo', fontSize: 24, fontVariations: [_w(700)], color: murekkep),
      titleLarge: TextStyle(fontFamily: 'Archivo', fontSize: 21, fontVariations: [_w(700)], color: murekkep),
      titleMedium: TextStyle(fontFamily: 'Manrope', fontSize: 19, fontVariations: [_w(700)], color: murekkep),
      bodyLarge: TextStyle(fontFamily: 'Manrope', fontSize: 19, fontVariations: [_w(500)], color: murekkep, height: 1.4),
      bodyMedium: TextStyle(fontFamily: 'Manrope', fontSize: 17, fontVariations: [_w(500)], color: murekkep, height: 1.4),
      labelLarge: TextStyle(fontFamily: 'Manrope', fontSize: 19, fontVariations: [_w(800)]),
    );

ThemeData _tema(Brightness b) {
  final acik = b == Brightness.light;
  final murekkep = acik ? Renk.geceMavisi : const Color(0xFFEEF2FA);
  final sema = ColorScheme.fromSeed(
    seedColor: Renk.turuncu,
    brightness: b,
    primary: acik ? Renk.turuncuYazi : Renk.turuncu,
    onPrimary: acik ? Colors.white : Renk.geceMavisi,
    secondary: acik ? Renk.camgobegiYazi : Renk.camgobegi,
    surface: acik ? Colors.white : Renk.geceYuzey,
    onSurface: murekkep,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: sema,
    scaffoldBackgroundColor: acik ? Renk.acikZemin : Renk.geceMavisi,
    textTheme: _yazilar(murekkep),
    appBarTheme: AppBarTheme(
      backgroundColor: acik ? Renk.acikZemin : Renk.geceMavisi,
      foregroundColor: murekkep,
      centerTitle: false,
      titleTextStyle: TextStyle(fontFamily: 'Archivo', fontSize: 22, fontVariations: [_w(700)], color: murekkep),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(64),
        backgroundColor: acik ? Renk.turuncuYazi : Renk.turuncu,
        foregroundColor: acik ? Colors.white : Renk.geceMavisi,
        textStyle: TextStyle(fontFamily: 'Manrope', fontSize: 20, fontVariations: [_w(800)]),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        textStyle: TextStyle(fontFamily: 'Manrope', fontSize: 18, fontVariations: [_w(700)]),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      labelStyle: const TextStyle(fontSize: 18),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: acik ? Colors.white : Renk.geceYuzey,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: acik ? const Color(0xFFE7E1D8) : const Color(0xFF26324D)),
      ),
    ),
  );
}

final acikTema = _tema(Brightness.light);
final koyuTema = _tema(Brightness.dark);

const monoStil = TextStyle(fontFamily: 'JetBrainsMono', fontVariations: [FontVariation('wght', 600)]);
