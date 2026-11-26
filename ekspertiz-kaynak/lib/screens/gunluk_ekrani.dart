import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/gunluk.dart';

/// Geçici: günlüğü metin olarak gösterir, dokununca tamamını kopyalar.
class GunlukEkrani extends StatelessWidget {
  const GunlukEkrani({super.key});

  void _kopyala(BuildContext context) {
    Clipboard.setData(ClipboardData(text: Gunluk.metin));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Günlük kopyalandı', style: TextStyle(fontSize: 17))));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Hata ayıklama günlüğü')),
        body: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton.icon(
                onPressed: () => _kopyala(context),
                icon: const Icon(Icons.copy),
                label: const Text('Tümünü Kopyala'),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => _kopyala(context),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: Text(Gunluk.metin, style: const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 12.5, height: 1.4)),
                ),
              ),
            ),
          ]),
        ),
      );
}
