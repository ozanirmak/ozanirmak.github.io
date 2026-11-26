import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../ayarlar.dart';
import '../models/rapor.dart';
import 'gunluk.dart';
import 'istemci.dart';

/// Sunucudan gelen olaylar: adım değişimi, sonuç ya da hata.
sealed class AnalizOlayi {}

class Adim extends AnalizOlayi {
  Adim(this.ad);
  final String ad; // okunuyor | kontrol | yorum
}

class Sonuc extends AnalizOlayi {
  Sonuc(this.rapor);
  final Rapor rapor;
}

class Hata extends AnalizOlayi {
  Hata(this.mesaj);
  final String mesaj;
}

class SecilenDosya {
  SecilenDosya({required this.ad, required this.bayt});
  final String ad;
  final List<int> bayt;

  MediaType get tur {
    final a = ad.toLowerCase();
    if (a.endsWith('.pdf')) return MediaType('application', 'pdf');
    if (a.endsWith('.png')) return MediaType('image', 'png');
    if (a.endsWith('.webp')) return MediaType('image', 'webp');
    if (a.endsWith('.heic')) return MediaType('image', 'heic');
    return MediaType('image', 'jpeg');
  }
}

/// SUPABASE_URL verilmemişse demo modunda çalışır: sunucuya gitmez, örnek rapor gösterir.
Stream<AnalizOlayi> analizEt(List<SecilenDosya> dosyalar,
    {int? ilanFiyati, String rol = 'alici', List<SecilenDosya> aracFotolari = const []}) async* {
  Gunluk.baslat('Ekspertiz Okuyucu günlüğü ${DateTime.now().toIso8601String()}');
  Gunluk.ekle('mod: ${Ayarlar.demoModu ? 'DEMO' : 'gerçek'}, rol: $rol, ilan fiyatı: ${ilanFiyati ?? '-'}');
  for (final d in dosyalar) {
    Gunluk.ekle('rapor dosyası: ${d.ad} (${(d.bayt.length / 1048576).toStringAsFixed(2)} MB)');
  }
  for (final d in aracFotolari) {
    Gunluk.ekle('araç fotoğrafı: ${d.ad} (${(d.bayt.length / 1048576).toStringAsFixed(2)} MB)');
  }
  yield Adim('yukleniyor');
  if (Ayarlar.demoModu) {
    for (final a in ['okunuyor', 'kontrol', 'yorum']) {
      Gunluk.ekle('demo adım: $a');
      yield Adim(a);
      await Future<void>.delayed(const Duration(milliseconds: 900));
    }
    yield Sonuc(Rapor(jsonDecode(await rootBundle.loadString('assets/demo_rapor.json')) as Map<String, dynamic>));
    return;
  }

  final istek = http.MultipartRequest('POST', Uri.parse('${Ayarlar.supabaseUrl}/functions/v1/analyze-report'))
    ..headers['Authorization'] = 'Bearer ${Ayarlar.supabaseAnonKey}'
    ..headers['apikey'] = Ayarlar.supabaseAnonKey
    ..fields['rol'] = rol;
  if (ilanFiyati != null) istek.fields['ilan_fiyati'] = '$ilanFiyati';
  for (final d in dosyalar) {
    istek.files.add(http.MultipartFile.fromBytes('dosya', d.bayt, filename: d.ad, contentType: d.tur));
  }

  for (final d in aracFotolari) {
    istek.files.add(http.MultipartFile.fromBytes('arac_foto', d.bayt, filename: d.ad, contentType: d.tur));
  }

  final istemci = yeniIstemci();
  try {
    Gunluk.ekle('istek sunucuya gönderiliyor (yanıt başlığı için en çok ${kIsWeb ? 300 : 120} sn beklenir)');
    final yanit = await istemci.send(istek).timeout(Duration(seconds: kIsWeb ? 300 : 120));
    Gunluk.ekle('sunucu yanıt başlığı: HTTP ${yanit.statusCode}');
    if (yanit.statusCode != 200) {
      Gunluk.ekle('HTTP ${yanit.statusCode} gövde: ${(await yanit.stream.bytesToString()).replaceAll('\n', ' ')}');
      yield Hata('Sunucu yanıt vermedi (${yanit.statusCode}). Lütfen tekrar deneyin.');
      return;
    }
    final satirlar = yanit.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .timeout(const Duration(seconds: 300), onTimeout: (sink) {
          Gunluk.ekle('300 sn boyunca sunucudan satır gelmedi');
          sink.addError(TimeoutException('300 sn sessizlik'));
          sink.close();
        });
    await for (final satir in satirlar) {
      if (satir.trim().isEmpty) continue;
      final o = jsonDecode(satir) as Map<String, dynamic>;
      if (o['adim'] != null) {
        Gunluk.ekle('sunucu adımı: ${o['adim']}');
        yield Adim(o['adim'] as String);
      }
      if (o['sonuc'] != null) {
        final sonuc = o['sonuc'] as Map<String, dynamic>;
        final meta = Map<String, dynamic>.from((sonuc['meta'] as Map?) ?? {});
        final izler = (meta.remove('iz') as List?) ?? const [];
        Gunluk.ekle('SONUÇ alındı. meta: ${jsonEncode(meta)}');
        for (final iz in izler) {
          Gunluk.ekle('  sunucu izi: ${jsonEncode(iz)}');
        }
        yield Sonuc(Rapor(sonuc));
      }
      if (o['hata'] != null) {
        Gunluk.ekle('SUNUCU HATASI: ${o['hata']}');
        Gunluk.ekle('  ayrıntı: ${o['ayrinti']}, sunucu süresi: ${o['sure_sn']} sn');
        for (final iz in (o['iz'] as List? ?? const [])) {
          Gunluk.ekle('  sunucu izi: ${jsonEncode(iz)}');
        }
        yield Hata(o['hata'] as String);
      }
    }
  } catch (e) {
    Gunluk.ekle('İSTEMCİ HATASI: ${e.runtimeType}: $e');
    yield Hata('İnternet bağlantısı koptu ya da işlem çok uzun sürdü. Lütfen tekrar deneyin.');
  } finally {
    istemci.close();
  }
}
