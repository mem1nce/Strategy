# CLAUDE.md

Bu depo, gerçek dünya haritasında geçen sadeleştirilmiş bir strateji oyununun kaynak
kodudur (çalışma adı: **Yerküre**). Android, yatay ekran. Godot 4.7, GDScript, 2D,
Mobile renderer.

Oyunun kuralları, veri yapısı ve yol haritası [TASARIM.md](TASARIM.md) dosyasındadır.
Kod yazmadan önce ilgili bölümü oku. Bir kural değişecekse önce TASARIM.md güncellenir,
sonra kod.

## Kurallar

1. **Simülasyon mantığı görsel koddan ayrı tutulur.**
   - `scripts/sim/`: dünya, ülkeler, bölgeler, çokgenler, sınırlar, oyun durumu, zaman
     (ileride birlik, savaş, ekonomi, yapay zekâ). Buradaki kod hiçbir şey çizmez, girdi okumaz ve
     görsel düğümlere dokunmaz; ekran olmadan çalıştırılıp sınanabilir olmalıdır.
   - Autoload'lar (ör. `Zaman`) düğümdür, çünkü `_process` gerekir; bunun dışında
     aynı kurala uyarlar.
   - `scripts/gorsel/` (harita, kamera) ve `scripts/arayuz/` (çubuklar, paneller)
     oyun durumunu doğrudan değiştirmez. Simülasyonun işlevlerini çağırır ve
     sinyallerini dinler.

2. **Tüm oyun verisi `data/` klasöründe JSON olarak durur.**
   - Ülke verisi ve denge sayıları koda gömülmez.
   - `data/` dosyaları oyun çalışırken değiştirilmez; kayıtlar `user://` altına yazılır.
   - `data/world.json` ve `data/regions.json` elle düzenlenmez; `python tools/dunya_donustur.py`
     ile `tools/kaynak/` altındaki Natural Earth verisinden üretilir. Oyun kaynak dosyaları okumaz.
   - Dönüştürücü ürettiği veriyi doğrular; doğrulama hatası varsa dosya yazmaz. Hata,
     denetimi gevşeterek değil nedenini düzelterek giderilir.

3. **Harita "çokgen → bölge → sahip ülke" mantığıyla çalışır.**
   - Harita kodu ülkeyi değil çokgeni çizer; rengini çokgenin bölgesinin `sahip` alanından alır.
     Sınır çizgisinin türü (ülke sınırı mı, bölge sınırı mı) de iki yandaki bölgelerin
     sahibine bakılarak belirlenir.
   - İleride bölgeler el değiştirecek; yeni kod "bir bölgenin sahibi hiç değişmez"
     varsayımını içermemelidir. Sahiplik değişince `HaritaGorunumu.yenile()` çağrılır.
   - Yüzlerce bölge tek tek düğüm yapılmaz; dolgular ve sınırlar toplu ağlarla (mesh) çizilir.

4. **Fare değil dokunmatik ekran varsayılır.**
   - Üzerine gelme (hover), sağ tık ve klavye kısayolu kullanılmaz.
   - Dokunulabilir öğeler en az 96 × 96 px (1920 × 1080 temel çözünürlükte).
   - Arayüz güvenli alanın (safe area) içinde kalır.
   - Bilgisayarda sınama için "Emulate Touch From Mouse" açıktır; ayrıca yalnızca
     fare tekerleğiyle yakınlaştırma desteklenir.
   - Harita girdisi `_unhandled_input` ile dinlenir ki arayüze gelen dokunuş haritaya geçmesin.

5. **Her seferinde sadece istenen aşama yapılır, fazlası eklenmez.**
   - TASARIM.md'deki yol haritasından yalnızca istenen yapılır.
   - Sonraki aşamaların kodu ve "ileride lazım olur" diye eklenen seçenekler yazılmaz.
   - Aşama bitince TASARIM.md'de işaretlenir ve nasıl sınanacağı söylenir.

6. **Başka oyunlardan içerik alınmaz.**
   - HOI4 ya da başka bir oyundan ad, metin, simge, harita ya da ekran düzeni kopyalanmaz.
   - Harita verisi yalnızca Natural Earth'ten (kamu malı) gelir.

7. **Açıklamalar ve kod yorumları Türkçe yazılır.**
   - Kullanıcıya verilen yanıtlar, kod yorumları, commit iletileri ve oyun içi
     metinler Türkçedir.

