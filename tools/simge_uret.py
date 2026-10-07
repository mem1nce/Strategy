#!/usr/bin/env python3
"""Geçici uygulama simgesini (sade bir yerküre) üretip icons/ klasörüne PNG olarak yazar.

Kullanım (proje klasöründen):
    python tools/simge_uret.py

Çıktılar:
    icons/icon_512.png                  projenin simgesi (Godot düzenleyicisi ve masaüstü)
    icons/main_192.png                  Android'in klasik simgesi
    icons/adaptive_foreground_432.png   Android uyarlanabilir simge: ön plan (saydam zemin)
    icons/adaptive_background_432.png   Android uyarlanabilir simge: arka plan (düz renk)

Dışarıdan resim kullanılmaz; yerküre birkaç daire, elips ve çizgiden çizilir. Kenarlar
4x büyük çizilip küçültülerek yumuşatılır. PNG, yalnızca zlib ile yazılır (ek kütüphane yok).
"""

import struct
import zlib
from pathlib import Path

import numpy as np

KOK = Path(__file__).resolve().parent.parent
CIKTI = KOK / "icons"
OLCEK = 4  # Yumuşatma için kaç kat büyük çizilip küçültüleceği.

ZEMIN = (29, 42, 58)        # Koyu mavi-gri (haritanın denizine yakın).
OKYANUS = (66, 120, 178)
KARA = (120, 178, 110)
CIZGI = (235, 240, 245)


def png_yaz(yol, rgba):
    """rgba: (y, x, 4) uint8 dizi."""
    yukseklik, genislik, _ = rgba.shape
    satirlar = b"".join(b"\x00" + rgba[y].tobytes() for y in range(yukseklik))

    def parca(tur, veri):
        return struct.pack(">I", len(veri)) + tur + veri + struct.pack(">I", zlib.crc32(tur + veri) & 0xFFFFFFFF)

    baslik = struct.pack(">IIBBBBB", genislik, yukseklik, 8, 6, 0, 0, 0)
    with open(yol, "wb") as dosya:
        dosya.write(b"\x89PNG\r\n\x1a\n" + parca(b"IHDR", baslik)
                    + parca(b"IDAT", zlib.compress(satirlar, 9)) + parca(b"IEND", b""))


def kucult(buyuk, kat):
    y, x, k = buyuk.shape
    return buyuk.reshape(y // kat, kat, x // kat, kat, k).mean(axis=(1, 3))


def yerkure(boyut, kure_orani, zeminli):
    """`boyut` piksellik kare simge; yerküre çapı boyutun `kure_orani` katı."""
    b = boyut * OLCEK
    resim = np.zeros((b, b, 4), dtype=float)
    if zeminli:
        resim[:, :, :3] = ZEMIN
        resim[:, :, 3] = 255
    y, x = np.mgrid[0:b, 0:b] + 0.5
    merkez = b / 2.0
    r = b * kure_orani / 2.0
    dx, dy = (x - merkez) / r, (y - merkez) / r
    kure = dx * dx + dy * dy <= 1.0

    def boya(maske, renk):
        resim[maske, :3] = renk
        resim[maske, 3] = 255

    boya(kure, OKYANUS)
    # Kara parçaları: küre içinde kalan birkaç eğik elips.
    for (cx, cy, rx, ry, aci) in [(-0.35, -0.25, 0.42, 0.28, 0.5), (0.3, 0.35, 0.33, 0.22, -0.4),
                                  (0.45, -0.45, 0.2, 0.14, 0.2), (-0.25, 0.55, 0.18, 0.12, 0.0)]:
        ca, sa = np.cos(aci), np.sin(aci)
        ux = (dx - cx) * ca + (dy - cy) * sa
        uy = -(dx - cx) * sa + (dy - cy) * ca
        boya(kure & ((ux / rx) ** 2 + (uy / ry) ** 2 <= 1.0), KARA)
    # Enlem ve boylam çizgileri, küre kenarı.
    kalinlik = 0.022
    cizgi = np.zeros_like(kure)
    for enlem in (-0.5, 0.0, 0.5):
        cizgi |= np.abs(dy - enlem) < kalinlik
    for kat in (0.0, 0.55):
        # Boylamlar: x = kat * sqrt(1 - y²) elipsleri.
        genislik = kat * np.sqrt(np.clip(1.0 - dy * dy, 0.0, 1.0))
        cizgi |= np.abs(np.abs(dx) - genislik) < kalinlik
    boya(kure & cizgi, CIZGI)
    kenar = np.abs(np.sqrt(dx * dx + dy * dy) - 1.0) < kalinlik * 1.4
    boya(kenar, CIZGI)
    return np.clip(kucult(resim, OLCEK), 0, 255).astype(np.uint8)


def main():
    CIKTI.mkdir(exist_ok=True)
    png_yaz(CIKTI / "icon_512.png", yerkure(512, 0.8, True))
    png_yaz(CIKTI / "main_192.png", yerkure(192, 0.8, True))
    # Uyarlanabilir simgede ön plan; Android bunu 432'nin ortadaki ~%60'ı görünecek şekilde keser.
    png_yaz(CIKTI / "adaptive_foreground_432.png", yerkure(432, 0.56, False))
    arka = np.zeros((432, 432, 4), dtype=np.uint8)
    arka[:, :, :3] = ZEMIN
    arka[:, :, 3] = 255
    png_yaz(CIKTI / "adaptive_background_432.png", arka)
    for yol in sorted(CIKTI.glob("*.png")):
        print(yol.relative_to(KOK))


if __name__ == "__main__":
    main()
