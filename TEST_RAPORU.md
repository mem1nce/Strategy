# Test raporu — Windows bilgisayar

**Tarih:** 6 Ekim 2026
**Sürüm:** `main`, commit `bdbbeff` ("DEVAM.md: H) DENGE performans teşhisi kaydedildi")
**Kapsam:** Kurulum, otomatik sınamalar, uzun koşu, ekran görüntüleri. Oyun koduna
dokunulmadı; bulunan hatalar düzeltilmedi, yalnızca listelendi.

## Ortam

| | |
|---|---|
| İşletim sistemi | Windows 11 Pro 64 bit (10.0.26200) |
| İşlemci / bellek | Intel Core i5-12500H, 15,6 GB |
| Ekran kartı | NVIDIA GeForce RTX 3050 Laptop (Godot: D3D12 12_0, Forward Mobile) |
| Godot | 4.7.2.stable.official (ed1daf0bf) — `project.godot` 4.7 bekliyor, **uyumlu** |
| Godot'nun yeri | `%USERPROFILE%\Downloads\Godot_v4.7.2-stable_win64.exe\` (PATH'te değil) |
| Python | 3.12.10 (shapely kurulu; dönüştürücü bu testte çalıştırılmadı) |

## Kurulum

- Depo zaten klonluydu; `git pull` ile Mac'teki 23 commit alındı, çalışma ağacı temiz.
- Headless import hatasız (`--headless --path . --import`).
- Headless açılış hatasız: "Dünya yüklendi: 176 ülke, 516 bölge, 637 çokgen,
  üçgenlenemeyen 0."

## Otomatik sınamalar