## Kod yazımı

- Statik tip kullanılır: her değişken, parametre ve dönüş değeri tiplidir.
- Sahneler sade tutulur (yalnızca kök düğüm); düğüm ağaçları script'ten kurulur.
- Değişken, işlev, sınıf ve JSON anahtarı adları Türkçedir ama Türkçe'ye özgü harf
  (ç, ğ, ı, ö, ş, ü) içermez: `ulke`, `cokgen`, `nufus`, `oyuncuyu_sec()`.
- Script dosyaları Türkçe adlıdır (`harita_gorunumu.gd`). Klasörler, `data/` altındaki
  dosyalar ve ana sahne İngilizce adlıdır (`world.json`, `main.tscn`).
- Dosya adları `kucuk_harf_alt_cizgi` biçimindedir. Sınıf adları `BuyukHarf` ile yazılır.
- Ekranda görünen metinlerde ve yorumlarda Türkçe harfler kullanılır.

## Sınama

- Windows'ta Godot PATH'te değil; `%USERPROFILE%\Downloads\Godot_v4.7.2-stable_win64.exe\`
  klasöründeki `Godot_v4.7.2-stable_win64.exe` kullanılır (`_console.exe` sürümü yoldaki
  boşluk yüzünden çalışmıyor; çıktı için `Start-Process -RedirectStandardOutput` kullan).
- macOS'ta Godot PATH'te değil; `~/Downloads/Godot.app/Contents/MacOS/Godot` kullanılır.
- Hata denetimi: `--headless --path . --import`, ardından `--headless --path . --quit-after 120`.
- Yeni `class_name` eklendiyse önce `--import` çalıştırılmalıdır.
- **Simülasyon sınamaları:** `tests/calistirici.gd`, `tests/sim/` altındaki sınıflardaki
  `sina_` ile başlayan işlevleri çalıştırır (boş metin = geçti, metin = hata açıklaması).
  Çalıştırmak için: `Godot --headless --path . --script res://tests/calistirici.gd`.
  Sınamalar oyuncunun gerçek kaydına dokunmaz: çalıştırıcı `KayitYoneticisi.kayit_dosyasi`'nı
  `user://sinama_kayit.json` yapar.
  Yeni bir simülasyon özelliği eklenince (yol bulma, muharebe, işgal, teslim, kayıt/yükleme…)
  `tests/sim/` altına yeni bir sınama dosyası eklenir ve `tests/calistirici.gd`'deki
  `SINAMA_SINIFLARI` listesine eklenir.
- **Uzun koşu sınaması:** şimdilik `tests/sim/zaman_testi.gd`'deki `sina_bes_yil_hatasiz_ilerler`
  5 oyun yılını (43800 saat) `Zaman.bir_saat_ilerle()` ile doğrudan, çerçeveye bağlı olmadan
  ilerletir ve özet yazdırır. Yapay zekâ, savaş ve ekonomi eklendikçe bu sınama, yalnızca
  yapay zekâ ülkeleriyle gerçek bir oyun döngüsü ilerletecek şekilde büyütülmeli.
- **Ekran görüntüsü:** oyun `-- --ekran-goruntusu <dosya yolu>` ile (headless OLMADAN)
  açılırsa 2 saniye bekleyip ekranı PNG olarak kaydeder ve kapanır:
  `Godot --path . -- --ekran-goruntusu /tam/yol/goruntu.png`. Dosya yolunun klasörü önceden
  var olmalı. Her görsel değişiklikten sonra çalıştırıp görüntüye bakılır.
- Girdi taklit ederken `Input.parse_input_event` konumları **pencere pikseli** ister,
  1920 × 1080 birimini değil.
- Python bu bilgisayarda kuruludur; `tools/` altındaki betikler Python'la yazılır.
  Dönüştürücü `shapely` kullanır (`python -m pip install -r tools/requirements.txt`).
  `tools/.gdignore` sayesinde Godot bu klasörü görmez.
- Açılışta konsola "Dünya yüklendi: … ülke, … bölge, … çokgen, üçgenlenemeyen …" yazılır.

## Kullanıcı

Kullanıcı oyun geliştirmeye yeni başlıyor. Yaptığın şeyi kısa ve sade anlat;
Godot düzenleyicisinde elle yapılması gereken bir şey varsa adım adım yaz.
Yalnızca bu proje klasöründe çalış; kullanıcının diğer Godot projelerine dokunma.
