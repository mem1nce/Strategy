# CLAUDE.md

Bu depo, gerçek dünya haritasında geçen sadeleştirilmiş bir strateji oyununun kaynak
kodudur (çalışma adı: **Yerküre**). Android, yatay ekran. Godot 4.7, GDScript, 2D,
Mobile renderer.

Oyunun kuralları, veri yapısı ve yol haritası [TASARIM.md](TASARIM.md) dosyasındadır.
Kod yazmadan önce ilgili bölümü oku. Bir kural değişecekse önce TASARIM.md güncellenir,
sonra kod.

## Kurallar

1. **Simülasyon mantığı görsel koddan ayrı tutulur.**
   - `scripts/sim/`: dünya, ülkeler, çokgenler, oyun durumu, zaman (ileride birlik,
     savaş, ekonomi, yapay zekâ). Buradaki kod hiçbir şey çizmez, girdi okumaz ve
     görsel düğümlere dokunmaz; ekran olmadan çalıştırılıp sınanabilir olmalıdır.
   - Autoload'lar (ör. `Zaman`) düğümdür, çünkü `_process` gerekir; bunun dışında
     aynı kurala uyarlar.
   - `scripts/gorsel/` (harita, kamera) ve `scripts/arayuz/` (çubuklar, paneller)
     oyun durumunu doğrudan değiştirmez. Simülasyonun işlevlerini çağırır ve
     sinyallerini dinler.

2. **Tüm oyun verisi `data/` klasöründe JSON olarak durur.**
   - Ülke verisi ve denge sayıları koda gömülmez.
   - `data/` dosyaları oyun çalışırken değiştirilmez; kayıtlar `user://` altına yazılır.
   - `data/world.json` elle düzenlenmez; `python tools/dunya_donustur.py` ile
     `tools/kaynak/` altındaki Natural Earth verisinden üretilir. Oyun kaynak dosyayı okumaz.

3. **Harita "çokgen + sahip ülke" mantığıyla çalışır.**
   - Harita kodu ülkeyi değil çokgeni çizer ve rengini `sahip` alanından alır.
   - İleride ülkeler bölgelere ayrılacak; yeni kod buna engel olacak varsayımlar
     (ör. "bir çokgenin sahibi hiç değişmez") içermemelidir.

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

- Godot PATH'te değil; `%USERPROFILE%\Downloads\Godot_v4.7.2-stable_win64.exe\` klasöründeki
  `Godot_v4.7.2-stable_win64.exe` kullanılır (`_console.exe` sürümü yoldaki boşluk
  yüzünden çalışmıyor; çıktı için `Start-Process -RedirectStandardOutput` kullan).
- Hata denetimi: `--headless --path . --import`, ardından `--headless --path . --quit-after 120`.
  Açılışta konsola "Dünya yüklendi: … ülke, … çokgen, üçgenlenemeyen …" yazılır.
- Yeni `class_name` eklendiyse önce `--import` çalıştırılmalıdır.
- Girdi taklit ederken `Input.parse_input_event` konumları **pencere pikseli** ister,
  1920 × 1080 birimini değil.
- Python ve Node bu bilgisayarda kuruludur; `tools/` altındaki betikler Python'la yazılır.
  `tools/.gdignore` sayesinde Godot bu klasörü görmez.

## Kullanıcı

Kullanıcı oyun geliştirmeye yeni başlıyor. Yaptığın şeyi kısa ve sade anlat;
Godot düzenleyicisinde elle yapılması gereken bir şey varsa adım adım yaz.
Yalnızca bu proje klasöründe çalış; kullanıcının diğer Godot projelerine dokunma.
