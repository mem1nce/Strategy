#!/usr/bin/env python3
"""Natural Earth verisini oyunun okuduğu data/world.json ve data/regions.json dosyalarına çevirir.

Kullanım (proje klasöründen):
    python -m pip install -r tools/requirements.txt     (yalnızca ilk seferde)
    python tools/dunya_donustur.py

Yaptıkları:
  1. Ülke çokgenlerini okur, Miller projeksiyonuyla düzleme çevirir, temizler.
  2. Şehirleri okur; her ülke için başkenti ve ülkeye yayılmış büyük şehirleri tohum seçer.
  3. Ülke çokgenlerini "en yakın tohum" kuralıyla (Voronoi) bölgelere ayırır.
  4. Bölgelerin kara komşularını, deniz yollarını, nüfusunu ve sınır çizgilerini çıkarır;
     dünyanın kara ve deniz yollarıyla tek parça olduğundan emin olur.
  5. Sonucu doğrular; hata varsa dosya yazmaz.

Kaynak dosyalar daha ayrıntılılarıyla değiştirilebilir; aynı alan adlarını taşıdıkları
sürece bu betik değişmeden çalışır. Oyun bu betiği çalıştırmaz, yalnızca ürettiği
dosyaları okur.
"""

import json
import math
import sys
from pathlib import Path

try:
    import shapely
    from shapely.geometry import LineString, MultiPoint, Point, Polygon
    from shapely.ops import nearest_points, polylabel, voronoi_diagram
    from shapely.strtree import STRtree
except ImportError:
    sys.exit("Bu betik shapely kütüphanesini kullanır. Kurmak için:\n"
             "    python -m pip install -r tools/requirements.txt")

KOK = Path(__file__).resolve().parent.parent
ULKE_KAYNAGI = KOK / "tools" / "kaynak" / "ne_110m_admin_0_countries.geojson"
SEHIR_KAYNAGI = KOK / "tools" / "kaynak" / "ne_10m_populated_places.geojson"
# Bölge sayısı formülünün ve tohum seçiminin ayarları (elle değiştirilebilir).
AYAR_DOSYASI = KOK / "tools" / "bolge_ayarlari.json"
DUNYA_CIKTISI = KOK / "data" / "world.json"
BOLGE_CIKTISI = KOK / "data" / "regions.json"

# --- Harita -----------------------------------------------------------------
# Haritanın birim cinsinden genişliği (-180° ile +180° arası).
HARITA_GENISLIGI = 4096.0
# Haritanın kuzey ve güney kenarı (enlem). Antarktika çıkarıldığı için güney kırpılır.
KUZEY_SINIRI = 84.5
GUNEY_SINIRI = -58.0
# Haritaya alınmayan ülkeler (ADM0_A3).
CIKARILANLAR = {"ATA"}
# Bütün köşeler bu ızgaraya yuvarlanır; komşu çokgenler böylece aynı noktaları paylaşır.
IZGARA = 0.01
ONDALIK = 2
# Bundan küçük alanlı ülke çokgenleri (harita birimi kare) atılır.
ASGARI_ALAN = 0.02
RENK_SAYISI = 9
# Sınırın bir noktaya gidip neredeyse aynı çizgiden geri döndüğü "sivri uçlar" atılır.
# İki kenar arasındaki açının sinüsü bundan küçükse uç sivri sayılır (yaklaşık 1 derece).
SIVRI_UC_ESIGI = 0.02

# --- Bölgeler ---------------------------------------------------------------
# Bölge sayısı formülü ve tohum seçimi ayarları tools/bolge_ayarlari.json dosyasındadır.
with open(AYAR_DOSYASI, encoding="utf-8") as _dosya:
    AYARLAR = json.load(_dosya)
# Tohum aralığı gevşetilirken inilebilecek en düşük oran (aralik_orani'nın katı).
ARALIK_GEVSEME_SINIRI = 0.3
# Gerçek yüzölçümü hesabı için Dünya'nın yarıçapı (km).
DUNYA_YARICAPI_KM = 6371.0
# Kaba kıyı çizgisi yüzünden ülke çokgeninin dışına düşen şehir, çokgene en çok
# bu kadar uzaksa yine o ülkenin şehri sayılır (harita birimi).
KIYI_PAYI = 4.0
# Bölgenin ana gövdesinden kopuk, bundan küçük parçalar komşu bölgeye katılır (birim kare).
KIRPINTI_ALANI = 4.0
# İki kıyı bölgesi arasındaki çizgi bundan kısaysa (ve karadan geçmiyorsa) deniz yoludur.
DENIZ_YOLU_AZAMI_UZAKLIK = 220.0
# Bir kıyı bölgesi için tutulan en yakın deniz yolu sayısı (karşı taraf için de geçerlidir).
DENIZ_YOLU_AZAMI_SAYI = 3
# Şehir verisindeki ülke kodu ülke verisindekinden farklıysa buradan çevrilir.
ULKE_KODU_ESLEMESI = {"SSD": "SDS"}
ATLANAN_SEHIR_SINIFLARI = {"Scientific station", "Historic place", "Meteorological Station"}

KITALAR = {
    "Africa": "Afrika",
    "Asia": "Asya",
    "Europe": "Avrupa",
    "North America": "Kuzey Amerika",
    "South America": "Güney Amerika",
    "Oceania": "Okyanusya",
    "Antarctica": "Antarktika",
    "Seven seas (open ocean)": "Açık deniz adaları",
}


class DogrulamaHatasi(Exception):
    """Üretilen veri tutarsız olduğunda fırlatılır; dosyalar yazılmaz."""


# =============================================================================
# Projeksiyon ve küçük yardımcılar
# =============================================================================

def miller_y(enlem):
    """Miller silindirik projeksiyonunda enlemin dikey karşılığı (radyan cinsinden)."""
    return 1.25 * math.log(math.tan(math.pi / 4.0 + 0.4 * math.radians(enlem)))


OLCEK = HARITA_GENISLIGI / (2.0 * math.pi)
UST_Y = miller_y(KUZEY_SINIRI)
HARITA_YUKSEKLIGI = round((UST_Y - miller_y(GUNEY_SINIRI)) * OLCEK)


def duzleme_cevir(boylam, enlem):
    """Boylam ve enlemi harita birimine çevirir. Sol üst köşe (0, 0)'dır."""
    enlem = max(GUNEY_SINIRI, min(KUZEY_SINIRI, enlem))
    x = (boylam + 180.0) / 360.0 * HARITA_GENISLIGI
    y = (UST_Y - miller_y(enlem)) * OLCEK
    return (round(x, ONDALIK), round(y, ONDALIK))


def ozellik(ozellikler, *adlar):
    """Verilen adlardan ilk bulunanın değerini döndürür (büyük/küçük harfe bakmaz)."""
    kucuk = {anahtar.lower(): deger for anahtar, deger in ozellikler.items()}
    for ad in adlar:
        deger = kucuk.get(ad.lower())
        if deger is not None and deger != "":
            return deger
    return None


def yuvarla(nokta):
    return (round(nokta[0], ONDALIK), round(nokta[1], ONDALIK))


def uzaklik(a, b):
    return math.hypot(a[0] - b[0], a[1] - b[1])


def halka_noktalari(halka):
    """Shapely halkasının noktalarını yuvarlanmış olarak, kapanış noktası olmadan verir."""
    noktalar = [yuvarla(p) for p in halka.coords]
    if len(noktalar) > 1 and noktalar[0] == noktalar[-1]:
        noktalar.pop()
    return noktalar


def kenar_anahtari(p, q):
    return (p, q) if p <= q else (q, p)


# =============================================================================
# 1. Ülkeler
# =============================================================================

