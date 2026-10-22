#!/usr/bin/env python3
"""Ticaretin deniz ağını, geçitleri ve limanları üretir: data/trade.json.

Kullanım (proje klasöründen):
    python -m pip install -r tools/requirements.txt     (numpy, pillow, shapely, scipy)
    python tools/ticaret_uret.py [--hata-ayikla <png yolu>]

Girdi: data/regions.json (bölgeler, kıyılar, deniz yolları) ve Natural Earth'ün kamu malı
liman verisi tools/kaynak/ne_10m_ports.geojson (indirme adresi:
https://raw.githubusercontent.com/nvkelso/natural-earth-vector/master/geojson/ne_10m_ports.geojson).

Yöntem:
1. Deniz havzaları: bölge çokgenlerinden kara maskesi çizilir, geçitlerin kesit çizgileri de
   kara sayılır; her havzanın tohum noktalarından deniz üzerinde yayılarak (en yakın tohum,
   su yolu uzaklığıyla) her deniz pikseli bir havzaya ayrılır.
2. Her kıyı bölgesinin kıyı çizgisi boyunca hemen açıktaki suyun havzası okunur: bölgenin
   havzaları.
3. Deniz kenarları: iki kıyı bölgesi arasındaki deniz yolları ve kıyıdaki kara komşulukları,
   ortak havzada ya da "serbest" komşu iki havza arasında. Bir geçidin kesit çizgisini kesen
   kenar o geçide bağlanır. Geçitle bağlanmayan iki havza arasındaki kenar atılır (geçidi
   atlayan bağlantı kalmasın).
4. Geçitler: kesit çizgisine yakın kıyı bölgeleri kontrol eder; kontrol eden bölge geçidin iki
   havzasına da değiyorsa içinden geçiş (bölge içinde havza değiştirme) o geçide bağlıdır.
   Süveyş ve Panama kanalları ayrıca iki ucu arasında deniz bağlantısı olarak eklenir.
5. Limanlar: büyük limanı (scalerank 3) olan kıyı bölgesi 3, (scalerank 4) olan 2 ile, diğer
   kıyı başkentleri 1 ile başlar; geri kalan kıyı bölgeleri 0.

Doğrulama: her geçidin en az bir kontrol bölgesi ve en az bir kenarı/içinden geçişi olmalı,
her kıyı bölgesinin en az bir havzası olmalı. Hata varsa dosya yazılmaz.
"""

import json
import math
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw
from shapely.geometry import LineString, Point, Polygon

KOK = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(KOK / "tools"))
import dunya_donustur as donustur  # noqa: E402

BOLGELER = KOK / "data" / "regions.json"
LIMANLAR = KOK / "tools" / "kaynak" / "ne_10m_ports.geojson"
CIKTI = KOK / "data" / "trade.json"

# Havza etiketleme ızgarası: haritanın yarı çözünürlüğü (bir piksel iki harita birimi).
OLCEK = 0.5
GENISLIK = int(donustur.HARITA_GENISLIGI * OLCEK)
YUKSEKLIK = int(donustur.HARITA_YUKSEKLIGI * OLCEK)

HAVZALAR = ["Atlantik", "Karayip", "Pasifik", "Hint", "Andaman", "Güney Çin", "Akdeniz",
            "Karadeniz", "Kızıldeniz", "Basra", "Baltık", "Hazar"]
# Geçit olmadan birbirine açılan havzalar (açık okyanus).
SERBEST = [("Atlantik", "Pasifik"), ("Atlantik", "Hint"), ("Hint", "Pasifik"), ("Atlantik", "Karayip"),
           ("Hint", "Andaman"), ("Hint", "Güney Çin"), ("Pasifik", "Güney Çin")]
