import json, random, os, io, subprocess, sys
from reportlab.lib.pagesizes import A4
from reportlab.pdfgen import canvas
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.lib import colors
from PIL import Image, ImageFilter, ImageDraw
random.seed(7)
OUT = sys.argv[1]
os.makedirs(OUT, exist_ok=True)
pdfmetrics.registerFont(TTFont('S', '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'))
pdfmetrics.registerFont(TTFont('SB', '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf'))
pdfmetrics.registerFont(TTFont('M', '/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf'))

PARCALAR = ["Ön Tampon","Kaput","Tavan","Bagaj Kapağı","Arka Tampon","Sol Ön Çamurluk","Sol Ön Kapı","Sol Arka Kapı","Sol Arka Çamurluk","Sağ Ön Çamurluk","Sağ Ön Kapı","Sağ Arka Kapı","Sağ Arka Çamurluk"]
DURUM = {"orijinal":"Orijinal","boyali":"Boyalı","lokal":"Lokal Boyalı","degisen":"Değişen"}
ARACLAR = [("Renault","Clio","1.5 dCi Joy",2016,"Dizel","Manuel"),("Volkswagen","Passat","1.6 TDI Comfortline",2017,"Dizel","Otomatik"),
 ("Fiat","Egea","1.4 Fire Easy",2019,"Benzin","Manuel"),("Toyota","Corolla","1.6 Vision",2018,"Benzin","Otomatik"),
 ("Hyundai","i20","1.4 MPI Style",2015,"Benzin","Otomatik"),("Ford","Focus","1.5 TDCi Trend X",2017,"Dizel","Manuel"),
 ("Opel","Astra","1.6 CDTI Sport",2016,"Dizel","Manuel"),("Honda","Civic","1.6 i-VTEC Eco Elegance",2018,"Benzin","Otomatik"),
 ("Peugeot","301","1.6 HDi Active",2014,"Dizel","Manuel"),("Dacia","Duster","1.5 dCi Laureate",2017,"Dizel","Manuel"),
 ("BMW","320i","Sedan Executive",2015,"Benzin","Otomatik"),("Skoda","Octavia","1.6 TDI Style",2018,"Dizel","Otomatik"),
 ("Nissan","Qashqai","1.5 dCi Visia",2016,"Dizel","Manuel"),("Seat","Leon","1.2 TSI Style",2017,"Benzin","Manuel"),
 ("Kia","Ceed","1.6 CRDi Concept",2016,"Dizel","Otomatik"),("Citroen","C3","1.2 PureTech Feel",2019,"Benzin","Manuel"),
 ("Mercedes","C 180","Sedan Style",2014,"Benzin","Otomatik")]
FIRMALAR = ["Eksper Oto Ekspertiz","Güven Araç Değerleme","Mavi Ekspertiz Merkezi","Anadolu Oto Kontrol"]
ILLER = ["26","06","34","35","16","41","07"]
HARFLER = "ABCDEFGHJKLMNPRSTUVYZ"

def plaka():
    return f"{random.choice(ILLER)} {''.join(random.choice(HARFLER) for _ in range(random.choice([2,3])))} {random.randint(10,999)}"

def maske(p):
    t = p.replace(" ","")
    return f"{t[:2]} *** {t[-2:]}"

def olustur(i, tip):
    a = ARACLAR[i % len(ARACLAR)]
    km = random.randint(40,230)*1000 + random.randint(0,9)*100
    pl = plaka()
    parts = {p:"orijinal" for p in PARCALAR}
    sasi = "Hasarsız, orijinal"
    tramer = 0
    if tip == "temiz":
        for p in random.sample(["Ön Tampon","Arka Tampon"],1): parts[p]="lokal"
    elif tip == "orta":
        for p in random.sample(PARCALAR[5:],3): parts[p]="boyali"
        parts[random.choice(["Ön Tampon","Arka Tampon"])]="degisen"
        tramer = random.choice([12500,18900,24300])
    elif tip == "agir":
        parts["Tavan"]="degisen"; parts["Sol Ön Çamurluk"]="degisen"; parts["Kaput"]="degisen"
        parts["Sol Ön Kapı"]="boyali"; parts["Sağ Ön Çamurluk"]="boyali"
        sasi = "Ön sol şasi (podye) kaynaklı onarım izi, düzeltme var"
        tramer = random.choice([86400,121000,157500])
    return dict(marka=a[0],model=a[1],paket=a[2],yil=a[3],yakit=a[4],vites=a[5],km=km,plaka=pl,plaka_maske=maske(pl),
                parts=parts,sasi=sasi,tramer=tramer,tip=tip,
                rapor_no=f"{random.choice(['EK','GA','MV','AN'])}-{random.randint(2026000,2026999)}",
                tarih=f"{random.randint(22,26)}.11.2026",firma=random.choice(FIRMALAR),
                tc=f"{random.randint(10,99)}{random.randint(10000000,99999999)}",tel=f"05{random.randint(30,59)} {random.randint(100,999)} {random.randint(10,99)} {random.randint(10,99)}",
                sahip=random.choice(["Hasan Yılmazoğlu","Fatma Kuşçuoğlu","Mehmet Ali Taşdemir","Ayşe Gülbahar"]),
                adres="Atatürk Mah. 1453. Sok. No:12 Odunpazarı",
                obd=random.choice([[],[],["P0420 Katalizör verimi düşük"],["P0299 Turbo basınç düşük","P2002 DPF verimi"]]),
                lastik=random.choice(["%70 diş","%40 diş","%85 diş"]), balata=random.choice(["%60","%30","%80"]))