def halkalar(geometri):
    """Geometrideki her çokgeni halka listesi olarak verir: ilk halka dış sınır, kalanı delik."""
    if geometri["type"] == "Polygon":
        return [geometri["coordinates"]]
    if geometri["type"] == "MultiPolygon":
        return geometri["coordinates"]
    raise ValueError("Desteklenmeyen geometri türü: %s" % geometri["type"])


def alan(noktalar):
    toplam = 0.0
    for i, (x1, y1) in enumerate(noktalar):
        x2, y2 = noktalar[(i + 1) % len(noktalar)]
        toplam += x1 * y2 - x2 * y1
    return abs(toplam) / 2.0


def gercek_alan_km2(dis_halka):
    """Halkanın gerçek yüzölçümü (km²): eşit alanlı silindirik izdüşümde (x = boylam, y = sin enlem)."""
    noktalar = [(math.radians(b), math.sin(math.radians(e))) for b, e in (n[:2] for n in dis_halka)]
    return alan(noktalar) * DUNYA_YARICAPI_KM ** 2


def cokgene_cevir(dis_halka):
    """Dış halkayı düzleme çevirir, art arda tekrar eden noktaları ve kapanış noktasını atar."""
    noktalar = []
    for boylam, enlem in (nokta[:2] for nokta in dis_halka):
        p = duzleme_cevir(boylam, enlem)
        if not noktalar or noktalar[-1] != p:
            noktalar.append(p)
    while len(noktalar) > 1 and noktalar[0] == noktalar[-1]:
        noktalar.pop()
    return sivri_uclari_at(noktalar)


def sivri_uclari_at(noktalar):
    """Alanı olmayan sivri uçları atar.

    Kaynak veride sınır bazen bir noktaya gidip aynı çizgiden geri döner (ör. Sudan'ın
    Etiyopya ile Güney Sudan arasındaki ucu). Böyle bir çokgen kendini keser ve
    üçgenlere bölünemez. Ucun tepe noktası atılınca çokgen düzelir, alanı değişmez.
    """
    noktalar = list(noktalar)
    degisti = True
    while degisti and len(noktalar) > 3:
        degisti = False
        for i in range(len(noktalar)):
            ax, ay = noktalar[i - 1]
            bx, by = noktalar[i]
            cx, cy = noktalar[(i + 1) % len(noktalar)]
            v1x, v1y, v2x, v2y = ax - bx, ay - by, cx - bx, cy - by
            boy = math.hypot(v1x, v1y) * math.hypot(v2x, v2y)
            ic_carpim = v1x * v2x + v1y * v2y
            dis_carpim = v1x * v2y - v1y * v2x
            if boy > 0.0 and ic_carpim > 0.0 and abs(dis_carpim) <= SIVRI_UC_ESIGI * boy:
                del noktalar[i]
                degisti = True
                break
    return noktalar


def ulkeleri_oku(kaynak_yolu):
    """Ülke kayıtlarını okur. Dönen sözlükte her ülkenin 'cokgenler' listesi vardır."""
    with open(kaynak_yolu, encoding="utf-8") as dosya:
        kaynak = json.load(dosya)

    ulkeler = {}
    # Sınır noktası -> o noktayı kullanan ülkeler. Ülke komşuluğu buradan çıkar.
    nokta_sahipleri = {}

    for kayit in kaynak["features"]:
        o = kayit["properties"]
        ulke_id = ozellik(o, "ADM0_A3")
        if ulke_id is None:
            raise ValueError("ADM0_A3 alanı olmayan bir kayıt var.")
        if ulke_id in CIKARILANLAR:
            continue
        if ulke_id in ulkeler:
            raise ValueError("Aynı id iki kez geçiyor: %s" % ulke_id)

        cokgenler = []
        gercek_alan = 0.0
        for cokgen_halkalari in halkalar(kayit["geometry"]):
            # Komşuluk için delikler de sayılır: Güney Afrika, Lesotho'ya deliğinden komşudur.
            for halka in cokgen_halkalari:
                for nokta in halka:
                    anahtar = (round(nokta[0], 6), round(nokta[1], 6))
                    nokta_sahipleri.setdefault(anahtar, set()).add(ulke_id)
            noktalar = cokgene_cevir(cokgen_halkalari[0])
            if len(noktalar) < 3 or alan(noktalar) < ASGARI_ALAN:
                continue
            cokgenler.append(noktalar)
            gercek_alan += gercek_alan_km2(cokgen_halkalari[0])
        if not cokgenler:
            print("  uyarı: %s için çizilecek çokgen kalmadı, ülke atlandı." % ulke_id)
            continue
        # Büyük parça başta dursun (anakara önce, adalar sonra).
        cokgenler.sort(key=alan, reverse=True)

        etiket_x = ozellik(o, "LABEL_X")
        etiket_y = ozellik(o, "LABEL_Y")
        if etiket_x is None or etiket_y is None:
            etiket = yuvarla(Polygon(cokgenler[0]).representative_point().coords[0])
        else:
            etiket = duzleme_cevir(float(etiket_x), float(etiket_y))

        kita = ozellik(o, "CONTINENT") or ""
        ulkeler[ulke_id] = {
            "id": ulke_id,
            "ad": ozellik(o, "NAME_TR", "NAME") or ulke_id,
            "kita": KITALAR.get(kita, kita),
            "nufus": int(ozellik(o, "POP_EST") or 0),
            "gsyh_milyon_dolar": int(ozellik(o, "GDP_MD", "GDP_MD_EST") or 0),
            "renk": int(ozellik(o, "MAPCOLOR9") or 1),
            "etiket": list(etiket),
            "komsular": [],
            "cokgenler": cokgenler,
            "_alan_km2": gercek_alan,
        }

    # Ülke komşuluğu: ortak sınır noktası paylaşan ülkeler komşudur.
    komsular = {ulke_id: set() for ulke_id in ulkeler}
    for sahipler in nokta_sahipleri.values():
        gecerli = [s for s in sahipler if s in ulkeler]
        for a in gecerli:
            for b in gecerli:
                if a != b:
                    komsular[a].add(b)
    for ulke_id, ulke in ulkeler.items():
        ulke["komsular"] = sorted(komsular[ulke_id])

    # Renk: komşu iki ülke aynı rengi taşıyorsa birini değiştir.
    for ulke_id in sorted(ulkeler):
        ulke = ulkeler[ulke_id]
        ulke["renk"] = (ulke["renk"] - 1) % RENK_SAYISI + 1
        komsu_renkleri = {ulkeler[k]["renk"] for k in ulke["komsular"]}
        if ulke["renk"] in komsu_renkleri:
            bos = [r for r in range(1, RENK_SAYISI + 1) if r not in komsu_renkleri]
            if bos:
                ulke["renk"] = bos[0]
    return ulkeler


# =============================================================================
# 2. Şehirler ve tohum seçimi
# =============================================================================

def sehirleri_oku(kaynak_yolu):
    with open(kaynak_yolu, encoding="utf-8") as dosya:
        kaynak = json.load(dosya)
    sehirler = []
    for kayit in kaynak["features"]:
        o = kayit["properties"]
        sinif = ozellik(o, "FEATURECLA") or ""
        if sinif in ATLANAN_SEHIR_SINIFLARI:
            continue
        kod = ozellik(o, "ADM0_A3") or ""
        boylam, enlem = kayit["geometry"]["coordinates"][:2]
        sehirler.append({
            "ad": ozellik(o, "NAME_TR", "NAME") or "?",
            "ulke": ULKE_KODU_ESLEMESI.get(kod, kod),
            "nufus": int(ozellik(o, "POP_MAX") or 0),
            "konum": duzleme_cevir(boylam, enlem),
            "sinif": sinif,
            "baskent_isareti": int(ozellik(o, "ADM0CAP") or 0),
            "baskent_notu": (ozellik(o, "CAPIN") or "").lower(),
        })
    return sehirler


