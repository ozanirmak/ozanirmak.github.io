import json, re, sys, time, os, requests
from concurrent.futures import ThreadPoolExecutor
AYAR = json.load(open("ekspertiz-kaynak/ayarlar.json"))
URL = AYAR["SUPABASE_URL"] + "/functions/v1/analyze-report"
H = {"Authorization": "Bearer " + AYAR["SUPABASE_ANON_KEY"], "apikey": AYAR["SUPABASE_ANON_KEY"]}
DIR = "ekspertiz-test/set"
DOGRU = json.load(open(DIR + "/dogru.json"))
ETIKET = {"temiz": ["Temiz görünüyor", "Pazarlıkla değerlendirilebilir"],
          "orta": ["Pazarlıkla değerlendirilebilir", "Dikkatli olun"],
          "agir": ["Dikkatli olun", "Ciddi risk var"]}

def cagir(k):
    yol = f"{DIR}/{k['dosya']}"
    tur = "application/pdf" if yol.endswith(".pdf") else "image/jpeg"
    t0 = time.time(); adimlar = []; sonuc = hata = None
    try:
        with open(yol, "rb") as f:
            r = requests.post(URL, headers=H, files={"dosya": (k["dosya"], f, tur)}, data={"rol": "alici"}, stream=True, timeout=(30, 300))
        if r.status_code != 200:
            return dict(sure=time.time() - t0, hata=f"HTTP {r.status_code}: {r.text[:200]}", adimlar=adimlar)
        for satir in r.iter_lines(decode_unicode=True):
            if not satir: continue
            o = json.loads(satir)
            if "adim" in o: adimlar.append((o["adim"], round(time.time() - t0, 1)))
            if "sonuc" in o: sonuc = o["sonuc"]
            if "hata" in o: hata = o["hata"] + " | " + str(o.get("ayrinti", ""))[:200]
    except Exception as e:
        hata = f"ISTEMCI: {type(e).__name__}: {e}"
    return dict(sure=time.time() - t0, sonuc=sonuc, hata=hata, adimlar=adimlar)

def say(x): return re.sub(r"\D", "", str(x))

def degerlendir(k, c):
    kontrol = {}
    if k["tur"] == "rapor_degil":
        kontrol["reddetti"] = bool(c.get("hata")) and "benzemiyor" in (c.get("hata") or "")
        return kontrol
    s = c.get("sonuc")
    kontrol["tamamlandi"] = s is not None
    kontrol["90sn_icinde"] = c["sure"] <= 90
    if not s: return kontrol
    rapor, arac = s["rapor"], (s.get("arac") or {})
    dump = json.dumps(s, ensure_ascii=False).lower()
    kontrol["marka"] = k["marka"].lower() in str(arac.get("marka", "")).lower()
    kontrol["yil"] = str(arac.get("model_yili")) == str(k["yil"])
    if k.get("eksik"):
        kontrol["km_uydurmadi"] = arac.get("km") in (None, 0, "")
        kontrol["plaka_uydurmadi"] = not re.search(r"\d{2}\s?\*+\s?\d{2}", str(arac.get("plaka_maskeli") or ""))
    else:
        kontrol["km"] = say(arac.get("km")) == str(k["km"])
        pm = str(arac.get("plaka_maskeli") or "").replace(" ", "")
        t = k["plaka"].replace(" ", "")
        kontrol["plaka_maske"] = pm[:2] == t[:2] and pm[-2:] == t[-2:] and "*" in pm
    kontrol["plaka_acik_degil"] = k["plaka"].replace(" ", "").lower() not in dump.replace(" ", "")
    kap = rapor["kaporta_ozeti"]
    ogeler = [str(x).lower() for l in ("kritik", "orta", "onemsiz") for x in kap.get(l, [])]
    bulunan = 0; toplam = 0
    for p, d in k["parts"].items():
        if d == "orijinal": continue
        toplam += 1
        kelimeler = p.lower().split()
        if any(all(w in o for w in kelimeler) for o in ogeler): bulunan += 1
    kontrol["degisen_boyali_yakalama"] = (bulunan / toplam >= 0.8) if toplam else True
    kontrol["yakalanan"] = f"{bulunan}/{toplam}"
    if k["tip"] in ("temiz", "orta") and "hasarsız" in k["sasi"].lower():
        kritik = " ".join(str(x).lower() for x in kap.get("kritik", []))
        kontrol["sasi_yanlis_alarm_yok"] = "şasi" not in kritik and "podye" not in kritik
    if k["tip"] in ETIKET and k["tip"] != "yok":
        kontrol["etiket_uygun"] = rapor["etiket"] in ETIKET[k["tip"]]
        kontrol["etiket"] = rapor["etiket"]
    if k["tramer"]:
        a = k["tramer"]; bi = f"{a:,}".replace(",", ".")
        kontrol["tramer_tutari"] = (bi in dump) or (str(a) in dump)
    if k.get("pii"):
        kontrol["kisisel_veri_sizmadi"] = not any(x.lower() in dump for x in [k["tc"], k["tel"], k["sahip"], k["tel"].replace(" ", "")])
    sah = rapor["sahtelik_uyarisi"]["var_mi"]
    if k.get("beklenen_sahtelik"): kontrol["sahtelik_yakaladi"] = sah
    elif k["tur"] in ("metin_pdf", "cok_sayfali", "kisisel_veri", "eksik"): kontrol["sahtelik_yanlis_alarm_yok"] = not sah
    return kontrol

