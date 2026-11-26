import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/api.dart';
import '../services/kamera.dart';
import 'isleniyor_ekrani.dart';

class EkBilgiEkrani extends StatefulWidget {
  const EkBilgiEkrani({super.key, required this.dosyalar});
  final List<SecilenDosya> dosyalar;

  @override
  State<EkBilgiEkrani> createState() => _EkBilgiEkraniState();
}

class _EkBilgiEkraniState extends State<EkBilgiEkrani> {
  final _fiyat = TextEditingController();
  String _rol = 'alici';
  final _foto = <SecilenDosya>[];
  static const _maksFoto = 4;
  static const _maksBayt = 15 * 1024 * 1024;

  Future<void> _fotoCek() async {
    final yeni = await kameradanCek(context, en: _maksFoto - _foto.length, coklu: true);
    if (mounted) setState(() => _foto.addAll(yeni));
  }

  Future<void> _fotoGaleri() async {
    final yeni = await galeridenSec(en: _maksFoto - _foto.length);
    if (mounted) setState(() => _foto.addAll(yeni));
  }

  @override
  void dispose() {
    _fiyat.dispose();
    super.dispose();
  }

  void _devam({bool atla = false}) {
    final foto = atla ? <SecilenDosya>[] : _foto;
    final toplam = [...widget.dosyalar, ...foto].fold<int>(0, (t, f) => t + f.bayt.length);
    if (toplam > _maksBayt) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dosyalar çok büyük (toplam en fazla 15 MB). Bazı fotoğrafları kaldırın.', style: TextStyle(fontSize: 17))),
      );
      return;
    }
    final fiyat = atla ? null : int.tryParse(_fiyat.text.replaceAll(RegExp(r'\D'), ''));
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => IsleniyorEkrani(dosyalar: widget.dosyalar, ilanFiyati: fiyat, rol: atla ? 'alici' : _rol, aracFotolari: foto),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Birkaç bilgi (isteğe bağlı)')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text('Aracın ilandaki fiyatı', style: t.textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _fiyat,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(fontSize: 22),
              decoration: const InputDecoration(hintText: 'Örnek: 850000', suffixText: 'TL'),
            ),
            const SizedBox(height: 8),
            Text('Fiyatı yazarsanız pazarlık önerisi de alırsınız.', style: t.textTheme.bodyMedium),
            const SizedBox(height: 28),
            Text('Siz kimsiniz?', style: t.textTheme.titleMedium),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              style: SegmentedButton.styleFrom(minimumSize: const Size.fromHeight(56), textStyle: const TextStyle(fontSize: 18)),
              segments: const [
                ButtonSegment(value: 'alici', label: Text('Alıcıyım')),
                ButtonSegment(value: 'satici', label: Text('Satıcıyım')),
              ],
              selected: {_rol},
              onSelectionChanged: (s) => setState(() => _rol = s.first),
            ),
            const SizedBox(height: 28),
            Text('Aracın fotoğrafı (isteğe bağlı)', style: t.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Aracın fotoğrafını eklerseniz marka, model, renk ve boya tonunu rapordakiyle karşılaştırırız. Fotoğraf kaydedilmez.',
              style: t.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            if (_foto.isNotEmpty)
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (var i = 0; i < _foto.length; i++)
                  Stack(children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(Uint8List.fromList(_foto[i].bayt), width: 88, height: 88, fit: BoxFit.cover),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: IconButton.filled(
                        iconSize: 18,
                        visualDensity: VisualDensity.compact,
                        onPressed: () => setState(() => _foto.removeAt(i)),
                        icon: const Icon(Icons.close),
                        tooltip: 'Kaldır',
                      ),
                    ),
                  ]),
              ]),
            if (_foto.length < _maksFoto) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(onPressed: _fotoCek, icon: const Icon(Icons.photo_camera), label: const Text('Aracın fotoğrafını çek')),
              const SizedBox(height: 8),
              OutlinedButton.icon(onPressed: _fotoGaleri, icon: const Icon(Icons.photo_library), label: const Text('Galeriden seç')),
            ],
            const SizedBox(height: 40),
            FilledButton(onPressed: _devam, child: const Text('Raporu Hazırla')),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: () => _devam(atla: true), child: const Text('Atla')),
          ],
        ),
      ),
    );
  }
}