# Havza tohumları: (havza, enlem, boylam).
TOHUMLAR = [
    ("Atlantik", 40.0, -40.0), ("Atlantik", -25.0, -20.0), ("Atlantik", 60.0, -30.0), ("Atlantik", 75.0, 10.0),
    ("Atlantik", 56.0, 3.0), ("Atlantik", 60.0, -85.0), ("Atlantik", 76.0, 70.0),
    ("Karayip", 15.0, -75.0), ("Karayip", 25.0, -90.0),
    ("Pasifik", 30.0, -150.0), ("Pasifik", -25.0, -120.0), ("Pasifik", 25.0, 140.0), ("Pasifik", 70.0, -170.0),
    ("Pasifik", 10.0, -95.0), ("Pasifik", -30.0, 165.0), ("Pasifik", 74.0, 140.0),
    ("Hint", -20.0, 75.0), ("Hint", 15.0, 65.0), ("Hint", 15.0, 88.0), ("Hint", -40.0, 120.0),
    ("Andaman", 10.0, 96.0), ("Andaman", 5.0, 97.5),
    ("Güney Çin", 12.0, 113.0), ("Güney Çin", -5.0, 110.0),
    ("Akdeniz", 35.0, 18.0), ("Akdeniz", 38.5, 25.0), ("Akdeniz", 40.7, 28.0), ("Akdeniz", 39.0, 5.0),
    ("Karadeniz", 43.0, 34.0), ("Karadeniz", 46.0, 36.5),
    ("Kızıldeniz", 20.0, 38.5), ("Kızıldeniz", 28.0, 33.5), ("Kızıldeniz", 28.5, 34.7),
    ("Basra", 27.0, 51.0),
    ("Baltık", 58.0, 20.0), ("Baltık", 61.0, 19.5), ("Baltık", 65.0, 23.0), ("Baltık", 59.8, 25.0),
    ("Baltık", 57.0, 11.5), ("Baltık", 54.5, 12.0),
    ("Hazar", 42.0, 51.0),
]
# Geçitler. "kesit": (enlem, boylam) noktaları; aralarındaki çizgi havzaları ayırır ve kontrol
# eden bölgeler buna yakın olanlardır. "kanal": iki ucu deniz bağlantısıyla birleştirilir.
GECITLER = [
    {"id": "istanbul", "ad": "İstanbul Boğazı", "havzalar": ["Karadeniz", "Akdeniz"],
     "kesit": [(41.25, 28.85), (41.0, 29.25)]},
    {"id": "suveys", "ad": "Süveyş Kanalı", "havzalar": ["Akdeniz", "Kızıldeniz"],
     "kesit": [(31.3, 32.3), (29.9, 32.55)], "kanal": [(31.26, 32.30), (29.95, 32.55)]},
    {"id": "panama", "ad": "Panama Kanalı", "havzalar": ["Karayip", "Pasifik"],
     "kesit": [(9.4, -79.9), (8.9, -79.5)], "kanal": [(9.36, -79.90), (8.95, -79.55)]},
    {"id": "cebelitarik", "ad": "Cebelitarık", "havzalar": ["Akdeniz", "Atlantik"],
     "kesit": [(36.15, -5.6), (35.75, -5.6)]},
    {"id": "hurmuz", "ad": "Hürmüz Boğazı", "havzalar": ["Basra", "Hint"],
     "kesit": [(27.0, 56.3), (26.1, 56.5)]},
    {"id": "babulmendep", "ad": "Babülmendep", "havzalar": ["Kızıldeniz", "Hint"],
     "kesit": [(12.9, 43.1), (12.4, 43.5)]},
    {"id": "malakka", "ad": "Malakka Boğazı", "havzalar": ["Andaman", "Güney Çin"],
     "kesit": [(2.9, 100.6), (1.7, 101.6), (1.25, 103.6), (1.0, 104.5)]},
    {"id": "danimarka", "ad": "Danimarka boğazları", "havzalar": ["Baltık", "Atlantik"],
     "kesit": [(57.75, 10.6), (57.9, 11.6)]},
]
# Bu enlemin kuzeyindeki kıyı bölgelerinin denizi buzlu sayılır (rotalar oradan pahalı geçer;
# Kuzey Buz Denizi yolu Süveyş'in yerini tutmasın).
BUZ_ENLEMI = 66.0
# Bir kıyı bölgesi, kesit çizgisine en çok bu kadar (harita birimi) yakınsa geçidi kontrol eder.
KONTROL_UZAKLIGI = 8.0


