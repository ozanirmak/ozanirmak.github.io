// GEÇİCİ: yayından önce kaldırılır. Kapatmak için derlemede --dart-define=TEST_MODU=false verin;
// tamamen silmek için bu dosyayı ve rapor_ekrani.dart içindeki "kTestModu" satırlarını silin.
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/rapor.dart';
import '../services/disari_ver.dart';
import '../tema.dart';

const bool kTestModu = bool.fromEnvironment('TEST_MODU', defaultValue: true);

class Kontrol {
  const Kontrol(this.ad, this.tamam, [this.not = '']);
  final String ad;
  final bool tamam;
  final String not;
}

const _etiketler = ['Temiz görünüyor', 'Pazarlıkla değerlendirilebilir', 'Dikkatli olun', 'Ciddi risk var'];
final _iyiHaber = RegExp(r'orijinaldir|hasarsız|sorunsuz|temiz|işlem görmemiş', caseSensitive: false);
final _sizinti = RegExp(r'\bnull\b|undefined|\{|\}|NaN|Instance of', caseSensitive: false);
final _kesin = RegExp(r'kesin (alın|almayın)', caseSensitive: false);
final _acikPlaka = RegExp(r'\b\d{2}\s?[A-ZÇĞİÖŞÜ]{1,3}\s?\d{2,4}\b');

/// Rapor verisinin mantık ve sağlamlık kontrolleri. Saf fonksiyon, ağ yok.
List<Kontrol> kaliteKontrol(Rapor r, {required bool fotoKaynakli}) {
  final k = <Kontrol>[];
  final metin = jsonEncode(r.ham);
  final kap = r.kaporta;
  final kritik = Rapor.liste(kap['kritik']);
  final km = r.arac['km'];
  final yil = r.arac['model_yili'];
  final plaka = '${r.arac['plaka_maskeli'] ?? ''}';
  final meta = r.ham['meta'] is Map ? Map<String, dynamic>.from(r.ham['meta'] as Map) : <String, dynamic>{};
  final sure = (meta['sure_ms'] is num) ? (meta['sure_ms'] as num) / 1000 : null;

  k.add(Kontrol('Etiket geçerli', _etiketler.contains(r.etiket), r.etiket));
  k.add(Kontrol('Özet dolu ve kısa', r.ozet.trim().isNotEmpty && r.ozet.length <= 600, '${r.ozet.length} karakter'));
  k.add(Kontrol('"Önce bunlara bakın" 3-5 madde', r.ilkBakista.length >= 3 && r.ilkBakista.length <= 5, '${r.ilkBakista.length} madde'));
  k.add(Kontrol('Maddelerin durumu geçerli', r.ilkBakista.every((b) => ['iyi', 'dikkat', 'risk'].contains(b['durum']) && '${b['aciklama']}'.isNotEmpty)));
  k.add(Kontrol('"Sıradaki adımlar" 3 madde', r.neYapmali.length == 3, '${r.neYapmali.length} madde'));
  k.add(Kontrol('5 soru var', r.saticiyaSorulacaklar.length == 5, '${r.saticiyaSorulacaklar.length} soru'));
  if (r.rol == 'satici') {
    k.add(Kontrol('Her soruda önerilen cevap var', r.saticiyaSorulacaklar.every((s) => s.contains('Önerilen cevap'))));
  }
  k.add(Kontrol('"Kritik" listesinde iyi haber yok', !kritik.any(_iyiHaber.hasMatch), kritik.where(_iyiHaber.hasMatch).join(' | ')));
  k.add(Kontrol('Etiket ile kritik bulgu uyumlu',
      !(r.etiket == 'Temiz görünüyor' && kritik.isNotEmpty) && !(r.etiket == 'Ciddi risk var' && kritik.isEmpty && !r.sahtelikVar),
      '${r.etiket}, ${kritik.length} kritik'));
  k.add(Kontrol('Kilometre makul', km == null || (km is num && km > 0 && km < 1000000), '$km'));
  k.add(Kontrol('Model yılı makul', yil == null || (yil is num && yil >= 1990 && yil <= DateTime.now().year + 1), '$yil'));
  k.add(Kontrol('Plaka maskeli', plaka.isEmpty || RegExp(r'^\d{2} \*{3} \d{2}$').hasMatch(plaka), plaka));
  k.add(Kontrol('Açık plaka sızmamış', !_acikPlaka.hasMatch(metin.replaceAll(plaka, ''))));
  k.add(Kontrol('Metinlerde sızıntı yok (null, { })', !_sizinti.hasMatch(jsonEncode(r.ham['rapor'] ?? {}))));
  k.add(Kontrol('"Kesin alın/almayın" denmemiş', !_kesin.hasMatch(metin)));
  k.add(Kontrol('Sahtelik sinyali tutarlı', !r.sahtelikVar || r.sahtelikSinyalleri.isNotEmpty));
  k.add(Kontrol('Kaynak bağlantıları https', r.kaynaklar.every((e) => '${e['url']}'.startsWith('https://')), '${r.kaynaklar.length} kaynak'));
  k.add(Kontrol('Yasal not var', r.yasalNot.isNotEmpty));
  if (r.fiyat != null) {
    k.add(Kontrol('Fiyat bölümü dolu', '${r.fiyat!['piyasa_araligi'] ?? ''}'.isNotEmpty));
  }
  if (sure != null) k.add(Kontrol('Süre 90 sn içinde', sure <= 90, '${sure.toStringAsFixed(1)} sn'));
  if (fotoKaynakli) k.add(Kontrol('Fotoğraf kaynaklı: kullanıcı kontrolü yapıldı', true, 'kontrol ekranından geçti'));
  return k;
}

