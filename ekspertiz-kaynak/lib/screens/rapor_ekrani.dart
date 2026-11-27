import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/rapor.dart';
import '../services/disari_ver.dart';
import '../tema.dart';
import '../test/test_modu.dart';
import 'gunluk_ekrani.dart';

class RaporEkrani extends StatefulWidget {
  const RaporEkrani({super.key, required this.rapor, this.fotoKaynakli = false});
  final Rapor rapor;
  /// Rapor fotoğraftan okunduysa rakamlar kullanıcı onayı olmadan gösterilmez.
  final bool fotoKaynakli;

  static Color etiketRengi(String e) => switch (e) {
        'Temiz görünüyor' => Renk.temiz,
        'Pazarlıkla değerlendirilebilir' => Renk.pazarlik,
        'Dikkatli olun' => Renk.dikkat,
        _ => Renk.risk,
      };

  @override
  State<RaporEkrani> createState() => _RaporEkraniState();
}

/// Görüntü kaydederken tüm bölümler açık çizilsin diye.
class _Yakala extends InheritedWidget {
  const _Yakala({required this.acik, required super.child});
  final bool acik;
  static bool of(BuildContext c) => c.dependOnInheritedWidgetOfExactType<_Yakala>()?.acik ?? false;
  @override
  bool updateShouldNotify(_Yakala o) => o.acik != acik;
}

class _RaporEkraniState extends State<RaporEkrani> {
  final _anahtar = GlobalKey();
  bool _yakala = false;
  final _onay = <String>{};
  late bool _kontrolBekliyor = widget.fotoKaynakli;

  List<(String, String)> get _kontrolSatirlari {
    final a = widget.rapor.arac;
    String? v(Object? x) => (x == null || '$x'.trim().isEmpty || '$x' == '0') ? null : '$x';
    final marka = [v(a['marka']), v(a['model'])].whereType<String>().join(' ');
    return [
      if (v(a['km']) != null) ('Kilometre', '${a['km']} km'),
      if (marka.isNotEmpty) ('Marka ve model', marka),
      if (v(a['model_yili']) != null) ('Model yılı', '${a['model_yili']}'),
      if (v(a['plaka_maskeli']) != null) ('Plaka', '${a['plaka_maskeli']}'),
    ];
  }

