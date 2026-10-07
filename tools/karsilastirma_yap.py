#!/usr/bin/env python3
"""Görsel yenilemenin önce/sonra görüntülerini yan yana (üstte önce, altta sonra) birleştirir.

Kullanım (proje klasöründen, önce tests/gorsel_cek.gd ile iki klasör doldurulur):
    python tools/karsilastirma_yap.py
Girdi: docs/gorsel/once/ ve docs/gorsel/sonra/ (aynı adlı JPG'ler).
Çıktı: docs/gorsel/karsilastirma/<ad>.jpg — her biri yarı boyutta, üst üste, etiketli.
"""

from pathlib import Path

from PIL import Image, ImageDraw

KOK = Path(__file__).resolve().parent.parent
ONCE = KOK / "docs" / "gorsel" / "once"
SONRA = KOK / "docs" / "gorsel" / "sonra"
CIKTI = KOK / "docs" / "gorsel" / "karsilastirma"
OLCEK = 0.5


def etiketle(goruntu, metin):
    kalem = ImageDraw.Draw(goruntu)
    kalem.rectangle([0, 0, 120, 34], fill=(14, 20, 29))
    kalem.text((10, 8), metin, fill=(230, 174, 72))


def main():
    CIKTI.mkdir(parents=True, exist_ok=True)
    sayi = 0
    for once_yolu in sorted(ONCE.glob("*.jpg")):
        sonra_yolu = SONRA / once_yolu.name
        if not sonra_yolu.exists():
            continue
        parcalar = []
        for yol, ad in [(once_yolu, "ONCE"), (sonra_yolu, "SONRA")]:
            g = Image.open(yol).convert("RGB")
            g = g.resize((int(g.width * OLCEK), int(g.height * OLCEK)), Image.LANCZOS)
            etiketle(g, ad)
            parcalar.append(g)
        birlesik = Image.new("RGB", (max(p.width for p in parcalar), sum(p.height for p in parcalar) + 6),
                             (230, 174, 72))
        birlesik.paste(parcalar[0], (0, 0))
        birlesik.paste(parcalar[1], (0, parcalar[0].height + 6))
        birlesik.save(CIKTI / once_yolu.name, quality=85)
        sayi += 1
    print("Yazıldı: %d karşılaştırma -> %s" % (sayi, CIKTI.relative_to(KOK)))


if __name__ == "__main__":
    main()