def baskent_puani(sehir):
    """Büyük olan başkenttir. Birden çok başkenti olan ülkelerde yönetim merkezi seçilir."""
    sinif_puani = {"Admin-0 capital": 3, "Admin-0 capital alt": 2, "Admin-0 region capital": 1}
    yonetim = 1 if ("admin" in sehir["baskent_notu"] or "de facto" in sehir["baskent_notu"]) else 0
    return (sinif_puani.get(sehir["sinif"], 0), sehir["baskent_isareti"], yonetim, sehir["nufus"])


def parcalari_hazirla(ulkeler):
    """Ülke çokgenlerini shapely çokgenine çevirir.

    Başka bir ülkeyi tümüyle içine alan çokgenden o ülke oyulur (Güney Afrika'dan Lesotho).
    Her parça: ülke id'si, ülke içindeki sırası ve geometrisi.
    """
    parcalar = []
    for ulke_id in sorted(ulkeler):
        for sira, noktalar in enumerate(ulkeler[ulke_id]["cokgenler"]):
            geo = Polygon(noktalar)
            if not geo.is_valid:
                raise DogrulamaHatasi("%s ülkesinin %d. çokgeni geçersiz: %s" % (
                    ulke_id, sira + 1, shapely.is_valid_reason(geo)))
            parcalar.append({"ulke": ulke_id, "sira": sira, "geo": geo})

    agac = STRtree([p["geo"] for p in parcalar])
    for i, parca in enumerate(parcalar):
        icerilenler = []
        for j in agac.query(parca["geo"], predicate="contains"):
            if j != i and parcalar[j]["ulke"] != parca["ulke"]:
                icerilenler.append(parcalar[j]["geo"])
        if icerilenler:
            parca["geo"] = shapely.difference(parca["geo"], shapely.union_all(icerilenler), grid_size=IZGARA)
    return parcalar


def hedef_bolge_sayisi(ulke):
    """Ülkenin hedef bölge sayısı: gerçek yüzölçümü ve nüfusun kareköklerinden (bkz. bolge_ayarlari.json)."""
    a = AYARLAR["bolge_sayisi"]
    deger = (a["sabit"]
             + a["alan_katsayisi"] * math.sqrt(ulke["_alan_km2"] / a["alan_birimi_km2"])
             + a["nufus_katsayisi"] * math.sqrt(ulke["nufus"] / a["nufus_birimi"]))
    return max(a["en_az"], min(a["en_cok"], round(deger)))


def en_iyi_aday(liste, secilen, aralik):
    """Seçilmişlere en az `aralik` uzaktaki şehirlerden, uzaklık × nüfus^ağırlık puanı en yüksek olanı."""
    en_iyi = None
    en_iyi_puan = 0.0
    for sehir in liste:
        if sehir in secilen:
            continue
        en_yakin = min(uzaklik(sehir["konum"], s["konum"]) for s in secilen)
        if en_yakin < aralik:
            continue
        puan = en_yakin * max(sehir["nufus"], 1000) ** AYARLAR["tohum"]["nufus_agirligi"]
        if puan > en_iyi_puan:
            en_iyi = sehir
            en_iyi_puan = puan
    return en_iyi


def hucre_alanlari(ulke_parcalari, secilen):
    """Tohumların ülke içindeki yaklaşık Voronoi hücrelerinin alanları (tohum sırasıyla)."""
    alanlar = [0.0] * len(secilen)
    hucre_geometrileri = [None] * len(secilen)
    if len(secilen) == 1:
        return [sum(p["geo"].area for p in ulke_parcalari)], [shapely.union_all([p["geo"] for p in ulke_parcalari])]
    noktalar = [Point(t["konum"]) for t in secilen]
    ulke_geo = shapely.union_all([p["geo"] for p in ulke_parcalari])
    hucreler = shapely.get_parts(voronoi_diagram(MultiPoint(noktalar), envelope=ulke_geo.buffer(50.0).envelope))
    for hucre in hucreler:
        ic = shapely.intersection(hucre, ulke_geo)
        if ic.is_empty:
            continue
        sira = next((i for i, n in enumerate(noktalar) if hucre.covers(n)), None)
        if sira is None:
            continue
        alanlar[sira] += ic.area
        hucre_geometrileri[sira] = ic
    return alanlar, hucre_geometrileri


def pay_sinirini_uygula(ulke_parcalari, liste, secilen, harita_alani):
    """En büyük hücre ülke alanının azami_bolge_payi'nı geçtiği sürece o hücreye bir tohum ekler."""
    sinir = AYARLAR["tohum"]["azami_bolge_payi"] * harita_alani
    en_cok = AYARLAR["bolge_sayisi"]["en_cok"]
    denenen = set()
    while len(secilen) < en_cok:
        alanlar, hucre_geometrileri = hucre_alanlari(ulke_parcalari, secilen)
        buyukler = [i for i in range(len(secilen)) if alanlar[i] > sinir and i not in denenen]
        if not buyukler:
            return
        i = max(buyukler, key=lambda k: alanlar[k])
        hucre = hucre_geometrileri[i]
        # Hücrenin içindeki, tohumlara en uzak şehir (nüfusu ne olursa olsun).
        en_iyi = None
        en_iyi_uzaklik = 0.0
        for sehir in liste:
            if sehir in secilen or not hucre.covers(Point(sehir["konum"])):
                continue
            d = min(uzaklik(sehir["konum"], t["konum"]) for t in secilen)
            if d > en_iyi_uzaklik:
                en_iyi = sehir
                en_iyi_uzaklik = d
        if en_iyi is None:
            denenen.add(i)
            continue
        secilen.append(en_iyi)


def tohumlari_sec(ulkeler, parcalar, sehirler):
    """Her ülke için bölge tohumu olacak şehirleri seçer.

    Dönen sözlük: ülke id'si -> seçilen şehirler (ilk sıradaki başkenttir). Her şehrin
    'parca' alanı, ait olduğu ülke çokgeninin sırasıdır. Şehri olmayan ülkenin listesi boştur.
    Ayrıca ülkenin geçerli bütün şehirleri (nüfus dağıtımı için) döndürülür.
    """
    ulke_parcalari = {}
    for parca in parcalar:
        ulke_parcalari.setdefault(parca["ulke"], []).append(parca)

    adaylar = {ulke_id: [] for ulke_id in ulkeler}
    for sehir in sehirler:
        if sehir["ulke"] not in ulkeler:
            continue
        nokta = Point(sehir["konum"])
        # Şehir hangi çokgende? İçinde değilse, kıyıya yeterince yakınsa en yakın çokgende sayılır.
        en_iyi = None
        en_iyi_uzaklik = KIYI_PAYI
        for parca in ulke_parcalari[sehir["ulke"]]:
            d = parca["geo"].distance(nokta)
            if d < en_iyi_uzaklik or (d == 0.0 and en_iyi is None):
                en_iyi = parca
                en_iyi_uzaklik = d
            if d == 0.0:
                break
        if en_iyi is None:
            continue
        aday = dict(sehir)
        aday["parca"] = en_iyi["sira"]
        adaylar[sehir["ulke"]].append(aday)

    tohumlar = {}
    for ulke_id, ulke in ulkeler.items():
        liste = adaylar[ulke_id]
        if not liste:
            tohumlar[ulke_id] = []
            continue
        harita_alani = sum(p["geo"].area for p in ulke_parcalari[ulke_id])
        hedef = hedef_bolge_sayisi(ulke)
        ulke["_hedef"] = hedef
        baskent = max(liste, key=baskent_puani)
        secilen = [baskent]
        # Tohumlar arası en az uzaklık ülkenin büyüklüğüne göredir: küçük ülkede kısa, büyükte uzun.
        aralik = AYARLAR["tohum"]["aralik_orani"] * math.sqrt(harita_alani / hedef)
        taban = aralik * ARALIK_GEVSEME_SINIRI
        while len(secilen) < hedef:
            en_iyi = en_iyi_aday(liste, secilen, aralik)
            if en_iyi is None:
                # Yeterince uzak şehir kalmadıysa aralık gevşetilir (ama tabanın altına inilmez).
                if aralik <= taban:
                    break
                aralik = max(taban, aralik * 0.8)
                continue
            secilen.append(en_iyi)
        # Büyük ülkelerde hiçbir bölge ülke alanının azami_bolge_payi'ndan büyük kalmasın:
        # büyük kalan hücredeki, tohumlara en uzak kasaba da tohum yapılır.
        if hedef >= AYARLAR["tohum"]["pay_denetimi_asgari_bolge"]:
            pay_sinirini_uygula(ulke_parcalari[ulke_id], liste, secilen, harita_alani)
        tohumlar[ulke_id] = secilen
    return tohumlar, adaylar


