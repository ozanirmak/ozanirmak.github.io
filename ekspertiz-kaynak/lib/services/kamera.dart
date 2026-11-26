import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'api.dart';

String _ad(String a) => RegExp(r'\.(jpe?g|png|webp|heic)$', caseSensitive: false).hasMatch(a) ? a : '$a.jpg';

/// Kameradan fotoğraf çeker. [coklu] açıksa her çekimden sonra "başka sayfa var mı" diye sorar.
Future<List<SecilenDosya>> kameradanCek(BuildContext context, {int en = 10, bool coklu = true}) async {
  final sonuc = <SecilenDosya>[];
  final secici = ImagePicker();
  while (sonuc.length < en) {
    final x = await secici.pickImage(source: ImageSource.camera, maxWidth: 2200, imageQuality: 85);
    if (x == null) break;
    sonuc.add(SecilenDosya(ad: _ad(x.name), bayt: await x.readAsBytes()));
    if (!coklu || sonuc.length >= en || !context.mounted) break;
    final devam = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Başka sayfa var mı?'),
        content: Text('${sonuc.length} fotoğraf çekildi.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Bitti')),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(140, 56)),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Bir tane daha'),
          ),
        ],
      ),
    );
    if (devam != true) break;
  }
  return sonuc;
}

/// Galeriden en çok [en] fotoğraf seçer (araç fotoğrafı için küçültülür).
Future<List<SecilenDosya>> galeridenSec({int en = 4}) async {
  final secim = await ImagePicker().pickMultiImage(maxWidth: 1600, imageQuality: 80);
  final sonuc = <SecilenDosya>[];
  for (final x in secim.take(en)) {
    sonuc.add(SecilenDosya(ad: _ad(x.name), bayt: await x.readAsBytes()));
  }
  return sonuc;
}