class TestPaneli extends StatefulWidget {
  const TestPaneli({super.key, required this.rapor, required this.fotoKaynakli});
  final Rapor rapor;
  final bool fotoKaynakli;

  @override
  State<TestPaneli> createState() => _TestPaneliState();
}

class _TestPaneliState extends State<TestPaneli> {
  final _not = TextEditingController();
  final _isaretli = <String>{};
  static const _alanlar = ['Veriler yanlış', 'Görsel bozuk', 'Yazı anlaşılmıyor', 'Fiyat tuhaf', 'Eksik bilgi'];

  Future<void> _paketle() async {
    final kontroller = kaliteKontrol(widget.rapor, fotoKaynakli: widget.fotoKaynakli);
    final ekran = MediaQuery.of(context);
    final paket = {
      'zaman': DateTime.now().toIso8601String(),
      'rol': widget.rapor.rol,
      'foto_kaynakli': widget.fotoKaynakli,
      'ekran': {
        'genislik': ekran.size.width.round(),
        'yukseklik': ekran.size.height.round(),
        'koyu_tema': Theme.of(context).brightness == Brightness.dark,
        'yazi_olcegi': ekran.textScaler.scale(10) / 10,
        'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
      },
      'kullanici_isaretleri': _isaretli.toList(),
      'kullanici_notu': _not.text.trim(),
      'otomatik_kontroller': [for (final c in kontroller) {'ad': c.ad, 'tamam': c.tamam, 'not': c.not}],
      'rapor': widget.rapor.ham,
    };
    final bytes = Uint8List.fromList(utf8.encode(const JsonEncoder.withIndent('  ').convert(paket)));
    await dosyaVer(context, bytes, 'ekspertiz_test_paketi.json', 'application/json');
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final kontroller = kaliteKontrol(widget.rapor, fotoKaynakli: widget.fotoKaynakli);
    final kalan = kontroller.where((c) => !c.tamam).toList();
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Test paneli (geçici)', style: t.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text('Yayından önce kaldırılacak. Raporu inceleyin, sorun varsa işaretleyin ve paketi Claude\'a gönderin.', style: t.textTheme.bodyMedium),
          const SizedBox(height: 12),
          Text('Otomatik kontrol: ${kontroller.length - kalan.length}/${kontroller.length} geçti', style: t.textTheme.titleMedium?.copyWith(color: kalan.isEmpty ? Renk.temiz : Renk.risk)),
          for (final c in kontroller)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(c.tamam ? Icons.check_circle : Icons.cancel, size: 20, color: c.tamam ? Renk.temiz : Renk.risk),
                const SizedBox(width: 8),
                Expanded(child: Text(c.not.isEmpty ? '${c.ad}  (${c.not})' : c.ad, style: t.textTheme.bodyMedium)),
              ]),
            ),
          const SizedBox(height: 16),
          Text('Sizce sorun ne?', style: t.textTheme.titleMedium),
          Wrap(spacing: 8, runSpacing: 4, children: [
            for (final a in _alanlar)
              FilterChip(
                label: Text(a),
                selected: _isaretli.contains(a),
                onSelected: (d) => setState(() => d ? _isaretli.add(a) : _isaretli.remove(a)),
              ),
          ]),
          const SizedBox(height: 8),
          TextField(controller: _not, maxLines: 3, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Neyi yanlış ya da eksik gördünüz?')),
          const SizedBox(height: 12),
          FilledButton.icon(onPressed: _paketle, icon: const Icon(Icons.inventory_2), label: const Text('Test paketini kaydet')),
          const SizedBox(height: 4),
          Text('Görüntüyü de üstteki indir menüsünden kaydedip ikisini birlikte gönderin.', style: t.textTheme.bodyMedium),
        ]),
      ),
    );
  }
}