# =============================================================================
# 3. Bölgelere ayırma
# =============================================================================

def bolgelere_ayir(ulkeler, parcalar, tohumlar):
    """Ülke çokgenlerini tohumlara göre böler.

    Bütün ülke sınırları ve bütün Voronoi kesim çizgileri tek bir çizgi ağında birleştirilip
    0,01'lik ızgaraya oturtulur; sonra bu ağın çevrelediği yüzler çıkarılır. Böylece komşu
    yüzler (aynı ülkede de olsa, farklı ülkelerde de olsa) sınırlarındaki noktaları birebir
    paylaşır. Dönen liste yüzlerdir: her yüzün geometrisi, ülkesi ve bölge sırası vardır.
    """
    cizgiler = []
    for parca in parcalar:
        cizgiler.append(LineString(parca["geo"].exterior.coords))
        for delik in parca["geo"].interiors:
            cizgiler.append(LineString(delik.coords))
        # Bu çokgenin içindeki tohumlar birden fazlaysa aralarındaki Voronoi kenarlarıyla kesilir.
        parca["tohumlar"] = [i for i, t in enumerate(tohumlar[parca["ulke"]]) if t["parca"] == parca["sira"]]
        if len(parca["tohumlar"]) >= 2:
            noktalar = MultiPoint([tohumlar[parca["ulke"]][i]["konum"] for i in parca["tohumlar"]])
            kenarlar = voronoi_diagram(noktalar, envelope=parca["geo"].buffer(50.0).envelope, edges=True)
            kesim = shapely.intersection(kenarlar, parca["geo"])
            if not kesim.is_empty:
                cizgiler.append(kesim)

    ag = shapely.unary_union(cizgiler, grid_size=IZGARA)
    yuz_geometrileri = shapely.get_parts(shapely.polygonize(shapely.get_parts(ag)))

    agac = STRtree([p["geo"] for p in parcalar])
    yuzler = []
    for geo in yuz_geometrileri:
        ic_nokta = geo.representative_point()
        # Yüz hangi ülke çokgeninin içinde? Hiçbirinde değilse sudur (ör. Hazar Denizi).
        sahipler = [parcalar[i] for i in agac.query(ic_nokta, predicate="intersects")]
        if not sahipler:
            continue
        parca = min(sahipler, key=lambda p: p["geo"].area)
        ulke_tohumlari = tohumlar[parca["ulke"]]
        if parca["tohumlar"]:
            # Çokgenin kendi tohumları var: en yakın tohumun bölgesi.
            bolge = min(parca["tohumlar"], key=lambda i: uzaklik(ulke_tohumlari[i]["konum"], ic_nokta.coords[0]))
        elif ulke_tohumlari:
            # Tohumu olmayan ada: bütünüyle, adaya en yakın tohumun bölgesine girer.
            bolge = min(range(len(ulke_tohumlari)), key=lambda i: parca["geo"].distance(Point(ulke_tohumlari[i]["konum"])))
        else:
            bolge = 0
        yuzler.append({"geo": geo, "ulke": parca["ulke"], "parca": parca["sira"], "bolge": bolge})
    return yuzler


def kenar_sozlugu(yuzler):
    """Her kenarı (iki nokta) onu kullanan yüzlere bağlar. Delik halkaları da sayılır."""
    kenarlar = {}
    for sira, yuz in enumerate(yuzler):
        for halka in [yuz["geo"].exterior] + list(yuz["geo"].interiors):
            noktalar = halka_noktalari(halka)
            for i in range(len(noktalar)):
                anahtar = kenar_anahtari(noktalar[i], noktalar[(i + 1) % len(noktalar)])
                kenarlar.setdefault(anahtar, []).append(sira)
    return kenarlar


def kirpintilari_kat(yuzler):
    """Bölgenin ana gövdesinden kopuk, çok küçük yüzleri sınırdaş olduğu bölgeye katar.

    Voronoi kesimi girintili kıyılarda bir bölgeden küçük parçalar koparabilir. Böyle bir
    parça aynı ülkenin başka bir bölgesine değiyorsa, en uzun sınırı paylaştığı bölgeye geçer.
    Hiçbir bölgeye değmeyen küçük adalar olduğu gibi kalır. Kaç yüzün taşındığını döndürür.
    """
    tasinan = 0
    while True:
        kenarlar = kenar_sozlugu(yuzler)
        en_buyuk = {}
        for yuz in yuzler:
            anahtar = (yuz["ulke"], yuz["bolge"])
            en_buyuk[anahtar] = max(en_buyuk.get(anahtar, 0.0), yuz["geo"].area)

        degisti = False
        for sira, yuz in enumerate(yuzler):
            if yuz["geo"].area >= KIRPINTI_ALANI or yuz["geo"].area >= en_buyuk[(yuz["ulke"], yuz["bolge"])]:
                continue
            # Bu yüzün, aynı ülkenin başka bölgeleriyle ve kendi bölgesiyle paylaştığı sınır uzunlukları.
            paylasim = {}
            for halka in [yuz["geo"].exterior] + list(yuz["geo"].interiors):
                noktalar = halka_noktalari(halka)
                for i in range(len(noktalar)):
                    p, q = noktalar[i], noktalar[(i + 1) % len(noktalar)]
                    for diger_sira in kenarlar[kenar_anahtari(p, q)]:
                        diger = yuzler[diger_sira]
                        if diger_sira != sira and diger["ulke"] == yuz["ulke"]:
                            paylasim[diger["bolge"]] = paylasim.get(diger["bolge"], 0.0) + uzaklik(p, q)
            # Kendi bölgesinin başka bir yüzüne değiyorsa kopuk değildir.
            if not paylasim or yuz["bolge"] in paylasim:
                continue
            yuz["bolge"] = max(paylasim, key=paylasim.get)
            tasinan += 1
            degisti = True
            break
        if not degisti:
            return tasinan


