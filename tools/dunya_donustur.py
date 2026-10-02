#!/usr/bin/env python3
"""Natural Earth ülke verisini oyunun okuduğu sade data/world.json dosyasına çevirir.

Kullanım (proje klasöründen):
    python tools/dunya_donustur.py
    python tools/dunya_donustur.py tools/kaynak/baska_dosya.geojson data/world.json

Kaynak dosya daha ayrıntılısıyla (ör. ne_50m_admin_0_countries.geojson) değiştirilebilir;
aynı alan adlarını taşıdığı sürece bu betik değişmeden çalışır.

Yalnızca Python'un kendi kütüphanesini kullanır. Oyun bu betiği çalıştırmaz,
yalnızca ürettiği data/world.json dosyasını okur.
"""

import json
import math
import sys
from pathlib import Path

KOK = Path(__file__).resolve().parent.parent
VARSAYILAN_KAYNAK = KOK / "tools" / "kaynak" / "ne_110m_admin_0_countries.geojson"
VARSAYILAN_CIKTI = KOK / "data" / "world.json"

# Haritanın birim cinsinden genişliği (-180° ile +180° arası).
HARITA_GENISLIGI = 4096.0
# Haritanın kuzey ve güney kenarı (enlem). Antarktika çıkarıldığı için güney kırpılır.
KUZEY_SINIRI = 84.5
GUNEY_SINIRI = -58.0
# Haritaya alınmayan ülkeler (ADM0_A3).
CIKARILANLAR = {"ATA"}
# Koordinatların virgülden sonraki basamak sayısı.
ONDALIK = 2
# Bundan küçük alanlı çokgenler (harita birimi kare) atılır.
ASGARI_ALAN = 0.02
RENK_SAYISI = 9
# Sınırın bir noktaya gidip neredeyse aynı çizgiden geri döndüğü "sivri uçlar" atılır.
# İki kenar arasındaki açının sinüsü bundan küçükse uç sivri sayılır (yaklaşık 1 derece).
SIVRI_UC_ESIGI = 0.02

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


def agirlik_merkezi(noktalar):
    capraz_toplam = 0.0
    mx = my = 0.0
    for i, (x1, y1) in enumerate(noktalar):
        x2, y2 = noktalar[(i + 1) % len(noktalar)]
        capraz = x1 * y2 - x2 * y1
        capraz_toplam += capraz
        mx += (x1 + x2) * capraz
        my += (y1 + y2) * capraz
    if abs(capraz_toplam) < 1e-9:
        return noktalar[0]
    return (round(mx / (3.0 * capraz_toplam), ONDALIK), round(my / (3.0 * capraz_toplam), ONDALIK))


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


def kendini_kesiyor_mu(noktalar):
    """Çokgenin komşu olmayan iki kenarı kesişiyorsa True döner."""
    def yon(a, b, c):
        return (b[0] - a[0]) * (c[1] - a[1]) - (b[1] - a[1]) * (c[0] - a[0])

    adet = len(noktalar)
    for i in range(adet):
        p1, p2 = noktalar[i], noktalar[(i + 1) % adet]
        for j in range(i + 2, adet):
            if i == 0 and j == adet - 1:
                continue
            p3, p4 = noktalar[j], noktalar[(j + 1) % adet]
            if max(p1[0], p2[0]) < min(p3[0], p4[0]) or max(p3[0], p4[0]) < min(p1[0], p2[0]):
                continue
            if yon(p3, p4, p1) * yon(p3, p4, p2) < 0 and yon(p1, p2, p3) * yon(p1, p2, p4) < 0:
                return True
    return False


