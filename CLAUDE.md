# CLAUDE.md

Bu depo **Altı Sancak** adlı oyunun kaynak kodudur: Android için, yatay ekranda
oynanan, sadeleştirilmiş bir büyük strateji oyunu. Godot 4.7, GDScript, 2D,
Mobile renderer.

Oyunun bütün kuralları, veri yapıları ve geliştirme adımları
[TASARIM.md](TASARIM.md) dosyasındadır. Kod yazmadan önce ilgili bölümü oku.
Bir kural değişecekse önce TASARIM.md güncellenir (14. bölüme de not düşülür), sonra kod.

## Kurallar

1. **Simülasyon mantığı görsel koddan ayrı tutulur.**
   - `scripts/sim/`: oyun durumu, zaman, hareket, savaş, ekonomi, yapay zekâ.
     Buradaki kod hiçbir şey çizmez, girdi okumaz ve görsel düğümlere dokunmaz;
     ekran olmadan çalıştırılıp sınanabilir olmalıdır.
   - Autoload'lar (ör. `Zaman`) düğümdür, çünkü `_process` gerekir; bunun dışında
     aynı kurala uyarlar.
   - `scripts/gorsel/` (harita, kamera) ve `scripts/arayuz/` (çubuklar, paneller)
     oyun durumunu doğrudan değiştirmez. Simülasyonun işlevlerini çağırır ve
     sinyallerini dinler.

2. **Tüm oyun verisi `data/` klasöründe JSON olarak durur.**
   - Ülke, bölge, birlik tipi, arazi ve denge sayıları koda gömülmez.
   - `data/` dosyaları oyun çalışırken değiştirilmez; kayıtlar `user://` altına yazılır.
   - `provinces.json` ve `countries.json` elle düzenlenmez; `tools/harita_uretici.gd`
     ile üretilir. Oyun çalışırken harita üretilmez.

3. **Fare değil dokunmatik ekran varsayılır.**
   - Üzerine gelme (hover), sağ tık ve klavye kısayolu kullanılmaz.
   - Dokunulabilir öğeler en az 96 × 96 px (1920 × 1080 temel çözünürlükte).
   - Bilgisayarda sınama için "Emulate Touch From Mouse" açıktır; ayrıca yalnızca
     fare tekerleğiyle yakınlaştırma desteklenir.
   - Harita girdisi `_unhandled_input` ile dinlenir ki arayüze gelen dokunuş haritaya geçmesin.

4. **Her seferinde sadece istenen adım yapılır, fazlası eklenmez.**
   - TASARIM.md'deki numaralı adımlardan yalnızca istenenler yapılır.
   - Sonraki adımların kodu, "ileride lazım olur" diye eklenen seçenekler ve
     TASARIM.md'de "Kapsam dışı" sayılan özellikler eklenmez.
   - Adım bitince TASARIM.md'de işaretlenir ve nasıl sınanacağı söylenir.

5. **HOI4'e ait isim, harita veya görsel kullanılmaz.**
   - Paradox oyunlarından ad, metin, simge, harita ya da ekran düzeni kopyalanmaz.
   - Gerçek ülke, şehir, bayrak ve tarihî kişi de kullanılmaz; dünya kurgusaldır.

6. **Açıklamalar ve kod yorumları Türkçe yazılır.**
   - Kullanıcıya verilen yanıtlar, kod yorumları, commit iletileri ve oyun içi
     metinler Türkçedir.

## Kod yazımı

- Statik tip kullanılır: her değişken, parametre ve dönüş değeri tiplidir.
- Sahneler sade tutulur (yalnızca kök düğüm); düğüm ağaçları script'ten kurulur.
- Değişken, işlev, sınıf ve JSON anahtarı adları Türkçedir ama Türkçe'ye özgü harf
  (ç, ğ, ı, ö, ş, ü) içermez: `bolge`, `ulke`, `guc`, `savas_coz()`.
- Script dosyaları Türkçe adlıdır (`harita_gorunumu.gd`). Klasörler, `data/` altındaki
  dosyalar ve ana sahne İngilizce adlıdır (`provinces.json`, `main.tscn`).
- Dosya adları `kucuk_harf_alt_cizgi` biçimindedir. Sınıf adları `BuyukHarf` ile yazılır.
- Ekranda görünen metinlerde ve yorumlarda Türkçe harfler kullanılır.

## Sınama

- Godot PATH'te değil; `%USERPROFILE%\Downloads\Godot_v4.7.2-stable_win64.exe\` klasöründeki
  `Godot_v4.7.2-stable_win64.exe` kullanılır (`_console.exe` sürümü yoldaki boşluk
  yüzünden çalışmıyor; çıktı için `Start-Process -RedirectStandardOutput` kullan).
- Hata denetimi: `--headless --path . --import`, ardından `--headless --path . --quit-after 120`.
- Yeni `class_name` eklendiyse önce `--import` çalıştırılmalıdır.
- Girdi taklit ederken `Input.parse_input_event` konumları **pencere pikseli** ister,
  1920 × 1080 birimini değil.

## Kullanıcı

Kullanıcı oyun geliştirmeye yeni başlıyor. Yaptığın şeyi kısa ve sade anlat;
Godot düzenleyicisinde elle yapılması gereken bir şey varsa adım adım yaz.
Yalnızca bu proje klasöründe çalış; kullanıcının diğer Godot projelerine dokunma.