  Widget _kontrolSayfasi(BuildContext context) {
    final t = Theme.of(context);
    final satirlar = _kontrolSatirlari;
    final hepsi = satirlar.every((e) => _onay.contains(e.$1));
    return Scaffold(
      appBar: AppBar(title: const Text('Önce kontrol edin')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(
              'Rapor fotoğraftan okundu. Fotoğraftaki rakamlar yanlış okunmuş olabilir. '
              'Raporunuzun aslına bakın, her satırı karşılaştırın; doğruysa kutuyu işaretleyin.',
              style: t.textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            for (final e in satirlar)
              Card(
                child: CheckboxListTile(
                  value: _onay.contains(e.$1),
                  onChanged: (d) => setState(() => d == true ? _onay.add(e.$1) : _onay.remove(e.$1)),
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(e.$1, style: t.textTheme.bodyMedium),
                  subtitle: Text(e.$2, style: t.textTheme.titleLarge),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            if (satirlar.isEmpty) Text('Fotoğraftan okunabilen bilgi yok. Raporun aslıyla karşılaştırarak ilerleyin.', style: t.textTheme.bodyMedium),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: hepsi ? () => setState(() => _kontrolBekliyor = false) : null,
              child: const Text('Kontrol ettim, raporu göster'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
              child: const Text('Yanlış var, fotoğrafı yeniden çekeceğim'),
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> _gorselKaydet() async {
    setState(() => _yakala = true);
    await WidgetsBinding.instance.endOfFrame;
    await WidgetsBinding.instance.endOfFrame;
    try {
      final sinir = _anahtar.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final resim = await sinir.toImage(pixelRatio: 2);
      final veri = await resim.toByteData(format: ui.ImageByteFormat.png);
      if (veri == null) throw Exception('Görüntü üretilemedi');
      if (!mounted) return;
      await dosyaVer(context, veri.buffer.asUint8List(), 'ekspertiz_rapor.png', 'image/png');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Kaydedilemedi: $e', style: const TextStyle(fontSize: 17))));
    } finally {
      if (mounted) setState(() => _yakala = false);
    }
  }

  Future<void> _hamKaydet() async {
    final metin = const JsonEncoder.withIndent('  ').convert(widget.rapor.ham);
    await dosyaVer(context, Uint8List.fromList(utf8.encode(metin)), 'ekspertiz_rapor.json', 'application/json');
  }

  @override
  Widget build(BuildContext context) {
    if (_kontrolBekliyor) return _kontrolSayfasi(context);
    final t = Theme.of(context);
    final r = widget.rapor;
    final kaporta = r.kaporta;
    final fiyat = r.fiyat;
    final foto = r.fotoKarsilastirma;
    return Scaffold(
      appBar: AppBar(
        title: Text(r.aracBasligi.isEmpty ? 'Raporunuz' : r.aracBasligi),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Raporu kaydet',
            icon: const Icon(Icons.download),
            onSelected: (v) => v == 'png' ? _gorselKaydet() : _hamKaydet(),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'png', child: Text('Görüntü olarak kaydet')),
              PopupMenuItem(value: 'json', child: Text('Ham veriyi kaydet')),
            ],
          ),
          if (kTestModu)
          IconButton(
            tooltip: 'Hata ayıklama günlüğü',
            icon: const Icon(Icons.bug_report),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GunlukEkrani())),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(children: [
          _Yakala(
            acik: _yakala,
            child: RepaintBoundary(
              key: _anahtar,
              child: Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (r.sahtelikVar) _SahtelikKarti(rapor: r),
            Card(
              color: RaporEkrani.etiketRengi(r.etiket),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(r.etiket, style: t.textTheme.headlineSmall?.copyWith(color: Colors.white)),
                  const SizedBox(height: 10),
                  Text(r.ozet, style: t.textTheme.bodyLarge?.copyWith(color: Colors.white)),
                ]),
              ),
            ),
            if (r.arac['km'] != null || r.arac['plaka_maskeli'] != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Text(
                  [if (r.arac['km'] != null) '${r.arac['km']} km', if (r.arac['plaka_maskeli'] != null) '${r.arac['plaka_maskeli']}'].join('   ·   '),
                  style: monoStil.copyWith(fontSize: 17, color: t.colorScheme.onSurface),
                ),
              ),
            for (final n in r.kontrolNotlari) _Not(metin: n),
            if (r.ilkBakista.isNotEmpty)
              _Bolum(baslik: r.rol == 'satici' ? 'Alıcı ilk bunlara bakacak' : 'Önce bunlara bakın', acik: true, children: [
                for (final b in r.ilkBakista)
                  _Madde(
                    metin: '${b['konu']}: ${b['aciklama']}',
                    renk: switch (b['durum']) { 'iyi' => Renk.temiz, 'risk' => Renk.risk, _ => Renk.pazarlik },
                    ikon: switch (b['durum']) { 'iyi' => Icons.check_circle, 'risk' => Icons.error, _ => Icons.warning_amber },
                  ),
              ]),
            if (r.iyiHaberler.isNotEmpty)
              _Bolum(baslik: r.rol == 'satici' ? 'Güçlü yanlarınız' : 'İyi haberler', acik: true, children: [
                for (final h in r.iyiHaberler) _Madde(metin: h, renk: Renk.temiz, ikon: Icons.check_circle),
              ]),
            if (r.neYapmali.isNotEmpty)
              _Bolum(baslik: r.rol == 'satici' ? 'Satıştan önce yapın' : 'Sıradaki adımlar', acik: true, children: [
                for (var i = 0; i < r.neYapmali.length; i++) _Madde(metin: '${i + 1}. ${r.neYapmali[i]}', ikon: Icons.flag),
              ]),
            _Bolum(baslik: 'Kaporta ve iskelet', acik: true, children: [
              for (final p in Rapor.liste(kaporta['kritik'])) _Madde(metin: p, renk: Renk.risk, ikon: Icons.error),
              for (final p in Rapor.liste(kaporta['orta'])) _Madde(metin: p, renk: Renk.pazarlik, ikon: Icons.warning_amber),
              for (final p in Rapor.liste(kaporta['onemsiz'])) _Madde(metin: p, renk: Colors.grey, ikon: Icons.info_outline),
              if ('${kaporta['deger_etkisi_yuzde_araligi'] ?? ''}'.isNotEmpty)
                _Madde(metin: 'Değere etkisi: ${kaporta['deger_etkisi_yuzde_araligi']}', ikon: Icons.trending_down),
            ]),
            _Bolum(baslik: 'Araç fotoğrafı ile karşılaştırma', acik: true, children: [
              if (foto != null) ...[
                _Madde(metin: 'Marka ve model: ${_tut(foto['marka_model_tutuyor'])}', renk: _tutRenk(foto['marka_model_tutuyor']), ikon: _tutIkon(foto['marka_model_tutuyor'])),
                _Madde(metin: 'Renk: ${_tut(foto['renk_tutuyor'])}', renk: _tutRenk(foto['renk_tutuyor']), ikon: _tutIkon(foto['renk_tutuyor'])),
                _Madde(metin: 'Plaka: ${_tut(foto['plaka_tutuyor'])}', renk: _tutRenk(foto['plaka_tutuyor']), ikon: _tutIkon(foto['plaka_tutuyor'])),
                for (final g in Rapor.liste(foto['gozlemler'])) _Madde(metin: g, ikon: Icons.visibility),
                for (final p in (foto['parca_farklari'] is List ? (foto['parca_farklari'] as List).whereType<Map>() : <Map>[]))
                  _Madde(metin: '${p['parca']} (rapor: ${p['rapordaki_durum']}): ${p['gozlem']}', renk: Renk.pazarlik, ikon: Icons.compare),
                if ('${foto['uyari'] ?? ''}'.isNotEmpty) _Madde(metin: '${foto['uyari']}', ikon: Icons.info_outline),
              ],
            ]),
            _Bolum(baslik: 'Motor ve mekanik', children: [
              for (final m in r.mekanik)
                _Madde(
                  metin: '${m['baslik'] ?? ''}: ${m['aciklama'] ?? ''}',
                  renk: switch (m['durum']) { 'iyi' => Renk.temiz, 'izlenmeli' => Renk.pazarlik, _ => Renk.risk },
                  ikon: switch (m['durum']) { 'iyi' => Icons.check_circle, 'izlenmeli' => Icons.visibility, _ => Icons.build },
                ),
              for (final h in r.hataKodlari)
                _Madde(metin: '${h['kod']}: ${h['sade_aciklama']}\nTahmini masraf: ${h['tahmini_masraf_araligi_tl'] ?? '-'}', ikon: Icons.memory),
            ]),
            if (r.kmTutarliligi.isNotEmpty || r.tramerYorumu.isNotEmpty)
              _Bolum(baslik: 'Kilometre ve hasar kaydı', children: [
                if (r.kmTutarliligi.isNotEmpty) _Madde(metin: r.kmTutarliligi, ikon: Icons.speed),
                if (r.tramerYorumu.isNotEmpty) _Madde(metin: r.tramerYorumu, ikon: Icons.receipt_long),
              ]),
            if (r.kronikSorunlar.isNotEmpty)
              _Bolum(baslik: 'Bu modelin bilinen sorunları', children: [
                if (r.kaynaklar.isEmpty) const _Madde(metin: 'Kaynak bulunamadı; bu bilgi doğrulanmamıştır, ustanıza sorun.', ikon: Icons.info_outline),
                for (final k in r.kronikSorunlar) _Madde(metin: '${k['sorun']}\nNasıl kontrol edilir: ${k['kontrol_yolu']}', ikon: Icons.history),
              ]),
            _Bolum(baslik: 'Fiyat ve pazarlık', acik: true, children: [
              if (fiyat == null) const _Madde(metin: 'Piyasa fiyatı için yeterli kaynak bulunamadı.', ikon: Icons.help_outline),
              if (fiyat != null) ...[
                if ('${fiyat['piyasa_araligi'] ?? ''}'.isNotEmpty) _Madde(metin: 'Piyasa aralığı: ${fiyat['piyasa_araligi']}', ikon: Icons.bar_chart),
                if (r.kaynaklar.isEmpty)
                  const _Madde(metin: 'Bu fiyat aralığı doğrulanmış bir ilan listesine dayanmıyor; yalnızca yön göstericidir. Kendiniz de benzer ilanlara bakın.', ikon: Icons.info_outline),
                if (r.degerKaybiTl != null)
                  _Madde(
                    metin: r.degerKaybiTl!.$1 < 1
                        ? 'Kaporta kaynaklı değer kaybı en çok %${r.degerEtkisiYuzde!.$2.toStringAsFixed(0)}: ilan fiyatına göre yaklaşık ${Rapor.tl(r.degerKaybiTl!.$2)} (tahmini)'
                        : 'Kaporta kaynaklı değer kaybı: %${r.degerEtkisiYuzde!.$1.toStringAsFixed(0)}-${r.degerEtkisiYuzde!.$2.toStringAsFixed(0)}, ilan fiyatına göre yaklaşık ${Rapor.tl(r.degerKaybiTl!.$1)} - ${Rapor.tl(r.degerKaybiTl!.$2)} (tahmini)',
                    ikon: Icons.calculate,
                  ),
                if ('${fiyat['onerilen_pazarlik_tl'] ?? ''}'.isNotEmpty) _Madde(metin: 'Önerilen pazarlık: ${fiyat['onerilen_pazarlik_tl']}', ikon: Icons.handshake),
              ],
            ]),
            _Bolum(baslik: r.rol == 'satici' ? 'Alıcının soracakları ve cevaplarınız' : 'Satıcıya sorun', acik: true, children: [
              for (var i = 0; i < r.saticiyaSorulacaklar.length; i++) _Madde(metin: '${i + 1}. ${r.saticiyaSorulacaklar[i]}'),
              if (r.saticiyaSorulacaklar.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.copy),
                    label: const Text('Soruları kopyala'),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: r.saticiyaSorulacaklar.asMap().entries.map((e) => '${e.key + 1}. ${e.value}').join('\n')));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sorular kopyalandı', style: TextStyle(fontSize: 17))));
                    },
                  ),
                ),
            ]),
            if (r.testSurusu.isNotEmpty)
              _Bolum(baslik: 'Test sürüşünde bakın', children: [for (final s in r.testSurusu) _Madde(metin: s, ikon: Icons.directions_car)]),
            _Bolum(baslik: 'Kaynaklar', acik: true, children: [
              for (final k in r.kaynaklar.take(8)) _Kaynak(baslik: '${k['baslik']}', url: '${k['url']}'),
            ]),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.share),
              label: const Text('Özeti kopyala (WhatsApp için)'),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: r.paylasimMetni()));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Özet kopyalandı, WhatsApp\'a yapıştırabilirsiniz', style: TextStyle(fontSize: 17))));
              },
            ),
            const SizedBox(height: 16),
            Text(r.yasalNot, style: t.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic)),
          ],
                ),
              ),
            ),
          ),
          if (kTestModu) TestPaneli(rapor: widget.rapor, fotoKaynakli: widget.fotoKaynakli),
        ]),
        ),
      ),
    );
  }
}

