#!/usr/bin/env python3
"""Oyunun kısa ses efektlerini sentezleyip sounds/ klasörüne WAV olarak yazar.

Kullanım (proje klasöründen):
    python tools/ses_uret.py

Dışarıdan hiçbir dosya indirilmez; her ses birkaç sinüs dalgası, yumuşak bir zarf (hızlı
yükseliş, üstel sönüm) ve gerektiğinde az miktarda süzülmüş gürültüden üretilir. Sesler
kısa (0,05-1,1 sn), alçak sesli ve tok tutulur ki üst üste çaldığında rahatsız etmesin.
Çıktı: 22 050 Hz, tek kanal, 16 bit.
"""

import math
import wave
from pathlib import Path

import numpy as np

KOK = Path(__file__).resolve().parent.parent
CIKTI = KOK / "sounds"
ORNEKLEME = 22050
# Bütün seslerin tepe genliği (0-1). Düşük tutulur; oyundaki ses düzeyi ayrıca ayarlanır.
TEPE = 0.5


def zaman(sure):
    return np.arange(int(sure * ORNEKLEME)) / ORNEKLEME


def zarf(t, yukselis=0.005, sonum=6.0):
    """Hızlı yükselen, üstel sönen yumuşak zarf (tık sesi olmasın diye yükseliş var)."""
    yukselme = np.clip(t / yukselis, 0.0, 1.0)
    return yukselme * np.exp(-sonum * t)


def ton(frekans, sure, sonum=6.0, harmonikler=(1.0, 0.3, 0.1)):
    """Hafif harmonikli yumuşak bir ton."""
    t = zaman(sure)
    dalga = sum(g * np.sin(2 * math.pi * frekans * (i + 1) * t) for i, g in enumerate(harmonikler))
    return dalga * zarf(t, sonum=sonum)


def arka_arkaya(*parcalar, aralik=0.0):
    """Parçaları sırayla (isteğe bağlı aralıkla, üst üste binerek) birleştirir."""
    toplam = sum(len(p) for p in parcalar)
    sonuc = np.zeros(toplam)
    konum = 0
    for parca in parcalar:
        sonuc[konum:konum + len(parca)] += parca
        konum += max(1, len(parca) - int(aralik * ORNEKLEME))
    return sonuc[:konum + int(aralik * ORNEKLEME)]


def gurultu(sure, sonum=10.0, yumusatma=40):
    """Hareketli ortalamayla yumuşatılmış (alçak geçiren) gürültü."""
    t = zaman(sure)
    ham = np.random.default_rng(7).uniform(-1.0, 1.0, len(t))
    yumusak = np.convolve(ham, np.ones(yumusatma) / yumusatma, mode="same")
    return yumusak * zarf(t, sonum=sonum) * 3.0


def tiklama():
    return ton(1400.0, 0.05, sonum=80.0, harmonikler=(1.0,)) * 0.6


def onay():
    return arka_arkaya(ton(660.0, 0.09, 30.0), ton(990.0, 0.16, 18.0), aralik=0.03)


def hata():
    return arka_arkaya(ton(392.0, 0.11, 22.0, (1.0, 0.4, 0.2)), ton(294.0, 0.18, 14.0, (1.0, 0.4, 0.2)),
                       aralik=0.02) * 0.8


def emir():
    t = zaman(0.14)
    # Yukarı kayan kısa bir "vın": frekans 500'den 900'e çıkar.
    faz = 2 * math.pi * np.cumsum(500.0 + 400.0 * t / t[-1]) / ORNEKLEME
    return np.sin(faz) * zarf(t, sonum=20.0) * 0.7


def muharebe():
    t = zaman(0.45)
    # Davul benzeri, perdesi düşen alçak bir vuruş ve biraz gürültü.
    frekans = 110.0 * np.exp(-6.0 * t) + 45.0
    faz = 2 * math.pi * np.cumsum(frekans) / ORNEKLEME
    vurus = np.sin(faz) * zarf(t, sonum=7.0)
    return vurus + gurultu(0.45, sonum=18.0) * 0.35


def ele_gecirme():
    return arka_arkaya(ton(523.3, 0.12, 14.0), ton(659.3, 0.12, 14.0), ton(784.0, 0.3, 8.0), aralik=0.04)


def savas_ilani():
    t = zaman(0.75)
    titresim = 1.0 + 0.004 * np.sin(2 * math.pi * 5.0 * t)
    dalga = (np.sin(2 * math.pi * 220.0 * titresim * t) + 0.6 * np.sin(2 * math.pi * 330.0 * titresim * t)
             + 0.25 * np.sin(2 * math.pi * 440.0 * titresim * t))
    zarfi = np.clip(t / 0.06, 0.0, 1.0) * np.exp(-3.0 * t)
    return dalga * zarfi * 0.6


def uretim():
    # Çan: temel frekans ve uyumsuz üst kısmilerle uzun bir sönüm.
    t = zaman(0.6)
    dalga = (np.sin(2 * math.pi * 1046.5 * t) + 0.5 * np.sin(2 * math.pi * 2093.0 * t)
             + 0.25 * np.sin(2 * math.pi * 2794.0 * t))
    return dalga * zarf(t, sonum=6.0) * 0.6


def zafer():
    notalar = [523.3, 659.3, 784.0, 1046.5]
    return arka_arkaya(*[ton(f, 0.18 if i < 3 else 0.6, 10.0 if i < 3 else 3.5) for i, f in enumerate(notalar)],
                       aralik=0.03)


def kaybetme():
    notalar = [440.0, 392.0, 349.2, 261.6]
    return arka_arkaya(*[ton(f, 0.22 if i < 3 else 0.7, 8.0 if i < 3 else 3.0, (1.0, 0.2)) for i, f in enumerate(notalar)],
                       aralik=0.03) * 0.8


SESLER = {
    "click": tiklama,
    "confirm": onay,
    "error": hata,
    "order": emir,
    "battle": muharebe,
    "capture": ele_gecirme,
    "war": savas_ilani,
    "production": uretim,
    "victory": zafer,
    "defeat": kaybetme,
}


def yaz(yol, dalga):
    dalga = np.asarray(dalga, dtype=float)
    tepe = np.max(np.abs(dalga))
    if tepe > 0:
        dalga = dalga / tepe * TEPE
    # Sonda kısa bir sönümle sıfıra in (son örnekte tık olmasın).
    son = min(len(dalga), int(0.01 * ORNEKLEME))
    dalga[-son:] *= np.linspace(1.0, 0.0, son)
    ornekler = (dalga * 32767).astype(np.int16)
    with wave.open(str(yol), "wb") as dosya:
        dosya.setnchannels(1)
        dosya.setsampwidth(2)
        dosya.setframerate(ORNEKLEME)
        dosya.writeframes(ornekler.tobytes())


def main():
    CIKTI.mkdir(exist_ok=True)
    for ad, uretici in SESLER.items():
        dalga = uretici()
        yaz(CIKTI / (ad + ".wav"), dalga)
        print("%-11s %.2f sn" % (ad + ".wav", len(dalga) / ORNEKLEME))


if __name__ == "__main__":
    main()
