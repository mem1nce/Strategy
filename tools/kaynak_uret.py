#!/usr/bin/env python3
"""Stratejik kaynakların (petrol, maden) bölge bölge üretimini üretir: data/resources.json.

Kullanım (proje klasöründen):
    python tools/kaynak_uret.py

NOT: Sayılar oyun için YUVARLANMIŞ TAHMİNLERDİR, resmî istatistik değildir.
- Petrol: ülkelerin yaklaşık ham petrol üretimi (2019 civarı, milyon varil/gün, yuvarlak).
- Maden: metal cevheri, kömür ve fosfatın kabaca bileşik üretim payı (birimsiz, yuvarlak).
Her ikisinde de yalnızca en büyük 30 üretici vardır; diğer ülkeler üretmez. Oyun bu sayıları
yalnızca oran olarak kullanır: dünya toplamını, başlangıçtaki dünya talebinin ~%105'ine
ölçekler (bkz. scripts/sim/piyasa.gd).

Ülke içinde üretim bilinen havzalara (enlem, boylam, pay) dağıtılır: her havza o ülkenin
koordinatı içeren ya da ona en yakın bölgesine yazılır. Payların toplamı 1'den azsa kalan,
ülkenin bölgelerine alanlarıyla orantılı dağıtılır. Havza listesi bilinmeyen ülkede bütün
üretim alana göre dağıtılır.

Doğrulama: listedeki her ülke dünyada olmalı, havza ülkesinin bir bölgesine en çok
AZAMI_HAVZA_UZAKLIGI harita birimi uzakta olmalı, paylar 1'i geçmemeli. Hata varsa dosya
yazılmaz.
"""

import json
import sys
from pathlib import Path

from shapely.geometry import Point, Polygon

KOK = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(KOK / "tools"))
import dunya_donustur as donustur  # noqa: E402

BOLGELER = KOK / "data" / "regions.json"
CIKTI = KOK / "data" / "resources.json"
AZAMI_HAVZA_UZAKLIGI = 120.0

PETROL = {
    "USA": 12.3, "RUS": 10.8, "SAU": 9.8, "CAN": 4.4, "IRQ": 4.6, "CHN": 3.8, "ARE": 3.1,
    "BRA": 2.9, "IRN": 2.8, "KWT": 2.7, "NOR": 1.7, "KAZ": 1.8, "MEX": 1.7, "NGA": 1.8,
    "QAT": 1.4, "DZA": 1.0, "LBY": 1.1, "AGO": 1.4, "OMN": 1.0, "COL": 0.9, "GBR": 0.9,
    "AZE": 0.7, "VEN": 0.9, "IDN": 0.75, "EGY": 0.6, "MYS": 0.6, "ECU": 0.5, "ARG": 0.5,
    "IND": 0.7, "AUS": 0.4,
}

MADEN = {
    "CHN": 20.0, "AUS": 15.0, "RUS": 7.0, "USA": 7.0, "BRA": 6.0, "CHL": 5.0, "ZAF": 4.0,
    "IND": 4.0, "CAN": 4.0, "PER": 3.0, "IDN": 3.0, "KAZ": 2.0, "COD": 2.0, "MEX": 1.5,
    "UKR": 1.2, "IRN": 1.0, "SWE": 0.8, "ZMB": 0.8, "MNG": 0.8, "TUR": 0.8, "MAR": 0.8,
    "GIN": 0.7, "POL": 0.6, "GHA": 0.6, "UZB": 0.6, "PHL": 0.5, "SAU": 0.5, "BOL": 0.4,
    "PNG": 0.4, "ARG": 0.4,
}