String _tut(Object? v) => switch (v) {
      'evet' => 'rapordakiyle uyuyor',
      'hayir' => 'rapordakiyle uyuşmuyor',
      _ => 'fotoğraftan anlaşılamadı',
    };
Color _tutRenk(Object? v) => switch (v) { 'evet' => Renk.temiz, 'hayir' => Renk.risk, _ => Colors.grey };
IconData _tutIkon(Object? v) => switch (v) { 'evet' => Icons.check_circle, 'hayir' => Icons.cancel, _ => Icons.help_outline };

class _Kaynak extends StatelessWidget {
  const _Kaynak({required this.baslik, required this.url});
  final String baslik;
  final String url;

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: EdgeInsets.zero,
        minTileHeight: 56,
        leading: const Icon(Icons.open_in_new, color: Renk.camgobegiYazi),
        title: Text(baslik, style: Theme.of(context).textTheme.bodyLarge, maxLines: 2, overflow: TextOverflow.ellipsis),
        onTap: () async {
          final uri = Uri.tryParse(url);
          if (uri == null || uri.scheme != 'https') return;
          final acildi = await launchUrl(uri, mode: LaunchMode.externalApplication);
          if (!acildi && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bağlantı açılamadı.', style: TextStyle(fontSize: 17))));
          }
        },
      );
}

