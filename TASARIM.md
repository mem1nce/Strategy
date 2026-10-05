# TASARIM — Yerküre (çalışma adı)

Bu belge oyunun tek tasarım kaynağıdır. Bir kural değişecekse önce burası güncellenir.

## 1. Oyun

Gerçek dünya haritasında geçen, sadeleştirilmiş bir strateji oyunu. Tek oyunculu,
Android, yatay ekran. Godot 4.7, GDScript, 2D, Mobile renderer.

Oyuncu haritadan bir ülke seçer ve onu yönetir. Zaman 1 Ocak 2026'da başlar,
durdurulabilir ve üç hızda akar; bitiş tarihi yoktur.

Dünya haritası, bölgeler, birlikler, savaş, ekonomi, yapay zekâ, kayıt/yükleme ve zafer/
kaybetme koşulları vardır; ana menü ve Android dışa aktarma henüz yoktur
(bkz. 14. Yol haritası).

"Yerküre" geçici bir çalışma adıdır; kalıcı ad sonra seçilecek.

## 2. Harita verisi

- **Kaynaklar** (Natural Earth, kamu malı), `tools/kaynak/` altında:
  - `ne_110m_admin_0_countries.geojson`: ülkeler (1:110 milyon ölçek, 177 kayıt)
  - `ne_50m_populated_places.geojson`: şehirler (1251 kayıt)
- **Dönüştürücü:** `tools/dunya_donustur.py` kaynakları `data/world.json` ve
  `data/regions.json` dosyalarına çevirir. Çalıştırmak için proje klasöründe:

  ```
  python -m pip install -r tools/requirements.txt     (yalnızca ilk seferde; shapely kurar)
  python tools/dunya_donustur.py
  ```

- **Oyun yalnızca `data/` altındaki dosyaları okur.** Kaynak dosyalar daha ayrıntılılarıyla
  değiştirilip dönüştürücü yeniden çalıştırılabilir; oyun kodu değişmez.

### Ülkeler

- Koordinatlar **Miller silindirik projeksiyonla** düzleme çevrilir. Harita 4096 birim
  genişliğinde, 2066 birim yüksekliğindedir (84,5° kuzey ile 58° güney arası).