| Sınama | Sonuç |
|---|---|
| `tests/calistirici.gd` (bütün headless sınamalar) | **99 / 99 geçti**, 9,1 sn |
| Takımdaki 5 yıllık koşu (`zaman_testi.gd`, yalnızca Zaman) | Geçti; 43800 saat, son tarih 31 Aralık 2030 |
| 5 yıllık tam YZ koşusu (176 ülke YZ'de, geçici ölçüm betiği) | Hatasız bitti, **195,5 sn (3,26 dk)** |

Konsolda bir `ERROR: Kayıt dosyasının sürümü (999.0) … uyuşmuyor` satırı çıkıyor. Bu
bir hata değil: `kayit_testi.gd` sürüm uyuşmazlığını bilerek deniyor.

**Uzun koşu ayrıntısı:** Öbür bilgisayardaki ~3,3 dakikalık ölçüm DEVAM.md'ye göre 30 günlük
koşudan doğrusal tahmindi; burada 5 yılın tamamı gerçekten koşturuldu ve aynı sonuç çıktı.
Yıllara göre süre: 31,5 / 39,2 / 41,6 / 41,6 / 41,7 sn. Hayatta kalan ülke 176 → 159 → 151
→ 149 → 146 → 144; toplam tümen 1414–1464 arasında sabit. 5. yılın sonunda en güçlüler:
Japonya, Almanya, Birleşik Krallık, Fransa, ABD. CLAUDE.md'deki "2 dakikadan kısa" hedefi
bu bilgisayarda da aşılıyor; bilgisayara özgü bir yavaşlık yok.

## Ekran görüntüleri

16:9 (1280 × 720 pencere = 1920 × 1080 taban) ve 20:9 (1600 × 720 pencere = 2400 × 1080
taban) için şu ekranlar alındı ve tek tek incelendi: ana menü, ülke seçimi (harita ve
panel), oyun ekranı, üretim göstergesi ve birlik kartı, güç sıralaması, zaman akarken.

Görüntüler geçici bir sınama betiğiyle alındı; oyun kodundaki `--ekran-goruntusu` aracı
yalnızca açılış ekranını çekebildiği için menüye ve düğmelere dokunuşlar betikten taklit
edildi. "Üretim" ekranı için hazine elle artırılıp `Oyun.tumen_sirala()` /
`fabrika_sirala()` doğrudan çağrıldı (oyunda bunun için düğme yok, bkz. Hata 3).

| Ekran | 16:9 | 20:9 |
|---|---|---|
| Ana menü | Düzgün | Düzgün |
| Ülke seçimi — harita | Üst çubukta "Sıralama" düğmesi ekrana sığmıyor (Hata 4) | Düzgün |
| Ülke seçimi — panel | **"Bu ülkeyle oyna" düğmesi sağdan taşıyor** (Hata 1) | Düzgün |
| Oyun ekranı | Düzgün; bazı yerlerde tümen kutuları üst üste (Hata 6) | Düzgün |
| Üretim göstergesi + birlik kartı | "İnşa: Tümen (120 sa) +1" doğru, geri sayıyor | Düzgün |
| Güç sıralaması | İlk 10 + "23. Türkiye" doğru; panel alt panele değiyor (Hata 5) | Düzgün |
| Zaman akarken | 3x'te tarih ilerliyor, "Durdur"/"3x" doğru vurgulu | Düzgün |

**Bu bilgisayara özgü fark:** Bulunmadı. Bütün sınamalar geçti, görüntülerde Windows'a ya
da bu ekran kartına özgü bir bozulma (yazı tipi, renk, çizgi, Türkçe harf) yok. Aşağıdaki
yerleşim hataları ekran oranına bağlı; Mac'te de 16:9 pencerede aynı çıkması beklenir.

## Hata listesi (önem sırasıyla)

### Yüksek

1. **16:9'da "Bu ülkeyle oyna" düğmesi ekrandan taşıyor.** Ülke seçim panelinde
   "Komşuları göster" ve "Bu ülkeyle oyna" düğmeleri sağa sığmıyor; "Bu ülkeyle oyna"nın
   yarısı ekran dışında ("Bu ülke…" görünüyor). Görünen kısma basılabildiği için akış
   tamamen kırılmıyor, ama oyunun ilk adımı. 16:10 ve 4:3 tabletlerde daha kötü olması
   beklenir. 20:9'da sorun yok.

2. **Sınamaları çalıştırmak gerçek kayıt dosyasını siliyor.** `tests/sim/kayit_testi.gd`
   ayrı bir sınama yolu yerine gerçek `user://kayit.json`'u kullanıyor ve her sınamada
   siliyor. Bu bilgisayarda bir kayıt vardı; sınamalar onu gerçekten sildi. Sınamalardan önce
   yedeklendiği için geri yüklendi. Oyuncu kaydı olan bir bilgisayarda
   sınama çalıştıran herkes ilerlemesini kaybeder.

### Orta

3. **Oyuncunun üretim yapacağı arayüz yok.** `Oyun.tumen_sirala()` ve `fabrika_sirala()`
   sim katmanında var, ama hiçbir düğme onları çağırmıyor (DEVAM.md'de de "bilinçli
   olarak dahil edilmedi" notu var). Oyuncu tümen ya da fabrika kuramıyor; tek yol
   "Ordu: YZ"yi açıp YZ'nin kurmasını beklemek. Bir "üretim paneli" bulunmadığı için bu
   ekranın görüntüsü yalnızca üst çubuktaki gösterge üzerinden alınabildi.

4. **16:9'da ülke seçilmeden önce "Sıralama" düğmesi görünmüyor.** "Ülkeni seç" yazısı
   ortada yer kapladığı için sağdaki düğme paneli taşıyor; "Ordu: YZ" kesik, "Sıralama"
   ekran dışında. Ülke seçilince yazı kalkıyor ve hepsi sığıyor. (Bu düğmeler o anda
   zaten kilitli olduğu için oynanışı engellemiyor.)

### Düşük

5. **Güç sıralaması paneli alt panele değiyor.** 16:9'da panelin son satırı ("23. Türkiye")
   alt bölge/birlik panelinin üst kenarına biniyor.

6. **Tümen kutuları yazılarla ve birbirleriyle üst üste.** Sık bölgelerde (Kıbrıs, İsrail,
   Lübnan çevresi) kutular başkent yıldızlarının ve bölge adlarının üstüne biniyor.

7. **Onay pencerelerinin düğmeleri küçük.** "Yeni oyun" onayındaki "Tamam" düğmesi
   yaklaşık 71 × 70 taban piksel; CLAUDE.md'deki 96 × 96 sınırının altında. Pencereler
   Godot'nun varsayılan `ConfirmationDialog`'u; aynı durum "Kaydı sil" ve "Savaş ilan et"
   onaylarında da beklenir. Ekran görüntüsünde alınamadı, düğüm boyutundan ölçüldü.

8. **Ülke seçim ekranında seçili bölgenin adı ülke adıyla üst üste.** Uzak görünümde
   Türkiye'ye dokununca "Ankara" yazısı ve yıldızı "Türkiye" yazısının üstüne biniyor.

9. **Uzun koşu süresi hedefin üstünde.** 5 yıllık tam YZ koşusu 195,5 sn; hedef 120 sn.
   DEVAM.md'deki teşhisle (önbelleksiz `Dunya.ulkenin_bolgeleri()`) uyumlu, yeni bir
   bulgu değil.

## Not

- Testlerin bu bilgisayarda bıraktığı kalıntı yok: kayıt dosyası eski hâline getirildi
  (SHA-1 aynı), geçici sınama ve ölçüm betikleri depoya eklenmedi.
- Elle test için: [TEST_LISTESI.md](TEST_LISTESI.md).