def izgaraya(boylam, enlem):
    x, y = donustur.duzleme_cevir(boylam, enlem)
    return x * OLCEK, y * OLCEK


def bolgeleri_oku():
    with open(BOLGELER, encoding="utf-8") as dosya:
        return json.load(dosya)


def kara_maskesi(bolgeler):
    maske = Image.new("L", (GENISLIK, YUKSEKLIK), 0)
    kalem = ImageDraw.Draw(maske)
    for bolge in bolgeler:
        for cokgen in bolge["cokgenler"]:
            kalem.polygon([(x * OLCEK, y * OLCEK) for x, y in cokgen], fill=255)
    for gecit in GECITLER:
        noktalar = [izgaraya(b, e) for e, b in gecit["kesit"]]
        kalem.line(noktalar, fill=255, width=3)
    return np.asarray(maske) > 127


def havzalari_etiketle(kara):
    """Her deniz pikseline tohumlardan su yolu uzaklığıyla en yakın havzanın sırası (1'den
    başlar). Hiçbir tohuma bağlanmayan su, en yakın etiketli suyun havzasını alır."""
    etiket = np.zeros(kara.shape, dtype=np.int16)
    su = ~kara
    for havza, enlem, boylam in TOHUMLAR:
        x, y = izgaraya(boylam, enlem)
        xi, yi = int(x), int(y)
        if not su[yi, xi]:
            # Tohum karaya düştüyse en yakın suya kaydır.
            ys, xs = np.nonzero(su[max(0, yi - 20):yi + 21, max(0, xi - 20):xi + 21])
            if len(ys) == 0:
                raise SystemExit("Tohum karada ve yakında su yok: %s (%.1f, %.1f)" % (havza, enlem, boylam))
            k = np.argmin((ys - 20) ** 2 + (xs - 20) ** 2)
            yi, xi = max(0, yi - 20) + ys[k], max(0, xi - 20) + xs[k]
        etiket[yi, xi] = HAVZALAR.index(havza) + 1
    while True:
        bos = (etiket == 0) & su
        if not bos.any():
            break
        degisti = False
        for kayma in [(0, 1), (0, -1), (1, 0), (-1, 0)]:
            # Yatayda harita sarmalanır (tarih çizgisi); dikeyde sarmalanmaz.
            komsu = np.roll(etiket, kayma, axis=(0, 1))
            if kayma[0] == 1:
                komsu[0, :] = 0
            elif kayma[0] == -1:
                komsu[-1, :] = 0
            yeni = bos & (komsu > 0)
            if yeni.any():
                etiket[yeni] = komsu[yeni]
                bos = bos & ~yeni
                degisti = True
        if not degisti:
            break
    kalan = (etiket == 0) & su
    if kalan.any():
        from scipy.ndimage import distance_transform_edt
        _, (iy, ix) = distance_transform_edt(etiket == 0, return_indices=True)
        etiket[kalan] = etiket[iy[kalan], ix[kalan]]
    return etiket


def hata_ayiklama_gorseli(etiket, yol):
    renkler = np.array([[20, 20, 20]] + [[(37 * i) % 255, (91 * i) % 255, (151 * i) % 255] for i in range(1, len(HAVZALAR) + 1)],
                       dtype=np.uint8)
    Image.fromarray(renkler[etiket]).save(yol)


def su_etiketi(etiket, x, y, yaricap=4):
    """Harita birimindeki noktanın çevresindeki (ızgara pikseli cinsinden yarıçapta) en yakın
    deniz pikselinin havzası; çevrede su yoksa None."""
    gx, gy = int(x * OLCEK), int(y * OLCEK)
    en_iyi = None
    en_iyi_uzaklik = 10 ** 9
    for dy in range(-yaricap, yaricap + 1):
        for dx in range(-yaricap, yaricap + 1):
            px, py = (gx + dx) % GENISLIK, gy + dy
            if 0 <= py < YUKSEKLIK and etiket[py, px] > 0:
                u = dx * dx + dy * dy
                if u < en_iyi_uzaklik:
                    en_iyi_uzaklik = u
                    en_iyi = HAVZALAR[etiket[py, px] - 1]
    return en_iyi