def pdf_yaz(d, yol, stil, sayfa_ek=0, producer=None, ekstra_kvkk=False, eksik=False):
    c = canvas.Canvas(yol, pagesize=A4)
    if producer: c.setProducer(producer); c.setCreator(producer)
    W,H = A4
    def baslik(y):
        c.setFont('SB',16); c.drawString(40,y,f"{d['firma']} - OTO EKSPERTİZ RAPORU")
        c.setFont('S',9); c.drawString(40,y-16,f"Rapor No: {d['rapor_no']}    Tarih: {d['tarih']}    Doğrulama kodu: {random.randint(100000,999999)}")
    baslik(H-50)
    y = H-100
    c.setFont('SB',11); c.drawString(40,y,"ARAÇ BİLGİLERİ"); y-=18
    c.setFont('S',10)
    satirlar = [f"Marka / Model: {d['marka']} {d['model']} {d['paket']}", f"Model Yılı: {d['yil']}    Yakıt: {d['yakit']}    Vites: {d['vites']}"]
    if not eksik:
        satirlar += [f"Kilometre: {d['km']:,}".replace(',','.')+" km", f"Plaka: {d['plaka']}"]
    else:
        satirlar += ["Kilometre: okunamadı (gösterge arızalı)", "Plaka: -"]
    if ekstra_kvkk:
        satirlar += [f"Araç Sahibi: {d['sahip']}   T.C. Kimlik No: {d['tc']}", f"Telefon: {d['tel']}   Adres: {d['adres']}"]
    for s in satirlar:
        c.drawString(40,y,s); y-=14
    y-=10
    c.setFont('SB',11); c.drawString(40,y,"KAPORTA / BOYA DURUMU"); y-=16
    c.setFont('S',10)
    for p,s in d['parts'].items():
        mik = {"orijinal":random.randint(95,140),"boyali":random.randint(180,320),"lokal":random.randint(150,230),"degisen":random.randint(220,400)}[s]
        if stil=="liste":
            c.drawString(40,y,f"{p}: {DURUM[s]}")
        else:
            c.drawString(40,y,p); c.drawString(240,y,DURUM[s]); c.drawString(340,y,f"{mik} mikron")
        y-=13
    y-=8
    c.setFont('SB',11); c.drawString(40,y,"ŞASİ / PODYE / DİREKLER"); y-=15
    c.setFont('S',10); c.drawString(40,y,d['sasi']); y-=24
    c.showPage()
    # 2. sayfa
    y = H-60
    c.setFont('SB',11); c.drawString(40,y,"MOTOR / MEKANİK"); y-=16; c.setFont('S',10)
    for s in ["Motor: Yağ sızıntısı yok, sessiz çalışıyor","Şanzıman: Vites geçişleri normal","Fren balata: "+d['balata'],"Lastikler: "+d['lastik'],"Akü: Sağlam","Süspansiyon: Sağ ön rotbaşı hafif boşluk"]:
        c.drawString(40,y,s); y-=13
    y-=10; c.setFont('SB',11); c.drawString(40,y,"OBD HATA KODLARI"); y-=15; c.setFont('S',10)
    for o in (d['obd'] or ["Kayıtlı hata kodu yok"]):
        c.drawString(40,y,o); y-=13
    y-=10; c.setFont('SB',11); c.drawString(40,y,"HASAR KAYDI (TRAMER)"); y-=15; c.setFont('S',10)
    c.drawString(40,y,("Kayıt yok" if d['tramer']==0 else f"Toplam hasar kaydı: {d['tramer']:,} TL".replace(',','.'))); y-=24
    c.setFont('SB',11); c.drawString(40,y,"EKSPERTİZ NOTLARI"); y-=15; c.setFont('S',10)
    c.drawString(40,y,"Araç genel olarak yaşına göre bakımlıdır. Test sürüşü yapılmıştır."); y-=14
    c.showPage()
    for k in range(sayfa_ek):
        y = H-60; c.setFont('SB',11); c.drawString(40,y,f"EK SAYFA {k+1}: Fotoğraflı detay açıklamaları"); y-=18; c.setFont('S',9)
        for j in range(40):
            c.drawString(40,y,f"Detay {j+1}: Parça kontrolü yapıldı, ölçüm sonucu rapor ana sayfalarında belirtilmiştir."); y-=13
        c.showPage()
    c.save()

