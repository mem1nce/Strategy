#!/usr/bin/env python3
"""Cinzel'in değişken (wght) sürümünden sabit 700 ağırlıklı, çakışan çizgileri birleştirilmiş
bir örnek üretir: assets/fonts/Cinzel.ttf.

Neden: harita adları MSDF (çok kanallı mesafe alanı) ile çizilir; değişken yazı tiplerinde
harflerin parçaları üst üste biner ve MSDF bu çakışmalarda harflerin üstünde küçük lekeler
bırakır. Çakışmalar kaldırılınca lekeler gider. Oyun yalnızca 700 ağırlığı kullanır.

Kullanım (proje klasöründen):
    python -m pip install -r tools/requirements.txt     (fonttools, skia-pathops)
    python tools/cinzel_sabitle.py

Kaynak: tools/kaynak/fontlar/Cinzel[wght].ttf (Google Fonts, SIL OFL 1.1; lisans
lisanslar/Cinzel_OFL.txt). Lisans ayrılmış ad (Reserved Font Name) içermediği için
değiştirilmiş sürüm aynı adla dağıtılabilir.
"""

import subprocess
import sys
from pathlib import Path

KOK = Path(__file__).resolve().parent.parent
KAYNAK = KOK / "tools" / "kaynak" / "fontlar" / "Cinzel[wght].ttf"
CIKTI = KOK / "assets" / "fonts" / "Cinzel.ttf"


def main():
    if not KAYNAK.exists():
        sys.exit("Kaynak yok: %s" % KAYNAK)
    subprocess.run([sys.executable, "-m", "fontTools.varLib.instancer", str(KAYNAK), "wght=700",
                    "--remove-overlaps", "-o", str(CIKTI)], check=True)
    print("Yazıldı:", CIKTI.relative_to(KOK))


if __name__ == "__main__":
    main()
