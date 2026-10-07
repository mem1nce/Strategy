#!/usr/bin/env python3
"""Ülke bonuslarını data/bonuses.json dosyasına yazar.

Kullanım (proje klasöründen):
    python tools/bonus_uret.py

Her ülkenin tek bir küçük bonusu vardır; hiçbiri %15'i geçmez. Bonuslar yalnızca coğrafyaya,
nüfusa ve ekonomiye dayanır (kalıp yargı ya da siyasi gönderme yoktur):

- GSYH'si en büyük 20 ülkenin bonusu aşağıda (OZEL) elle yazılmıştır.
- Diğer ülkeler verilerine göre dört genel bonustan birini alır (bkz. genel_bonus):
  kıyı ülkesi -> güçlü ekonomi -> geniş topraklar -> kalabalık nüfus (ilk tutan).

Veri: tools/kaynak/ altındaki Natural Earth ülke dosyası (gerçek yüzölçümü, nüfus, GSYH) ve
data/regions.json (kıyı bölgeleri). Oyun bu betiği çalıştırmaz, yalnızca data/bonuses.json'u okur.
"""

import json
import sys
from pathlib import Path

KOK = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(KOK / "tools"))
import dunya_donustur as donustur  # noqa: E402

CIKTI = KOK / "data" / "bonuses.json"
AZAMI_DEGER = 0.15
OZEL_SAYISI = 20

# Bonus türleri ve oyundaki etkileri (bkz. scripts/sim/ulke_bonuslari.gd):
TURLER = {
    "gelir": "Gelir +%{}",
    "fabrika_indirimi": "Fabrika %{} ucuz",
    "piyade_indirimi": "Piyade %{} ucuz",
    "deniz_saldirisi": "Denizden saldırı cezası %{} az",
    "kendi_toprak_savunmasi": "Kendi toprağında savunma +%{}",
    "arastirma_hizi": "Araştırma %{} kısa sürer",
    "hareket_hizi": "Tümenler %{} hızlı yürür",
    "bakim_indirimi": "Tümen bakımı %{} ucuz",
}

# GSYH'si en büyük 20 ülke: coğrafyasına ya da ekonomisine dayanan özel bonus.
OZEL = {
    "USA": ("Büyük iç pazar", "gelir", 0.10),
    "CHN": ("Geniş sanayi tabanı", "fabrika_indirimi", 0.15),
    "JPN": ("Ada ülkesi", "deniz_saldirisi", 0.15),
    "DEU": ("Güçlü mühendislik sanayisi", "arastirma_hizi", 0.15),
    "IND": ("Çok büyük nüfus", "piyade_indirimi", 0.15),
    "GBR": ("Ada ülkesi", "deniz_saldirisi", 0.15),
    "FRA": ("Verimli tarım toprakları", "bakim_indirimi", 0.15),
    "ITA": ("Uzun kıyı şeridi", "deniz_saldirisi", 0.10),
    "BRA": ("Geniş orman ve ovalar", "kendi_toprak_savunmasi", 0.10),
    "CAN": ("Geniş kuzey toprakları", "kendi_toprak_savunmasi", 0.15),
    "RUS": ("En geniş topraklar", "kendi_toprak_savunmasi", 0.15),
    "KOR": ("Yüksek teknoloji sanayisi", "arastirma_hizi", 0.10),
    "AUS": ("Ada kıta", "deniz_saldirisi", 0.15),
    "ESP": ("Hizmet ekonomisi", "gelir", 0.05),
    "MEX": ("Genç ve kalabalık nüfus", "piyade_indirimi", 0.10),
    "TWN": ("Yarı iletken sanayisi", "arastirma_hizi", 0.15),
    "IDN": ("Takımadalar", "deniz_saldirisi", 0.15),
    "NLD": ("Ticaret limanları", "gelir", 0.10),
    "SAU": ("Petrol gelirleri", "gelir", 0.10),
    "TUR": ("İki kıta arasında kara köprüsü", "hareket_hizi", 0.10),
}

