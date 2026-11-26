import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/api.dart';
import 'gunluk_ekrani.dart';
import 'rapor_ekrani.dart';

/// Sunucudan gelen gerçek adımları gösterir. Her adımın içindeki yüzde,
/// o adımın tipik süresine göre tahmindir; adım gerçekten bitmeden sonraki adıma geçmez.
class IsleniyorEkrani extends StatefulWidget {
  const IsleniyorEkrani({super.key, required this.dosyalar, this.ilanFiyati, this.rol = 'alici', this.aracFotolari = const [], this.akis});
  final List<SecilenDosya> dosyalar;
  final int? ilanFiyati;
  final String rol;
  final List<SecilenDosya> aracFotolari;
  final Stream<AnalizOlayi>? akis; // testler için

  @override
  State<IsleniyorEkrani> createState() => _IsleniyorEkraniState();
}

class _Adim {
  const _Adim(this.ad, this.baslik, this.baslangic, this.bitis, this.tipikSn);
  final String ad, baslik;
  final int baslangic, bitis; // yüzde aralığı
  final double tipikSn;
}

class _IsleniyorEkraniState extends State<IsleniyorEkrani> {
  static const _adimlar = [
    _Adim('yukleniyor', 'Dosya sunucuya gönderiliyor', 0, 8, 8),
    _Adim('okunuyor', 'Rapor okunuyor', 8, 50, 35),
    _Adim('kontrol', 'Parçalar ve belge kontrol ediliyor', 50, 56, 3),
    _Adim('yorum', 'Piyasa araştırılıyor, rapor yazılıyor', 56, 98, 45),
  ];

  String _aktif = 'yukleniyor';
  String? _hata;
  StreamSubscription<AnalizOlayi>? _abone;
  Timer? _zamanlayici;
  final _toplam = Stopwatch();
  final _adimSure = Stopwatch();
  final _bitenSureler = <String, int>{};

  @override
  void initState() {
    super.initState();
    _baslat();
  }

  void _baslat() {
    _aktif = 'yukleniyor';
    _hata = null;
    _bitenSureler.clear();
    _toplam
      ..reset()
      ..start();
    _adimSure
      ..reset()
      ..start();
    _zamanlayici?.cancel();
    _zamanlayici = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) setState(() {});
    });
    setState(() {});
    _abone?.cancel();
    _abone = (widget.akis ?? analizEt(widget.dosyalar, ilanFiyati: widget.ilanFiyati, rol: widget.rol, aracFotolari: widget.aracFotolari)).listen((o) {
      if (!mounted) return;
      switch (o) {
        case Adim(:final ad):
          if (ad != _aktif && _adimlar.any((a) => a.ad == ad)) {
            _bitenSureler[_aktif] = _adimSure.elapsed.inSeconds;
            _adimSure
              ..reset()
              ..start();
            setState(() => _aktif = ad);
          }
        case Hata(:final mesaj):
          _durdur();
          setState(() => _hata = mesaj);
        case Sonuc(:final rapor):
          _durdur();
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => RaporEkrani(rapor: rapor)));
      }
    });
  }

  void _durdur() {
    _zamanlayici?.cancel();
    _toplam.stop();
    _adimSure.stop();
  }

  @override
  void dispose() {
    _abone?.cancel();
    _zamanlayici?.cancel();
    super.dispose();
  }

  int get _yuzde {
    final i = _adimlar.indexWhere((a) => a.ad == _aktif);
    final a = _adimlar[i < 0 ? 0 : i];
    final oran = 1 - math.exp(-_adimSure.elapsed.inMilliseconds / 1000 / a.tipikSn);
    return (a.baslangic + (a.bitis - a.baslangic) * oran).floor();
  }

  String _sn(int s) => s >= 60 ? '${s ~/ 60} dk ${s % 60} sn' : '$s sn';

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final aktifNo = _adimlar.indexWhere((a) => a.ad == _aktif);
    final yuzde = _hata == null ? _yuzde : 0;
    return Scaffold(
      appBar: AppBar(title: const Text('Raporunuz hazırlanıyor')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_hata == null) ...[
                Text('%$yuzde', textAlign: TextAlign.center, style: t.textTheme.displayMedium?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(value: yuzde / 100, minHeight: 14),
                ),
                const SizedBox(height: 8),
                Text('Geçen süre: ${_sn(_toplam.elapsed.inSeconds)}', textAlign: TextAlign.center, style: t.textTheme.bodyMedium),
                const SizedBox(height: 16),
              ],
              for (var i = 0; i < _adimlar.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(children: [
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: i < aktifNo
                          ? Icon(Icons.check_circle, color: t.colorScheme.secondary, size: 32)
                          : i == aktifNo && _hata == null
                              ? const CircularProgressIndicator(strokeWidth: 3)
                              : Icon(Icons.circle_outlined, color: t.disabledColor, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        _adimlar[i].baslik,
                        style: t.textTheme.bodyLarge?.copyWith(color: i <= aktifNo ? null : t.disabledColor),
                      ),
                    ),
                    if (i < aktifNo && _bitenSureler[_adimlar[i].ad] != null) Text(_sn(_bitenSureler[_adimlar[i].ad]!), style: t.textTheme.bodyMedium),
                    if (i == aktifNo && _hata == null) Text(_sn(_adimSure.elapsed.inSeconds), style: t.textTheme.bodyMedium),
                  ]),
                ),
              const SizedBox(height: 12),
              if (_hata == null)
                Text(
                  'Yüzde, adımın tipik süresine göre tahmindir; adım bitmeden sonrakine geçilmez. '
                  'İnternet yavaşsa ya da işlem uzarsa uygulama beklemeye devam eder, bu ekranı kapatmayın.',
                  style: t.textTheme.bodyMedium,
                ),
              if (_hata != null) ...[
                Text(_hata!, style: t.textTheme.bodyLarge?.copyWith(color: t.colorScheme.error)),
                const SizedBox(height: 24),
                FilledButton(onPressed: _baslat, child: const Text('Tekrar Dene')),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GunlukEkrani())),
                  icon: const Icon(Icons.bug_report),
                  label: const Text('Hata Günlüğünü Göster'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Geri Dön')),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