# Ülke -> [(ad, enlem, boylam, pay)]
PETROL_HAVZALARI = {
    "USA": [("Teksas (Permiyen)", 31.9, -102.3, 0.45), ("Kuzey Dakota", 48.0, -103.5, 0.12),
            ("Meksika Körfezi", 29.5, -91.0, 0.15), ("Alaska", 70.3, -148.5, 0.04),
            ("Oklahoma", 35.5, -97.5, 0.06)],
    "RUS": [("Tümen (Batı Sibirya)", 61.0, 73.0, 0.6), ("Volga-Ural", 54.0, 52.0, 0.2),
            ("Yamal", 67.0, 75.0, 0.1), ("Sahalin", 52.0, 143.0, 0.05)],
    "SAU": [("Gavar (Doğu Eyaleti)", 25.4, 49.6, 0.8), ("Safaniye", 28.0, 48.8, 0.2)],
    "CAN": [("Alberta", 56.7, -111.4, 0.85), ("Saskatchewan", 50.5, -104.0, 0.1)],
    "IRQ": [("Basra", 30.5, 47.8, 0.75), ("Kerkük", 35.5, 44.4, 0.2)],
    "CHN": [("Daqing", 46.6, 125.0, 0.25), ("Bohai / Shengli", 37.5, 118.5, 0.3),
            ("Sincan", 44.0, 84.9, 0.2), ("Changqing", 37.5, 108.5, 0.25)],
    "ARE": [("Abu Dabi", 24.0, 53.8, 0.95)],
    "BRA": [("Campos / Santos", -22.5, -41.0, 1.0)],
    "IRN": [("Ahvaz (Huzistan)", 31.3, 48.7, 0.8), ("Buşehr", 28.9, 50.8, 0.2)],
    "KWT": [("Burgan", 29.0, 48.0, 1.0)],
    "NOR": [("Kuzey Denizi", 58.9, 5.7, 1.0)],
    "KAZ": [("Tengiz (Atırav)", 46.2, 53.3, 0.7), ("Mangıstav", 43.6, 51.2, 0.3)],
    "MEX": [("Campeche / Tabasco", 18.5, -92.6, 0.9)],
    "NGA": [("Nijer Deltası", 4.8, 6.9, 1.0)],
    "QAT": [("Katar", 25.3, 51.5, 1.0)],
    "DZA": [("Hassi Messaoud", 31.7, 6.1, 1.0)],
    "LBY": [("Sirte havzası", 29.5, 19.5, 1.0)],
    "AGO": [("Kabinda / açık deniz", -5.6, 12.2, 1.0)],
    "OMN": [("Umman iç havzası", 21.0, 56.5, 1.0)],
    "COL": [("Llanos", 4.5, -72.0, 1.0)],
    "GBR": [("Aberdeen (Kuzey Denizi)", 57.1, -2.1, 1.0)],
    "AZE": [("Bakü", 40.4, 49.9, 1.0)],
    "VEN": [("Maracaibo", 10.6, -71.6, 0.5), ("Orinoko", 8.5, -64.0, 0.5)],
    "IDN": [("Riau (Sumatra)", 1.0, 101.5, 0.6), ("Doğu Kalimantan", -1.0, 117.0, 0.4)],
    "EGY": [("Süveyş Körfezi", 28.5, 33.0, 0.6), ("Batı Çölü", 30.0, 27.5, 0.4)],
    "MYS": [("Saravak / Sabah", 4.5, 113.9, 0.6), ("Terengganu", 5.3, 103.1, 0.4)],
    "ECU": [("Oriente", -0.5, -76.5, 1.0)],
    "ARG": [("Neuquén", -38.9, -68.1, 0.7), ("Chubut", -45.8, -67.5, 0.3)],
    "IND": [("Mumbai High", 19.0, 72.8, 0.5), ("Assam", 27.0, 94.5, 0.2), ("Gujarat", 22.5, 72.0, 0.3)],
    "AUS": [("Kuzeybatı Sahanlığı", -20.7, 116.8, 1.0)],
}

