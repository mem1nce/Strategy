#!/usr/bin/env python3
"""Oyunun arayüz ve harita simgelerini tek bir stilde SVG olarak yazar (art/icons/).

Kullanım (proje klasöründen):
    python tools/simgeler_uret.py

Stil (bkz. STIL.md): 24 x 24 birimlik ızgara, tek çizgi kalınlığı (2 birim), yuvarlak uç ve
köşeler, dolgu yok (yalnızca birkaç küçük nokta/dolgu vurgusu), beyaz çizgi. Oyunda renk
`modulate` ile verilir. Dosyalar 96 x 96 piksel boyutlu yazılır ki Godot onları keskin içe
aktarsın. Hiçbir simge başka bir oyundan alınmamıştır; hepsi burada elle tanımlanmıştır.
"""

from pathlib import Path

KOK = Path(__file__).resolve().parent.parent
CIKTI = KOK / "art" / "icons"
CIZGI = 2.0

# Her simge: SVG öğelerinin listesi (yalnızca şekil; stil aşağıda ortak verilir).
# "d:" ile başlayan öğeler dolgulu çizilir.
SIMGELER = {
    # --- Kaynaklar ve istatistikler ---
    "para": ['<circle cx="12" cy="12" r="8"/>', '<path d="M12 7v10M9.5 9.5h4a1.75 1.75 0 0 1 0 3.5h-3a1.75 1.75 0 0 0 0 3.5h4"/>'],
    "gelir": ['<path d="M4 17l5-5 4 3 7-7"/>', '<path d="M15 8h5v5"/>'],
    "sanayi": ['<path d="M3 20V10l5 3V10l5 3V6h4v14z"/>', '<path d="M7 17h2M12 17h2"/>'],
    "ordu": ['<path d="M12 3l7 3v5c0 5-3 8-7 10c-4-2-7-5-7-10V6z"/>'],
    "nufus": ['<circle cx="9" cy="8" r="3"/>', '<path d="M3 20c0-3.5 2.7-6 6-6s6 2.5 6 6"/>',
              '<circle cx="17" cy="9" r="2.5"/>', '<path d="M16 14.2c2.8.3 5 2.6 5 5.8"/>'],
    "tarih": ['<rect x="3.5" y="5" width="17" height="15" rx="2"/>', '<path d="M3.5 10h17M8 3v4M16 3v4"/>'],
    "alan": ['<path d="M4 7l5-3 6 3 5-3v13l-5 3-6-3-5 3z"/>', '<path d="M9 4v13M15 7v13"/>'],
    # --- Zaman denetimi ---
    "oynat": ['d:<path d="M8 5v14l11-7z"/>'],
    "duraklat": ['<path d="M9 5v14M15 5v14"/>'],
    # --- Tümen türleri (çerçeve içinde sade işaret) ---
    "piyade": ['<rect x="3" y="6" width="18" height="12" rx="2"/>', '<path d="M3.5 6.5l17 11M20.5 6.5l-17 11"/>'],
    "zirhli": ['<rect x="3" y="6" width="18" height="12" rx="2"/>', '<rect x="7" y="9.5" width="10" height="5" rx="2.5"/>'],
    "topcu": ['<rect x="3" y="6" width="18" height="12" rx="2"/>', 'd:<circle cx="12" cy="12" r="2.6"/>'],
    # --- Harita işaretleri ---
    "muharebe": ['<path d="M5 4l9 9M4 5l1-1M14 13l-2 4 2 2 2-2 4-2-2-2"/>',
                 '<path d="M19 4l-9 9M20 5l-1-1M10 13l2 4-2 2-2-2-4-2 2-2"/>'],
    "tahkimat": ['<path d="M4 20V8h3v3h3V8h4v3h3V8h3v12z"/>', '<path d="M10 20v-4a2 2 0 0 1 4 0v4"/>'],
    "fabrika": ['<path d="M3 20V10l5 3V10l5 3V6h4v14z"/>', '<path d="M7 17h2M12 17h2"/>'],
    "baskent": ['<circle cx="12" cy="12" r="9"/>', 'd:<path d="M12 6.5l1.6 3.4 3.7.4-2.8 2.5.8 3.7L12 14.6l-3.3 1.9.8-3.7-2.8-2.5 3.7-.4z"/>'],
    # --- Paneller ve kipler ---
    "teknoloji": ['<path d="M9 3h6M10 3v6l-5 9a2 2 0 0 0 1.8 3h10.4a2 2 0 0 0 1.8-3l-5-9V3"/>', '<path d="M7.5 15h9"/>'],
    "siralama": ['<path d="M5 20V12M12 20V6M19 20v-5"/>', '<path d="M3 20h18"/>'],
    "ayarlar": ['<circle cx="12" cy="12" r="3"/>',
                '<path d="M12 2.5v3M12 18.5v3M21.5 12h-3M5.5 12h-3M18.7 5.3l-2.1 2.1M7.4 16.6l-2.1 2.1M18.7 18.7l-2.1-2.1M7.4 7.4L5.3 5.3"/>',
                '<circle cx="12" cy="12" r="6.5"/>'],
    "siyasi": ['<path d="M5 21V4"/>', '<path d="M5 4h11l-2 4 2 4H5"/>'],
    "diplomasi": ['<circle cx="9" cy="12" r="5"/>', '<circle cx="15" cy="12" r="5"/>'],
    "ekonomi": ['<path d="M4 20h16"/>', '<path d="M6 16v-3M10 16v-6M14 16v-4M18 16V7"/>'],
    "savas": ['<path d="M5 4l9 9M4 5l1-1M14 13l-2 4 2 2 2-2 4-2-2-2"/>',
              '<path d="M19 4l-9 9M20 5l-1-1M10 13l2 4-2 2-2-2-4-2 2-2"/>'],
    "baris": ['<path d="M5 21V4"/>', '<path d="M5 4c3-1.5 5 1.5 8 0s4-1 6 0v8c-2-1-3-1.5-6 0s-5-1.5-8 0"/>'],
    "bildirim": ['<path d="M6 16V11a6 6 0 0 1 12 0v5l2 2H4z"/>', '<path d="M10 20a2 2 0 0 0 4 0"/>'],
    "uretim": ['<circle cx="12" cy="12" r="3.5"/>', '<path d="M12 3v3M12 18v3M3 12h3M18 12h3"/>', '<circle cx="12" cy="12" r="7.5"/>'],
    "sis": ['<path d="M3 12s3.5-6 9-6 9 6 9 6-3.5 6-9 6-9-6-9-6z"/>', '<circle cx="12" cy="12" r="2.5"/>', '<path d="M4 4l16 16"/>'],
    "kapat": ['<path d="M6 6l12 12M18 6L6 18"/>'],
    "bilgi": ['<circle cx="12" cy="12" r="9"/>', '<path d="M12 11v6"/>', 'd:<circle cx="12" cy="7.5" r="1.2"/>'],
    "ses": ['<path d="M4 9h4l5-4v14l-5-4H4z"/>', '<path d="M17 9a4 4 0 0 1 0 6M19.5 6.5a7.5 7.5 0 0 1 0 11"/>'],
    "lisans": ['<path d="M6 3h9l4 4v14H6z"/>', '<path d="M15 3v4h4M9 12h7M9 16h7"/>'],
}


def svg(ogeler):
    govde = []
    for oge in ogeler:
        if oge.startswith("d:"):
            govde.append('<g fill="#ffffff" stroke="none">%s</g>' % oge[2:])
        else:
            govde.append(oge)
    return ('<svg xmlns="http://www.w3.org/2000/svg" width="96" height="96" viewBox="0 0 24 24" fill="none" '
            'stroke="#ffffff" stroke-width="%g" stroke-linecap="round" stroke-linejoin="round">%s</svg>\n'
            % (CIZGI, "".join(govde)))


def main():
    CIKTI.mkdir(parents=True, exist_ok=True)
    for ad, ogeler in SIMGELER.items():
        (CIKTI / (ad + ".svg")).write_text(svg(ogeler), encoding="utf-8")
    print("%d simge yazıldı: %s" % (len(SIMGELER), CIKTI.relative_to(KOK)))


if __name__ == "__main__":
    main()