def bolge_havzalari(veri, etiket):
    """Kıyı bölgesi -> değdiği havzalar. Kıyı çizgisi boyunca her ~2 birimde bir, hemen açıktaki
    suyun havzası sayılır; örneklerin %5'inden azını (ve 8'den azını) tutan havza gürültüdür."""
    sayilar = {}
    for sinir in veri["sinirlar"]:
        if sinir.get("b", "") != "":
            continue
        noktalar = sinir["noktalar"]
        for i in range(len(noktalar) - 1):
            ax, ay = noktalar[i]
            bx, by = noktalar[i + 1]
            uzunluk = math.hypot(bx - ax, by - ay)
            adim = max(1, int(uzunluk / 2.0))
            for k in range(adim):
                t = (k + 0.5) / adim
                havza = su_etiketi(etiket, ax + (bx - ax) * t, ay + (by - ay) * t)
                if havza is not None:
                    sayac = sayilar.setdefault(sinir["a"], {})
                    sayac[havza] = sayac.get(havza, 0) + 1
    sonuc = {}
    for bolge_id, sayac in sayilar.items():
        toplam = sum(sayac.values())
        sonuc[bolge_id] = sorted(h for h, n in sayac.items() if n >= 0.05 * toplam or n >= 8)
    return sonuc


def gecit_cizgisi(gecit):
    return LineString([donustur.duzleme_cevir(b, e) for e, b in gecit["kesit"]])


def serbest_mi(a, b):
    return a == b or (a, b) in SERBEST or (b, a) in SERBEST


def kenarlari_kur(veri, havzalar, etiket, cizgiler):
    """Deniz kenarları: [x, havza_x, y, havza_y, geçit] (geçit yoksa ""). Geçidi atladığı için
    atılan kenarları da döndürür."""
    bolgeler = {b["id"]: b for b in veri["bolgeler"]}
    kenarlar = {}
    atilan = []

    def ekle(x, hx, y, hy, gecit):
        anahtar = tuple(sorted([(x, hx), (y, hy)])) + (gecit,)
        kenarlar[anahtar] = [x, hx, y, hy, gecit]

    def kesilen_gecit(x, y):
        cizgi = LineString([bolgeler[x]["etiket"], bolgeler[y]["etiket"]])
        for gecit_id, kesit in cizgiler.items():
            if cizgi.intersects(kesit):
                return gecit_id
        return ""

    gecit_havzalari = {g["id"]: set(g["havzalar"]) for g in GECITLER}
    for b in veri["bolgeler"]:
        x = b["id"]
        if x not in havzalar:
            continue
        # Deniz yolları.
        for y in b["deniz_gecisleri"]:
            if y not in havzalar or y < x:
                continue
            gecit = kesilen_gecit(x, y)
            ortak = sorted(set(havzalar[x]) & set(havzalar[y]))
            ex, ey = bolgeler[x]["etiket"], bolgeler[y]["etiket"]
            if ortak and not gecit:
                orta = su_etiketi(etiket, (ex[0] + ey[0]) / 2, (ex[1] + ey[1]) / 2, 12)
                havza = orta if orta in ortak else ortak[0]
                ekle(x, havza, y, havza, "")
                continue
            hx = su_etiketi(etiket, ex[0] * 0.75 + ey[0] * 0.25, ex[1] * 0.75 + ey[1] * 0.25, 12)
            hy = su_etiketi(etiket, ex[0] * 0.25 + ey[0] * 0.75, ex[1] * 0.25 + ey[1] * 0.75, 12)
            if hx not in havzalar[x]:
                hx = havzalar[x][0]
            if hy not in havzalar[y]:
                hy = havzalar[y][0]
            # Kenar yalnızca geçidin iki havzasını bağlıyorsa geçitten geçer.
            if gecit and hx != hy and {hx, hy} == gecit_havzalari[gecit]:
                ekle(x, hx, y, hy, gecit)
            elif serbest_mi(hx, hy):
                ekle(x, hx, y, hy, "")
            elif ortak:
                ekle(x, ortak[0], y, ortak[0], "")
            else:
                atilan.append((x, hx, y, hy, gecit))
        # Kıyıdaki kara komşulukları: ortak havzada kıyı boyunca.
        for y in b["kara_komsulari"]:
            if y not in havzalar or y < x:
                continue
            for havza in sorted(set(havzalar[x]) & set(havzalar[y])):
                ekle(x, havza, y, havza, "")
        # Bölge içinde, geçitsiz birbirine açılan iki havza arasında geçiş (ör. Horn Burnu).
        for i, h1 in enumerate(havzalar[x]):
            for h2 in havzalar[x][i + 1:]:
                if serbest_mi(h1, h2):
                    ekle(x, h1, x, h2, "")
    return list(kenarlar.values()), atilan


