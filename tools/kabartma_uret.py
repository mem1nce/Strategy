#!/usr/bin/env python3
"""Natural Earth "Shaded Relief" (SR_50M, kamu malı) rasterini oyunun Miller izdüşümüne çevirir.

Kullanım (proje klasöründen):
    python -m pip install -r tools/requirements.txt     (pillow, numpy)
    python tools/kabartma_uret.py

Kaynak: tools/kaynak/SR_50M.zip (https://naciscdn.org/naturalearth/50m/raster/SR_50M.zip;
depoya girmez, bu adresten indirilir). Eşdikdörtgen (enlem-boylam) 10800 x 5400 gri tonlu bir
gölgeli kabartmadır.

Çıktı: assets/relief.png — harita ile aynı boyutta (4096 x 2066; bir piksel bir harita birimi),
gri tonlu tek doku. İki iş görür (kara ve deniz ayrı gölgelendiricilerle çizildiği için
karışmazlar):
- Kara piksellerinde gölgeli kabartma: düz arazi DUZ_DEGER'dir; kara gölgelendiricisi dolguyu
  değer / DUZ_DEGER ile çarpar (dağlar ve vadiler).
- Deniz piksellerinde kıyıya yakınlık: kıyıda DUZ_DEGER, açık denizde 0. Deniz gölgelendiricisi
  bununla derinlik geçişi yapar (kıyı açık, açık deniz koyu). Kıyıdaki değer düz araziyle
  aynı olduğu için kıyı çizgisinde iki doku birbirine sızmaz.
Kara/deniz ayrımı oyunun kendi çokgenlerinden (data/regions.json) yapılır ki haritayla çakışsın.
"""

import io
import json
import math
import sys
import zipfile
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

KOK = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(KOK / "tools"))
import dunya_donustur as donustur  # noqa: E402

KAYNAK = KOK / "tools" / "kaynak" / "SR_50M.zip"
BOLGELER = KOK / "data" / "regions.json"
CIKTI = KOK / "assets" / "relief.png"
## Kaynaktaki düz arazinin (ve düz denizin) gri değeri. Gölgelendiriciler de bunu kullanır.
DUZ_DEGER = 206
## Kıyıya yakınlık üç ayrı genişlikte bulanıklaştırılmış kara maskesinin toplamıdır:
## (yarıçap piksel, ağırlık). Dar olan kıyı şeridini, geniş olan kıta sahanlığını verir.
KIYI_KATMANLARI = [(3, 0.45), (18, 0.35), (70, 0.20)]

Image.MAX_IMAGE_PIXELS = None


def main():
    if not KAYNAK.exists():
        sys.exit("Kaynak yok: %s (indirme adresi betiğin başında)" % KAYNAK)
    with zipfile.ZipFile(KAYNAK) as arsiv:
        tif = next(ad for ad in arsiv.namelist() if ad.lower().endswith(".tif"))
        kaynak = np.asarray(Image.open(io.BytesIO(arsiv.read(tif))).convert("L"), dtype=np.float32)
    kaynak_y, kaynak_x = kaynak.shape

    genislik = int(donustur.HARITA_GENISLIGI)
    yukseklik = int(donustur.HARITA_YUKSEKLIGI)
    # Her çıktı pikselinin merkezi için enlem ve boylam (Miller'in tersi).
    x = (np.arange(genislik) + 0.5)
    y = (np.arange(yukseklik) + 0.5)
    boylam = x / genislik * 360.0 - 180.0
    miller = donustur.UST_Y - y / donustur.OLCEK
    enlem = np.degrees(2.5 * (np.arctan(np.exp(miller / 1.25)) - math.pi / 4.0))

    # Kaynakta çift doğrusal örnekleme.
    kx = (boylam + 180.0) / 360.0 * kaynak_x - 0.5
    ky = (90.0 - enlem) / 180.0 * kaynak_y - 0.5
    kx0 = np.clip(np.floor(kx).astype(int), 0, kaynak_x - 2)
    ky0 = np.clip(np.floor(ky).astype(int), 0, kaynak_y - 2)
    fx = np.clip(kx - kx0, 0.0, 1.0)[None, :]
    fy = np.clip(ky - ky0, 0.0, 1.0)[:, None]
    a = kaynak[ky0[:, None], kx0[None, :]]
    b = kaynak[ky0[:, None], kx0[None, :] + 1]
    c = kaynak[ky0[:, None] + 1, kx0[None, :]]
    d = kaynak[ky0[:, None] + 1, kx0[None, :] + 1]
    sonuc = (a * (1 - fx) + b * fx) * (1 - fy) + (c * (1 - fx) + d * fx) * fy

    kara = kara_maskesi(genislik, yukseklik)
    yakinlik = kiyi_yakinligi(kara)
    sonuc = np.where(kara > 0, sonuc, yakinlik * DUZ_DEGER)

    CIKTI.parent.mkdir(exist_ok=True)
    Image.fromarray(np.clip(sonuc, 0, 255).astype(np.uint8), mode="L").save(CIKTI, optimize=True)
    print("Yazıldı: %s (%d x %d, kaynak %d x %d)" % (CIKTI.relative_to(KOK), genislik, yukseklik, kaynak_x, kaynak_y))


def kara_maskesi(genislik, yukseklik):
    """Oyunun bölge çokgenlerini çizer: kara 255, deniz 0 (numpy dizisi)."""
    with open(BOLGELER, encoding="utf-8") as dosya:
        bolgeler = json.load(dosya)["bolgeler"]
    maske = Image.new("L", (genislik, yukseklik), 0)
    kalem = ImageDraw.Draw(maske)
    for bolge in bolgeler:
        for cokgen in bolge["cokgenler"]:
            kalem.polygon([(x, y) for x, y in cokgen], fill=255)
    return np.asarray(maske)


def kiyi_yakinligi(kara):
    """Her piksel için 0 (açık deniz) ile 1 (kıyı) arası yakınlık."""
    maske = Image.fromarray(kara)
    toplam = np.zeros(kara.shape, dtype=np.float32)
    for yaricap, agirlik in KIYI_KATMANLARI:
        bulanik = np.asarray(maske.filter(ImageFilter.GaussianBlur(yaricap)), dtype=np.float32) / 255.0
        # Kıyıda bulanık maske ~0,5'tir; 2 ile çarpılınca kıyı tam yakınlık alır.
        toplam += agirlik * np.clip(bulanik * 2.0, 0.0, 1.0)
    return np.clip(toplam, 0.0, 1.0)


if __name__ == "__main__":
    main()
