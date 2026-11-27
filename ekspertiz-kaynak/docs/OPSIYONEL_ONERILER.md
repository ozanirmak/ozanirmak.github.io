# Ekspertiz Okuyucu: opsiyonel öneriler

Henüz yapılmadı. Karar verilince eklenir. İlk 7 uyumsuzluk kontrolü (yakıt-paket, boya kalınlığı, şasi özeti, tramer, hata kodu-yakıt, etiket zorlaması, taranmış PDF) yapıldı.

## Uyumsuzluk kontrolleri (kod, ek maliyet yok)
8. İlan km'si ile rapor km'si: ek bilgi ekranına "ilandaki km" alanı gerekir. Fark 1.000 km üstünde uyarı. Değeri yüksek.
9. Vites ile paket: "Manuel" yazılmış ama paket DSG, EDC, CVT ya da AMT ise. Küçük iş.
10. Rapor tarihi ile model yılı: rapor, aracın model yılından önce yapılmış olamaz. Çok ucuz.
11. Okunamayan alan sayısı çok (3'ten fazla): "fotoğraf kalitesi düşük, yeniden çekin" önerisi.
12. Şasi numarasındaki yıl harfi ile model yılı: okuma sırasında yıl harfi kodla hesaplanıp numara atılır. Orta iş, sunucu değişikliği.

## Bilerek yapılmayanlar
- Lastik aşınması ile km, akü voltu ile durum: eşikler araca göre değişir, yanlış alarm riski yüksek. AI'ya bırakıldı.
- Fiyat ile hasar çelişkisi: kaynaksız fiyatla anlamsız. Önce piyasa kaynağı sorunu çözülmeli.

## Diğer
- Satıcı rolünün test ölçümü: Gemini harcama sınırı yükselince ekspertiz-test iş akışı yeniden koşulacak.
- Yayın öncesi: test paneli, ham veri ve PNG indirme menüsü, hata günlüğü ekranı kaldırılacak (TEST_MODU=false ya da dosyaları silmek).
