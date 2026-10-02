# TASARIM — Yerküre (çalışma adı)

Bu belge oyunun tek tasarım kaynağıdır. Bir kural değişecekse önce burası güncellenir.

## 1. Oyun

Gerçek dünya haritasında geçen, sadeleştirilmiş bir strateji oyunu. Tek oyunculu,
Android, yatay ekran. Godot 4.7, GDScript, 2D, Mobile renderer.

Oyuncu haritadan bir ülke seçer ve onu yönetir. Zaman 1 Ocak 2026'da başlar,
durdurulabilir ve üç hızda akar; bitiş tarihi yoktur.

Şu an yalnızca temel vardır: dünya haritası, kamera, ülke seçimi ve zaman.
Birlik, savaş, ekonomi ve yapay zekâ henüz yoktur (bkz. 8. bölüm).

"Yerküre" geçici bir çalışma adıdır; kalıcı ad sonra seçilecek.

## 2. Harita verisi

- **Kaynak:** Natural Earth'ün kamu malı ülke verisi,
  `tools/kaynak/ne_110m_admin_0_countries.geojson` (1:110 milyon ölçek, 177 kayıt).
- **Dönüştürücü:** `tools/dunya_donustur.py` kaynağı `data/world.json` dosyasına çevirir.
  Çalıştırmak için proje klasöründe: `python tools/dunya_donustur.py`
- **Oyun yalnızca `data/world.json` dosyasını okur.** Kaynak dosya daha ayrıntılısıyla
  (ör. 1:50 milyon) değiştirilip dönüştürücü yeniden çalıştırılabilir; oyun kodu değişmez.

Dönüştürücünün yaptıkları:

- Koordinatları **Miller silindirik projeksiyonla** düzleme çevirir. Harita 4096 birim
  genişliğinde, 2066 birim yüksekliğindedir (84,5° kuzey ile 58° güney arası).