MADEN_HAVZALARI = {
    "AUS": [("Pilbara", -22.3, 118.6, 0.6), ("Kalgoorlie", -30.7, 121.5, 0.15), ("Bowen", -22.0, 148.5, 0.25)],
    "BRA": [("Minas Gerais", -19.9, -43.9, 0.6), ("Carajás", -6.1, -50.2, 0.4)],
    "CHN": [("İç Moğolistan", 40.6, 109.8, 0.3), ("Şanşi", 37.9, 112.5, 0.3),
            ("Hebei", 39.6, 118.2, 0.2), ("Yunnan", 25.0, 102.7, 0.2)],
    "RUS": [("Norilsk", 69.3, 88.2, 0.3), ("Kuzbas", 54.0, 86.7, 0.3), ("Urallar", 56.8, 60.6, 0.25),
            ("Kursk", 51.7, 36.2, 0.15)],
    "USA": [("Nevada", 39.5, -117.0, 0.3), ("Arizona", 33.0, -110.8, 0.3), ("Wyoming", 43.5, -105.5, 0.2),
            ("Minnesota", 47.5, -92.5, 0.2)],
    "CHL": [("Antofagasta", -23.6, -70.4, 0.7), ("Atacama", -27.4, -70.3, 0.3)],
    "ZAF": [("Witwatersrand", -26.2, 28.0, 0.5), ("Bushveld", -25.7, 27.2, 0.5)],
    "IND": [("Jharkhand / Odisha", 22.8, 86.2, 0.7), ("Goa / Karnataka", 15.3, 74.5, 0.3)],
    "CAN": [("Sudbury", 46.5, -81.0, 0.4), ("Labrador Çukuru", 52.9, -66.9, 0.3), ("Britanya Kolumbiyası", 50.5, -120.5, 0.3)],
    "PER": [("Güney And Dağları", -14.0, -72.0, 0.6), ("Cajamarca", -7.2, -78.5, 0.4)],
    "IDN": [("Papua (Grasberg)", -4.05, 137.1, 0.5), ("Kalimantan kömürü", -1.0, 116.0, 0.5)],
    "KAZ": [("Karaganda", 49.8, 73.1, 0.6), ("Kostanay", 53.2, 63.6, 0.4)],
    "COD": [("Katanga", -10.7, 25.5, 1.0)],
    "MEX": [("Sonora", 29.1, -110.9, 0.6), ("Zacatecas", 22.8, -102.6, 0.4)],
    "UKR": [("Krivoy Rog", 47.9, 33.4, 0.7), ("Donbas", 48.0, 37.8, 0.3)],
    "IRN": [("Kirman", 30.3, 57.1, 1.0)],
    "SWE": [("Kiruna", 67.9, 20.2, 1.0)],
    "ZMB": [("Bakır Kuşağı", -12.8, 28.2, 1.0)],
    "MNG": [("Oyu Tolgoi", 43.0, 106.9, 1.0)],
    "TUR": [("Sivas / Elazığ", 38.7, 39.2, 0.5), ("Zonguldak", 41.4, 31.8, 0.5)],
    "MAR": [("Hurayb", 32.9, -6.9, 1.0)],
    "GIN": [("Boké", 10.9, -14.3, 1.0)],
    "POL": [("Silezya", 50.3, 19.0, 0.6), ("Lubin", 51.4, 16.2, 0.4)],
    "GHA": [("Obuasi", 6.2, -1.7, 1.0)],
    "UZB": [("Muruntau", 41.5, 64.2, 1.0)],
    "BOL": [("Potosí", -19.6, -65.8, 1.0)],
}


def bolgeleri_oku():
    with open(BOLGELER, encoding="utf-8") as dosya:
        veri = json.load(dosya)["bolgeler"]
    sonuc = {}
    for b in veri:
        ulke = b["id"].split("_")[0]
        cokgenler = [Polygon(c) for c in b["cokgenler"] if len(c) >= 3]
        alan = sum(c.area for c in cokgenler)
        sonuc.setdefault(ulke, []).append({"id": b["id"], "cokgenler": cokgenler, "alan": alan,
                                           "etiket": b["etiket"]})
    return sonuc