def raster(pdf_yol, cikis_jpg=None, cikis_pdf=None, aci=1.5, kalite=55, dpi=130, bulanik=0.8):
    subprocess.run(["pdftoppm","-r",str(dpi),"-jpeg","-jpegopt","quality=90",pdf_yol,"/tmp/_sayfa"],check=True)
    sayfalar = sorted(f for f in os.listdir("/tmp") if f.startswith("_sayfa"))
    imgs=[]
    for f in sayfalar:
        im = Image.open("/tmp/"+f).convert("RGB")
        im = im.rotate(aci, expand=True, fillcolor=(235,232,225))
        im = im.filter(ImageFilter.GaussianBlur(bulanik))
        d = ImageDraw.Draw(im)
        for _ in range(6):
            x=random.randint(0,im.width); d.line([(x,0),(x+random.randint(-40,40),im.height)],fill=(228,226,220),width=random.randint(2,6))
        imgs.append(im)
        os.remove("/tmp/"+f)
    if cikis_jpg:
        imgs[0].save(cikis_jpg,"JPEG",quality=kalite)
    if cikis_pdf:
        imgs[0].save(cikis_pdf,"PDF",save_all=True,append_images=imgs[1:])

kayit = []
def ekle(ad, d, **kw):
    kayit.append(dict(dosya=ad, **{k:v for k,v in d.items()}, **kw))

n = 0
def yeni(tip, **kw):
    global n
    d = olustur(n, tip); n += 1; return d

# temiz x3, orta x3, agir x3 metin PDF
for tip in ["temiz","temiz","temiz","orta","orta","orta","agir","agir","agir"]:
    d = yeni(tip); ad = f"{len(kayit)+1:02d}_{tip}_metin.pdf"
    pdf_yaz(d, f"{OUT}/{ad}", random.choice(["tablo","liste"]), sayfa_ek=0)
    ekle(ad, d, tur="metin_pdf")
# taranmis PDF x2 (orta, temiz)
for tip in ["orta","temiz"]:
    d = yeni(tip); ad=f"{len(kayit)+1:02d}_{tip}_taranmis.pdf"; tmp="/tmp/_t.pdf"
    pdf_yaz(d,tmp,"tablo"); raster(tmp,cikis_pdf=f"{OUT}/{ad}",aci=1.2); ekle(ad,d,tur="taranmis_pdf")
# telefon fotografi JPEG x2 (sadece 1. sayfa; parca durumlari sayfa 1'de)
for tip in ["agir","orta"]:
    d = yeni(tip); ad=f"{len(kayit)+1:02d}_{tip}_telefon_foto.jpg"; tmp="/tmp/_t.pdf"
    pdf_yaz(d,tmp,"tablo"); raster(tmp,cikis_jpg=f"{OUT}/{ad}",aci=2.5,kalite=45,dpi=110,bulanik=1.1); ekle(ad,d,tur="foto",sadece_sayfa1=True)
# cok sayfali x1
d = yeni("orta"); ad=f"{len(kayit)+1:02d}_orta_cok_sayfali.pdf"; pdf_yaz(d,f"{OUT}/{ad}","liste",sayfa_ek=10); ekle(ad,d,tur="cok_sayfali")
# sahte (duzenlenmis) x1
d = yeni("agir"); ad=f"{len(kayit)+1:02d}_agir_duzenlenmis.pdf"; pdf_yaz(d,f"{OUT}/{ad}","tablo",producer="Adobe Photoshop 25.0")
ekle(ad,d,tur="sahte",beklenen_sahtelik=True)
# kisisel veri x1
d = yeni("temiz"); ad=f"{len(kayit)+1:02d}_temiz_kisisel_veri.pdf"; pdf_yaz(d,f"{OUT}/{ad}","tablo",ekstra_kvkk=True); ekle(ad,d,tur="kisisel_veri",pii=True)
# eksik alan x1
d = yeni("orta"); ad=f"{len(kayit)+1:02d}_orta_eksik_alan.pdf"; pdf_yaz(d,f"{OUT}/{ad}","tablo",eksik=True); ekle(ad,d,tur="eksik",eksik=True)
# rapor degil x1
ad=f"{len(kayit)+1:02d}_rapor_degil.pdf"
c=canvas.Canvas(f"{OUT}/{ad}",pagesize=A4); c.setFont('SB',16); c.drawString(40,780,"Lezzet Durağı - Yemek Menüsü")
c.setFont('S',11)
for i,(u,f) in enumerate([("Adana Kebap","320 TL"),("Mercimek Çorbası","90 TL"),("Künefe","150 TL"),("Ayran","30 TL")]): c.drawString(40,740-i*18,f"{u} ........ {f}")
c.save(); kayit.append(dict(dosya=ad,tur="rapor_degil",tip="yok"))
json.dump(kayit, open(f"{OUT}/dogru.json","w"), ensure_ascii=False, indent=1)
print(len(kayit),"dosya")
