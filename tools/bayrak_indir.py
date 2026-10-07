#!/usr/bin/env python3
"""Oyundaki ülkelerin bayraklarını lipis/flag-icons deposundan (MIT lisansı, 4x3 SVG) indirir.

Kullanım (proje klasöründen):
    python tools/bayrak_indir.py

Eşleştirme Natural Earth ülke verisindeki ISO_A2 koduyladır; ISO_A2 "-99" olan birkaç kayıtta
(ör. Fransa, Norveç) yine Natural Earth'teki ISO_A2_EH alanı kullanılır. Bayrağı bulunamayan
ülke listelenir; oyun ona ülke renginde sade bir yedek bayrak çizer (bkz. scripts/arayuz/bayraklar.gd).

Çıktı: tools/kaynak/bayraklar/<ULKE_ID>.svg ve tools/kaynak/bayraklar/eslesme.json. Ardından
tools/bayrak_atlasi.gd (Godot ile) bunları tek bir doku atlasına çevirir.
"""

import json
import sys
import urllib.request
from pathlib import Path

KOK = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(KOK / "tools"))
import dunya_donustur as donustur  # noqa: E402

CIKTI = KOK / "tools" / "kaynak" / "bayraklar"
ADRES = "https://raw.githubusercontent.com/lipis/flag-icons/main/flags/4x3/%s.svg"


def main():
    with open(donustur.ULKE_KAYNAGI, encoding="utf-8") as dosya:
        kaynak = json.load(dosya)
    ulkeler = donustur.ulkeleri_oku(donustur.ULKE_KAYNAGI)
    kodlar = {}
    for kayit in kaynak["features"]:
        o = kayit["properties"]
        ulke_id = o.get("ADM0_A3")
        if ulke_id not in ulkeler:
            continue
        kod = o.get("ISO_A2")
        if not kod or kod == "-99":
            kod = o.get("ISO_A2_EH")
        if kod and kod != "-99":
            kodlar[ulke_id] = kod.lower()

    CIKTI.mkdir(parents=True, exist_ok=True)
    eslesme = {}
    eksikler = []
    for ulke_id in sorted(ulkeler):
        kod = kodlar.get(ulke_id)
        hedef = CIKTI / ("%s.svg" % ulke_id)
        if kod is None:
            eksikler.append(ulke_id)
            continue
        if not hedef.exists():
            try:
                with urllib.request.urlopen(ADRES % kod, timeout=30) as yanit:
                    hedef.write_bytes(yanit.read())
            except Exception as hata:  # İndirilemeyen bayrak yedekle çizilir.
                print("  indirilemedi: %s (%s): %s" % (ulke_id, kod, hata))
                eksikler.append(ulke_id)
                continue
        eslesme[ulke_id] = kod
    with open(CIKTI / "eslesme.json", "w", encoding="utf-8", newline="\n") as dosya:
        json.dump(eslesme, dosya, ensure_ascii=False, indent=1, sort_keys=True)
    print("Bayrak: %d ülke, yedek bayrak çizilecek: %d (%s)" % (
        len(eslesme), len(eksikler), ", ".join("%s %s" % (u, ulkeler[u]["ad"]) for u in eksikler)))


if __name__ == "__main__":
    main()