def kucuk_bolgeleri_kat(yuzler, tohumlar):
    """Alanı ülkesindeki ortalama bölge alanının `ortalama_orani`ndan küçük kalan, başkent
    olmayan bölgeyi, en uzun sınırı paylaştığı aynı ülkeden bölgeye katar. Katılan bölge
    sayısını döndürür. Hiçbir bölgeye değmeyen (ör. ada) küçük bölge olduğu gibi kalır."""
    oran = AYARLAR["kucuk_bolge"]["ortalama_orani"]
    katilan = 0
    while True:
        bolge_alanlari = {}
        for yuz in yuzler:
            anahtar = (yuz["ulke"], yuz["bolge"])
            bolge_alanlari[anahtar] = bolge_alanlari.get(anahtar, 0.0) + yuz["geo"].area
        ulke_toplam = {}
        ulke_sayi = {}
        for (ulke_id, _), a in bolge_alanlari.items():
            ulke_toplam[ulke_id] = ulke_toplam.get(ulke_id, 0.0) + a
            ulke_sayi[ulke_id] = ulke_sayi.get(ulke_id, 0) + 1
        adaylar = sorted(
            (a, k) for k, a in bolge_alanlari.items()
            if k[1] != 0 and ulke_sayi[k[0]] > 1 and a < oran * ulke_toplam[k[0]] / ulke_sayi[k[0]])
        if not adaylar:
            return katilan
        kenarlar = kenar_sozlugu(yuzler)
        katildi = False
        for _, (ulke_id, sira) in adaylar:
            paylasim = {}
            for yuz_sira, yuz in enumerate(yuzler):
                if yuz["ulke"] != ulke_id or yuz["bolge"] != sira:
                    continue
                for halka in [yuz["geo"].exterior] + list(yuz["geo"].interiors):
                    noktalar = halka_noktalari(halka)
                    for i in range(len(noktalar)):
                        p, q = noktalar[i], noktalar[(i + 1) % len(noktalar)]
                        for diger_sira in kenarlar[kenar_anahtari(p, q)]:
                            diger = yuzler[diger_sira]
                            if diger["ulke"] == ulke_id and diger["bolge"] != sira:
                                paylasim[diger["bolge"]] = paylasim.get(diger["bolge"], 0.0) + uzaklik(p, q)
            if not paylasim:
                continue
            hedef = max(paylasim, key=paylasim.get)
            for yuz in yuzler:
                if yuz["ulke"] == ulke_id and yuz["bolge"] == sira:
                    yuz["bolge"] = hedef
            katilan += 1
            katildi = True
            break
        if not katildi:
            return katilan


# =============================================================================
# 4. Bölge kayıtları: komşuluk, sınırlar, deniz geçişleri, nüfus
# =============================================================================

def bolgeleri_kur(ulkeler, yuzler, tohumlar, adaylar):
    """Yüzlerden bölge kayıtlarını ve sınır çizgilerini üretir."""
    # Yüzü olan (ülke, tohum sırası) çiftleri bölge olur. Boş kalan tohumlar atlanır.
    bolge_yuzleri = {}
    for yuz in yuzler:
        bolge_yuzleri.setdefault((yuz["ulke"], yuz["bolge"]), []).append(yuz)

    bolgeler = {}
    bolge_idleri = {}
    for ulke_id in sorted(ulkeler):
        ulke_tohumlari = tohumlar[ulke_id]
        siralar = sorted(sira for (u, sira) in bolge_yuzleri if u == ulke_id)
        if not siralar:
            raise DogrulamaHatasi("%s ülkesine hiç yüz düşmedi." % ulke_id)
        if ulke_tohumlari and 0 not in siralar:
            raise DogrulamaHatasi("%s ülkesinin başkent tohumuna (%s) hiç toprak düşmedi." % (
                ulke_id, ulke_tohumlari[0]["ad"]))
        for yeni_sira, sira in enumerate(siralar, start=1):
            bolge_id = "%s_%d" % (ulke_id, yeni_sira)
            bolge_idleri[(ulke_id, sira)] = bolge_id
            parca_listesi = sorted(bolge_yuzleri[(ulke_id, sira)], key=lambda y: y["geo"].area, reverse=True)
            bolgeler[bolge_id] = {
                "id": bolge_id,
                "ad": ulke_tohumlari[sira]["ad"] if ulke_tohumlari else ulkeler[ulke_id]["ad"],
                "sahip": ulke_id,
                "baskent": sira == 0,
                "nufus": 0,
                "kiyi": False,
                "etiket": None,
                "kara_komsulari": [],
                "deniz_gecisleri": [],
                "cokgenler": [halka_noktalari(y["geo"].exterior) for y in parca_listesi],
                # Aşağıdakiler yalnızca hesap içindir, dosyaya yazılmaz.
                "_geo": shapely.union_all([y["geo"] for y in parca_listesi]),
                "_alan": sum(y["geo"].area for y in parca_listesi),
                "_parcalar": {y["parca"] for y in parca_listesi},
                "_tohum": ulke_tohumlari[sira]["konum"] if ulke_tohumlari else None,
            }
            en_buyuk = parca_listesi[0]["geo"]
            bolgeler[bolge_id]["etiket"] = list(yuvarla(polylabel(en_buyuk, tolerance=0.2).coords[0]))
    for yuz in yuzler:
        yuz["bolge_id"] = bolge_idleri[(yuz["ulke"], yuz["bolge"])]

    sinirlar, paylasilan = sinirlari_cikar(yuzler)
    nokta_komsuluklari = nokta_komsuluklarini_bul(ulkeler, bolgeler, yuzler, paylasilan)
    for (a, b) in sorted(paylasilan | nokta_komsuluklari):
        bolgeler[a]["kara_komsulari"].append(b)
        bolgeler[b]["kara_komsulari"].append(a)

    kiyi_idleri = {sinir["a"] for sinir in sinirlar if sinir["b"] == ""}
    for bolge_id, bolge in bolgeler.items():
        bolge["kiyi"] = bolge_id in kiyi_idleri

    deniz_gecislerini_bul(bolgeler, kiyi_idleri)
    baglanan = dunya_baglantisini_tamamla(bolgeler, kiyi_idleri)
    for bolge in bolgeler.values():
        bolge["kara_komsulari"].sort()
        bolge["deniz_gecisleri"].sort()

    nufusu_dagit(ulkeler, bolgeler, adaylar)
    return bolgeler, sinirlar, nokta_komsuluklari, baglanan


def nokta_komsuluklarini_bul(ulkeler, bolgeler, yuzler, paylasilan):
    """Yalnızca tek noktada değen komşu ülkelerin o noktadaki bölgelerini komşu yapar.

    Bölgeler arasında tek köşede değmek komşuluk sayılmaz. Ama iki ÜLKE kaynak veride
    ortak bir sınır noktası taşıyorsa gerçekte sınırdaştır; kaba ölçek o kısa sınırı tek
    noktaya indirmiştir (ör. Türkiye ile Azerbaycan'ın Nahçıvan sınırı). Böyle çiftlerde
    o noktaya değen bölgeler kara komşusu sayılır. Eklenen bölge çiftlerini döndürür.
    """
    sinirdas_ulkeler = {kenar_anahtari(bolgeler[a]["sahip"], bolgeler[b]["sahip"]) for (a, b) in paylasilan}
    eksikler = [(u, k) for u in sorted(ulkeler) for k in ulkeler[u]["komsular"]
                if u < k and (u, k) not in sinirdas_ulkeler]
    if not eksikler:
        return set()

    kose_bolgeleri = {}
    for yuz in yuzler:
        for halka in [yuz["geo"].exterior] + list(yuz["geo"].interiors):
            for nokta in halka_noktalari(halka):
                kose_bolgeleri.setdefault(nokta, set()).add(yuz["bolge_id"])

    eklenen = set()
    for (ulke_a, ulke_b) in eksikler:
        for uyeler in kose_bolgeleri.values():
            a_bolgeleri = [b for b in uyeler if bolgeler[b]["sahip"] == ulke_a]
            b_bolgeleri = [b for b in uyeler if bolgeler[b]["sahip"] == ulke_b]
            for a in a_bolgeleri:
                for b in b_bolgeleri:
                    eklenen.add(kenar_anahtari(a, b))
    return eklenen