def gecitleri_kur(veri, havzalar, cizgiler, kenarlar, hatalar):
    bolgeler = {b["id"]: b for b in veri["bolgeler"]}
    sekiller = {b["id"]: [Polygon(c) for c in b["cokgenler"] if len(c) >= 3] for b in veri["bolgeler"]}
    sonuc = []
    for gecit in GECITLER:
        kesit = cizgiler[gecit["id"]]
        kontrol = []
        for bolge_id in havzalar:
            if min(c.distance(kesit) for c in sekiller[bolge_id]) <= KONTROL_UZAKLIGI:
                kontrol.append(bolge_id)
        h1, h2 = gecit["havzalar"]
        # Kanal: iki ucun bölgeleri arasında deniz bağlantısı.
        if "kanal" in gecit:
            uclar = []
            for (enlem, boylam), havza in zip(gecit["kanal"], [h1, h2]):
                nokta = Point(donustur.duzleme_cevir(boylam, enlem))
                if not kontrol:
                    break
                aday = min(kontrol, key=lambda i: min(c.distance(nokta) for c in sekiller[i]))
                if havza not in havzalar[aday]:
                    havzalar[aday] = sorted(set(havzalar[aday]) | {havza})
                uclar.append((aday, havza))
            if len(uclar) == 2:
                kenarlar.append([uclar[0][0], uclar[0][1], uclar[1][0], uclar[1][1], gecit["id"]])
        # Kontrol eden bölge iki havzaya da değiyorsa içinden geçiş.
        for bolge_id in kontrol:
            if h1 in havzalar[bolge_id] and h2 in havzalar[bolge_id]:
                kenarlar.append([bolge_id, h1, bolge_id, h2, gecit["id"]])
        gecis_sayisi = sum(1 for k in kenarlar if k[4] == gecit["id"])
        if not kontrol:
            hatalar.append("%s: kontrol eden bölge yok" % gecit["ad"])
        if gecis_sayisi == 0:
            hatalar.append("%s: hiçbir deniz kenarı ya da içinden geçiş yok" % gecit["ad"])
        merkez = kesit.interpolate(0.5, normalized=True)
        sonuc.append({"id": gecit["id"], "ad": gecit["ad"], "havzalar": gecit["havzalar"], "kontrol": sorted(kontrol),
                      "merkez": [round(merkez.x, 2), round(merkez.y, 2)],
                      "kesit": [[round(x, 2), round(y, 2)] for x, y in kesit.coords]})
        print("  %-20s kontrol: %s | kenar: %d" % (gecit["ad"], ", ".join(
            "%s(%s)" % (bolgeler[b]["ad"], b) for b in sorted(kontrol)), gecis_sayisi))
    return sonuc