with ThreadPoolExecutor(3) as ex:
    cevaplar = list(ex.map(cagir, DOGRU))
tum = []; maliyet = 0
for k, c in zip(DOGRU, cevaplar):
    kon = degerlendir(k, c)
    tum.append((k, c, kon))
    m = (c.get("sonuc") or {}).get("meta", {})
    maliyet += m.get("maliyet_usd", 0) or 0
    bool_kon = {a: b for a, b in kon.items() if isinstance(b, bool)}
    kalan = [a for a, b in bool_kon.items() if not b]
    print(f"{k['dosya']:36s} {c['sure']:5.1f}sn  {'GECTI' if not kalan else 'KALDI: ' + ','.join(kalan)}  {kon.get('yakalanan','')} {kon.get('etiket','')}")
    if c.get("hata"): print("    hata:", c["hata"][:300])
    if m.get("iz"):
        print("    iz:", [(i.get("adim"), i.get("sure_sn"), i.get("sonuc")) for i in m["iz"] if i.get("sonuc") or i.get("adim") == "bitti"])
print()
kat = {}
for k, c, kon in tum:
    for a, b in kon.items():
        if isinstance(b, bool): kat.setdefault(a, []).append(b)
for a, l in sorted(kat.items()):
    print(f"{a:28s} {sum(l)}/{len(l)}  %{100*sum(l)//len(l)}")
rap = [(k, c, kon) for k, c, kon in tum if k["tur"] != "rapor_degil"]
tamam = sum(1 for k, c, kon in rap if kon.get("tamamlandi"))
mutlu = sum(1 for k, c, kon in rap if kon.get("tamamlandi") and kon.get("90sn_icinde") and all(b for a, b in kon.items() if isinstance(b, bool)))
sureler = sorted(c["sure"] for k, c, kon in rap if kon.get("tamamlandi"))
print(f"\nTAMAMLANMA: {tamam}/{len(rap)}   HER SEY DOGRU VE 90 SN ICINDE: {mutlu}/{len(rap)}")
if sureler: print(f"SURE sn: ort {sum(sureler)/len(sureler):.1f}  medyan {sureler[len(sureler)//2]:.1f}  maks {sureler[-1]:.1f}")
print(f"TOPLAM MALIYET: {maliyet:.3f} USD, rapor basina {maliyet/max(1,tamam):.4f} USD")
json.dump([dict(dosya=k['dosya'], sure=c['sure'], hata=c.get('hata'), kontrol=kon) for k, c, kon in tum], open("ekspertiz-test/sonuc.json", "w"), ensure_ascii=False, indent=1)
