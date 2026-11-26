import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../ayarlar.dart';
import '../services/api.dart';
import '../services/kamera.dart';
import '../tema.dart';
import 'ek_bilgi_ekrani.dart';

class AnaEkran extends StatefulWidget {
  const AnaEkran({super.key});

  @override
  State<AnaEkran> createState() => _AnaEkranState();
}

class _AnaEkranState extends State<AnaEkran> {
  static const _maksBayt = 15 * 1024 * 1024;
  static const _kanal = MethodChannel('ekspertiz/paylas');

  @override
  void initState() {
    super.initState();
    _kanal.setMethodCallHandler((c) async {
      if (c.method == 'paylasim') _paylasimiAl(c.arguments);
    });
    _ilkPaylasim();
  }

  @override
  void dispose() {
    _kanal.setMethodCallHandler(null);
    super.dispose();
  }

  /// Uygulama başka bir uygulamadan "Paylaş" ile açıldıysa dosyaları alır.
  Future<void> _ilkPaylasim() async {
    try {
      _paylasimiAl(await _kanal.invokeMethod<Object?>('ilkPaylasim'));
    } catch (_) {
      // Kanal yok (test ortamı): sorun değil.
    }
  }

  void _paylasimiAl(Object? veri) {
    if (veri is! List || !mounted) return;
    final dosyalar = veri
        .whereType<Map>()
        .where((m) => m['bayt'] is Uint8List)
        .map((m) => SecilenDosya(ad: '${m['ad']}', bayt: m['bayt'] as Uint8List))
        .toList();
    if (dosyalar.isNotEmpty) _ilerle(dosyalar);
  }

  Future<void> _kameradan() async {
    if (!await _kvkkOnayi(context) || !mounted) return;
    final dosyalar = await kameradanCek(context);
    if (dosyalar.isEmpty || !mounted) return;
    _ilerle(dosyalar, onayVerildi: true);
  }

  Future<void> _ilerle(List<SecilenDosya> dosyalar, {bool onayVerildi = false}) async {
    final hata = _kontrol(dosyalar);
    if (hata != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(hata, style: const TextStyle(fontSize: 17))));
      return;
    }
    if (!onayVerildi && !await _kvkkOnayi(context)) return;
    if (!mounted) return;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => EkBilgiEkrani(dosyalar: dosyalar)));
  }

  Future<void> _raporSec() async {
    if (!await _kvkkOnayi(context)) return;
    final secim = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png', 'webp', 'heic'],
      allowMultiple: true,
      withData: true,
    );
    if (secim == null || !mounted) return;
    final dosyalar = secim.files
        .where((f) => f.bytes != null)
        .map((f) => SecilenDosya(ad: f.name, bayt: f.bytes!))
        .toList();
    _ilerle(dosyalar, onayVerildi: true);
  }

  static String? _kontrol(List<SecilenDosya> d) {
    if (d.isEmpty) return 'Dosya okunamadı.';
    final pdf = d.where((f) => f.ad.toLowerCase().endsWith('.pdf')).length;
    if (pdf > 0 && d.length > 1) return 'PDF seçtiyseniz sadece onu seçin.';
    if (d.length > 10) return 'En fazla 10 fotoğraf seçebilirsiniz.';
    if (d.fold<int>(0, (t, f) => t + f.bayt.length) > _maksBayt) return 'Dosya çok büyük (en fazla 15 MB).';
    return null;
  }

  /// İlk kullanımda bir kez. Rapor Google'ın yurt dışındaki sunucularında işlendiği için açık rıza gerekir.
  Future<bool> _kvkkOnayi(BuildContext context) async {
    final tercih = await SharedPreferences.getInstance();
    if (tercih.getBool('kvkk_onay') == true) return true;
    if (!context.mounted) return false;
    final onay = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Raporunuz nasıl işlenir?'),
        content: const SingleChildScrollView(
          child: Text(
            'Seçtiğiniz rapor, açıklama hazırlanması için yapay zeka hizmetine (Google Gemini, yurt dışı sunucular) gönderilir.\n\n'
            'Dosyanız kaydedilmez, işlem bitince silinir. Plaka ve şase numarası gizlenir; ad, telefon ve kimlik bilgileri okunmaz.\n\n'
            'Devam ederek kişisel verilerinizin bu amaçla yurt dışına aktarılmasına açık rıza vermiş olursunuz.',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Vazgeç')),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(140, 56)),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Kabul ediyorum'),
          ),
        ],
      ),
    );
    if (onay == true) await tercih.setBool('kvkk_onay', true);
    return onay == true;
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, kutu) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: kutu.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                  child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (Ayarlar.demoModu)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: Renk.camgobegi.withValues(alpha: .18), borderRadius: BorderRadius.circular(12)),
                  child: Text('Demo modu: sunucuya bağlanmadan örnek rapor gösterilir.', style: t.textTheme.bodyMedium),
                ),
              Text('Ekspertiz\nOkuyucu', style: t.textTheme.headlineLarge),
              const SizedBox(height: 16),
              Text(
                'Ekspertiz raporunuzu seçin, size sade dille anlatalım: neye dikkat etmelisiniz, ne kadar pazarlık yapabilirsiniz.',
                style: t.textTheme.bodyLarge,
              ),
              const Spacer(),
              Icon(Icons.description_outlined, size: 96, color: t.colorScheme.primary),
              const Spacer(),
              FilledButton.icon(
                onPressed: _raporSec,
                icon: const Icon(Icons.upload_file, size: 28),
                label: const Text('Raporumu Açıkla'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _kameradan,
                icon: const Icon(Icons.photo_camera, size: 28),
                label: const Text('Fotoğraf Çek'),
              ),
              const SizedBox(height: 12),
              Text('PDF ya da raporun fotoğrafları. Başka uygulamadan "Paylaş" ile de gönderebilirsiniz.',
                  textAlign: TextAlign.center, style: t.textTheme.bodyMedium),
            ],
          ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