class _SahtelikKarti extends StatelessWidget {
  const _SahtelikKarti({required this.rapor});
  final Rapor rapor;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Card(
      color: Renk.risk.withValues(alpha: .12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: Renk.risk, width: 2)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.gpp_maybe, color: Renk.risk, size: 30),
            const SizedBox(width: 10),
            Expanded(child: Text('Belgeyi doğrulayın', style: t.textTheme.titleLarge)),
          ]),
          const SizedBox(height: 8),
          for (final s in rapor.sahtelikSinyalleri) Text('• $s', style: t.textTheme.bodyMedium),
          const SizedBox(height: 10),
          Text('Ne yapmalı?', style: t.textTheme.titleMedium),
          for (final a in rapor.dogrulamaAdimlari) Text('• $a', style: t.textTheme.bodyMedium),
        ]),
      ),
    );
  }
}

class _Not extends StatelessWidget {
  const _Not({required this.metin});
  final String metin;

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          leading: const Icon(Icons.info, color: Renk.camgobegiYazi),
          title: Text(metin, style: Theme.of(context).textTheme.bodyMedium),
        ),
      );
}

class _Bolum extends StatelessWidget {
  const _Bolum({required this.baslik, required this.children, this.acik = false});
  final String baslik;
  final List<Widget> children;
  final bool acik;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        key: ValueKey('$baslik-${_Yakala.of(context)}'),
        initiallyExpanded: acik || _Yakala.of(context),
        minTileHeight: 64,
        title: Text(baslik, style: Theme.of(context).textTheme.titleLarge),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class _Madde extends StatelessWidget {
  const _Madde({required this.metin, this.ikon, this.renk});
  final String metin;
  final IconData? ikon;
  final Color? renk;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (ikon != null) ...[Icon(ikon, color: renk ?? Theme.of(context).colorScheme.secondary, size: 26), const SizedBox(width: 12)],
          Expanded(child: Text(metin, style: Theme.of(context).textTheme.bodyLarge)),
        ]),
      );
}
