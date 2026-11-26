import 'package:flutter/material.dart';

import 'screens/ana_ekran.dart';
import 'tema.dart';

void main() => runApp(const EkspertizOkuyucu());

class EkspertizOkuyucu extends StatelessWidget {
  const EkspertizOkuyucu({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Ekspertiz Okuyucu',
        debugShowCheckedModeBanner: false,
        theme: acikTema,
        darkTheme: koyuTema,
        themeMode: ThemeMode.system,
        home: const AnaEkran(),
      );
}