def sinirlari_cikar(yuzler):
    """Sınır çizgilerini ve kara komşuluklarını çıkarır.

    Her sınır, iki bölge arasındaki (ya da bölge ile deniz arasındaki) kesintisiz bir çizgidir.
    Ortak bir kenar paylaşan iki bölge kara komşusudur; yalnızca bir köşede değenler
    ortak kenar paylaşmadığı için komşu sayılmaz.
    """
    kenarlar = kenar_sozlugu(yuzler)
    sinirlar = []
    paylasilan = set()

    for sira, yuz in enumerate(yuzler):
        kendi = yuz["bolge_id"]
        for halka in [yuz["geo"].exterior] + list(yuz["geo"].interiors):
            noktalar = halka_noktalari(halka)
            adet = len(noktalar)
            # Her kenarın öbür yanındaki bölge: None = deniz, kendi id'si = bölgenin iç dikişi.
            karsi = []
            for i in range(adet):
                diger = None
                for diger_sira in kenarlar[kenar_anahtari(noktalar[i], noktalar[(i + 1) % adet])]:
                    if diger_sira != sira:
                        diger = yuzler[diger_sira]["bolge_id"]
                karsi.append(diger)

            # Komşunun değiştiği bir köşeden başla ki çizgiler ortadan bölünmesin.
            baslangic = 0
            for i in range(adet):
                if karsi[i] != karsi[i - 1]:
                    baslangic = i
                    break
            i = 0
            while i < adet:
                diger = karsi[(baslangic + i) % adet]
                parca = [noktalar[(baslangic + i) % adet]]
                while i < adet and karsi[(baslangic + i) % adet] == diger:
                    parca.append(noktalar[(baslangic + i + 1) % adet])
                    i += 1
                if diger == kendi:
                    continue
                if diger is None:
                    sinirlar.append({"a": kendi, "b": "", "noktalar": parca})
                else:
                    paylasilan.add(kenar_anahtari(kendi, diger))
                    # Ortak sınır iki bölgenin halkasında da bulunur; yalnızca birinden eklenir.
                    if kendi < diger:
                        sinirlar.append({"a": kendi, "b": diger, "noktalar": parca})
    sinirlar.sort(key=lambda s: (s["a"], s["b"], s["noktalar"][0]))
    return sinirlar, paylasilan


def _karadan_geciyor_mu(kara_agaci, p, q):
    """p-q çizgisinin ucuna yakın kısımları (bölgelerin kendi kıyısı) hariç, arada kara var mı?"""
    hat = LineString([p, q])
    ic_hat = LineString([hat.interpolate(0.05, normalized=True), hat.interpolate(0.95, normalized=True)])
    return len(kara_agaci.query(ic_hat, predicate="intersects")) > 0


def deniz_gecislerini_bul(bolgeler, kiyi_idleri):
    """Kıyı bölgeleri arasındaki deniz yollarını bulur.

    İki kıyı bölgesi arasında, aralarındaki en kısa çizgi karadan geçmiyorsa ve
    DENIZ_YOLU_AZAMI_UZAKLIK'tan kısaysa aday bir deniz yoludur. Her bölge için en yakın
    DENIZ_YOLU_AZAMI_SAYI aday tutulur; bir kenar, iki ucundan birinin en yakınları arasındaysa
    tutulur (bu yüzden bir bölgenin deniz yolu sayısı bu sayıyı geçebilir).
    """
    tum_idler = sorted(bolgeler)
    kara_agaci = STRtree([bolgeler[i]["_geo"] for i in tum_idler])

    kiyi_listesi = sorted(kiyi_idleri)
    kiyi_geo = [bolgeler[i]["_geo"] for i in kiyi_listesi]
    kiyi_agaci = STRtree(kiyi_geo)

    adaylar = {bolge_id: [] for bolge_id in kiyi_listesi}
    for sira, bolge_id in enumerate(kiyi_listesi):
        bolge = bolgeler[bolge_id]
        for diger_sira in kiyi_agaci.query(kiyi_geo[sira], predicate="dwithin", distance=DENIZ_YOLU_AZAMI_UZAKLIK):
            diger_id = kiyi_listesi[diger_sira]
            if diger_sira <= sira or diger_id in bolge["kara_komsulari"]:
                continue
            p, q = nearest_points(kiyi_geo[sira], kiyi_geo[diger_sira])
            aralik = p.distance(q)
            # Birbirine köşeden değen bölgelerin arasında su yoktur.
            if aralik < 5 * IZGARA:
                continue
            if _karadan_geciyor_mu(kara_agaci, p, q):
                continue
            adaylar[bolge_id].append((aralik, diger_id))
            adaylar[diger_id].append((aralik, bolge_id))

    eklenen = set()
    for bolge_id, liste in adaylar.items():
        liste.sort()
        for (_, diger_id) in liste[:DENIZ_YOLU_AZAMI_SAYI]:
            eklenen.add(kenar_anahtari(bolge_id, diger_id))
    for (a, b) in eklenen:
        bolgeler[a]["deniz_gecisleri"].append(b)
        bolgeler[b]["deniz_gecisleri"].append(a)


def dunya_baglantisini_tamamla(bolgeler, kiyi_idleri):
    """Kara komşuluğu ve deniz yollarıyla dünyanın tek parça olduğundan emin olur.

    DENIZ_YOLU_AZAMI_UZAKLIK içinde deniz yolu bulamayan bir ada kalırsa (ör. uzak bir
    Pasifik adası), o adanın en yakın kıyı bölgesini, erişilebilir en büyük kümenin en yakın
    kıyı bölgesine ek bir deniz yoluyla bağlar. Eklenen (a, b) çiftlerini döndürür.
    """
    def bilesenleri_bul():
        gorulen = set()
        bilesenler = []
        for baslangic in sorted(bolgeler):
            if baslangic in gorulen:
                continue
            kume = {baslangic}
            kuyruk = [baslangic]
            while kuyruk:
                su_an = kuyruk.pop()
                for komsu in bolgeler[su_an]["kara_komsulari"] + bolgeler[su_an]["deniz_gecisleri"]:
                    if komsu not in kume:
                        kume.add(komsu)
                        kuyruk.append(komsu)
            gorulen |= kume
            bilesenler.append(kume)
        return bilesenler

    eklenen = []
    while True:
        bilesenler = bilesenleri_bul()
        if len(bilesenler) <= 1:
            return eklenen
        ana = max(bilesenler, key=len)
        hedef_bilesen = min((b for b in bilesenler if b is not ana), key=len)

        ana_kiyilari = sorted(b for b in ana if b in kiyi_idleri) or sorted(ana)
        aday_kiyilari = sorted(b for b in hedef_bilesen if b in kiyi_idleri) or sorted(hedef_bilesen)
        en_iyi = min(
            ((bolgeler[a]["_geo"].distance(bolgeler[b]["_geo"]), a, b)
             for a in aday_kiyilari for b in ana_kiyilari),
            key=lambda x: x[0])
        _, a, b = en_iyi
        bolgeler[a]["deniz_gecisleri"].append(b)
        bolgeler[b]["deniz_gecisleri"].append(a)
        eklenen.append((a, b))


def nufusu_dagit(ulkeler, bolgeler, adaylar):
    """Ülke nüfusunun yarısını bölgelerin alanına, yarısını şehirlerinin nüfusuna göre dağıtır."""
    for ulke_id, ulke in ulkeler.items():
        ulke_bolgeleri = [b for b in bolgeler.values() if b["sahip"] == ulke_id]
        sehir_nufusu = {b["id"]: 0 for b in ulke_bolgeleri}
        for sehir in adaylar[ulke_id]:
            nokta = Point(sehir["konum"])
            en_yakin = min(ulke_bolgeleri, key=lambda b: b["_geo"].distance(nokta))
            sehir_nufusu[en_yakin["id"]] += sehir["nufus"]

        toplam_alan = sum(b["_alan"] for b in ulke_bolgeleri)
        toplam_sehir = sum(sehir_nufusu.values())
        paylar = {}
        for bolge in ulke_bolgeleri:
            alan_payi = bolge["_alan"] / toplam_alan
            sehir_payi = sehir_nufusu[bolge["id"]] / toplam_sehir if toplam_sehir > 0 else alan_payi
            paylar[bolge["id"]] = ulke["nufus"] * (alan_payi + sehir_payi) / 2.0

        # Tam sayıya yuvarlarken toplam, ülke nüfusuna eşit kalsın: artan kişiler
        # küsuratı en büyük bölgelere verilir.
        for bolge in ulke_bolgeleri:
            bolge["nufus"] = int(paylar[bolge["id"]])
        kalan = ulke["nufus"] - sum(b["nufus"] for b in ulke_bolgeleri)
        for bolge in sorted(ulke_bolgeleri, key=lambda b: paylar[b["id"]] - int(paylar[b["id"]]), reverse=True)[:kalan]:
            bolge["nufus"] += 1