# Genel bonuslar ve seçim eşikleri.
KIYI_PAYI_ESIGI = 0.8          # Bölgelerinin bu kadarı kıyıdaysa (ya da kara komşusu yoksa) kıyı ülkesi.
GUCLU_EKONOMI_ESIGI = 20000.0  # Kişi başı GSYH ($) bundan büyükse güçlü ekonomi.
GENIS_TOPRAK_YOGUNLUGU = 30.0  # Kişi/km² bundan azsa geniş topraklar.
GENEL = {
    "kiyi": ("Kıyı ülkesi", "deniz_saldirisi", 0.10),
    "ekonomi": ("Güçlü ekonomi", "gelir", 0.05),
    "toprak": ("Geniş topraklar", "kendi_toprak_savunmasi", 0.10),
    "nufus": ("Kalabalık nüfus", "piyade_indirimi", 0.10),
}


def genel_bonus(ulke, kiyi_payi):
    if not ulke["komsular"] or kiyi_payi >= KIYI_PAYI_ESIGI:
        return GENEL["kiyi"]
    if ulke["gsyh_milyon_dolar"] * 1e6 / max(ulke["nufus"], 1) >= GUCLU_EKONOMI_ESIGI:
        return GENEL["ekonomi"]
    if ulke["nufus"] / max(ulke["_alan_km2"], 1.0) < GENIS_TOPRAK_YOGUNLUGU:
        return GENEL["toprak"]
    return GENEL["nufus"]


def main():
    ulkeler = donustur.ulkeleri_oku(donustur.ULKE_KAYNAGI)
    with open(KOK / "data" / "regions.json", encoding="utf-8") as dosya:
        bolgeler = json.load(dosya)["bolgeler"]
    kiyi = {}
    for bolge in bolgeler:
        sayac = kiyi.setdefault(bolge["sahip"], [0, 0])
        sayac[0] += 1 if bolge["kiyi"] else 0
        sayac[1] += 1

    en_buyukler = sorted(ulkeler, key=lambda u: -ulkeler[u]["gsyh_milyon_dolar"])[:OZEL_SAYISI]
    if set(en_buyukler) != set(OZEL):
        sys.exit("En büyük %d ülke değişti, OZEL listesini güncelle: %s" % (OZEL_SAYISI, sorted(en_buyukler)))

    sonuc = {}
    for ulke_id in sorted(ulkeler):
        ad, tur, deger = OZEL.get(ulke_id) or genel_bonus(ulkeler[ulke_id], kiyi[ulke_id][0] / kiyi[ulke_id][1])
        assert tur in TURLER and 0.0 < deger <= AZAMI_DEGER, (ulke_id, tur, deger)
        sonuc[ulke_id] = {"ad": ad, "tur": tur, "deger": deger}

    metin = "{\n"
    metin += '\t"_aciklama": "Ülke bonusları. tools/bonus_uret.py ile üretilir; her ülkenin tek bonusu vardır, hiçbiri %15\'i geçmez. Türlerin etkisi: scripts/sim/ulke_bonuslari.gd.",\n'
    metin += '\t"ulkeler": {\n'
    metin += ",\n".join('\t\t"%s": %s' % (k, json.dumps(v, ensure_ascii=False)) for k, v in sonuc.items())
    metin += "\n\t}\n}\n"
    with open(CIKTI, "w", encoding="utf-8", newline="\n") as dosya:
        dosya.write(metin)

    sayilar = {}
    for v in sonuc.values():
        sayilar[v["ad"]] = sayilar.get(v["ad"], 0) + 1
    print("Yazıldı: %s (%d ülke)" % (CIKTI.relative_to(KOK), len(sonuc)))
    for ad in sorted(sayilar, key=lambda a: -sayilar[a]):
        print("  %-32s %d" % (ad, sayilar[ad]))


if __name__ == "__main__":
    main()
