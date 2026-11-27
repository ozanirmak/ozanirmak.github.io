/// analyze-report sonucunun Dart karşılığı. Bilinmeyen/eksik alanlar boş değer olur, uygulama çökmez.
class Rapor {
  Rapor(this.ham);
  final Map<String, dynamic> ham;

  Map<String, dynamic> get _r => _map(ham['rapor']);
  Map<String, dynamic> get arac => _map(ham['arac']);

  String get etiket => _r['etiket'] as String? ?? '';
  String get rol => _r['rol'] == 'satici' ? 'satici' : 'alici';
  List<Map<String, dynamic>> get ilkBakista => _maps(_r['ilk_bakista']);
  List<String> get iyiHaberler => _str(_r['iyi_haberler']);
  List<String> get neYapmali => _str(_r['ne_yapmali']);
  String get ozet => _r['ozet'] as String? ?? '';
  String get yasalNot => _r['yasal_not'] as String? ?? '';
  bool get sahtelikVar => _map(_r['sahtelik_uyarisi'])['var_mi'] == true;
  List<String> get sahtelikSinyalleri => _str(_map(_r['sahtelik_uyarisi'])['sinyaller']);
  List<String> get dogrulamaAdimlari => _str(_map(_r['sahtelik_uyarisi'])['dogrulama_adimlari']);
  Map<String, dynamic> get kaporta => _map(_r['kaporta_ozeti']);
  List<Map<String, dynamic>> get mekanik => _maps(_r['mekanik_ozeti']);
  List<Map<String, dynamic>> get hataKodlari => _maps(_r['hata_kodlari_aciklama']);
  List<Map<String, dynamic>> get kronikSorunlar => _maps(_r['kronik_sorunlar']);
  String get kmTutarliligi => _r['km_tutarliligi'] as String? ?? '';
  String get tramerYorumu => _r['tramer_yorumu'] as String? ?? '';
  Map<String, dynamic>? get fiyat => _r['fiyat_yorumu'] is Map ? _map(_r['fiyat_yorumu']) : null;
  List<String> get saticiyaSorulacaklar => _str(_r['saticiya_sorulacaklar']);
  List<String> get testSurusu => _str(_r['test_surusunde_kontrol']);
  /// Arama kaynakları: sunucu Google'dan gelen gerçek bağlantıları verir. Sadece https kabul edilir.
  List<Map<String, dynamic>> get kaynaklar =>
      _maps(ham['kaynaklar']).where((k) => '${k['url']}'.startsWith('https://')).toList();
  Map<String, dynamic>? get fotoKarsilastirma => _r['arac_foto_karsilastirma'] is Map ? _map(_r['arac_foto_karsilastirma']) : null;
  List<String> get kontrolNotlari => _str(ham['kontrol_notlari']);

  String get aracBasligi => [arac['marka'], arac['model'], arac['model_yili']]
      .where((e) => e != null && '$e'.isNotEmpty)
      .join(' ');

  static List<String> liste(Object? o) => _str(o);

  static Map<String, dynamic> _map(Object? o) => o is Map ? Map<String, dynamic>.from(o) : {};
  static List<String> _str(Object? o) => o is List ? o.map((e) => '$e').where((e) => e.trim().isNotEmpty).toList() : [];
  static List<Map<String, dynamic>> _maps(Object? o) => o is List ? o.whereType<Map>().map(Map<String, dynamic>.from).toList() : [];
}