- **Antarktika'yı çıkarır.** Geriye 176 ülke, 279 çokgen kalır.
- Polygon ve MultiPolygon'u destekler: adalar ayrı çokgendir, aynı ülkeye aittir.
- İç delikleri yok sayar (Güney Afrika'nın içindeki Lesotho boşluğu gibi).
- Art arda tekrar eden noktaları, çok küçük çokgenleri ve alanı olmayan sivri uçları atar.
- **Komşuluk:** iki ülke ortak bir sınır noktası paylaşıyorsa komşudur (delikler dahil).
- **Renk:** `MAPCOLOR9` alanını kullanır; komşu iki ülke aynı rengi alırsa birini değiştirir.

### `data/world.json`

```json
{
	"kaynak": "Natural Earth (kamu malı) - ne_110m_admin_0_countries.geojson",
	"projeksiyon": "miller",
	"genislik": 4096,
	"yukseklik": 2066,
	"ulkeler": [
		{
			"id": "TUR",
			"ad": "Türkiye",
			"kita": "Asya",
			"nufus": 83429615,
			"gsyh_milyon_dolar": 761425,
			"renk": 8,
			"etiket": [2440.63, 847.61],
			"komsular": ["ARM", "AZE", "BGR", "GEO", "GRC", "IRN", "IRQ", "SYR"],
			"cokgenler": [
				[[2557.41, 876.36], [2551.96, 878.58], [2547.97, 875.24]],
				[[2345.15, 814.14], [2356.74, 809.85], [2366.54, 811.68]]
			]
		}
	]
}
```

| Alan | Kaynaktaki karşılığı | Açıklama |
|---|---|---|
| `id` | `ADM0_A3` | Üç harfli ülke kodu |
| `ad` | `NAME_TR` (yoksa `NAME`) | Türkçe ad |
| `kita` | `CONTINENT` | Türkçeye çevrilir |
| `nufus` | `POP_EST` | Kişi |
| `gsyh_milyon_dolar` | `GDP_MD` | Milyon dolar |
| `renk` | `MAPCOLOR9` | 1–9 arası renk indeksi |
| `etiket` | `LABEL_X`, `LABEL_Y` | Ülke adının yazılacağı nokta |
| `komsular` | — | Komşu ülke id'leri |
| `cokgenler` | geometri | Her biri `[x, y]` noktalarından oluşan liste; büyük parça başta |

Formüllerde kullanılan sabitler `data/balance.json` dosyasındadır (şimdilik yalnızca zaman).

### Veriyle ilgili bilinmesi gerekenler

- Bu ölçekte çok küçük ülkeler **yoktur** (ör. Singapur, Malta, Bahreyn, Vatikan).
- Sınırlar Natural Earth'ün "fiilî durum" çizimidir; oyunun bir görüşünü yansıtmaz.
  Kaynakta ayrı kayıt olan tartışmalı ya da bağımlı yerler ayrı ülke gibi çizilir:
  Batı Sahra, Kuzey Kıbrıs, Somaliland, Kosova, Tayvan, Filistin, Falkland Adaları,
  Grönland, Porto Riko, Yeni Kaledonya, Fransız Güney Toprakları.
- Adlar kaynaktaki `NAME_TR` alanından gelir (ör. "Çin Halk Cumhuriyeti", "Beyaz Rusya").

## 3. Harita görünümü

- Harita **"çokgen + sahip ülke"** mantığıyla çalışır: her çokgen, sahibi olan ülkenin
  rengini alır. Şimdilik en küçük birim ülkedir ve sahiplik değişmez. İleride ülkeler
  bölgelere ayrılınca her bölge kendi çokgenine ve sahibine kavuşur; çizim kodu aynı kalır.
- Deniz düz, koyu mavi-gri bir arka plandır.
- Ülkeler renk indeksine göre dokuz sakin renkten birini alır; komşular farklı renktedir.
- Çokgenler büyükten küçüğe çizilir; iç içe ülkelerde küçük olan üstte kalır (Lesotho).
- Sınır çizgileri, çerçeveler ve yazılar yakınlıktan bağımsız olarak ekranda hep aynı
  kalınlıkta ve boyutta görünür.
- **Ülke adları:** bir ad, ülke ekranda adına yetecek kadar büyükse yazılır. Uzaktan
  yalnızca büyük ülkeler, yakınlaştıkça küçükler de görünür. Adlar üst üste binmez;
  çakışmada büyük ülkenin adı kalır.
- Seçili ülke sarı, oyuncunun ülkesi kalın beyaz çerçeveyle işaretlenir.
- Açılışta her çokgen üçgenlere bölünür. Bölünemeyen çokgen oyunu durdurmaz: konsola
  ülke adıyla uyarı yazılır, dolgusu atlanır, sınırı yine çizilir.

## 4. Kamera ve dokunma

Fare ya da klavye varsayılmaz. Bilgisayarda sınama için "Emulate Touch From Mouse"
açıktır: fareyle sürükleme tek parmak gibi çalışır, fare tekerleği yakınlaştırır.

| Hareket | Sonuç |
|---|---|
| Tek dokunuş | O noktadaki ülkeyi seçer |
| Tek parmakla sürükleme | Haritayı kaydırır |
| İki parmakla kıstırma | Yakınlaştırır / uzaklaştırır |

- Parmak **12 pikselden** az oynadıysa dokunuş, fazla oynadıysa kaydırma sayılır.
  Kaydırma ya da kıstırma bittiğinde ülke seçilmez.
- Dokunulan noktada ülke yoksa **30 piksel** içindeki en yakın ülke seçilir (küçük
  ülkeler ve adalar için). O da yoksa seçim kalkar.
- İç içe ülkelerde en küçük olan seçilir.
- **En uzak görünüm:** dünyanın tamamı ekrana sığar. **En yakın görünüm:** 16 kat;
  Lüksemburg bu yakınlıkta yaklaşık 100 × 160 piksel yer kaplar.
- Kamera haritadan uzaklaşamaz. Yatayda harita kenarı ekranın içine giremez. Dikeyde
  harita, üst çubuğun ve alt panelin altından çıkarılabilsin diye biraz daha
  kaydırılabilir; açılan yer deniz rengindedir.
- Arayüze (panel, düğme) dokunuş haritaya geçmez.

## 5. Ülke seçimi ve arayüz

Temel çözünürlük 1920 × 1080, yatay. Ölçekleme `canvas_items`, en-boy `expand`.

1. Oyun, üstte **"Ülkeni seç"** yazısıyla açılır. Zaman durmuştur, zaman düğmeleri kilitlidir.
2. Bir ülkeye dokununca **alt panel** açılır: ad, kıta, nüfus ("83,4 milyon"),
   GSYH ("761 milyar $"), komşu ülkeler ve **"Bu ülkeyle oyna"** düğmesi.
3. Düğmeye basınca: ülke kalın beyaz çerçeveyle işaretlenir, adı üst çubuğa yazılır,
   kamera o ülkeye kayar, "Ülkeni seç" yazısı kalkar, zaman düğmeleri açılır.
   Zaman durmuş kalır; oyuncu "Devam"a basarak başlatır.
4. Sonrasında başka ülkelere dokununca bilgi paneli yine açılır ama düğme görünmez.
   Ülke bir kez seçilir, değiştirilemez.

- **Üst çubuk:** solda oyuncunun ülkesi ve tarih-saat; sağda durdur/devam düğmesi ve
  üç hız düğmesi. Etkin hız ve durdurulmuş hâl sarı renkle vurgulanır.
- Dokunulabilir her öğe en az **96 × 96 px**. Düğmeler şu an 132 × 104 px ve daha büyüktür.
- Arayüz yazıları en az 36 px, harita yazıları en az 24 px.
- Arayüz, çentik ve yuvarlak köşelerin dışında, güvenli alanın (safe area) içinde kalır.

## 6. Zaman

- **1 tick = 1 oyun saati.** Simülasyon tick ile ilerler; kare hızına bağlı değildir.
- Başlangıç: **1 Ocak 2026, 00:00.** Bitiş tarihi yoktur.
- Takvim gerçektir (ay uzunlukları ve artık yıllar dahil).
- Hızlar: saniyede **2, 6 ve 24** tick (bir oyun günü 12, 4 ve 1 saniye).
- Bir karede en çok 5 tick işlenir (yavaş cihazda takılmayı önlemek için).
- Oyuncu ülkesini seçene kadar zaman kilitlidir.
- Başlangıç tarihi ve hızlar `data/balance.json` içindeki `zaman` bölümünden okunur.

Zaman, `Zaman` adlı autoload ile yönetilir ve şu sinyalleri yayar:

| Sinyal | Ne zaman |
|---|---|
| `saat_gecti(toplam_saat)` | Her oyun saatinde |
| `gun_basladi(toplam_gun)` | Saat 00:00 olduğunda, `saat_gecti`'den sonra |
| `durum_degisti` | Durdurma, hız ya da kilit değiştiğinde |

Birlikler, savaş ve ekonomi ileride bu sinyallere bağlanacaktır.

## 7. Kod mimarisi

```
data/              Oyun verisi (JSON): world.json, balance.json
scenes/main.tscn   Yalnızca kök düğüm; ağaç script'ten kurulur
scripts/main.gd    Veriyi yükler, harita, kamera ve arayüzü kurup birbirine bağlar
scripts/sim/       Saf simülasyon (hiçbir şey çizmez, girdi okumaz)
scripts/gorsel/    Harita çizimi ve kamera
scripts/arayuz/    Üst çubuk, alt panel, tema
tools/             Dönüştürücü ve kaynak veri (oyunun parçası değildir)
```

| Dosya | Görevi |
|---|---|
| `sim/veri_okuyucu.gd` | JSON dosyası okur |
| `sim/ulke.gd` | Bir ülkenin verisi |
| `sim/cokgen.gd` | Bir toprak parçası: noktalar ve sahibi olan ülke |
| `sim/dunya.gd` | Ülkeleri ve çokgenleri yükler, doğrular; "bu noktada hangi parça var", "en yakın parça hangisi" sorularını yanıtlar |
| `sim/oyun.gd` | Oyunun durumu: dünya ve oyuncunun ülkesi |
| `sim/takvim.gd` | Saat sayısını tarihe çevirir |
| `sim/zaman.gd` | Zaman yöneticisi (autoload `Zaman`) |
| `gorsel/harita_gorunumu.gd` | Dolguları, sınırları, çerçeveleri ve ülke adlarını çizer |
| `gorsel/harita_kamerasi.gd` | Kaydırma, yakınlaştırma, dokunuşu ayırma, ülkeye odaklanma |
| `arayuz/arayuz.gd` | Arayüzün kökü ve güvenli alan |
| `arayuz/ust_cubuk.gd`, `ulke_paneli.gd` | Üst çubuk, alt panel |
| `arayuz/arayuz_temasi.gd`, `bicim.gd` | Ortak görünüm, sayı biçimleme |

Görsel taraf oyun durumunu doğrudan değiştirmez; simülasyonun işlevlerini çağırır
(ör. `oyun.oyuncuyu_sec("TUR")`, `Zaman.hiz_sec(2)`) ve sinyallerini dinler.

## 8. Yol haritası

Her aşama tek başına çalışıp sınanabilir bir oyun bırakır. Bir seferde yalnızca
istenen aşama yapılır.

| # | Durum | Aşama | İçerik |
|---|---|---|---|
| 1 | ✅ | **Dünya haritası temeli** | Harita verisi ve dönüştürücü, harita görünümü, kamera, ülke seçimi, zaman |
| 2 | ⬜ | **Ülkeleri bölgelere ayırma** | Her ülkenin çokgenleri bölgelere bölünür; bölgenin sahibi değişebilir |
| 3 | ⬜ | **Birlikler ve hareket** | Birlik verisi, haritada gösterim, seçme, bölgeden bölgeye yürütme |
| 4 | ⬜ | **Savaş** | Savaş ilanı, çarpışma, bölge ele geçirme |
| 5 | ⬜ | **Ekonomi ve üretim** | Kaynaklar, gelir, birlik üretimi |
| 6 | ⬜ | **Yapay zekâ** | Diğer ülkelerin savunması, saldırısı ve üretimi |
| 7 | ⬜ | **Kayıt** | Oyunu kaydetme ve yükleme |
| 8 | ⬜ | **Android** | Dışa aktarma, gerçek telefonda dokunma ve güvenli alan denemesi, performans |

Kapsam dışı (istenmedikçe eklenmez): hava ve deniz kuvvetleri, diplomasi, odak ağacı,
araştırma, çok oyunculu oyun.

## 9. Geçmiş

2 Ekim 2026'ya kadar oyun, kurgusal Kalmera kıtasında geçen "Altı Sancak" olarak
tasarlanmıştı. O hâli git'te `kalmera-arsiv` etiketiyle durur. Kamera, dokunma, zaman
yöneticisi ve arayüz kodu oradan devralındı; harita üretici, bölge ve ülke verileri,
bloklar, zafer puanı ve 1931–1935 süre sınırı kaldırıldı.
