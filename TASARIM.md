# TASARIM — Altı Sancak

Bu belge oyunun tek tasarım kaynağıdır. Kod yazılırken buradaki kurallar ve
adlar esas alınır. Bir kural değişecekse önce bu belge güncellenir.

---

## 1. Oyunun adı ve dönemi

- **Ad:** Altı Sancak
- **Tür:** Gerçek zamanlı (durdurulabilir) büyük strateji, tek oyunculu.
- **Platform:** Android, yatay ekran. Motor: Godot 4.7, GDScript, 2D, Mobile renderer.
- **Dünya:** Tamamen kurgusal **Kalmera** kıtası. Gerçek ülke, şehir, harita ya da
  tarihî kişi yoktur.
- **Dönem:** Teknoloji düzeyi 1930'lar (piyade, süvari, ilk tanklar).
  Oyun **1 Ocak 1931**'de başlar, **1 Ocak 1935**'te biter (4 oyun yılı).
- **Oyuncu ne yapar:** Altı ülkeden birini seçer, fabrikalarıyla birlik üretir,
  birliklerini harita üzerinde yürütür ve karşı bloğu teslim olmaya zorlar.

---

## 2. Kapsam

| Öğe | Değer |
|---|---|
| Ülke | 6 (iki sabit blok, 3'e 3) |
| Bölge | 72 (ülke başına 12) |
| Savaş türü | Yalnızca kara |
| Birlik tipi | 3 (piyade, süvari, zırhlı) |
| Kaynak | 3 (insan gücü, çelik, petrol) |
| Bir oyunun süresi | En yüksek hızda yaklaşık 25 dakika, durdurmalarla 1–2 saat |

### Ülkeler ve bloklar

Diplomasi yoktur; bloklar sabittir ve savaş oyunun ilk saatinden itibaren açıktır.

| Blok | Ülke | `id` | Renk |
|---|---|---|---|
| Kuzey Antlaşması (`kuzey`) | Vardanya | `vardanya` | mavi |
| Kuzey Antlaşması (`kuzey`) | Kelmor | `kelmor` | yeşil |
| Kuzey Antlaşması (`kuzey`) | Suvat | `suvat` | mor |
| Güney Birliği (`guney`) | Darmek | `darmek` | kırmızı |
| Güney Birliği (`guney`) | Yelbor | `yelbor` | sarı |
| Güney Birliği (`guney`) | Orsin | `orsin` | turuncu |

Kuzey bloğu soğuk, güney bloğu sıcak renkler taşır; yan yana duran iki ülkenin
rengi birbirine benzemez.

İki ülke **farklı bloktaysa düşmandır**, aynı bloktaysa müttefiktir. Kodda bu
tek bir işlevle sorulur: `dusman_mi(ulke_a, ulke_b)`.

### Harita

- Dünya 4200 × 2400 pikseldir. İçine 200 nokta serpilir ve **Voronoi** yöntemiyle
  200 hücreye bölünür. Merkeze en yakın 72 hücre kara (Kalmera kıtası), kalanı denizdir.
- Kıtanın çevresi denizdir. Hücre kenarları rastgele kırılarak kıyılar girintili
  çıkıntılı, iç sınırlar hafif eğri yapılır.
- Kuzeydeki 36 bölge Kuzey Antlaşması'na, güneydeki 36 bölge Güney Birliği'ne aittir.
  Her blok batıdan doğuya 12'şer bölgelik üç ülkeye bölünür; her ülke tek parçadır.
  Cephe, kıtayı doğudan batıya kesen bloklar arası sınırdır.
- Her ülkenin bir başkenti (cepheden uzak) ve bir şehri daha vardır.
- Harita `tools/harita_uretici.gd` ile **sabit bir tohumla** bir kez üretilip
  `data/provinces.json` ve `data/countries.json` dosyalarına yazılır. Aynı tohum hep
  aynı haritayı verir. **Oyun çalışırken harita üretilmez**, yalnızca bu dosyalar okunur.

Haritayı yeniden üretmek için:

- Godot içinden: `tools/harita_uret_editor.gd` dosyasını betik düzenleyicisinde aç,
  Dosya → Çalıştır (Ctrl+Shift+X).
- Komut satırından: `godot --headless --path . --script res://tools/harita_uret_cli.gd`

Başka bir harita için `tools/harita_uretici.gd` içindeki `TOHUM` sayısı değiştirilir.

---

## 3. Veri yapıları

Tüm başlangıç verisi `data/` altında JSON olarak durur. Bu dosyalar oyun
çalışırken **asla değiştirilmez**; oyun sırasında değişen durum bellekte tutulur,
kayıtlar `user://` altına yazılır.

| Dosya | İçerik | Durum |
|---|---|---|
| `data/provinces.json` | Dünya boyutu ve 72 bölge (araçla üretilir) | var |
| `data/countries.json` | 2 blok ve 6 ülke (araçla üretilir) | var |
| `data/terrain.json` | Arazi türleri ve çarpanları | var |
| `data/balance.json` | Formüllerdeki sabitler (şimdilik yalnızca zaman) | var |
| `data/unit_types.json` | 3 birlik tipi | 7. adımda |
| `data/start.json` | Ülkelerin başlangıç kaynakları ve birlikleri | 7. adımda |

Dosya adları İngilizcedir. Dosyaların içindeki anahtarlar ve koddaki adlar
Türkçedir, ama Türkçe'ye özgü harf içermez (`bolge`, `ulke`, `guc`). Ekranda
görünen metinlerde Türkçe harfler kullanılır (`"ad": "Gedirge"`).

### 3.1 Bölge (`data/provinces.json`)

```json
{
	"tohum": 1931,
	"dunya": {"genislik": 4200, "yukseklik": 2400},
	"bolgeler": [
		{
			"id": "b09",
			"ad": "Gedirge",
			"sahip": "vardanya",
			"arazi": "sehir",
			"komsular": ["b06", "b10", "b11", "b13"],
			"zafer_puani": 5,
			"insan_gucu": 40,
			"celik": 0,
			"petrol": 0,
			"fabrika": 3,
			"merkez": [1278, 732],
			"kose_noktalari": [[1202, 878], [1191, 851], [1176, 825], [1168, 797]]
		}
	]
}
```

- `sahip`: oyun başındaki sahip. Oyun içinde bölgeyi ele geçiren ülke yeni sahibi olur.
- `arazi`: `ova`, `orman`, `dag` ya da `sehir`.
- `komsular`: iki yönlü olmalı (A, B'nin komşusuysa B de A'nın komşusudur).
- `zafer_puani`: başkent 5, şehir 3, fabrikası ya da kaynağı olan bölge 1, kalanlar 0.
- `insan_gucu`, `celik`, `petrol`: bölgenin **günlük geliri**.
- `merkez`: simge ve yazının çizileceği nokta.
- `kose_noktalari`: bölgenin çokgeni (gerçekte bölge başına yaklaşık 30 nokta).
  Komşu iki bölge ortak sınırlarındaki noktaları **birebir aynı** taşır; sınır
  çizgileri buna dayanarak çıkarılır.
- Başkent olup olmadığı burada yazmaz; `countries.json` içindeki `baskent` alanından anlaşılır.

Bölge numaraları ülke sırasıyla gider: `b01`–`b12` Vardanya, `b13`–`b24` Kelmor,
`b25`–`b36` Suvat, `b37`–`b48` Darmek, `b49`–`b60` Yelbor, `b61`–`b72` Orsin.

### 3.2 Arazi (`data/terrain.json`)

```json
{
	"ova": { "ad": "Ova", "hareket": 1.0, "savunma": 1.0 },
	"orman": { "ad": "Orman", "hareket": 1.5, "savunma": 1.25 },
	"dag": { "ad": "Dağ", "hareket": 2.0, "savunma": 2.0 },
	"sehir": { "ad": "Şehir", "hareket": 1.0, "savunma": 1.5 }
}
```

Haritada 30 ova, 19 orman, 11 dağ ve 12 şehir (6 başkent + 6 şehir) vardır.

### 3.3 Ülke ve blok (`data/countries.json`)

```json
{
	"bloklar": [
		{ "id": "kuzey", "ad": "Kuzey Antlaşması" },
		{ "id": "guney", "ad": "Güney Birliği" }
	],
	"ulkeler": [
		{ "id": "vardanya", "ad": "Vardanya", "blok": "kuzey", "renk": "#3b6fb6", "baskent": "b09" }
	]
}
```

Başkentler her zaman `sehir` arazisindedir ve haritadaki en yüksek zafer puanını (5) taşır.

Her ülke 6–8 fabrikayla başlar; ülkeler arasında küçük farklar vardır (biri
sanayide, biri nüfusta güçlü). Başlangıç kaynakları ve birlikleri (ülke başına
yaklaşık 7 piyade, 1 süvari, 1 zırhlı) 7. adımda `data/start.json` dosyasına
yazılacaktır; `countries.json` harita üreticisi tarafından yeniden yazıldığı için
elle girilen veri orada tutulmaz.

### 3.4 Birlik tipi (`data/unit_types.json`, 7. adımda)

```json
{
  "id": "piyade",
  "ad": "Piyade Tümeni",
  "saldiri": 10,
  "savunma": 14,
  "azami_org": 60,
  "hiz": 1.0,
  "maliyet": { "uretim_puani": 120, "insan_gucu": 3000, "celik": 40, "petrol": 0 }
}
```

| Tip | Saldırı | Savunma | Azami org | Hız | Üretim puanı | İnsan gücü | Çelik | Petrol |
|---|---|---|---|---|---|---|---|---|
| Piyade Tümeni (`piyade`) | 10 | 14 | 60 | 1.0 | 120 | 3000 | 40 | 0 |
| Süvari Tümeni (`suvari`) | 9 | 8 | 50 | 1.6 | 140 | 2500 | 30 | 0 |
| Zırhlı Tümen (`zirhli`) | 18 | 10 | 40 | 2.0 | 300 | 1500 | 150 | 60 |

### 3.5 Birlik (oyun içi durum)

Birlikler oyun başında başlangıç verisinden ve sonra üretimden doğar.
Kayıt dosyasında şu biçimde saklanır:

```json
{
  "id": 42,
  "tip": "piyade",
  "ulke": "vardanya",
  "bolge": "b09",
  "guc": 100.0,
  "org": 60.0,
  "rota": ["b10", "b13"],
  "hareket_kalan_saat": 17
}
```

- `guc`: 0–100. Birliğin canı. 0 olursa birlik yok olur.
- `org`: 0–`azami_org`. Savaşma isteği. 0 olursa birlik savaştan çekilir.
- `rota`: sırayla gidilecek bölgeler. Boşsa birlik duruyordur.
- `hareket_kalan_saat`: rotadaki ilk bölgeye varmaya kalan saat.

---

## 4. Zaman sistemi

- **1 tick = 1 oyun saati.** Bütün simülasyon tick ile ilerler; kare hızına bağlı değildir.
- Takvim sadeleştirilmiştir: her ay 30 gün, yıl 360 gün.
- **Durdurma:** Oyun durmuşken tick atılmaz ama emir verilebilir. Oyun durdurulmuş başlar.
- **Üç hız:**

| Hız | Saniyede tick | 1 oyun günü |
|---|---|---|
| 1 | 2 | 12 saniye |
| 2 | 6 | 4 saniye |
| 3 | 24 | 1 saniye |

- Bir karede en çok 5 tick işlenir (yavaş cihazda takılmayı önlemek için).
- Başlangıç yılı, bitiş yılı ve hızlar `data/balance.json` içindeki `zaman` bölümünden okunur.
- Tarih 1 Ocak 1935, 00:00'a ulaşınca zaman durur, bir daha başlatılamaz ve ekrana
  "Süre doldu" yazılır.
- Uygulama arka plana atılınca oyun kendiliğinden durur (21. adımda eklenecek).

### Zaman yöneticisi

Zaman, `Zaman` adlı autoload ile yönetilir (`scripts/sim/zaman.gd`). Şu sinyalleri yayar:

| Sinyal | Ne zaman |
|---|---|
| `saat_gecti(toplam_saat)` | Her oyun saatinde |
| `gun_basladi(toplam_gun)` | Saat 00:00 olduğunda, `saat_gecti`'den sonra |
| `durum_degisti` | Durdurma ya da hız değiştiğinde |
| `sure_doldu` | Bitiş tarihine ulaşıldığında, bir kez |

Ekonomi, savaş ve yapay zekâ ileride bu sinyallere bağlanacaktır.

### Bir tick'te işlem sırası

Sıra sabittir; aynı başlangıç ve aynı rastgele tohumla oyun hep aynı sonucu verir.

1. Hareketleri ilerlet (varışlar, ele geçirmeler).
2. Savaşları çöz.
3. Savaşta olmayan birliklerin organizasyonunu yenile.
4. Saat 00:00 ise **günlük işlemler:** gelir → üretim → takviye → yapay zekâ →
   teslim kontrolü → oyun sonu kontrolü.

---

## 5. Hareket kuralları

- Emir: "şu birlik şu bölgeye gitsin". Rota, komşuluk üzerinden en kısa süreli
  yol olarak hesaplanır (A*).
- Birlik kendi bölgelerinden ve müttefik bölgelerinden serbestçe geçer.
- Bir bölgeye geçiş süresi:

```
sure_saat = yukari_yuvarla( 24 × arazi.hareket[hedef] / birlik_tipi.hiz )
```

  Örnek: piyade ovaya 24 saatte, dağa 48 saatte; zırhlı ovaya 12 saatte girer.

- Birlik, süre dolana kadar çıkış bölgesinde sayılır; süre dolunca bir anda
  hedefe geçer.
- **Ele geçirme:** Birlik içinde düşman birliği olmayan bir düşman bölgesine
  varırsa bölgenin sahibi o birliğin ülkesi olur.
- **Düşman birliği olan bölge:** Hareket süresi işlemez, onun yerine savaş
  başlar (bkz. 6). Bölgede düşman kalmayınca süre saymaya başlar.
- **Yığın sınırı:** Bir bölgede aynı bloktan en çok 6 birlik durabilir. Varışta
  yer yoksa birlik olduğu yerde kalır ve emri silinir.
- Yeni emir eskisini siler. Yoldaki birliğin harcadığı süre geri gelmez.

---

## 6. Savaş kuralları

Savaş, hedef bölge başına bir tanedir. Farklı bölgelerden aynı hedefe saldıran
birlikler aynı savaşa katılır.

- **Saldıran taraf:** O bölgeye girmek isteyen birlikler (kendi bölgelerinde dururlar).
- **Savunan taraf:** Hedef bölgedeki bütün birlikler.

Her tick'te (saatte bir):

```
S = toplam( saldiri × guc / 100 )                         saldıran birlikler için
V = toplam( savunma × guc / 100 ) × arazi.savunma[hedef]  savunan birlikler için

oran = sinirla( S / V, 0.25, 4.0 )
zar  = rastgele( 0.85, 1.15 )

savunanin_org_kaybi  = ORG_HASAR × oran × zar
saldiranin_org_kaybi = ORG_HASAR / oran × zar
guc_kaybi            = org_kaybi × GUC_ORANI
```

- `ORG_HASAR = 2.0`, `GUC_ORANI = 0.25` (`data/balance.json`).
- Bir tarafın kaybı, o taraftaki birliklere **eşit bölünür**.
- **Örnek:** 2 piyade, ovadaki 1 piyadeye saldırıyor. S = 20, V = 14, oran ≈ 1.43.
  Savunan saatte ≈ 2.9 org kaybeder ve yaklaşık 21 saatte çöker. Saldıranların
  her biri saatte ≈ 0.7 org kaybeder. Aynı saldırı dağda yapılsaydı V = 28 olur,
  oran 0.71'e düşer ve saldıranlar önce çökerdi.

### Savaşın sonu

- **Org'u 0'a düşen savunan birlik geri çekilir:** Aynı bloktan, en az birlik
  bulunan komşu bölgeye anında geçer. Böyle bir komşu yoksa (kuşatılmışsa) **yok olur**.
- **Org'u 0'a düşen saldıran birlik** saldırıyı bırakır; emri silinir, yerinde kalır.
- **Gücü 0'a düşen birlik** yok olur.
- Bir tarafta birlik kalmayınca savaş biter. Savunan kalmadıysa saldıranların
  hareket süresi işlemeye başlar ve varınca bölgeyi ele geçirirler.

### Diğer kurallar

- Saldırı altındaki bölgedeki birlikler savunur; kendi saldırı emirleri savaş
  bitene kadar bekler. Dost bir bölgeye çekilme emri verilebilir.
- **Org yenileme:** Savaşta olmayan birlik saatte `ORG_YENILEME = 1.0` org kazanır.
- **Takviye:** Kendi bloğunun bölgesinde duran ve savaşta olmayan birlik günde
  `TAKVIYE = 2` güç kazanır. Her güç puanı, birlik tipinin insan gücü maliyetinin
  %1'i kadar insan gücü harcar. İnsan gücü yoksa takviye olmaz.

---

## 7. Ekonomi

### Kaynaklar

| Kaynak | Günlük gelir | Kullanım |
|---|---|---|
| İnsan gücü | sahip olunan bölgelerin `insan_gucu` toplamı | Birlik üretimi, takviye |
| Çelik | sahip olunan bölgelerin `celik` toplamı | Birlik ve fabrika üretimi |
| Petrol | sahip olunan bölgelerin `petrol` toplamı | Zırhlı tümen üretimi |

Kaynaklar birikir; üst sınır yoktur. Ele geçirilen bölgenin geliri yeni sahibine geçer.

Bölge gelirleri araziye göre dağıtılmıştır: başkent 40, şehir 32, ova 16–24,
orman 8–16, dağ 4–8 insan gücü verir. Çelik çoğunlukla dağlarda, petrol
çoğunlukla ovalarda çıkar. Bir ülkenin günlük geliri yaklaşık 190–260 insan gücü,
6–9 çelik ve 2–3 petroldür.

### Fabrikalar

- Her fabrika günde **1 üretim puanı** verir.
- Ele geçirilen bölgedeki fabrikalar yeni sahibine geçer.
- Bir bölgede en çok 4 fabrika olabilir.
- Başlangıçta başkentte 3, şehirde 2 ve ülkenin 1–3 bölgesinde birer fabrika bulunur.

### Üretim

- Her ülkenin tek bir **üretim kuyruğu** vardır. Bütün fabrikalar kuyruğun
  ilk sırasındaki işe çalışır; artan puan sıradakine aktarılır.
- Sipariş verilirken insan gücü, çelik ve petrol **peşin** ödenir. Yetmiyorsa
  sipariş verilemez. İptal edilen siparişin kaynakları geri verilir.
- Üretilebilenler:

| İş | Üretim puanı | İnsan gücü | Çelik | Petrol |
|---|---|---|---|---|
| Piyade Tümeni | 120 | 3000 | 40 | 0 |
| Süvari Tümeni | 140 | 2500 | 30 | 0 |
| Zırhlı Tümen | 300 | 1500 | 150 | 60 |
| Fabrika | 360 | 0 | 200 | 0 |

- Biten birlik **başkentte** tam güç ve tam org ile doğar. Başkent elde değilse
  en çok fabrikası olan bölgede doğar.
- Biten fabrika, sipariş verilirken seçilen bölgeye eklenir. O bölge o sırada
  elde değilse iş kuyrukta bekler.
- Örnek: 8 fabrikalı bir ülke bir piyade tümenini 15 günde, bir fabrikayı 45 günde üretir.

Bu bölümdeki bütün sayılar ilk tahmindir; denge adımında `data/balance.json`
üzerinden ayarlanır.

---

## 8. Yapay zekâ

Her yapay zekâ ülkesi günde bir kez (günlük işlemler sırasında) şu kuralları
sırayla uygular. Yapay zekâ hile yapmaz; oyuncuyla aynı kurallara ve aynı emir
işlevlerine bağlıdır.

**Tanımlar**
- *Cephe bölgesi:* Düşman bölgesine komşu olan kendi bölgesi.
- *Tehdit:* Bir cephe bölgesine komşu düşman bölgelerindeki birliklerin
  `saldiri × guc / 100` toplamı.

**1. Savunma dağılımı**
- Boşta olan (savaşmayan, emri olmayan) her birlik için: cephede değilse en
  yakın cephe bölgesine gider.
- Hiç birliği olmayan cephe bölgesi varsa, komşu cephe bölgelerinden birden
  fazla birliği olanlardan biri oraya kaydırılır.
- Başkentte her zaman en az 1 birlik bırakılır.

**2. Saldırı**
- Her komşu düşman bölgesi için: o bölgeye komşu kendi bölgelerindeki, org'u
  azamisinin en az %70'i olan birliklerin `S` değeri ile hedefin `V` değeri hesaplanır.
- `S ≥ 1.5 × V` ise ya da hedef boşsa saldırılır. Her çıkış bölgesinde 1 birlik
  geride bırakılır.
- Birden çok uygun hedef varsa zafer puanı en yüksek olan seçilir.
- Org'u azamisinin %30'unun altına düşen saldıran birlik saldırıyı bırakır.

**3. Üretim**
- Kuyruk boşsa ve kaynak yetiyorsa bir sipariş verir:
  - İlk oyun yılında ve fabrika sayısı 10'dan azsa: cepheden en uzak, yeri olan bölgeye fabrika.
  - Değilse 3 piyadeye 1 zırhlı oranını korur; petrol ya da çelik yetmiyorsa piyade üretir.

**4. Yeni birlikler**
- Başkentte doğan birlik, 1. kuralla en çok tehdit altındaki cephe bölgesine gönderilir.

---

## 9. Dokunmatik kontroller ve arayüz

Fare ya da klavye varsayılmaz. Üzerine gelme (hover), sağ tık ve kısayol tuşu yoktur.
Bilgisayarda sınama için "Emulate Touch From Mouse" açıktır: fareyle sürükleme tek
parmak gibi çalışır, fare tekerleği yakınlaştırır.

### Hareketler

| Hareket | Sonuç | Durum |
|---|---|---|
| Tek dokunuş (bölgeye) | Bölgeyi seçer, parlak çerçeveyle vurgular, alt paneli açar | var |
| Tek dokunuş (denize) | Seçimi kaldırır | var |
| Tek parmakla sürükleme | Haritayı kaydırır | var |
| İki parmakla kıstırma | Yakınlaştırır / uzaklaştırır | var |
| Tek dokunuş (kendi birliğin olan bölgeye) | Birlikleri seçer | 10. adımda |
| Seçili birlik varken başka bölgeye tek dokunuş | Hareket / saldırı emri verir | 10. adımda |
| Uzun basma (0,5 sn) | Emir vermeden bölge bilgisini açar | 10. adımda |

- Parmak **12 pikselden** az oynadıysa dokunuş, fazla oynadıysa kaydırma sayılır.
  Kaydırma ya da kıstırma bittiğinde bölge seçilmez.
- Kamera harita dışını göstermez. En uzak görünümde ekran haritayla dolar
  (16:9 ekranda kıtanın tamamı görünür); en yakın görünüm 2,5 kattır.
- Arayüze (panel, düğme) dokunuş haritaya geçmez; panellerin arasındaki boşluklar geçirir.

### Harita görünümü

- Her bölge sahibinin rengiyle boyanır. Arazi hem rengin tonuyla hem küçük bir
  simgeyle belli olur: orman koyu ton ve ağaç, dağ gri-koyu ton ve tepe, şehir açık
  ton ve bina. Ovada simge yoktur.
- Başkentlerde yıldız vardır.
- Sınırlar: bölge sınırı ince, ülke sınırı kalın ve koyu, bloklar arası **cephe hattı**
  en kalın ve kırmızıdır. Bir bölge el değiştirince sınırın türü kendiliğinden değişir.
- Çizgi kalınlıkları, simgeler ve yazılar yakınlıktan bağımsız olarak ekranda hep
  aynı boyutta görünür.
- Uzak görünümde büyük ülke adları, yakınlık 0,8'i geçince bölge adları görünür.

### Ekran düzeni

Temel çözünürlük 1920 × 1080, yatay. Ölçekleme `canvas_items`, en-boy `expand`.

```
┌──────────────────────────────────────────────────────────────────────┐
│ ┌────────────────────┐                  ┌──────────────────────────┐ │
│ │ 1 Ocak 1931, 00:00 │                  │ [Devam] [1x] [2x] [3x]   │ │
│ └────────────────────┘                  └──────────────────────────┘ │
│                                                                      │
│                               HARİTA                                 │
│                                                                      │
│ ┌──────────────────────────────────────────────────────────────────┐ │
│ │ ■ Gedirge (Başkent)                   Vardanya · Kuzey Antlaşması │ │
│ │ Arazi  Zafer puanı  İnsan gücü  Çelik  Petrol  Fabrika           │ │
│ └──────────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────────┘
```

- **Üst çubuk:** solda tarih ve saat; sağda durdur/devam düğmesi ve üç hız düğmesi.
  Etkin hız ve durdurulmuş hâl sarı renkle vurgulanır. İki panelin arası boştur.
- **Alt panel:** seçili bölgenin adı, sahibi ve bloğu, arazisi, zafer puanı, günlük
  kaynak gelirleri ve fabrika sayısı. Seçim yokken gizlidir.
- **"Süre doldu" yazısı:** oyun süresi bitince ekranın ortasında çıkar.
- İleride eklenecekler: üst çubukta ülke ve kaynaklar (14. adım), birlik bilgisi
  (13. adım), üretim paneli (15. adım), savaş göstergesi (12. adım).

### Mobil kurallar

- Dokunulabilir her öğe en az **96 × 96 px** (temel çözünürlükte). Düğmeler şu an
  132 × 104 px'tir.
- Arayüz yazıları en az 36 px, harita yazıları en az 30 px.
- Arayüz, çentik ve yuvarlak köşelerin dışında, güvenli alanın (safe area) içinde kalır.
- Bilgi yalnızca renkle verilmez; ülke adı ve simge de gösterilir.

---

## 10. Kazanma ve kaybetme

- **Teslim olma:** Bir ülkenin elindeki bölgelerin zafer puanı toplamı,
  oyun başındaki toplamının **yarısının altına** düşerse o ülke teslim olur.
  Bütün birlikleri yok olur; kalan bölgeleri, teslime yol açan son bölgeyi
  ele geçiren ülkeye geçer.
- **Zafer:** Karşı bloktaki üç ülke de teslim olursa.
- **Yenilgi:** Oyuncunun kendi ülkesi teslim olursa (müttefikleri ayakta olsa bile).
- **Süre dolarsa (1 Ocak 1935):** Blokların zafer puanı toplamları karşılaştırılır.
  Oyuncunun bloğu öndeyse zafer, gerideyse yenilgi, eşitse beraberlik.

Her ülke oyuna 13–14 zafer puanıyla başlar; başkentini (5) ve şehrini (3) kaybeden
ülke teslim olmaya çok yaklaşır.

---

## 11. Kapsam dışı

Aşağıdakiler **bilerek** yapılmayacaktır. İstenmedikçe eklenmez.

- Hava kuvvetleri, deniz kuvvetleri, deniz aşırı çıkarma
- Diplomasi, ittifak kurma/bozma, barış görüşmesi, ticaret
- Odak ağacı, araştırma/teknoloji, siyaset, ideoloji, danışmanlar
- Tümen tasarımcısı, ekipman stokları, generaller, deneyim
- İkmal hatları, altyapı, hava durumu, gece/gündüz, nehirler
- Direniş, işgal yönetimi, kukla devletler
- Çok oyunculu oyun, senaryo düzenleyici, mod desteği

Bunların yerine geçen basit kurallar: sabit bloklar (diplomasi yerine), yığın
sınırı ve kuşatılınca yok olma (ikmal yerine), arazi çarpanları (hava ve nehir yerine).

---

## 12. Kod mimarisi

```
data/              Başlangıç verisi (JSON)
scenes/            Sahneler (.tscn) — yalnızca kök düğüm; ağaç script'ten kurulur
scripts/main.gd    Ana sahne: veriyi yükler, görünümü ve arayüzü kurup bağlar
scripts/sim/       Saf simülasyon: bölge, ülke, dünya, takvim, zaman (ileride hareket, savaş…)
scripts/gorsel/    Harita çizimi ve kamera
scripts/arayuz/    Üst çubuk, paneller, tema
tools/             Harita üretici (oyunun parçası değildir)
assets/            Simgeler, yazı tipleri, sesler
```

| Dosya | Görevi |
|---|---|
| `scripts/sim/veri_okuyucu.gd` | JSON dosyası okur |
| `scripts/sim/bolge.gd`, `ulke.gd`, `arazi.gd` | Tek bir bölgenin / ülkenin / arazi türünün verisi |
| `scripts/sim/dunya.gd` | Bütün bölgeleri ve ülkeleri yükler, doğrular; "bu noktada hangi bölge var", "bu iki ülke düşman mı" sorularını yanıtlar |
| `scripts/sim/takvim.gd` | Saat sayısını tarihe çevirir |
| `scripts/sim/zaman.gd` | Zaman yöneticisi (autoload `Zaman`) |
| `scripts/gorsel/harita_gorunumu.gd` | Haritayı, sınırları, simgeleri, adları ve seçim çerçevesini çizer |
| `scripts/gorsel/harita_kamerasi.gd` | Kaydırma, yakınlaştırma, dokunuşu kaydırmadan ayırma |
| `scripts/arayuz/arayuz.gd` | Arayüzün kökü, güvenli alan, "Süre doldu" yazısı |
| `scripts/arayuz/ust_cubuk.gd`, `bolge_paneli.gd`, `arayuz_temasi.gd` | Üst çubuk, alt panel, ortak görünüm |

- `scripts/sim/` içindeki kod hiçbir şey çizmez, girdi okumaz ve görsel düğümlere
  dokunmaz. Yalnızca veri okur, durumu değiştirir ve sinyal yayar.
- Autoload'lar (şimdilik `Zaman`) düğümdür, çünkü gerçek zamanı saymak için
  `_process` gerekir; bunun dışında aynı kurala uyarlar.
- Görsel taraf durumu **doğrudan değiştirmez**; simülasyonun işlevlerini çağırır
  (ör. `Zaman.hiz_sec(2)`) ve sinyalleri dinleyerek kendini günceller.
- Böylece simülasyon ekran olmadan da çalıştırılıp sınanabilir.

---

## 13. Geliştirme adımları

Her adım tek başına çalıştırılıp sınanabilir. Bir seferde yalnızca istenen adımlar yapılır.

| # | Durum | Adım | Nasıl sınanır |
|---|---|---|---|
| 1 | ✅ | **Proje ayarları ve ana sahne.** Oyun adı, 1920×1080, yatay yön, fareyle dokunma taklidi, `scenes/main.tscn`. | F5 ile oyun yatay pencerede açılır. |
| 2 | ✅ | **Sabit veri dosyaları ve yükleyici.** `terrain.json`, `countries.json`, `balance.json` ve bunları okuyup doğrulayan sınıflar. | Bozuk ya da eksik veri konsolda anlaşılır bir hata verir. |
| 3 | ✅ | **Harita üretici araç.** 72 bölgeyi Voronoi ile üretip `provinces.json`'a yazar. | Araç çalışınca dosya oluşur; 72 bölge, komşuluk iki yönlü, her ülkede 12 bitişik bölge ve 1 başkent. |
| 4 | ✅ | **Harita çizimi.** Bölge dolguları, üç tür sınır, arazi simgeleri, başkent yıldızları, bölge ve ülke adları. | Ekranda altı renkli 72 bölge ve kırmızı cephe hattı görünür. |
| 5 | ✅ | **Kamera.** Tek parmakla kaydırma, iki parmakla yakınlaştırma, harita dışına çıkmama. | Harita kaydırılıp yakınlaştırılır, kenarda durur. |
| 6 | ✅ | **Bölge seçimi ve bilgi paneli.** Dokunulan bölge vurgulanır, alt panelde bilgisi açılır. | Bölgeye dokununca doğru bilgiler görünür; sürükleme seçim yapmaz; denize dokunmak seçimi kaldırır. |
| 7 | ⬜ | **Birlik verisi ve oyun durumu.** `unit_types.json`, `start.json`; ülkelerin kaynak stoku ve birliklerin durumu için saf simülasyon sınıfları. (Bölge ve ülke sınıfları hazır.) | Ekransız sınama: 3 birlik tipi yüklenir, her ülkenin başlangıç birlikleri doğru bölgede ve doğru sayıda. |
| 8 | ✅ | **Zaman sistemi ve üst çubuk.** Tick, durdurma, 3 hız, tarih-saat göstergesi, süre sonu. | Tarih ilerler; durdur ve hız düğmeleri çalışır; her hızda bir günün süresi tabloya uyar. |
| 9 | ⬜ | **Birliklerin haritada gösterimi.** Birlikler bölge merkezinde simge ve sayı olarak çizilir. | Her ülkenin birlikleri doğru bölgede, doğru sayıda görünür. |
| 10 | ⬜ | **Birlik seçimi ve hareket.** Seçme, emir verme, rota bulma, zamanla ilerleme, emir oku (yalnızca dost bölgeler). | Birlik seçilip uzak bir dost bölgeye gönderilir; formüldeki sürede varır. |
| 11 | ⬜ | **Ele geçirme.** Boş düşman bölgesine giren birlik bölgeyi alır, harita rengi ve sınırlar değişir. | Boş düşman bölgesine yürüyen birlik bölgenin rengini değiştirir. |
| 12 | ⬜ | **Savaş.** Savaşın başlaması, saatlik çözüm, geri çekilme, yok olma, savaş göstergesi. | Ekransız sınama: bölüm 6'daki örnek yaklaşık 21 saatte biter. Oyunda saldırı sonucu görünür. |
| 13 | ⬜ | **Org yenileme, takviye ve birlik paneli.** Güç ve org çubukları. | Savaştan çıkan birliğin çubukları zamanla dolar; insan gücü azalır. |
| 14 | ⬜ | **Ekonomi.** Günlük gelir, üst çubukta kaynaklar. | Kaynaklar her gün formüle göre artar; bölge el değiştirince gelir değişir. |
| 15 | ⬜ | **Üretim.** Üretim paneli, kuyruk, birlik ve fabrika üretimi. | Sipariş kaynağı düşer, doğru günde başkentte birlik doğar; fabrika üretim hızını artırır. |
| 16 | ⬜ | **Teslim olma ve oyun sonu.** Teslim kuralı, zafer / yenilgi / süre sonu ekranı. | Zafer puanı yarının altına düşen ülke teslim olur; üç düşman teslim olunca zafer ekranı çıkar. |
| 17 | ⬜ | **Yapay zekâ: savunma ve üretim.** Bölüm 8'deki 1., 3. ve 4. kurallar. | Yapay zekâ ülkeleri cepheyi doldurur ve birlik üretir. |
| 18 | ⬜ | **Yapay zekâ: saldırı.** Bölüm 8'deki 2. kural. | Yapay zekâ zayıf bölgelere saldırır; oyuncusuz bir oyun kendiliğinden sonuçlanır. |
| 19 | ⬜ | **Ana menü ve ülke seçimi.** Yeni oyun, ülke seçme ekranı. | Seçilen ülkeyle oyun başlar; diğer beşi yapay zekâ oynar. |
| 20 | ⬜ | **Kaydet / yükle.** Oyun durumunu `user://` altına JSON olarak yazma ve okuma. | Kaydedip kapatıp açınca oyun aynı tarih ve aynı durumla sürer. |
| 21 | ⬜ | **Mobil cilâ ve Android dışa aktarma.** Arka planda durdurma, gerçek telefonda güvenli alan ve dokunma denemesi, APK. | APK telefona kurulur; bütün düğmelere parmakla rahat basılır. |
| 22 | ⬜ | **Denge ayarı.** `data/balance.json` ve başlangıç verileriyle oynama. | Oyuncusuz 10 oyunda iki blok da en az birkaç kez kazanır; bir oyun 4 yılı aşmaz. |

---

## 14. Tasarım değişiklikleri

İlk tasarımdan sonra yapılan değişiklikler:

| Tarih | Değişiklik | Neden |
|---|---|---|
| 2 Ekim 2026 | Temel çözünürlük 1280×720 yerine 1920×1080. | İstek üzerine. |
| 2 Ekim 2026 | Harita altıgen ızgara yerine Voronoi ile üretiliyor; çevresi deniz, kıyılar girintili. Dünya 4200×2400. | İstek üzerine; daha doğal görünüm. |
| 2 Ekim 2026 | Veri dosyalarının adları İngilizce (`provinces.json`, `countries.json`, `terrain.json`, `balance.json`); ana sahne `scenes/main.tscn`; araçlar `tools/` altında. | İstek üzerine; diğer dosyalar tutarlı olsun diye aynı düzene çekildi. |
| 2 Ekim 2026 | "Tepe" arazisi kaldırıldı; arazi türleri ova, orman, dağ, şehir. | İstek üzerine. |
| 2 Ekim 2026 | Bölgede `nufus` yerine doğrudan günlük `insan_gucu` geliri var. `baskent` alanı bölgeden kaldırıldı, ülkede tutuluyor. | İstek üzerine; aynı bilgi iki yerde durmasın. |
| 2 Ekim 2026 | Yelbor sarı, Orsin turuncu oldu (önce tersi). | Yan yana duran kırmızı–turuncu–sarı sıralaması zor ayırt ediliyordu. |
| 2 Ekim 2026 | Bölge bilgisi sağ panel yerine alt panelde. Dokunma eşiği 16 yerine 12 piksel. | İstek üzerine. |
| 2 Ekim 2026 | Başlangıç kaynakları ve birlikleri `countries.json` yerine ayrı bir dosyada (`start.json`) tutulacak. | `countries.json` harita üreticisi tarafından yeniden yazılıyor. |
| 2 Ekim 2026 | Adımlar yeniden düzenlendi: birlik tipleri verisi 2. adımdan 7. adıma alındı. | Bu görevde birliklere dokunulmadı. |