def havza_bolgesi(bolgeler, enlem, boylam):
    """Koordinatı içeren bölge; yoksa en yakın bölge. (bölge id, uzaklık) döndürür."""
    nokta = Point(donustur.duzleme_cevir(boylam, enlem))
    en_iyi = None
    en_iyi_uzaklik = float("inf")
    for b in bolgeler:
        for c in b["cokgenler"]:
            uzaklik = c.distance(nokta)
            if uzaklik < en_iyi_uzaklik:
                en_iyi_uzaklik = uzaklik
                en_iyi = b["id"]
    return en_iyi, en_iyi_uzaklik


def dagit(ad, uretimler, havzalar, bolgeler, hatalar):
    sonuc = {}
    for ulke, miktar in uretimler.items():
        if ulke not in bolgeler:
            hatalar.append("%s: %s dünyada yok" % (ad, ulke))
            continue
        kalan = 1.0
        for havza_adi, enlem, boylam, pay in havzalar.get(ulke, []):
            bolge_id, uzaklik = havza_bolgesi(bolgeler[ulke], enlem, boylam)
            if uzaklik > AZAMI_HAVZA_UZAKLIGI:
                hatalar.append("%s: %s havzası (%s) ülkenin bölgelerinden %.0f birim uzakta" % (ad, havza_adi, ulke, uzaklik))
                continue
            sonuc[bolge_id] = sonuc.get(bolge_id, 0.0) + miktar * pay
            kalan -= pay
        if kalan < -1e-6:
            hatalar.append("%s: %s havza payları 1'i geçiyor" % (ad, ulke))
        if kalan > 1e-6:
            toplam_alan = sum(b["alan"] for b in bolgeler[ulke])
            for b in bolgeler[ulke]:
                sonuc[b["id"]] = sonuc.get(b["id"], 0.0) + miktar * kalan * b["alan"] / toplam_alan
    return {k: round(v, 4) for k, v in sorted(sonuc.items()) if v >= 0.0005}


def main():
    bolgeler = bolgeleri_oku()
    hatalar = []
    petrol = dagit("petrol", PETROL, PETROL_HAVZALARI, bolgeler, hatalar)
    maden = dagit("maden", MADEN, MADEN_HAVZALARI, bolgeler, hatalar)
    if len(PETROL) != 30 or len(MADEN) != 30:
        hatalar.append("her kaynakta tam 30 üretici olmalı (%d, %d)" % (len(PETROL), len(MADEN)))
    if hatalar:
        for hata in hatalar:
            print("HATA:", hata)
        sys.exit("Doğrulama geçmedi; dosya yazılmadı.")
    veri = {
        "not": "Oyun için yuvarlanmış tahminler; resmî istatistik değildir. Petrol: ~2019 ham petrol "
               "(milyon varil/gün); maden: metal cevheri, kömür ve fosfatın kabaca bileşik payı. "
               "Yalnızca en büyük 30 üretici. Oyun sayıları oran olarak kullanır. "
               "Üretici: tools/kaynak_uret.py",
        "petrol": petrol,
        "maden": maden,
    }
    with open(CIKTI, "w", encoding="utf-8") as dosya:
        json.dump(veri, dosya, ensure_ascii=False, indent="\t")
        dosya.write("\n")
    print("Yazıldı: %s (petrol %d bölge, maden %d bölge)" % (CIKTI.relative_to(KOK), len(petrol), len(maden)))
    for ad, havzalar in [("petrol", PETROL_HAVZALARI), ("maden", MADEN_HAVZALARI)]:
        for ulke in ["IRQ", "IRN", "RUS", "USA", "CAN", "AUS", "BRA"]:
            for havza_adi, enlem, boylam, _pay in havzalar.get(ulke, []):
                bolge_id, _u = havza_bolgesi(bolgeler[ulke], enlem, boylam)
                print("  %s %s -> %s" % (ad, havza_adi, bolge_id))


if __name__ == "__main__":
    main()