- **Antarktika çıkarılır.** Geriye 176 ülke kalır.
- Polygon ve MultiPolygon desteklenir: adalar ayrı çokgendir, aynı ülkeye aittir.
- Kaynaktaki iç delikler yok sayılır. Başka bir ülkeyi tümüyle içine alan ülkeden o ülke
  oyulur (Güney Afrika'dan Lesotho).
- Art arda tekrar eden noktalar, çok küçük çokgenler ve alanı olmayan sivri uçlar atılır.
- **Ülke komşuluğu:** iki ülke ortak bir sınır noktası paylaşıyorsa komşudur.
- **Renk:** `MAPCOLOR9` alanı kullanılır; komşu iki ülke aynı rengi alırsa biri değiştirilir.

### Bölgeler

Her bölge bir şehrin çevresidir ve o şehrin adını taşır.

- **Tohum şehirler:** Her ülkede başkent her zaman seçilir. Sonra, seçilmişlere en uzak
  ve en kalabalık şehir eklenerek devam edilir (puan = en yakın tohuma uzaklık × nüfus^0,35);
  böylece bölgeler ülkenin her yanına yayılır. İki tohum arası en az 25 birimdir.
- **Bölge sayısı:** hedef = karekök(ülke alanı) / 20, en az 1, en çok 14. Küçük ülkeler tek
  bölgedir. Verisinde şehri olmayan ülke de tek bölgedir ve ülkenin adını taşır.
- Şehir, kaba kıyı çizgisi yüzünden ülke çokgeninin dışına düşse bile çokgene en çok
  4 birim uzaktaysa ülke koduna göre o ülkenin şehri sayılır.
- **Bölme:** Her ülke çokgeni, içindeki tohumlara göre "en yakın tohum" kuralıyla (Voronoi)
  bölünür. Tohumu olmayan çokgen (ada) bütünüyle en yakın tohumun bölgesine girer. Bir bölge
  birden çok çokgenden oluşabilir.
- Bütün köşeler 0,01 birimlik ızgaraya oturtulur; komşu bölgeler sınırlarındaki noktaları
  birebir paylaşır. Bölgenin ana gövdesinden kopuk, 4 birim kareden küçük kırpıntılar
  sınırdaş olduğu bölgeye katılır.
- **Başkent:** Birden çok başkenti olan ülkelerde yönetim merkezi seçilir (Pretoria, La Paz).
  Kaynakta başkenti olmayan ülkede en büyük şehrin bölgesi başkent bölgesi sayılır.
- **Nüfus:** Ülke nüfusunun yarısı bölgelerin alanına, yarısı bölgelere düşen şehirlerin
  nüfusuna göre dağıtılır. Bölge nüfuslarının toplamı ülke nüfusuna eşittir.
- **Kara komşusu:** ortak bir sınır parçası paylaşan iki bölge (farklı ülkelerden olsalar da).
  Yalnızca tek köşede değenler komşu değildir. Tek istisna: iki ÜLKE kaynak veride yalnızca
  tek noktada değiyorsa (Türkiye ile Azerbaycan'ın Nahçıvan sınırı) o noktadaki bölgeleri
  komşu sayılır; çünkü gerçekte sınırdaştırlar, kaba ölçek sınırı noktaya indirmiştir.
- **Kıyı bölgesi:** en az bir kıyı (deniz) sınırı olan bölge kıyı bölgesi sayılır (`kiyi` alanı).
- **Deniz yolu:** kara komşusu olmayan iki kıyı bölgesi arasında, aralarındaki en kısa çizgi
  220 harita biriminden kısaysa ve başka bir karadan geçmiyorsa deniz yolu vardır. Her kıyı
  bölgesi için en yakın 3 deniz yolu tutulur (bir bölge, başka bir bölgenin en yakın 3'üne
  girdiği için bundan fazla deniz yoluna sahip olabilir).
- **Dünya bağlantısı:** kara komşuluğu ve deniz yollarıyla dünyadaki her bölgeye başka her
  bölgeden ulaşılabilir. 220 birim içinde deniz yolu bulamayan bir ada kalırsa (ör. uzak
  Pasifik adaları), o adanın en yakın kıyı bölgesi, erişilebilir ana kümenin en yakın kıyı
  bölgesine ek bir deniz yoluyla bağlanır.
- **Sınır çizgileri:** İki bölge arasındaki ya da bölge ile deniz arasındaki her kesintisiz
  çizgi ayrıca yazılır. Harita sınırları bunlardan çizer.

Şu anki sonuç: **516 bölge**, 85 tek bölgeli ülke, 1121 kara komşuluğu (sayılar deniz yolu
kuralı değiştiği için yeniden üretimde güncellenir).

### Doğrulama

Dönüştürücü her çalıştığında şunları denetler; hata varsa dosya yazmaz:

1. Kara komşuluğu ve deniz yolu iki yönlüdür; bir bölge çifti aynı anda ikisi de olamaz.
2. Komşu olan her ülke çiftinde en az bir bölge çifti komşudur (ve tersi).
3. Bir ülkenin bölgelerinin toplam alanı ülke alanından en fazla %1 sapar.
4. Aynı kara parçasındaki bölgeler komşuluk zinciriyle birbirine ulaşır.
5. Her ülkenin tam bir başkent bölgesi, her bölgenin çokgeni ve çokgeninin içinde etiket
   noktası vardır.
6. Kara komşuluğu ve deniz yollarının birleşimiyle dünyadaki her bölgeye her bölgeden
   ulaşılabilir (bağlantı tamamlama adımı bunu zaten garanti eder; bu denetim onu doğrular).

En az üç bölgesi olduğu hâlde bir bölgesi ülke alanının %40'ını geçen ülkeler **uyarı**
olarak listelenir (şehir verisinin seyrek olduğu yerler).

### `data/world.json`

```json
{
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
			"anakara_kutusu": [2345.77, 811.23, 211.89, 82.72],
			"komsular": ["ARM", "AZE", "BGR", "GEO", "GRC", "IRN", "IRQ", "SYR"],
			"baskent_bolgesi": "TUR_1",
			"bolgeler": ["TUR_1", "TUR_2", "TUR_3", "TUR_4", "TUR_5", "TUR_6"]
		}
	]
}
```

`id` ← `ADM0_A3`, `ad` ← `NAME_TR` (yoksa `NAME`), `kita` ← `CONTINENT`, `nufus` ← `POP_EST`,
`gsyh_milyon_dolar` ← `GDP_MD`, `renk` ← `MAPCOLOR9`, `etiket` ← `LABEL_X`/`LABEL_Y`.
`anakara_kutusu`, ülkenin en büyük kara parçasını saran dikdörtgendir (kamera için).
Ülke çokgenleri bu dosyada durmaz; bölgelerin çokgenleri `regions.json` içindedir.

### `data/regions.json`

```json
{
	"bolgeler": [
		{
			"id": "TUR_1",
			"ad": "Ankara",
			"sahip": "TUR",
			"baskent": true,
			"nufus": 12950188,
			"kiyi": false,
			"etiket": [2422.26, 834.39],
			"kara_komsulari": ["TUR_2", "TUR_4", "TUR_5", "TUR_6"],
			"deniz_gecisleri": [],
			"cokgenler": [
				[[2432.86, 811.47], [2429.31, 811.52], [2416.05, 815.38]]
			]
		}
	],
	"sinirlar": [
		{"a": "TUR_1", "b": "TUR_2", "noktalar": [[2402.57, 824.06], [2394.2, 849.3]]},
		{"a": "TUR_2", "b": "", "noktalar": [[2344.47, 827.76], [2344.32, 830.54]]}
	]
}
```

- Bölge `id`'si ülke kodu ve sıra numarasından oluşur; başkent bölgesi 1 numaradır.
- Şehir adı kaynaktaki `NAME_TR` alanından gelir (yoksa `NAME`); ülke kodu `ADM0_A3`,
  nüfus `POP_MAX`, başkentlik `FEATURECLA` alanından okunur.
- `sahip`: oyun başındaki sahip ülke. Oyun içinde değişebilir.
- `kiyi`: en az bir kıyı sınırı olan bölgede `true`.
- `cokgenler`: büyükten küçüğe; her biri `[x, y]` noktalarından oluşur.
- `sinirlar` içinde `b` boşsa çizgi kıyıdır.

Formüllerde kullanılan sabitler `data/balance.json` dosyasındadır (şimdilik yalnızca zaman).

### Veriyle ilgili bilinmesi gerekenler

- Bu ölçekte çok küçük ülkeler **yoktur** (ör. Singapur, Malta, Bahreyn, Vatikan).
- Sınırlar Natural Earth'ün "fiilî durum" çizimidir; oyunun bir görüşünü yansıtmaz.
  Kaynakta ayrı kayıt olan tartışmalı ya da bağımlı yerler ayrı ülke gibi çizilir:
  Batı Sahra, Kuzey Kıbrıs, Somaliland, Kosova, Tayvan, Filistin, Falkland Adaları,
  Grönland, Porto Riko, Yeni Kaledonya, Fransız Güney Toprakları.
- Adlar kaynaktaki `NAME_TR` alanından gelir (ör. "Çin Halk Cumhuriyeti", "Beyaz Rusya").
- Şehir verisi seyrektir (ör. Türkiye için 7 şehir, doğuda hiç şehir yok). Bu yüzden bazı
  bölgeler adını taşıdığı şehirden çok uzağa uzanır (Samsun bölgesi İran sınırına kadar).
  Daha ayrıntılı şehir verisi (`ne_10m_populated_places`) bunu düzeltir.

## 3. Harita görünümü

- Harita **"çokgen → bölge → sahip ülke"** mantığıyla çalışır: her çokgen, bölgesinin o anki
  sahibinin rengini alır. Sınır çizgisinin türü de iki yanındaki bölgelerin sahibine göre
  belirlenir. Bir bölge el değiştirince harita ve ülke sınırları kendiliğinden güncellenir.
- Deniz düz, koyu mavi-gri bir arka plandır.
- Ülkeler renk indeksine göre dokuz sakin renkten birini alır; komşular farklı renktedir.
- Çokgenler büyükten küçüğe çizilir; iç içe ülkelerde küçük olan üstte kalır (Lesotho).
- **Sınırlar:** kıyı ince, ülke sınırı kalın, bölge sınırı ince ve soluktur. Hepsi
  yakınlıktan bağımsız olarak ekranda aynı kalınlıkta görünür.
- **Uzaktan** harita sadedir: yalnızca ülkeler, ülke sınırları ve büyük ülkelerin adları.
- **Yakınlaşınca** (yakınlık 1,7 ile 2,6 arasında yavaşça) bölge sınırları, bölge adları ve
  başkent bölgelerindeki yıldızlar belirir; ülke adları solar ve daha da yakında kaybolur.
- **Adlar:** bir ad, ülke ya da bölge ekranda adına yetecek kadar büyükse yazılır. Adlar üst
  üste binmez; çakışmada büyük ülkenin, bölgelerde başkentin ve kalabalık bölgenin adı kalır.
- Seçili bölge parlak sarı, ülkesi daha hafif bir çerçeveyle; oyuncunun ülkesi kalın beyaz
  çerçeveyle işaretlenir.
- Açılışta her çokgen üçgenlere bölünür. Bölünemeyen çokgen oyunu durdurmaz: konsola bölge
  ve ülke adıyla uyarı yazılır, dolgusu atlanır, sınırı yine çizilir.

**Performans:** Bölgeler tek tek düğüm değildir. Bütün dolgular tek bir ağda (mesh), sınırlar
türlerine göre üç ağda çizilir. Sınır kalınlığını gölgelendirici (`sinir_cizgisi.gdshader`)
verdiği için yakınlık değişince ağlar baştan kurulmaz. Adlardan yalnızca ekrandakiler çizilir;
bölge adlarının hangi yakınlıkta görüneceği açılışta bir kez hesaplanır.

## 4. Kamera ve dokunma

Fare ya da klavye varsayılmaz. Bilgisayarda sınama için "Emulate Touch From Mouse"
açıktır: fareyle sürükleme tek parmak gibi çalışır, fare tekerleği yakınlaştırır.

| Hareket | Sonuç |
|---|---|
| Tek dokunuş | O noktadaki bölgeyi seçer |
| Tek parmakla sürükleme | Haritayı kaydırır |
| İki parmakla kıstırma | Yakınlaştırır / uzaklaştırır |

- Parmak **12 pikselden** az oynadıysa dokunuş, fazla oynadıysa kaydırma sayılır.
  Kaydırma ya da kıstırma bittiğinde seçim yapılmaz.
- Dokunulan noktada bölge yoksa **30 piksel** içindeki en yakın bölge seçilir (küçük
  bölgeler ve adalar için). O da yoksa seçim kalkar.
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
2. Bir bölgeye dokununca **alt panel** açılır ve **"Bu ülkeyle oyna"** düğmesi görünür;
   düğme, dokunulan bölgenin ülkesini seçer.
3. Düğmeye basınca: ülke kalın beyaz çerçeveyle işaretlenir, adı üst çubuğa yazılır,
   kamera o ülkeye kayar, "Ülkeni seç" yazısı kalkar, zaman düğmeleri açılır.
   Zaman durmuş kalır; oyuncu "Devam"a basarak başlatır.
4. Sonrasında başka bölgelere dokununca bilgi paneli yine açılır ama "Bu ülkeyle oyna"
   düğmesi görünmez. Ülke bir kez seçilir, değiştirilemez.

**Alt panel**

- Üst satır: bölgenin adı, başkentse "Başkent" yazısı, bölgenin nüfusu.
- Orta satır: ülkenin adı, kıtası, toplam nüfusu ("83,4 milyon") ve GSYH'si ("761 milyar $").
- Alt satır: kara komşusu ve deniz geçişi sayıları; yanlarındaki renkli kutular haritadaki
  vurgu renkleridir.
- **"Komşuları göster"** düğmesi: basınca seçili bölgenin kara komşuları yeşil-turkuaz,
  deniz geçişleri turuncu boyanır; tekrar basınca kapanır. Açıkken başka bölge seçilirse
  vurgu yeni bölgeye geçer.

**Üst çubuk:** solda oyuncunun ülkesi ve tarih-saat; sağda durdur/devam düğmesi ve üç hız
düğmesi. Etkin hız ve durdurulmuş hâl sarı renkle vurgulanır.

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

## 7. Birlikler

Tek birlik türü: **tümen**. Gücü 0-100 arasındadır (bkz. data/balance.json → "ordu").

- **Başlangıç ordusu:** ülke başına tümen sayısı nüfus ve GSYH'den basit bir puanla çıkar:
  `puan = (sqrt(nufus / nufus_bolen) + sqrt(gsyh_milyon_dolar / gsyh_bolen)) / 2`, yuvarlanıp
  `asgari_tumen`-`azami_tumen` (1-24) arasına sınırlanır. Sabitler data/balance.json →
  "ordu" içindedir; dengesi ileride uzun koşu sınamasıyla ayarlanacaktır (bkz. 9. Yol
  haritası, H).
- **Yerleşim:** tümenler başkent bölgesine ve kara sınırı olan (başka ülkeye komşu) bölgelere
  sırayla dağıtılır; sınır bölgesi yoksa (ör. ada ülkesi) hepsi başkente yerleşir.
- **Gösterim:** aynı bölgedeki bütün tümenler haritada tek bir kutu olarak görünür; kutu
  bölgenin sahibinin renginde, içinde o bölgedeki toplam güç yazar. Kutu, bölge adları gibi
  yakınlıktan bağımsız, sabit ekran boyutundadır.
- **Seçme ve emir:** oyuncunun kendi tümenlerinin olduğu bölgeye dokununca birlik kartı
  açılır. Kart açıkken başka bir bölgeye dokunmak hareket emridir: tümenler
  `YolBulucu`nun bulduğu sürede (kara 24 saat, deniz daha yavaş) hedefe yürür; yürürken
  kaynak-hedef arası sarı bir çizgi görünür. Savaş henüz olmadığından yalnızca kendi
  toprağın içinde hareket edilebilir.
- **Yarısını ayır:** birlik kartındaki düğme, gösterilen tümenleri yarıya ayırır (tek
  tümende gücü ikiye böler, birden çok tümende sayıca yarısını ayırır); ayrılan yarı bir
  sonraki hedef seçiminde yürütülür, kalan yarı yerinde durur.
- Henüz yok: savaş, bakım, hareketin görsel animasyonu (şu an yalnızca varış anında bölge
  değişir) (bkz. 14. Yol haritası, C).

Kod mimarisinde: `sim/birlik.gd` (tümen verisi), `sim/ordu_kurucu.gd` (başlangıç ordusu
üretimi), `Oyun.birlikler` (oyunun o anki tümen listesi).

## 8. Savaş

Herkes barışta başlar. Savaş çiftler hâlinde tutulur (`Oyun._savaslar`); iki ülke arasında
savaş varsa her iki yönde de `savasta_mi()` doğru döner.

- **İlan:** bölge panelinde, dokunulan bölgenin sahibi (a) oyuncunun ülkesi değilse,
  (b) o ülkeyle savaşta değilse ve (c) o ülke oyuncunun ülkesine kara ya da deniz yoluyla
  **doğrudan** komşuysa "Savaş ilan et" düğmesi görünür (`Dunya.ulkeler_komsu_mu()`; üçüncü
  bir ülkenin toprağından geçerek ulaşmak sayılmaz). Düğme bir onay penceresi açar.
- **Hareket:** `Oyun.birlikleri_yurut()`, hedef kendi toprağın değilse yalnızca hedefin
  sahibiyle savaştaysan kabul eder (bkz. 7. Birlikler).
- **Boş bölge işgali:** savaşta olunan ve içinde savunan (bölgenin o anki sahibine ait)
  tümen kalmamış bir bölgeye varan tümen, bölgeyi hemen ele geçirir (`Oyun.saat_ilerledi()`
  içinde); sahip, renk ve sınır çizgileri `HaritaGorunumu.yenile()` ile güncellenir.
- **Muharebe:** bir bölgede birden fazla ülkenin tümeni varsa (saldırgan dolu bir düşman
  bölgesine girdiyse) her saat çarpışırlar (`Oyun._muharebeyi_coz()`, sabitler
  data/balance.json → "savas"):
  - Her taraf, karşı tarafın **etkin** toplam gücüyle orantılı saatlik kayıp alır
    (`saatlik_kayip_orani`).
  - **Savunan** `savunan_avantaji` (×1,25) kadar avantajlıdır: verdiği hasar bu oranda artar.
  - Son adımı deniz yoluyla gelen **saldırgan** tümenler `deniz_cezasi` (×0,70) alır: güçleri
    hasap edilirken bu oranda azalır.
  - Gücü `ASGARI_GUC`'un altına düşen tümen yok sayılır (silinir).
  - Bir taraf tükenirse ya da karşı tarafın gücünün `cekilme_esigi`'nin (×0,25) altına
    düşerse **geri çekilir**: en yakın dost komşu (kara ya da deniz) bölgeye taşınır; öyle
    bir komşu yoksa yok olur. Savunan tükenir ya da çekilirse bölgede artık savunan
    kalmadığından bölge hemen saldırganın olur.
  - Haritada, birden çok ülkenin tümeni bulunan bölgenin kutusunun yanında kırmızı bir
    daire (muharebe işareti) görünür; kutudaki sayı iki tarafın toplam gücüdür.
- **Teslim:** bir bölgenin sahibi değiştiğinde (işgal ya da muharebe sonucu), eski sahibi
  için denetlenir: başkenti düşmüş VE oyun başındaki bölge sayısının yarısından fazlasını
  kaybetmişse teslim olur. Kalan bölgeleri başkentini alan ülkeye geçer, bütün tümenleri
  silinir (`Oyun.ulke_teslim_oldu` sinyali yayılır).
- **Barış teklifi:** bölge panelinde, savaşta olunan bir ülkenin bölgesi gösterildiğinde
  "Savaş ilan et" yerine "Barış teklif et" düğmesi görünür (onaysız, tek dokunuş). Hedef
  kabul eder: kendi toplam askeri gücü teklif edenden azsa ("kaybediyorsa") ya da savaş
  180 günden (`Oyun.BARIS_ESIGI_SAAT`) uzun sürdüyse. Kabul edilirse savaş biter, herkes
  elindekini tutar (`Oyun.baris_yapildi` sinyali).
- Henüz: ülke paneli yok (bkz. Kararlar), bildirim/UI geri bildirimi yok (F) OYUN AKIŞI'nda
  gelecek), yapay zekâ henüz yok — barış kabulü basit bir kurala (kaybetme/süre) dayanıyor,
  gerçek bir karar değil.

## 9. Ekonomi

Tek kaynak: **üretim** (gelir, hazineye işlenir).

- **Sanayi:** her bölgenin bir sanayi değeri vardır; bölgenin "ev sahibi" ülkesinin (bölge
  id'sinin öneki, ör. "TUR_1" → "TUR") GSYH'sinden türer ve o ülke içindeki nüfus payıyla
  bölgelere dağıtılır: `ulke_sanayisi = sqrt(gsyh_milyon_dolar / sanayi_gsyh_bolen)`,
  `bolge_sanayisi = ulke_sanayisi * (bolge.nufus / ev_ulkesinin_nufusu)`. `sqrt` GSYH'yi
  yumuşatır, küçük ülkeler çaresiz kalmaz (bkz. TASARIM.md 7. Birlikler'deki tümen
  formülüyle aynı mantık). Sabit data/balance.json → "ekonomi".
- **Gelir:** bir ülkenin günlük geliri, o an sahip olduğu bölgelerin sanayilerinin
  toplamıdır (`Oyun.ulkenin_geliri`); el değiştiren bölgenin geliri de otomatik olarak yeni
  sahibine gider.
- **İşgal cezası:** bir bölge ele geçirildikten sonraki `isgal_cezasi_gun` (60) gün boyunca,
  ev sahibi ülkesinde değilse `isgal_cezasi_orani` (×0,5) kadar üretir. `Bolge.isgal_saati`
  (`Oyun._bolgeyi_devret()` içinde kaydedilir) bunun için kullanılır.
  Ev sahibi kendi bölgesini geri alınca ceza hemen kalkar.
  Bu alan, tümen hareketindeki `son_adim_deniz_mi` gibi, Bölge'nin coğrafyası dışındaki
  tek dinamik ekonomi alanıdır.
- **Hazine:** `Oyun.hazineler` (ülke id'si → birikmiş üretim), her oyun günü başında
  (`Oyun.gun_basladi()`, `Zaman.gun_basladi`'den main.gd aracılığıyla çağrılır) o günün
  geliri eklenerek güncellenir. Üst çubukta oyuncunun hazinesi yazılı.
- **Harcama:** `Oyun.tumen_sirala()` ve `fabrika_sirala()`, bir ülkenin (kendi) bir
  bölgesinde iş sıralar; maliyet hemen hazineden düşülür (yetmezse sıralanamaz). Her
  ülkenin **tek** bir inşa kuyruğu vardır (`Oyun.insa_kuyruklari`), en fazla
  `AZAMI_KUYRUK_UZUNLUGU` (5) iş bekleyebilir; yalnızca kuyruğun ÖNÜNDEKİ iş ilerler,
  arkadakiler sırasını bekler. Süresi dolan tümen işi, belirtilen bölgede
  `baslangic_gucu` ile yeni bir tümen doğurur; fabrika işi bölgenin `fabrika_sanayisi`'ni
  kalıcı olarak `fabrika_sanayi_artisi` kadar artırır (bkz. yukarıdaki "Sanayi"). Sabitler
  data/balance.json → "ekonomi" (`tumen_maliyeti`, `tumen_suresi_saat`, ...).
- **Bakım:** her oyun günü başında (gelir eklendikten sonra), her ülkenin tümen sayısı ×
  `bakim_birim_maliyeti` hazinesinden düşülür. Hazine yetmezse 0'da kalır ve açık, o
  ülkenin bütün tümenlerine güçleriyle orantılı kayıp olarak yansıtılır (muharebedeki
  `_guc_azalt` ile aynı mekanizma); güç `ASGARI_GUC` altına düşen tümen silinir.
- Arayüz: şimdilik yok — tümen/fabrika sıralama yalnızca sim katmanında (`Oyun`) var;
  düğmeler G) ARAYÜZ aşamasında (ya da öncesinde küçük bir ek adımda) eklenecek.

## 10. Yapay zekâ

Oyuncunun ülkesi dışındaki her ülke, kendi kendine karar verir.

- **Düşünme zamanlaması:** her ülkenin sabit bir "düşünme saati" vardır
  (`absi(ulke_id.hash()) % 24`, 0-23) ve günde tam bir kez, o saat gelince düşünür
  (`Oyun._yapay_zekayi_isle()`, her saat çağrılır). Ülkeler böylece 24 saate yayılır;
  hepsi aynı karede düşünüp yığılma yapmaz. Oyuncunun ülkesi ve hiç bölgesi kalmamış
  (teslim olmuş) ülkeler düşünmez.
- **Barışta:** kuyruğunda yer ve hazinesi yeterliyse bir iş sıralar — küçük bir olasılıkla
  (`yapay_zeka.fabrika_olasiligi`, ×0,2) fabrika, yoksa tümen; başkente ya da rastgele bir
  sınır bölgesine (`OrduKurucu.yerlesim_bolgeleri`, başlangıç ordusuyla aynı yerleşim
  mantığı) kurar.
- **Savaşta:** her sınır bölgesinde (başkent hariç — başkent hiç saldırıya katılmaz, böylece
  hep korunur) kendi gücünü savaşta olduğu bir komşu bölgedeki düşman gücüyle kıyaslar;
  en az `yapay_zeka.saldiri_esigi` (×1,3) katıysa oraya saldırır (`Oyun._savastaki_ulke_dusun`).
- **Savaş ilanı:** yaklaşık ayda bir (`yapay_zeka.savas_ilani_gun_araligi`, 30 gün)
  değerlendirilir. Zaten `yapay_zeka.azami_eszamanli_savas` (2) savaştaysa ya da zar
  (`yapay_zeka.savas_ilani_olasiligi`, ×0,1 — "küçük bir olasılık") tutmazsa hiçbir şey
  yapmaz. Tutarsa, doğrudan komşu olup kendisinden `yapay_zeka.savas_ilani_esigi` (×2) kat
  güçsüz, henüz savaşılmayan ilk ülkeye ilan eder. Oyuncu, oyunun ilk
  `yapay_zeka.oyuncuya_dokunulmazlik_gun` (90) günü boyunca aday sayılmaz
  (`Oyun._savas_ilanini_degerlendir`).
- **"Ordumu yapay zekâ yönetsin":** üst çubuktaki "Ordu: YZ" düğmesi (`Oyun.yz_oyuncuyu_yonetsin`)
  açılınca, oyuncunun ülkesi de `_yapay_zekayi_isle()`'nin atladığı istisnadan çıkar ve aynı
  barış/savaş davranışıyla yönetilir. Tercih kayıtta saklanır.

## 11. Kayıt

Tek kayıt yuvası: `user://kayit.json`. Oyun verisi `data/` altındaki dosyalardan ayrıdır ve
yalnızca buraya yazılır (bkz. 2. Harita verisi'ndeki "Oyun yalnızca data/ altındaki dosyaları
okur" kuralı); kayıt, oyunun DURUMUNU tutar, coğrafyayı değil.

- **Ne kaydedilir** (`Oyun.kaydet_icin_veri()`): oyuncunun ülkesi; değişmiş bölgeler
  (sahip, işgal saati, fabrika sanayisi — hiç değişmemiş bölgeler yer kaplamasın diye
  atlanır); bütün tümenler; savaşlar (ilan saatleriyle); hazineler; inşa kuyrukları.
  Zaman durumu (`Zaman.durumu_al()`) ayrıca eklenir; `KayitYoneticisi` Zaman autoload'ına
  bağlı olmasın diye bu, çağıran taraftan (main.gd) parametre olarak verilir.
- **Sürüm:** dosyada bir `surum` sayısı durur (`KayitYoneticisi.SURUM`). Okurken sürüm
  uyuşmazsa kayıt yok sayılır, oyun sıfırdan başlar — eski bir kayıt sessizce bozuk
  davranışa yol açmaz.
- **Otomatik kayıt:** her oyun günü başında (`Zaman.gun_basladi`) ve uygulama arka plana
  geçince ya da kapatılmak istenince (`NOTIFICATION_APPLICATION_PAUSED`,
  `NOTIFICATION_WM_CLOSE_REQUEST`). Oyuncu henüz ülkesini seçmediyse kaydedilmez (henüz
  korunacak bir ilerleme yok).
- **Yükleme:** oyun açılışta (`main.gd _ready()`) bir kayıt bulursa `Oyun.kayittan_yukle()`
  ile OrduKurucu'nun ürettiği taze orduyu ve dünyanın başlangıç sahipliklerini tamamen
  değiştirir, sonra `Zaman.durumu_uygula()` çağrılır. Henüz "Yeni oyun / Devam et" seçeneği
  sunan bir ana menü yok; kayıt varsa otomatik yüklenir (bkz. 14. Yol haritası, F).

## 12. Oyun sonu

- **Kaybetme:** oyuncunun ülkesi teslim olunca (bkz. 8. Savaş'taki teslim kuralı)
  `Oyun.oyun_kaybedildi` bir kez yayılır.
- **Zafer:** oyuncunun kıtasındaki bölgelerin (bir bölgenin kıtası, "ev sahibi" ülkesinin
  kıtasıdır, kimin elinde olduğundan bağımsız) `ZAFER_ORANI`'ı (×0,6) kadarı kendisinin
  olunca `Oyun.oyun_kazanildi` bir kez yayılır (`_zafer_kazanildi` bayrağıyla, kayıtta da
  saklanır). Oyun kilitlenmez; "sonrasında oynamaya devam edilebilir".
- Her ikisinde de ekranın ortasında kapatılabilir bir bildirim gösterilir
  (`Arayuz.zaferi_goster()`/`kaybi_goster()`, `SonucPaneli`) ve zaman durur (önemli bir
  olay olduğu için); oyuncu "Kapat"tan sonra "Devam"a basarak sürdürebilir.
- Henüz yok: ana menü, güç sıralaması paneli, diğer bildirimler (bölge kaybı/kazancı,
  üretim bitti vb.) (bkz. 14. Yol haritası, F).

## 13. Kod mimarisi

```
data/              Oyun verisi (JSON): world.json, regions.json, balance.json
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
| `sim/bolge.gd` | Bir bölgenin verisi: ad, sahip, nüfus, komşular, çokgenler |
| `sim/cokgen.gd` | Bir toprak parçası: noktalar ve ait olduğu bölge |
| `sim/sinir.gd` | İki bölge (ya da bölge ile deniz) arasındaki sınır çizgisi |
| `sim/dunya.gd` | Ülkeleri, bölgeleri ve sınırları yükler, doğrular, sorguları yanıtlar |
| `sim/oyun.gd` | Oyunun durumu: dünya, oyuncunun ülkesi, tümenler, savaş, hazineler, yapay zekâ |
| `sim/birlik.gd` | Bir tümenin verisi: sahip, bulunduğu bölge, güç |
| `sim/ordu_kurucu.gd` | Ülkelerin başlangıç ordusunu üretir |
| `sim/insa_isi.gd` | İnşa kuyruğundaki tek bir iş: tümen ya da fabrika |
| `sim/kayit_yoneticisi.gd` | Oyun durumunu user:// altına JSON olarak kaydeder/yükler |
| `sim/takvim.gd` | Saat sayısını tarihe çevirir |
| `sim/zaman.gd` | Zaman yöneticisi (autoload `Zaman`) |
| `gorsel/harita_gorunumu.gd` | Dolguları, sınırları, çerçeveleri, vurguları, adları ve tümen kutularını çizer |
| `gorsel/sinir_cizgisi.gdshader` | Sınır çizgilerini ekranda sabit kalınlıkta çizer |
| `gorsel/harita_kamerasi.gd` | Kaydırma, yakınlaştırma, dokunuşu ayırma, ülkeye odaklanma |
| `arayuz/arayuz.gd` | Arayüzün kökü ve güvenli alan |
| `arayuz/ust_cubuk.gd`, `bolge_paneli.gd` | Üst çubuk, alt panel |
| `arayuz/arayuz_temasi.gd`, `bicim.gd` | Ortak görünüm, sayı biçimleme |

**Simülasyon sorguları** (`Dunya`):

| Sorgu | Yanıt |
|---|---|
| `bolgenin_sahibi(bolge_id)` | Bölgenin o anki sahibi olan ülke |
| `ulkenin_bolgeleri(ulke_id)` | Ülkenin o an elindeki bölgeler |
| `bolgenin_kara_komsulari(bolge_id)` | Ortak sınırı olan bölgeler |
| `bolgenin_deniz_gecisleri(bolge_id)` | Dar sudan geçilerek ulaşılan bölgeler |
| `bolgenin_komsulari(bolge_id)` | İkisinin birleşimi |
| `noktadaki_cokgen(nokta)`, `en_yakin_cokgen(nokta, uzaklik)` | Dokunulan toprak parçası |
| `ulkeler_komsu_mu(ulke_a, ulke_b)` | İki ülke kara/deniz yoluyla doğrudan komşu mu (savaş ilanı için) |

Görsel taraf oyun durumunu doğrudan değiştirmez; simülasyonun işlevlerini çağırır
(ör. `oyun.oyuncuyu_sec("TUR")`, `Zaman.hiz_sec(2)`) ve sinyallerini dinler. Bir bölgenin
sahibi değiştiğinde harita `HaritaGorunumu.yenile()` ile güncellenir.

## 14. Yol haritası

Her aşama tek başına çalışıp sınanabilir bir oyun bırakır. Bir seferde yalnızca
istenen aşama yapılır.

| # | Durum | Aşama | İçerik |
|---|---|---|---|
| 1 | ✅ | **Dünya haritası temeli** | Harita verisi ve dönüştürücü, harita görünümü, kamera, ülke seçimi, zaman |
| 2 | ✅ | **Ülkeleri bölgelere ayırma** | Şehir verisi, Voronoi bölme, bölge komşulukları ve deniz geçişleri, bölge seçimi ve paneli |
| 3 | ✅ | **Birlikler ve hareket** | Birlik verisi, haritada gösterim, seçme, bölgeden bölgeye yürütme |
| 4 | ✅ | **Savaş** | Savaş ilanı, çarpışma, bölge ele geçirme |
| 5 | ✅ | **Ekonomi ve üretim** | Kaynaklar, gelir, birlik üretimi |
| 6 | ✅ | **Yapay zekâ** | Diğer ülkelerin savunması, saldırısı ve üretimi |
| 7 | ✅ | **Kayıt** | Oyunu kaydetme ve yükleme |
| 8 | ⬜ | **Android** | Dışa aktarma, gerçek telefonda dokunma ve güvenli alan denemesi, performans |

Kapsam dışı (istenmedikçe eklenmez): hava ve deniz kuvvetleri, diplomasi, odak ağacı,
araştırma, çok oyunculu oyun.

## 15. Geçmiş

2 Ekim 2026'ya kadar oyun, kurgusal Kalmera kıtasında geçen "Altı Sancak" olarak
tasarlanmıştı. O hâli git'te `kalmera-arsiv` etiketiyle durur. Kamera, dokunma, zaman
yöneticisi ve arayüz kodu oradan devralındı; harita üretici, bölge ve ülke verileri,
bloklar, zafer puanı ve 1931–1935 süre sınırı kaldırıldı.
