# CLAUDE.md

Bu depo **Altı Sancak** adlı oyunun kaynak kodudur: Android için, yatay ekranda
oynanan, sadeleştirilmiş bir büyük strateji oyunu. Godot 4.7, GDScript, 2D,
Mobile renderer.

Oyunun bütün kuralları, veri yapıları ve geliştirme adımları
[TASARIM.md](TASARIM.md) dosyasındadır. Kod yazmadan önce ilgili bölümü oku.
Bir kural değişecekse önce TASARIM.md güncellenir, sonra kod.

## Kurallar

1. **Simülasyon mantığı görsel koddan ayrı tutulur.**
   - `scripts/sim/`: oyun durumu, zaman, hareket, savaş, ekonomi, yapay zekâ.
     Buradaki kod sahne, düğüm, girdi ya da çizimle ilgili hiçbir şeye dokunmaz;
     ekran olmadan çalıştırılıp sınanabilir olmalıdır.
   - `scripts/gorsel/` (harita, birlik simgeleri, kamera) ve `scripts/arayuz/`
     (çubuklar, paneller, menüler) oyun durumunu doğrudan değiştirmez.
     Simülasyonun emir işlevlerini çağırır ve sinyallerini dinler.

2. **Tüm oyun verisi `data/` klasöründe JSON olarak durur.**
   - Ülke, bölge, birlik tipi, arazi ve denge sayıları koda gömülmez.
   - `data/` dosyaları oyun çalışırken değiştirilmez; kayıtlar `user://` altına yazılır.

3. **Fare değil dokunmatik ekran varsayılır.**
   - Üzerine gelme (hover), sağ tık, tekerlek ve klavye kısayolu kullanılmaz.
   - Dokunulabilir öğeler en az 96 × 96 px (1280 × 720 temel çözünürlükte).
   - Bilgisayarda sınama için yalnızca Godot'nun "fareyle dokunma taklidi" kullanılır.

4. **Her seferinde sadece istenen adım yapılır, fazlası eklenmez.**
   - TASARIM.md'deki numaralı adımlardan yalnızca istenen yapılır.
   - Sonraki adımların kodu, "ileride lazım olur" diye eklenen seçenekler ve
     TASARIM.md'de "Kapsam dışı" sayılan özellikler eklenmez.
   - Adım bitince nasıl sınanacağı söylenir.

5. **HOI4'e ait isim, harita veya görsel kullanılmaz.**
   - Paradox oyunlarından ad, metin, simge, harita ya da ekran düzeni kopyalanmaz.
   - Gerçek ülke, şehir, bayrak ve tarihî kişi de kullanılmaz; dünya kurgusaldır.

6. **Açıklamalar ve kod yorumları Türkçe yazılır.**
   - Kullanıcıya verilen yanıtlar, kod yorumları, commit iletileri ve oyun içi
     metinler Türkçedir.

## Adlandırma

- Dosya, klasör, değişken, işlev ve JSON anahtarı adlarında Türkçe'ye özgü
  harf (ç, ğ, ı, ö, ş, ü) kullanılmaz: `bolge`, `ulke`, `guc`, `savas_coz()`.
- Ekranda görünen metinlerde ve yorumlarda Türkçe harfler kullanılır.
- Dosya adları `kucuk_harf_alt_cizgi` biçimindedir. Sınıf adları `BuyukHarf` ile yazılır.

## Kullanıcı

Kullanıcı oyun geliştirmeye yeni başlıyor. Yaptığın şeyi kısa ve sade anlat;
Godot düzenleyicisinde elle yapılması gereken bir şey varsa adım adım yaz.