def donustur(kaynak_yolu, cikti_yolu):
    with open(kaynak_yolu, encoding="utf-8") as dosya:
        kaynak = json.load(dosya)

    ulkeler = {}
    # Sınır noktası -> o noktayı kullanan ülkeler. Komşuluk buradan çıkar.
    nokta_sahipleri = {}
    atilan_cokgen = 0
    # Çokgeni kendini kesen ülkeler; oyun bunların dolgusunu çizemeyebilir.
    kendini_kesenler = []

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
        for cokgen_halkalari in halkalar(kayit["geometry"]):
            # Komşuluk için delikler de sayılır: Güney Afrika, Lesotho'ya deliğinden komşudur.
            for halka in cokgen_halkalari:
                for nokta in halka:
                    anahtar = (round(nokta[0], 6), round(nokta[1], 6))
                    nokta_sahipleri.setdefault(anahtar, set()).add(ulke_id)
            # Çizim için yalnızca dış halka alınır; delikler yok sayılır.
            noktalar = cokgene_cevir(cokgen_halkalari[0])
            if len(noktalar) < 3 or alan(noktalar) < ASGARI_ALAN:
                atilan_cokgen += 1
                continue
            if kendini_kesiyor_mu(noktalar):
                kendini_kesenler.append(ulke_id)
            cokgenler.append(noktalar)
        if not cokgenler:
            print("  uyarı: %s için çizilecek çokgen kalmadı, ülke atlandı." % ulke_id)
            continue
        # Büyük parça başta dursun (anakara önce, adalar sonra).
        cokgenler.sort(key=alan, reverse=True)

        etiket_x = ozellik(o, "LABEL_X")
        etiket_y = ozellik(o, "LABEL_Y")
        if etiket_x is None or etiket_y is None:
            etiket = agirlik_merkezi(cokgenler[0])
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
        }

    # Komşuluk: ortak sınır noktası paylaşan ülkeler komşudur.
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
    degisen_renkler = []
    for ulke_id in sorted(ulkeler):
        ulke = ulkeler[ulke_id]
        ulke["renk"] = (ulke["renk"] - 1) % RENK_SAYISI + 1
        komsu_renkleri = {ulkeler[k]["renk"] for k in ulke["komsular"] if k < ulke_id}
        komsu_renkleri |= {ulkeler[k]["renk"] for k in ulke["komsular"] if k > ulke_id}
        if ulke["renk"] in komsu_renkleri:
            bos = [r for r in range(1, RENK_SAYISI + 1) if r not in komsu_renkleri]
            if bos:
                degisen_renkler.append("%s: %d -> %d" % (ulke_id, ulke["renk"], bos[0]))
                ulke["renk"] = bos[0]
            else:
                print("  uyarı: %s için komşularından farklı renk bulunamadı." % ulke_id)

    yaz(cikti_yolu, kaynak_yolu, ulkeler)

    cokgen_sayisi = sum(len(u["cokgenler"]) for u in ulkeler.values())
    nokta_sayisi = sum(len(c) for u in ulkeler.values() for c in u["cokgenler"])
    print("Kaynak : %s" % kaynak_yolu)
    print("Çıktı  : %s" % cikti_yolu)
    print("Harita : %d x %d birim (Miller, %.1f° ile %.1f° arası)" % (
        HARITA_GENISLIGI, HARITA_YUKSEKLIGI, GUNEY_SINIRI, KUZEY_SINIRI))
    print("Ülke   : %d   Çokgen: %d   Nokta: %d   Atılan küçük çokgen: %d" % (
        len(ulkeler), cokgen_sayisi, nokta_sayisi, atilan_cokgen))
    print("Komşusu olmayan ülke: %d" % sum(1 for u in ulkeler.values() if not u["komsular"]))
    if kendini_kesenler:
        print("UYARI: çokgeni kendini kesen ülkeler: %s" % ", ".join(kendini_kesenler))
    else:
        print("Kendini kesen çokgen yok.")
    if degisen_renkler:
        print("Komşusuyla çakıştığı için rengi değiştirilenler: %s" % ", ".join(degisen_renkler))
    else:
        print("Renk çakışması yok.")


def yaz(cikti_yolu, kaynak_yolu, ulkeler):
    """Dosyayı okunur ama derli toplu yazar: her ülke birkaç satır, her çokgen tek satır."""
    def kisa(deger):
        return json.dumps(deger, ensure_ascii=False, separators=(",", ":"))

    ulke_metinleri = []
    for ulke_id in sorted(ulkeler):
        ulke = ulkeler[ulke_id]
        satirlar = []
        for anahtar, deger in ulke.items():
            if anahtar == "cokgenler":
                cokgen_satirlari = ",\n".join("\t\t\t\t" + kisa(c) for c in deger)
                satirlar.append('\t\t\t"cokgenler": [\n%s\n\t\t\t]' % cokgen_satirlari)
            else:
                satirlar.append("\t\t\t%s: %s" % (
                    json.dumps(anahtar), json.dumps(deger, ensure_ascii=False)))
        ulke_metinleri.append("\t\t{\n%s\n\t\t}" % ",\n".join(satirlar))

    metin = "{\n"
    metin += '\t"kaynak": %s,\n' % json.dumps(
        "Natural Earth (kamu malı) - %s" % Path(kaynak_yolu).name, ensure_ascii=False)
    metin += '\t"projeksiyon": "miller",\n'
    metin += '\t"genislik": %d,\n' % HARITA_GENISLIGI
    metin += '\t"yukseklik": %d,\n' % HARITA_YUKSEKLIGI
    metin += '\t"ulkeler": [\n%s\n\t]\n}\n' % ",\n".join(ulke_metinleri)

    Path(cikti_yolu).parent.mkdir(parents=True, exist_ok=True)
    with open(cikti_yolu, "w", encoding="utf-8", newline="\n") as dosya:
        dosya.write(metin)


if __name__ == "__main__":
    kaynak_yolu = Path(sys.argv[1]) if len(sys.argv) > 1 else VARSAYILAN_KAYNAK
    cikti_yolu = Path(sys.argv[2]) if len(sys.argv) > 2 else VARSAYILAN_CIKTI
    if not kaynak_yolu.exists():
        sys.exit("Kaynak dosya bulunamadı: %s" % kaynak_yolu)
    donustur(kaynak_yolu, cikti_yolu)