# =============================================================================
# 5. Doğrulama
# =============================================================================

def dogrula(ulkeler, parcalar, bolgeler, tohumlar):
    """Veriyi denetler. Hataları ve uyarıları ayrı listelerde döndürür."""
    hatalar = []
    uyarilar = []

    # 1. Komşuluk simetrik olmalı.
    for bolge in bolgeler.values():
        for alan_adi in ("kara_komsulari", "deniz_gecisleri"):
            for diger in bolge[alan_adi]:
                if bolge["id"] not in bolgeler[diger][alan_adi]:
                    hatalar.append("%s -> %s (%s) tek yönlü" % (bolge["id"], diger, alan_adi))
        ortak = set(bolge["kara_komsulari"]) & set(bolge["deniz_gecisleri"])
        if ortak:
            hatalar.append("%s: hem kara komşusu hem deniz geçişi olanlar var: %s" % (bolge["id"], sorted(ortak)))

    # 2. Komşu olan her ülke çiftinde en az bir bölge çifti komşu olmalı.
    komsu_ulke_ciftleri = set()
    for bolge in bolgeler.values():
        for diger in bolge["kara_komsulari"]:
            if bolgeler[diger]["sahip"] != bolge["sahip"]:
                komsu_ulke_ciftleri.add(kenar_anahtari(bolge["sahip"], bolgeler[diger]["sahip"]))
    for ulke_id, ulke in ulkeler.items():
        for komsu in ulke["komsular"]:
            if ulke_id < komsu and (ulke_id, komsu) not in komsu_ulke_ciftleri:
                hatalar.append("%s ile %s komşu ülkeler ama hiçbir bölgeleri komşu değil" % (ulke_id, komsu))
    for (a, b) in sorted(komsu_ulke_ciftleri):
        if b not in ulkeler[a]["komsular"]:
            hatalar.append("%s ile %s bölgeleri komşu ama ülkeler komşu görünmüyor" % (a, b))

    # 3. Bölgelerin toplam alanı ülke alanından en fazla %1 sapmalı.
    for ulke_id in ulkeler:
        ulke_alani = sum(p["geo"].area for p in parcalar if p["ulke"] == ulke_id)
        bolge_alani = sum(b["_alan"] for b in bolgeler.values() if b["sahip"] == ulke_id)
        if abs(bolge_alani - ulke_alani) > 0.01 * ulke_alani:
            hatalar.append("%s: bölge alanları toplamı %.1f, ülke alanı %.1f" % (ulke_id, bolge_alani, ulke_alani))

    # 4. Aynı kara parçasındaki bölgeler komşuluk zinciriyle birbirine ulaşabilmeli.
    # Kara parçası: birbirine değen ülke çokgenlerinin oluşturduğu küme (ör. Avrasya-Afrika).
    kume = list(range(len(parcalar)))

    def kok(i):
        while kume[i] != i:
            kume[i] = kume[kume[i]]
            i = kume[i]
        return i

    agac = STRtree([p["geo"] for p in parcalar])
    for i, parca in enumerate(parcalar):
        for j in agac.query(parca["geo"], predicate="intersects"):
            kume[kok(i)] = kok(int(j))
    parca_sirasi = {(p["ulke"], p["sira"]): i for i, p in enumerate(parcalar)}
    kara_parcalari = {}
    for bolge in bolgeler.values():
        for sira in bolge["_parcalar"]:
            kara_parcalari.setdefault(kok(parca_sirasi[(bolge["sahip"], sira)]), set()).add(bolge["id"])
    for uyeler in kara_parcalari.values():
        ilk = sorted(uyeler)[0]
        gorulen = {ilk}
        kuyruk = [ilk]
        while kuyruk:
            for komsu in bolgeler[kuyruk.pop()]["kara_komsulari"]:
                if komsu in uyeler and komsu not in gorulen:
                    gorulen.add(komsu)
                    kuyruk.append(komsu)
        if gorulen != uyeler:
            hatalar.append("Aynı kara parçasında birbirine ulaşamayan bölgeler var: %s ... (ulaşılamayan %d bölge: %s)" % (
                ilk, len(uyeler - gorulen), ", ".join(sorted(uyeler - gorulen)[:8])))

    # 6. Kara komşuluğu ve deniz yollarının birleşimiyle dünyadaki her bölgeye ulaşılabilmeli.
    tum_bolge_idleri = set(bolgeler)
    baslangic = next(iter(tum_bolge_idleri))
    gorulen = {baslangic}
    kuyruk = [baslangic]
    while kuyruk:
        su_an = kuyruk.pop()
        for komsu in bolgeler[su_an]["kara_komsulari"] + bolgeler[su_an]["deniz_gecisleri"]:
            if komsu not in gorulen:
                gorulen.add(komsu)
                kuyruk.append(komsu)
    if gorulen != tum_bolge_idleri:
        kayip = tum_bolge_idleri - gorulen
        hatalar.append("Dünyada ulaşılamayan %d bölge var: %s" % (
            len(kayip), ", ".join(sorted(kayip)[:8])))

    # 5. Büyük ülkelerde bir bölgesi ülke alanının azami_bolge_payi'nı geçen ülkeler (uyarı).
    for ulke_id in sorted(ulkeler):
        ulke_bolgeleri = [b for b in bolgeler.values() if b["sahip"] == ulke_id]
        if len(ulke_bolgeleri) < AYARLAR["tohum"]["pay_denetimi_asgari_bolge"]:
            continue
        toplam = sum(b["_alan"] for b in ulke_bolgeleri)
        en_buyuk = max(ulke_bolgeleri, key=lambda b: b["_alan"])
        if en_buyuk["_alan"] > AYARLAR["tohum"]["azami_bolge_payi"] * toplam:
            uyarilar.append("%s (%s): %d bölgesi var ama '%s' bölgesi ülke alanının %%%d'i" % (
                ulkeler[ulke_id]["ad"], ulke_id, len(ulke_bolgeleri), en_buyuk["ad"],
                round(100.0 * en_buyuk["_alan"] / toplam)))

    # Ek denetimler: her ülkenin tam bir başkent bölgesi, her bölgenin çokgeni olmalı.
    for ulke_id in ulkeler:
        baskentler = [b for b in bolgeler.values() if b["sahip"] == ulke_id and b["baskent"]]
        if len(baskentler) != 1:
            hatalar.append("%s: %d başkent bölgesi var (1 olmalı)" % (ulke_id, len(baskentler)))
    for bolge in bolgeler.values():
        if not bolge["cokgenler"] or any(len(c) < 3 for c in bolge["cokgenler"]):
            hatalar.append("%s: çokgeni eksik" % bolge["id"])
        if not Polygon(bolge["cokgenler"][0]).contains(Point(bolge["etiket"])):
            hatalar.append("%s: etiket noktası en büyük çokgenin dışında" % bolge["id"])
    return hatalar, uyarilar


# =============================================================================
# 6. Dosyaya yazma
# =============================================================================

def kisa(deger):
    return json.dumps(deger, ensure_ascii=False, separators=(",", ":"))


def kayit_metni(kayit, tek_satir_listeler):
    """Bir kaydı satır satır yazar; uzun nokta listeleri (çokgenler) tek satırda kalır."""
    satirlar = []
    for anahtar, deger in kayit.items():
        if anahtar.startswith("_"):
            continue
        if anahtar in tek_satir_listeler:
            ic_satirlar = ",\n".join("\t\t\t\t" + kisa(parca) for parca in deger)
            satirlar.append('\t\t\t%s: [\n%s\n\t\t\t]' % (json.dumps(anahtar), ic_satirlar))
        else:
            satirlar.append("\t\t\t%s: %s" % (json.dumps(anahtar), json.dumps(deger, ensure_ascii=False)))
    return "\t\t{\n%s\n\t\t}" % ",\n".join(satirlar)