def limanlari_kur(veri, havzalar):
    with open(LIMANLAR, encoding="utf-8") as dosya:
        ozellikler = json.load(dosya)["features"]
    sekiller = {b["id"]: [Polygon(c) for c in b["cokgenler"] if len(c) >= 3]
                for b in veri["bolgeler"] if b["id"] in havzalar}
    seviyeler = {}
    adlar = {}
    for oz in ozellikler:
        derece = oz["properties"].get("scalerank", 9)
        if derece > 4:
            continue
        boylam, enlem = oz["geometry"]["coordinates"][:2]
        nokta = Point(donustur.duzleme_cevir(boylam, enlem))
        en_iyi, en_iyi_uzaklik = None, 25.0
        for bolge_id, cokgenler in sekiller.items():
            uzaklik = min(c.distance(nokta) for c in cokgenler)
            if uzaklik < en_iyi_uzaklik:
                en_iyi, en_iyi_uzaklik = bolge_id, uzaklik
        if en_iyi is None:
            continue
        seviye = 3 if derece <= 3 else 2
        if seviye > seviyeler.get(en_iyi, 0):
            seviyeler[en_iyi] = seviye
            adlar[en_iyi] = oz["properties"].get("name", "")
    for b in veri["bolgeler"]:
        if b.get("baskent") and b["id"] in havzalar and b["id"] not in seviyeler:
            seviyeler[b["id"]] = 1
    return dict(sorted(seviyeler.items())), dict(sorted(adlar.items()))


def main():
    veri = bolgeleri_oku()
    bolgeler = veri["bolgeler"]
    kara = kara_maskesi(bolgeler)
    etiket = havzalari_etiketle(kara)
    if "--hata-ayikla" in sys.argv:
        hata_ayiklama_gorseli(etiket, sys.argv[sys.argv.index("--hata-ayikla") + 1])
        print("hata ayıklama görseli yazıldı")
    hatalar = []
    havzalar = bolge_havzalari(veri, etiket)
    for b in bolgeler:
        if b.get("kiyi") and b["id"] not in havzalar:
            hatalar.append("%s (%s): kıyı bölgesi ama havzası bulunamadı" % (b["ad"], b["id"]))
    cizgiler = {g["id"]: gecit_cizgisi(g) for g in GECITLER}
    kenarlar, atilan = kenarlari_kur(veri, havzalar, etiket, cizgiler)
    print("Geçitler:")
    gecitler = gecitleri_kur(veri, havzalar, cizgiler, kenarlar, hatalar)
    limanlar, liman_adlari = limanlari_kur(veri, havzalar)
    if hatalar:
        for hata in hatalar:
            print("HATA:", hata)
        sys.exit("Doğrulama geçmedi; dosya yazılmadı.")
    buz_y = donustur.duzleme_cevir(0.0, BUZ_ENLEMI)[1]
    buzlu = sorted(b["id"] for b in bolgeler if b["id"] in havzalar and b["etiket"][1] < buz_y)
    cikti = {
        "not": "Üretici: tools/ticaret_uret.py. Havzalar tohumlardan su yoluyla etiketlendi; "
               "limanlar Natural Earth ne_10m_ports (kamu malı).",
        "havzalar": HAVZALAR,
        "serbest": [list(c) for c in SERBEST],
        "bolge_havzalari": dict(sorted(havzalar.items())),
        "deniz_kenarlari": sorted(kenarlar),
        "gecitler": gecitler,
        "buzlu_bolgeler": buzlu,
        "limanlar": limanlar,
        "liman_adlari": liman_adlari,
    }
    with open(CIKTI, "w", encoding="utf-8") as dosya:
        json.dump(cikti, dosya, ensure_ascii=False, separators=(",", ":"))
        dosya.write("\n")
    seviye_sayilari = {s: sum(1 for v in limanlar.values() if v == s) for s in (1, 2, 3)}
    print("Yazıldı: %s — %d kıyı bölgesi, %d deniz kenarı (%d geçitli), geçidi atladığı için atılan %d; "
          "limanlar 1/2/3: %s" % (CIKTI.relative_to(KOK), len(havzalar), len(kenarlar),
                                   sum(1 for k in kenarlar if k[4]), len(atilan), seviye_sayilari))
    for a in atilan[:15]:
        print("  atılan:", a)


if __name__ == "__main__":
    main()
