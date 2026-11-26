/// Geçici hata ayıklama günlüğü: her adımın süresini ve sunucu izini metin olarak tutar.
/// Sorun çözülünce bu dosya, günlük ekranı ve çağrıları kaldırılacak.
class Gunluk {
  static final Stopwatch _saat = Stopwatch();
  static final List<String> _satirlar = [];

  static void baslat(String baslik) {
    _satirlar.clear();
    _saat
      ..reset()
      ..start();
    _satirlar.add(baslik);
  }

  static void ekle(String mesaj) {
    final sn = (_saat.elapsedMilliseconds / 1000).toStringAsFixed(1).padLeft(6);
    _satirlar.add('[$sn sn] $mesaj');
  }

  static String get metin => _satirlar.isEmpty ? 'Henüz kayıt yok.' : _satirlar.join('\n');
}