def dosyaya_yaz(yol, metin):
    Path(yol).parent.mkdir(parents=True, exist_ok=True)
    with open(yol, "w", encoding="utf-8", newline="\n") as dosya:
        dosya.write(metin)


def dunyayi_yaz(ulkeler, bolgeler):
    ulke_metinleri = []
    for ulke_id in sorted(ulkeler):
        ulke = ulkeler[ulke_id]
        ulke_bolgeleri = sorted((b for b in bolgeler.values() if b["sahip"] == ulke_id),
                                key=lambda b: int(b["id"].rsplit("_", 1)[1]))
        anakara = Polygon(ulke["cokgenler"][0]).bounds
        kayit = {
            "id": ulke["id"],
            "ad": ulke["ad"],
            "kita": ulke["kita"],
            "nufus": ulke["nufus"],
            "gsyh_milyon_dolar": ulke["gsyh_milyon_dolar"],
            "renk": ulke["renk"],
            "etiket": ulke["etiket"],
            # Ülkenin en büyük kara parçasını saran dikdörtgen: [x, y, genişlik, yükseklik].
            "anakara_kutusu": [round(anakara[0], ONDALIK), round(anakara[1], ONDALIK),
                               round(anakara[2] - anakara[0], ONDALIK), round(anakara[3] - anakara[1], ONDALIK)],
            "komsular": ulke["komsular"],
            "baskent_bolgesi": next(b["id"] for b in ulke_bolgeleri if b["baskent"]),
            "bolgeler": [b["id"] for b in ulke_bolgeleri],
        }
        ulke_metinleri.append(kayit_metni(kayit, ()))

    metin = "{\n"
    metin += '\t"kaynak": "Natural Earth (kamu malı) - %s",\n' % ULKE_KAYNAGI.name
    metin += '\t"projeksiyon": "miller",\n'
    metin += '\t"genislik": %d,\n' % HARITA_GENISLIGI
    metin += '\t"yukseklik": %d,\n' % HARITA_YUKSEKLIGI
    metin += '\t"ulkeler": [\n%s\n\t]\n}\n' % ",\n".join(ulke_metinleri)
    dosyaya_yaz(DUNYA_CIKTISI, metin)


def bolgeleri_yaz(bolgeler, sinirlar):
    def bolge_sirasi(bolge_id):
        ulke_id, sira = bolge_id.rsplit("_", 1)
        return (ulke_id, int(sira))

    bolge_metinleri = [kayit_metni(bolgeler[i], ("cokgenler",)) for i in sorted(bolgeler, key=bolge_sirasi)]
    sinir_metinleri = ["\t\t" + kisa(s) for s in sinirlar]

    metin = "{\n"
    metin += '\t"kaynak": "Natural Earth (kamu malı) - %s, %s",\n' % (ULKE_KAYNAGI.name, SEHIR_KAYNAGI.name)
    metin += '\t"bolgeler": [\n%s\n\t],\n' % ",\n".join(bolge_metinleri)
    metin += '\t"sinirlar": [\n%s\n\t]\n}\n' % ",\n".join(sinir_metinleri)
    dosyaya_yaz(BOLGE_CIKTISI, metin)


# =============================================================================
# Ana akış
# =============================================================================

def donustur():
    ulkeler = ulkeleri_oku(ULKE_KAYNAGI)
    sehirler = sehirleri_oku(SEHIR_KAYNAGI)
    parcalar = parcalari_hazirla(ulkeler)
    tohumlar, adaylar = tohumlari_sec(ulkeler, parcalar, sehirler)
    yuzler = bolgelere_ayir(ulkeler, parcalar, tohumlar)
    tasinan = kirpintilari_kat(yuzler)
    katilan = kucuk_bolgeleri_kat(yuzler, tohumlar)
    bolgeler, sinirlar, nokta_komsuluklari, baglanan = bolgeleri_kur(ulkeler, yuzler, tohumlar, adaylar)
    hatalar, uyarilar = dogrula(ulkeler, parcalar, bolgeler, tohumlar)

    kiyi = sum(1 for b in bolgeler.values() if b["kiyi"])
    kara = sum(len(b["kara_komsulari"]) for b in bolgeler.values()) // 2
    deniz = sum(len(b["deniz_gecisleri"]) for b in bolgeler.values()) // 2
    print("Harita : %d x %d birim (Miller, %.1f° ile %.1f° arası)" % (
        HARITA_GENISLIGI, HARITA_YUKSEKLIGI, GUNEY_SINIRI, KUZEY_SINIRI))
    print("Ülke   : %d   (şehri olmayan: %s)" % (
        len(ulkeler), ", ".join(sorted(u for u in ulkeler if not tohumlar[u])) or "yok"))
    print("Bölge  : %d   Çokgen: %d   Nokta: %d   Katılan kırpıntı: %d" % (
        len(bolgeler), sum(len(b["cokgenler"]) for b in bolgeler.values()),
        sum(len(c) for b in bolgeler.values() for c in b["cokgenler"]), tasinan))
    print("Tek bölgeli ülke: %d   Komşusuna katılan küçük bölge: %d" % (
        sum(1 for u in ulkeler if sum(1 for b in bolgeler.values() if b["sahip"] == u) == 1), katilan))
    sayilar = {}
    for b in bolgeler.values():
        sayilar[b["sahip"]] = sayilar.get(b["sahip"], 0) + 1
    print("En çok bölgeli 30 ülke (bölge / hedef):")
    for u in sorted(sayilar, key=lambda k: -sayilar[k])[:30]:
        print("  %-4s %-32s %2d / %2d   (%.0f bin km², %.1f milyon)" % (
            u, ulkeler[u]["ad"], sayilar[u], ulkeler[u].get("_hedef", 1),
            ulkeler[u]["_alan_km2"] / 1000.0, ulkeler[u]["nufus"] / 1e6))
    print("Sınır  : %d çizgi   Kıyı bölgesi: %d   Kara komşuluğu: %d   Deniz yolu: %d" % (
        len(sinirlar), kiyi, kara, deniz))

    for (a, b) in sorted(nokta_komsuluklari):
        print("Tek noktada değen ülkeler için eklenen kara komşuluğu: %s (%s) - %s (%s)" % (
            a, bolgeler[a]["ad"], b, bolgeler[b]["ad"]))
    for (a, b) in baglanan:
        print("Dünya bağlantısını tamamlamak için eklenen deniz yolu: %s (%s) - %s (%s)" % (
            a, bolgeler[a]["ad"], b, bolgeler[b]["ad"]))
    for uyari in uyarilar:
        print("UYARI: %s" % uyari)
    if hatalar:
        for hata in hatalar:
            print("HATA: %s" % hata)
        raise DogrulamaHatasi("%d doğrulama hatası var; dosyalar yazılmadı." % len(hatalar))

    dunyayi_yaz(ulkeler, bolgeler)
    bolgeleri_yaz(bolgeler, sinirlar)
    print("Doğrulama geçti. Yazıldı: %s, %s" % (DUNYA_CIKTISI.name, BOLGE_CIKTISI.name))
    return ulkeler, bolgeler, sinirlar


if __name__ == "__main__":
    for yol in (ULKE_KAYNAGI, SEHIR_KAYNAGI, AYAR_DOSYASI):
        if not yol.exists():
            sys.exit("Kaynak dosya bulunamadı: %s" % yol)
    try:
        donustur()
    except DogrulamaHatasi as hata:
        sys.exit("DURDU: %s" % hata)
