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
  - `ne_10m_populated_places.geojson`: şehirler ve kasabalar (7342 kayıt)
- **Ayarlar:** `tools/bolge_ayarlari.json` bölge sayısı formülünün katsayılarını ve tohum
  seçiminin sayılarını tutar; değiştirip dönüştürücüyü yeniden çalıştırmak yeterlidir.
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

- **Bölge sayısı:** hedef = sabit + a × karekök(yüzölçümü km² / 1000) + b × karekök(nüfus /
  1 milyon), yuvarlanır, en az 1, en çok 40. Yüzölçümü projeksiyondan bağımsız gerçek alandır
  (eşit alanlı izdüşümle hesaplanır; Miller'ın kutuplara doğru büyütmesi sayıyı şişirmez).
  Şu anki katsayılar: sabit −0,5, a = 0,27, b = 0,32. Sonuç: Rusya, ABD, Çin, Kanada, Brezilya,
  Hindistan, Avustralya 25-36; Türkiye, Fransa, Almanya, İran, Meksika, Mısır 9-15;
  Yunanistan, Hollanda, Portekiz, Suriye 3-4; çok küçük ülkeler 1-2.
- **Tohum şehirler:** Her ülkede başkent her zaman seçilir. Sonra, seçilmişlere en uzak
  ve en kalabalık şehir eklenerek devam edilir (puan = en yakın tohuma uzaklık × nüfus^0,35);
  böylece bölgeler ülkenin her yanına yayılır. İki tohum arasındaki en az uzaklık ülkenin
  büyüklüğüne göredir: 0,5 × karekök(ülkenin harita alanı / hedef bölge sayısı). Yeterince
  uzak şehir kalmazsa bu aralık adım adım (en çok %30'una kadar) gevşetilir.
- **Büyük bölge sınırı:** en az 8 bölgeli ülkelerde hiçbir bölge ülke alanının %20'sini
  geçmemelidir. Geçen bölgedeki, tohumlara en uzak kasaba (nüfusu ne olursa olsun) da tohum
  yapılır; Sibirya, Sahra, Kuzey Kanada ve Avustralya'nın içi böyle bölünür. Bölgede hiç
  yerleşim yoksa (Libya'nın, Nijer'in, Mali'nin çölü, Grönland'ın kuzeyi) uyarı verilir.
- Verisinde şehri olmayan ülke tek bölgedir ve ülkenin adını taşır.
- Şehir, kaba kıyı çizgisi yüzünden ülke çokgeninin dışına düşse bile çokgene en çok
  4 birim uzaktaysa ülke koduna göre o ülkenin şehri sayılır.
- **Bölme:** Her ülke çokgeni, içindeki tohumlara göre "en yakın tohum" kuralıyla (Voronoi)
  bölünür. Tohumu olmayan çokgen (ada) bütünüyle en yakın tohumun bölgesine girer. Bir bölge
  birden çok çokgenden oluşabilir.
- **Küçük bölgeler:** alanı, ülkesindeki ortalama bölge alanının %20'sinden küçük kalan
  (başkent olmayan) bölge, en uzun sınırı paylaştığı aynı ülkeden bölgeye katılır.
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

Şu anki sonuç: **1095 bölge**, 32 tek bölgeli ülke, 2580 kara komşuluğu, 538 kıyı bölgesi,
881 deniz yolu.

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

En az 8 bölgesi olduğu hâlde bir bölgesi ülke alanının %20'sini geçen ülkeler **uyarı**
olarak listelenir (hiç yerleşimi olmayan çöller).

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
- Şehir verisi 1:10 milyon ölçektedir (ör. Türkiye için 83 yerleşim). Şehir nüfusları
  kaynaktaki `POP_MAX` alanıdır. Tohum seçimi ülkeye yayılmayı nüfustan önde tuttuğu için
  bazen büyük bir şehir yerine diğer tohumlardan daha uzaktaki komşusu seçilir (Türkiye'de
  Adana yerine Tarsus, Bursa ve Konya hiç seçilmez).

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
- **Yakınlaşınca** (yakınlık 2,4 ile 3,4 arasında yavaşça; bölgeler sıklaştığı için eskiden
  1,7-2,6 idi) bölge sınırları, bölge adları ve başkent bölgelerindeki yıldızlar belirir; ülke
  adları solar ve daha da yakında kaybolur. Tümen kutuları bu belirme en az yarıya varınca
  (yakınlık ~2,9) çizilir.
- **Adlar:** bir ad, ülke ya da bölge ekranda adına yetecek kadar büyükse yazılır. Adlar üst
  üste binmez; çakışmada büyük ülkenin, bölgelerde başkentin ve kalabalık bölgenin adı kalır.
- Seçili bölge parlak sarı, ülkesi daha hafif bir çerçeveyle; oyuncunun ülkesi kalın beyaz
  çerçeveyle işaretlenir.
- **Savaştaki ülkeler** (yalnızca oyuncuyla savaşta olanlar) kırmızı bir dış çerçeveyle
  işaretlenir (`HaritaGorunumu.savaslari_yenile()`, savaş ilan edilince/barış yapılınca
  çağrılır).
- **Yeni işgal edilen bölgeler** (son `isgal_cezasi_gun` (60) gün içinde el değiştirmiş,
  hâlâ ev sahibine dönmemiş — bkz. 9. Ekonomi'deki üretim cezası) turuncu bir çerçeveyle
  işaretlenir (`HaritaGorunumu.isgalleri_yenile()`, her oyun günü başında çağrılır).
  Çerçeveler öncelik sırasıyla üst üste çizilir: savaş/işgal en altta, oyuncu çerçevesi
  üstte — aynı kenar birden fazla çerçeveye girerse üsttekinin rengi görünür.
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

## 5. Ana menü ve ülke seçimi

Temel çözünürlük 1920 × 1080, yatay. Ölçekleme `canvas_items`, en-boy `expand`.

**Ana menü** (`AnaMenu`): oyun açılır açılmaz haritanın üstünde görünen, dokunuşu yutan bir
menü. Dört düğme:

- **Yeni oyun:** varsa kayıt dosyası onay penceresinden sonra silinir (`KayitYoneticisi.sil()`);
  `Oyun`/`Dunya` zaten hiç kayıt uygulanmadan taze kurulmuş olduğundan başka bir şey
  yapmaya gerek yoktur, menü kapanır ve oyuncu normal "Ülkeni seç" akışına düşer.
- **Devam et:** yalnızca bir kayıt varken etkindir; basılınca açılışta okunan kayıt
  `Oyun.kayittan_yukle()` ve `Zaman.durumu_uygula()` ile uygulanır (bkz. 11. Kayıt).
- **Nasıl oynanır:** oyunun amacını ve temel eylemlerini özetleyen, kapatılabilir bir
  bilgi paneli açar.
- **Ayarlar:** şu an yalnızca **"Kaydı sil"** içerir (onaylı, kayıt yoksa pasif); tek
  kalıcı ayar kayıt dosyasıdır, başka bir ayar (ses, grafik) henüz yok.

Menü kapanınca (Yeni oyun ya da Devam et) aşağıdaki ülke seçimi akışı başlar:

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

**Üst çubuk:** solda oyuncunun ülkesi, tarih-saat, hazine ve (varsa) **üretim göstergesi**
("İnşa: Tümen (45 sa)", birden fazla iş kuyrukta beklerse "+N" eklenir — bkz.
`Oyun.onde_ki_is()`/`kuyruktaki_is_sayisi()`, her saat ve kuyruk değiştiğinde güncellenir);
sağda durdur/devam düğmesi, üç hız düğmesi, "Ordu: YZ" ve "Sıralama". Etkin hız ve
durdurulmuş hâl sarı renkle vurgulanır. "Ordu: YZ" ve "Sıralama" ülke seçilene kadar gizlidir
(o anda işlevleri yok; gizli olmaları "Ülkeni seç" yazısıyla birlikte üst çubuğun 16:9
ekrana sığmasını sağlar).

- Dokunulabilir her öğe en az **96 × 96 px**. Düğmeler şu an 132 × 104 px ve daha büyüktür.
- Arayüz yazıları en az 36 px, harita yazıları en az 24 px.
- Arayüz, çentik ve yuvarlak köşelerin dışında, güvenli alanın (safe area) içinde kalır.
- Onay pencereleri (Yeni oyun, Kaydı sil, Savaş ilan et) Türkçedir ("Onay", "Evet",
  "Vazgeç") ve düğmeleri de bu sınırlara uyar (`ArayuzTemasi.onay_penceresi_olustur()`).

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

Birlik: **tümen**. Gücü 0-100 arasındadır (bkz. data/balance.json → "ordu"). Üç tümen türü
vardır (`sim/birlik_turleri.gd`, sayılar data/balance.json → "birlik_turleri"):

| Tür | Fiyat | Süre | Bakım/gün | Saldırı | Savunma | Hız | Üstün olduğu |
|---|---|---|---|---|---|---|---|
| Piyade | 40 | 4 gün | 0,4 | ×1,0 | ×1,0 | ×1,0 | topçu |
| Zırhlı | 90 | 7 gün | 1,0 | ×1,2 | ×0,9 | ×0,6 süre (hızlı) | piyade |
| Topçu | 60 | 5 gün | 0,6 | ×1,1 | ×1,1 | ×1,1 süre (yavaş) | zırhlı |

- **Üstünlük üçgeni:** zırhlı > piyade > topçu > zırhlı. Üstün tür, yendiği türe
  `ustunluk_bonusu` (+%50) fazla hasar verir. Karışık bir yığında bonus, karşı tarafın
  gücünün o türdeki payıyla orantılıdır (yarısı piyade olan yığına zırhlı +%25).
- Karışık yığın tek muharebede çözülür; yığın en yavaş türünün hızıyla yürür.
- Türü bilinmeyen tümenler piyade sayılır.

- **Başlangıç ordusu:** ülke başına tümen sayısı nüfus ve GSYH'den basit bir puanla çıkar:
  `puan = (sqrt(nufus / nufus_bolen) + sqrt(gsyh_milyon_dolar / gsyh_bolen)) / 2`, yuvarlanıp
  `asgari_tumen`-`azami_tumen` (1-24) arasına sınırlanır. Sabitler data/balance.json →
  "ordu" içindedir; dengesi ileride uzun koşu sınamasıyla ayarlanacaktır (bkz. 9. Yol
  haritası, H).
- **Başlangıçta tür dağılımı:** kişi başı GSYH `ordu.kisi_basi_gsyh_alt` (2 000 $) ile
  `kisi_basi_gsyh_ust` (50 000 $) arasında `agir_pay_asgari` (%10) ile `agir_pay_azami`
  (%50) arasında bir "ağır tümen" (zırhlı + topçu) payı verir; zengin ülkenin zırhlı ve
  topçusu daha çoktur. Ağır tümenler zırhlı ve topçu arasında dönüşümlü dağıtılır.
- **Yerleşim:** tümenler başkent bölgesine ve kara sınırı olan (başka ülkeye komşu) bölgelere
  sırayla dağıtılır; sınır bölgesi yoksa (ör. ada ülkesi) hepsi başkente yerleşir.
- **Gösterim:** aynı bölgedeki bütün tümenler haritada tek bir kutu olarak görünür; kutu
  bölgenin sahibinin renginde, solunda toplam güç, sağında her tür için sade bir işaret ve
  tümen sayısı yazar (piyade çarpı, zırhlı yatay oval, topçu dolu daire; ör. "520 ✕3 ⬭2 ●1").
  Kutu, bölge adları gibi yakınlıktan bağımsız, sabit ekran boyutundadır. Kutular üst üste
  binmez: güçlü bölgeden zayıfa, her kutu için etiketin üstü, solu ve sağı, gerekirse 4 kata
  kadar daha üstü denenir; yerinden kayan kutu bölgesine ince bir çizgiyle bağlanır. Birlik kartında
  tümen sayısı türlere göre yazar ("Tümen: 6 (Piyade 3 · Zırhlı 2 · Topçu 1)").
- **Seçme ve emir:** oyuncunun kendi tümenlerinin olduğu bölgeye dokununca birlik kartı
  açılır. Kart açıkken başka bir bölgeye dokunmak hareket emridir: tümenler
  `YolBulucu`nun bulduğu sürede hedefe yürür. Kara komşuluğu, iki bölgenin etiket noktaları
  arasındaki mesafe × `hareket.kara_saat_birim_basi` (0,33) saat sürer, en az 8 en çok 48
  saat (eski haritadaki ortalama komşu uzaklığı 74 birim ≈ 24 saat); böylece sık bölgeli
  ülkelerde yürümek anlamsızca yavaşlamaz. Deniz yolu daha yavaştır; yürürken
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
  - Bir tarafın verdiği hasar, tümenlerinin türüne göre (`saldiri` ya da savunurken
    `savunma` çarpanı, karşı tarafın tür dağılımına göre üstünlük bonusu) ve Silah
    teknolojisine göre artar; alınan hasar tümenlere güçleriyle orantılı dağıtılır ve
    Savunma teknolojisine bölünür (bkz. 10a. Teknoloji).
  - **Savunan** `savunan_avantaji` (×1,25) kadar avantajlıdır: verdiği hasar bu oranda artar;
    bölgenin tahkimatı da seviye başına +%15 ekler (bkz. 10b. Tahkimat).
  - Son adımı deniz yoluyla gelen **saldırgan** tümenler `deniz_cezasi` (×0,70) alır: güçleri
    hasap edilirken bu oranda azalır. Lojistik teknolojisi cezayı seviye başına 0,1 hafifletir.
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
- **Harcama:** `Oyun.tumen_sirala(ulke, bolge, tur)`, `fabrika_sirala()` ve `tahkimat_sirala()`,
  bir ülkenin (kendi) bir bölgesinde iş sıralar; maliyet hemen hazineden düşülür (yetmezse sıralanamaz). Her
  ülkenin **tek** bir inşa kuyruğu vardır (`Oyun.insa_kuyruklari`), en fazla
  `AZAMI_KUYRUK_UZUNLUGU` (5) iş bekleyebilir; yalnızca kuyruğun ÖNÜNDEKİ iş ilerler,
  arkadakiler sırasını bekler. Süresi dolan tümen işi, belirtilen bölgede
  `baslangic_gucu` ile yeni bir tümen doğurur; fabrika işi bölgenin `fabrika_sanayisi`'ni
  kalıcı olarak `fabrika_sanayi_artisi` kadar artırır (bkz. yukarıdaki "Sanayi"). Tümenin
  fiyatı ve süresi türüne göredir (bkz. 7. Birlikler); fabrika sabitleri data/balance.json →
  "ekonomi".
- **Bakım:** her oyun günü başında (gelir eklendikten sonra), her ülkenin tümenlerinin
  türlerine göre bakımları toplamı (bkz. 7. Birlikler) hazinesinden düşülür. Hazine yetmezse 0'da kalır ve açık, o
  ülkenin bütün tümenlerine güçleriyle orantılı kayıp olarak yansıtılır (muharebedeki
  `_guc_azalt` ile aynı mekanizma); güç `ASGARI_GUC` altına düşen tümen silinir.
- **Gelir çarpanı:** Sanayi teknolojisi geliri seviye başına %10 artırır.
- Arayüz: oyuncunun kendi bölgesine dokununca açılan bölge ya da birlik panelinde
  **"Tümen kur"**, **"Fabrika kur (500)"** ve **"Tahkimat 1/3 · Kur (160)"** düğmeleri vardır
  (maliyetler data/balance.json'dan gelir); iş o bölgeye sıralanır. "Tümen kur" ortada üç
  büyük seçenek açar (her birinde fiyat, süre ve neye karşı güçlü olduğu) ve "Vazgeç". Sıralanamazsa (hazine yetmiyor ya
  da kuyruk dolu) nedeni bildirim kartında yazar; sıralanınca da kısa bir bildirim çıkar.

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
- **Tümen türü:** taban ağırlıklarla (`yapay_zeka.tur_agirliklari`: piyade 0,45, zırhlı 0,3,
  topçu 0,25) rastgele seçilir; komşu ülkelerin toplamda en çok kullandığı türe üstün gelen
  türün ağırlığı `karsi_tur_bonusu` (+%60) artar. Seçilen türün parası yetmiyorsa ucuz bir
  türe geçmez, para birikene kadar bekler (yoksa piyade hep önce alınıyordu).
- **Araştırma:** araştırması yoksa günde `arastirma_olasiligi` (×0,3) olasılıkla en geride
  kalan dalda bir sonraki seviyeye başlar.
- **Tahkimat:** günde `tahkimat_olasiligi` (×0,08) olasılıkla başkentini ya da savaştığı bir
  ülkeye komşu bölgelerinden en az tahkim edilmiş olanı bir seviye tahkim eder.
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

## 10a. Teknoloji

Dört dal, her biri 3 seviye (`sim/teknoloji.gd`, sayılar data/balance.json → "teknoloji"):

| Dal | Seviye başına |
|---|---|
| Sanayi | Gelir +%10 |
| Silah | Verilen hasar +%10 |
| Savunma | Alınan hasar ÷ (1 + 0,1 × seviye) |
| Lojistik | Hız +%15 (yürüyüş süresi bu orana bölünür), denizden saldırı cezası 0,1 hafifler |

- Her ülke aynı anda **tek** araştırma yürütür. Seviye n'nin maliyeti `taban_maliyet` × n
  (150, 300, 450), süresi `taban_sure_gun` × n gün (30, 60, 90); maliyet hazineden peşin ödenir.
- Bitince seviye artar; oyuncuya "Araştırma tamamlandı: Silah 2 (Saldırı +%20)." bildirimi gelir.
- **Arayüz:** üst çubuktaki "Teknoloji" düğmesi paneli açar: 4 satır × 3 kutu, her kutuda
  seviyenin ne verdiği, fiyatı ve süresi. Biten seviyeler sarı, sıradaki seviye dokunulabilir,
  sonrakiler kapalı; başlığın yanında süren araştırmanın kalan günü ve ilerleme çubuğu.
  Panel açılınca bölge seçimi kalkar, bir bölge seçilince panel kapanır (aynı yeri kaplarlar).

## 10b. Tahkimat

- Oyuncu kendi bölgesinde "Tahkimat" düğmesiyle bir seviye tahkimat sıralar (inşa kuyruğuna
  girer). En çok `tahkimat.azami_seviye` (3) seviye; kuyrukta bekleyenler de sayılır.
  Seviye n'nin maliyeti `taban_maliyet` × n (40, 80, 120), süresi `sure_saat` (240 saat).
  Bölgeler ~2 kat sıklaşınca bölge başına gelir yarıya indiği için maliyet de yarıya indi.
- Savunanın verdiği hasar seviye başına `seviye_avantaji` (+%15) artar.
- Bölge el değiştirince tahkimatı 1 seviye düşer.
- **Arayüz:** haritada tahkimatlı bölgenin adının solunda gri bir kule ve içinde seviyesi;
  kendi bölgende düğmede "Tahkimat 2/3", başkasının bölgesinde bölge panelinde "Tahkimat: 2/3".

## 10c. Savaş sisi

- Yeni oyun ekranında "Savaş sisi: Açık / Kapalı" seçilir (`Oyun.savas_sisi`, kayıtta saklanır).
- **Görünen bölgeler** (`sim/gorunurluk.gd`): ülkenin kendi bölgeleri, kendi tümenlerinin
  bulunduğu bölgeler ve bunlara kara ya da deniz yoluyla komşu bölgeler. İttifak yok.
- Oyuncunun görmediği bölgelerde yabancı tümenler, muharebe işaretleri, yürüyüş çizgileri ve
  tahkimat işaretleri çizilmez; bölgelerin sahibi (rengi) her zaman görünür. Görünmeyen
  bölgelerin dolgusu %32 koyulaşır. Bölge panelinde "Birlikler: bilinmiyor" yazar (görülen
  bölgede "Birlikler: 3 (güç 280)" ya da "Birlikler: yok").
- Görünürlük her karede değil, yalnızca tümenler ya da sahiplikler değişince
  (`birlikler_degisti`, `bolge_sahipligi_degisti`) yeniden hesaplanır; sonuç değişirse
  `Oyun.gorunurluk_degisti` yayılır ve harita dolgu ağını bir kez yeniden kurar.
- Sis kapalıyken ya da oyuncu henüz ülke seçmemişken her yer görünür.
- **Yapay zekâ da aynı kuralla görür** (sis seçeneğinden bağımsız): savaş ilanında komşusunun
  gücünü yalnızca gördüğü bölgelerdeki tümenlerinden bilir; tümen türü seçerken yalnızca
  gördüğü bölgelerdeki yabancı tümenlerin türlerine bakar. Saldırı ve tahkimat kararları
  zaten yalnızca komşu bölgelere bakıyordu.

## 10d. Animasyon ve ses

Animasyonlar ve sesler yalnızca sunumdur; simülasyonu değiştirmez ve yavaşlatmaz.

- **Ayarlar** (ana menü → Ayarlar, `user://ayarlar.json`, `sim/ayarlar.gd`): "Animasyonlar: Açık /
  Azaltılmış", ses düzeyi ("−" / "+", %10 adımla) ve "Sessiz: Açık / Kapalı". Kayıttan ayrıdır.
- **Harita:** yürüyen tümen kutuları kaynakla hedef arasında, geçen zamana göre kayar
  (`Birlik.cikis_saati`, `Zaman.saat_kesri`). Muharebe işareti hafifçe atar; altındaki küçük
  çubuk savunanın (solda) ve saldıranın güç oranını gösterir. El değiştiren bölge 0,7 saniyelik
  beyaz bir parlamayla yeni sahibinin rengine döner (`Oyun.bolge_el_degistirdi`).
- **Arayüz:** paneller solarak açılıp kapanır, düğmeler basılınca hafifçe küçülür, bildirim
  kartları sağdan kayarak gelir (`arayuz/gecis.gd`). Zafer, kaybetme ve oyuncunun savaştığı bir
  ülkenin teslimi ekranın ortasında kısa, tam genişlikte bir şeritle duyurulur (`SeritPaneli`).
- Üst katman yalnızca ekranda süren bir animasyon varken her kare yeniden çizilir. Ekran dışındaki
  tümenler ve parlamalar çizilmez. En yüksek oyun hızında ve "Azaltılmış" seçiliyken tümenler
  kaymaz (eskisi gibi bölgelerinde görünür), işaret atmaz, parlama ve panel geçişi olmaz.
- **Ses** (`tools/ses_uret.py` sentezler, `sounds/*.wav`; dışarıdan dosya yok, müzik yok):
  tıklama (her düğme), onay ve hata (inşa, araştırma, barış sonucu), emir (yürüyüş), muharebe
  başlangıcı, bölge ele geçirme, savaş ilanı, üretim bitti, zafer, kaybetme. Yalnızca oyuncuyu
  ilgilendiren olaylarda çalar (`SesYoneticisi`); aynı ses 0,25 sn'de (en yüksek hızda 1,2 sn'de)
  bir kereden sık çalmaz, aynı anda en çok 4 ses çalar.

## 11. Kayıt

Tek kayıt yuvası: `user://kayit.json`. Oyun verisi `data/` altındaki dosyalardan ayrıdır ve
yalnızca buraya yazılır (bkz. 2. Harita verisi'ndeki "Oyun yalnızca data/ altındaki dosyaları
okur" kuralı); kayıt, oyunun DURUMUNU tutar, coğrafyayı değil.

- **Ne kaydedilir** (`Oyun.kaydet_icin_veri()`): oyuncunun ülkesi; değişmiş bölgeler
  (sahip, işgal saati, fabrika sanayisi — hiç değişmemiş bölgeler yer kaplamasın diye
  atlanır; tahkimat da burada); bütün tümenler (türleriyle); savaşlar (ilan saatleriyle);
  hazineler; inşa kuyrukları; teknoloji seviyeleri ve süren araştırmalar.
  Zaman durumu (`Zaman.durumu_al()`) ayrıca eklenir; `KayitYoneticisi` Zaman autoload'ına
  bağlı olmasın diye bu, çağıran taraftan (main.gd) parametre olarak verilir.
- **Sürüm:** dosyada bir `surum` sayısı durur (`KayitYoneticisi.SURUM`, şu an 4; 4. sürümde
  savaş sisi tercihi eklendi, 3. sürüm kayıt da açılır ve sis açık sayılır). 3. sürümde
  bölgeler yeniden üretildi ve bölge kimlikleri değişti; bu yüzden yalnızca 3. sürüm açılır.
  Daha eski bir kayıt bulunursa ana menüde "Bu kayıt eski bir sürüme ait. Yeni oyun başlat."
  yazar, "Devam et" kapalı kalır, "Yeni oyun" onay sormadan eski kaydı silip başlar. Oyun
  çökmez; eski bir kayıt sessizce bozuk davranışa yol açmaz.
- **Otomatik kayıt:** her oyun günü başında (`Zaman.gun_basladi`) ve uygulama arka plana
  geçince ya da kapatılmak istenince (`NOTIFICATION_APPLICATION_PAUSED`,
  `NOTIFICATION_WM_CLOSE_REQUEST`). Oyuncu henüz ülkesini seçmediyse kaydedilmez (henüz
  korunacak bir ilerleme yok).
- **Yükleme:** oyun açılışta kaydı okur ama hemen uygulamaz; ana menüde oyuncu "Devam et"e
  basınca `Oyun.kayittan_yukle()` (OrduKurucu'nun ürettiği taze orduyu ve dünyanın başlangıç
  sahipliklerini tamamen değiştirir) ve `Zaman.durumu_uygula()` çağrılır (bkz. 5. Ana menü
  ve ülke seçimi). "Yeni oyun" seçilirse hiç uygulanmaz; `Oyun`/`Dunya` zaten taze kurulmuştur.

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
- **Güç sıralaması:** üst çubuktaki "Sıralama" düğmesi, hâlâ var olan (en az bir bölgesi
  kalan) her ülkeyi toplam askeri güce göre büyükten küçüğe sıralayan paneli açar
  (`Oyun.guc_siralamasi()`, `SiralamaPaneli`). İlk 10 ülke ve altında, oyuncu ilk 10'da
  değilse ayraçla ayrılmış kendi sırası gösterilir; oyuncunun satırı vurgu rengiyle
  işaretlenir. Zamanı durdurmaz, bilgi amaçlıdır.
- **Bildirimler:** oyuncuyla ilgili önemli olaylarda (`Oyun.bildirim_gonder(metin, bolge_id)`)
  sağ üstte, üst çubuğun altında küçük kartlar birikir (`BildirimKutusu`, en yenisi en
  üstte, en fazla 4 — fazlası okunmadan atılır). Üç olay: sana savaş ilanı (düşmanın
  başkentine odaklar), bölge kaybı/kazancı, üretim bitti (tümen/fabrika). Karta dokunmak
  onu kapatır VE kamerayı `HaritaKamerasi.odaklan()` ile ilgili bölgeye götürür
  (`Bolge.sinir_kutusu()`). Zamanı durdurmaz, oyuncunun KENDİ ülkesini ilgilendirmeyen
  olaylar (ör. iki YZ ülkesi arasında savaş) bildirim üretmez.

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
| `sim/birlik.gd` | Bir tümenin verisi: sahip, tür, bulunduğu bölge, güç |
| `sim/birlik_turleri.gd` | Tümen türlerinin sayıları ve üstünlük üçgeni |
| `sim/teknoloji.gd` | Teknoloji dalları, seviyelerin maliyeti, süresi ve etkisi |
| `sim/ordu_kurucu.gd` | Ülkelerin başlangıç ordusunu üretir |
| `sim/insa_isi.gd` | İnşa kuyruğundaki tek bir iş: tümen (türüyle), fabrika ya da tahkimat |
| `sim/kayit_yoneticisi.gd` | Oyun durumunu user:// altına JSON olarak kaydeder/yükler |
| `sim/takvim.gd` | Saat sayısını tarihe çevirir |
| `sim/zaman.gd` | Zaman yöneticisi (autoload `Zaman`) |
| `gorsel/harita_gorunumu.gd` | Dolguları, sınırları, çerçeveleri, vurguları, adları ve tümen kutularını çizer |
| `gorsel/sinir_cizgisi.gdshader` | Sınır çizgilerini ekranda sabit kalınlıkta çizer |
| `gorsel/harita_kamerasi.gd` | Kaydırma, yakınlaştırma, dokunuşu ayırma, ülkeye odaklanma |
| `arayuz/arayuz.gd` | Arayüzün kökü ve güvenli alan |
| `arayuz/ust_cubuk.gd`, `bolge_paneli.gd` | Üst çubuk, alt panel |
| `arayuz/arayuz_temasi.gd`, `bicim.gd` | Ortak görünüm, sayı biçimleme |
| `arayuz/tumen_secim_paneli.gd` | "Tümen kur"un üç seçenekli tür seçimi |
| `arayuz/teknoloji_paneli.gd` | Teknoloji paneli (4 dal × 3 seviye, ilerleme çubuğu) |
| `tests/uzun_kosu.gd` | 5 yıllık tam YZ koşusu ve denge hedefleri raporu |

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
| 7a | ✅ | **Birlik türleri, teknoloji, tahkimat** | Piyade/zırhlı/topçu ve üstünlük üçgeni, 4 dal × 3 seviye araştırma, 3 seviye tahkimat, YZ'nin üçünü de kullanması |
| 8 | ⬜ | **Android** | Dışa aktarma, gerçek telefonda dokunma ve güvenli alan denemesi, performans |

Kapsam dışı (istenmedikçe eklenmez): hava ve deniz kuvvetleri, diplomasi, odak ağacı,
çok oyunculu oyun.

**Denge hedefleri** (`tests/uzun_kosu.gd`, 5 yıllık tam YZ oyunu): 5-30 ülke teslim olur,
hiçbir ülke dünyadaki bölgelerin %40'ını geçmez, üç tümen türünün her biri üretimin en az
%15'i olur, koşu 120 saniyeden kısa sürer.

## 15. Geçmiş

2 Ekim 2026'ya kadar oyun, kurgusal Kalmera kıtasında geçen "Altı Sancak" olarak
tasarlanmıştı. O hâli git'te `kalmera-arsiv` etiketiyle durur. Kamera, dokunma, zaman
yöneticisi ve arayüz kodu oradan devralındı; harita üretici, bölge ve ülke verileri,
bloklar, zafer puanı ve 1931–1935 süre sınırı kaldırıldı.
