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
| Güney Birliği (`guney`) | Yelbor | `yelbor` | turuncu |
| Güney Birliği (`guney`) | Orsin | `orsin` | sarı |

İki ülke **farklı bloktaysa düşmandır**, aynı bloktaysa müttefiktir. Kodda bu
tek bir işlevle sorulur: `dusman_mi(ulke_a, ulke_b)`.

### Harita

- 12 sütun × 6 satırlık altıgen ızgara; köşe noktaları rastgele kaydırılarak
  doğal görünümlü 72 çokgen elde edilir. Dünya boyutu yaklaşık 2400 × 1300 piksel.
- Üst üç satır Kuzey Antlaşması'na, alt üç satır Güney Birliği'ne aittir.
  Her ülke 4 sütun × 3 satırlık bir blok kaplar. Cephe, haritanın ortasından
  yatay geçen 12 bölgelik hattır.
- Harita bir kez araç betiğiyle üretilip `data/bolgeler.json` dosyasına yazılır;
  sonrasında elle düzenlenebilir. Oyun çalışırken harita üretilmez.

---

## 3. Veri yapıları

Tüm başlangıç verisi `data/` altında JSON olarak durur. Bu dosyalar oyun
çalışırken **asla değiştirilmez**; oyun sırasında değişen durum bellekte tutulur,
kayıtlar `user://` altına yazılır.

| Dosya | İçerik |
|---|---|
| `data/bolgeler.json` | 72 bölge |
| `data/ulkeler.json` | 6 ülke ve başlangıç birlikleri |
| `data/birlik_tipleri.json` | 3 birlik tipi |
| `data/arazi.json` | Arazi türleri ve çarpanları |
| `data/denge.json` | Formüllerdeki sabitler (hız, hasar, gelir…) |

Dosya, anahtar ve değişken adlarında Türkçe'ye özgü harf kullanılmaz
(`bolge`, `ulke`, `guc`). Ekranda görünen metinlerde kullanılır (`"ad": "Kızılova"`).

### 3.1 Bölge

```json
{
  "id": "b017",
  "ad": "Kızılova",
  "sahip": "vardanya",
  "arazi": "ova",
  "komsular": ["b005", "b016", "b018", "b029", "b030"],
  "merkez": [512, 340],
  "kose_noktalari": [[470, 300], [540, 296], [566, 340], [538, 388], [472, 384], [450, 342]],
  "fabrika": 2,
  "nufus": 3,
  "celik": 0,
  "petrol": 1,
  "zafer_puani": 2,
  "baskent": false
}
```

- `sahip`: oyun başındaki sahip. Oyun içinde bölgeyi ele geçiren ülke yeni sahibi olur.
- `komsular`: iki yönlü olmalı (A, B'nin komşusuysa B de A'nın komşusudur).
- `merkez`: birlik simgesinin çizileceği nokta.
- `nufus`: 1–5, günlük insan gücü gelirini belirler.
- `celik`, `petrol`: bölgenin günlük kaynak üretimi (çoğu bölgede 0).
- `zafer_puani`: 0–5. Başkent 5, şehirler 2–3, kalanlar 0–1.

### 3.2 Arazi

```json
{
  "ova":    { "ad": "Ova",    "hareket": 1.0, "savunma": 1.0  },
  "orman":  { "ad": "Orman",  "hareket": 1.5, "savunma": 1.25 },
  "tepe":   { "ad": "Tepe",   "hareket": 1.5, "savunma": 1.5  },
  "dag":    { "ad": "Dağ",    "hareket": 2.0, "savunma": 2.0  },
  "sehir":  { "ad": "Şehir",  "hareket": 1.0, "savunma": 1.5  }
}
```

### 3.3 Ülke

```json
{
  "id": "vardanya",
  "ad": "Vardanya",
  "blok": "kuzey",
  "renk": "#3B6FB6",
  "baskent": "b017",
  "baslangic": { "insan_gucu": 12000, "celik": 300, "petrol": 100 },
  "baslangic_birlikleri": [
    { "tip": "piyade", "bolge": "b017" },
    { "tip": "piyade", "bolge": "b029" },
    { "tip": "zirhli", "bolge": "b017" }
  ]
}
```

Her ülke yaklaşık 6–8 fabrika, 7 piyade, 1 süvari ve 1 zırhlı ile başlar.
Ülkeler arasında küçük farklar olur (biri sanayide, biri nüfusta güçlü).

### 3.4 Birlik tipi

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

Birlikler dosyada durmaz; oyun başında `baslangic_birlikleri`'nden ve sonra
üretimden doğar. Kayıt dosyasında şu biçimde saklanır:

```json
{
  "id": 42,
  "tip": "piyade",
  "ulke": "vardanya",
  "bolge": "b017",
  "guc": 100.0,
  "org": 60.0,
  "rota": ["b018", "b029"],
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

- Uygulama arka plana atılınca oyun kendiliğinden durur.
- Bir karede en çok 5 tick işlenir (yavaş cihazda takılmayı önlemek için).

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

- `ORG_HASAR = 2.0`, `GUC_ORANI = 0.25` (`data/denge.json`).
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
| İnsan gücü | sahip olunan bölgelerin `nufus` toplamı × 8 | Birlik üretimi, takviye |
| Çelik | sahip olunan bölgelerin `celik` toplamı | Birlik ve fabrika üretimi |
| Petrol | sahip olunan bölgelerin `petrol` toplamı | Zırhlı tümen üretimi |

Kaynaklar birikir; üst sınır yoktur. Ele geçirilen bölgenin geliri yeni sahibine geçer.

### Fabrikalar

- Her fabrika günde **1 üretim puanı** verir.
- Ele geçirilen bölgedeki fabrikalar yeni sahibine geçer.
- Bir bölgede en çok 4 fabrika olabilir.

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

Bu bölümdeki bütün sayılar ilk tahmindir; denge adımında `data/denge.json`
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

### Hareketler

| Hareket | Sonuç |
|---|---|
| Tek dokunuş (bölgeye) | Bölgede kendi birliğin varsa birlikleri seçer, yoksa bölge bilgisini açar |
| Seçili birlik varken başka bölgeye tek dokunuş | Hareket / saldırı emri verir |
| Seçili birlik varken aynı bölgeye tek dokunuş | Seçimi kaldırır |
| Uzun basma (0,5 sn) | Emir vermeden bölge bilgisini açar |
| Tek parmakla sürükleme | Haritayı kaydırır |
| İki parmakla kıstırma | Yakınlaştırır / uzaklaştırır |

- Parmak 16 pikselden fazla oynarsa dokunuş değil sürükleme sayılır.
- Bir bölgede birden çok birlik varsa hepsi birlikte seçilir; seçim panelindeki
  listeden tek tek çıkarılabilir.
- Verilen emir haritada ok olarak görünür. Emir vermek için onay sorulmaz;
  yanlış emir yeni emirle düzeltilir.

### Ekran düzeni

Temel çözünürlük 1280 × 720, yatay. Ölçekleme `canvas_items`, en-boy `expand`.

```
┌──────────────────────────────────────────────────────────────────────┐
│ Vardanya  İG 12.4b  Çelik 310  Petrol 95  Fab 8   14 Mar 1931 09:00  │
│                                                         [||][1][2][3] │
├──────────────────────────────────────────────┬───────────────────────┤
│                                              │  SEÇİM PANELİ         │
│                                              │  (bölge ya da birlik  │
│                 HARİTA                       │   bilgisi; seçim      │
│                                              │   yokken kapalı)      │
│                                              │                       │
│                                              │                       │
│ [Üretim]                                     │                 [ X ] │
└──────────────────────────────────────────────┴───────────────────────┘
```

- **Üst çubuk** (72 px): ülke, kaynaklar, fabrika sayısı, tarih-saat, durdur ve hız düğmeleri.
- **Seçim paneli** (sağda, 360 px): bölge seçiliyse ad, sahip, arazi, fabrika,
  kaynak, zafer puanı; birlik seçiliyse her birliğin tipi, güç ve org çubukları.
- **Üretim düğmesi** (sol alt): üretim panelini açar — kuyruk, ilerleme çubuğu ve
  dört sipariş düğmesi.
- **Savaş göstergesi:** savaş süren bölgenin üstünde, iki tarafın durumunu
  gösteren küçük bir çubuk.

### Mobil kurallar

- Dokunulabilir her öğe en az **96 × 96 px** (temel çözünürlükte, yaklaşık 48 dp).
- Yazı boyutu en az 24 px.
- Çentik ve yuvarlak köşeler için güvenli alan boşluğu bırakılır.
- Bilgi yalnızca renkle verilmez; ülke adı ve simge de gösterilir.
- Panel açıkken panelin altındaki haritaya dokunuş geçmez.

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
scenes/            Sahneler (.tscn)
scripts/sim/       Saf simülasyon: durum, zaman, hareket, savaş, ekonomi, yapay zekâ
scripts/gorsel/    Harita ve birlik çizimi, kamera
scripts/arayuz/    Üst çubuk, paneller, menüler
assets/            Simgeler, yazı tipleri, sesler
```

- `scripts/sim/` içindeki kod hiçbir sahneye, düğüme, girdiye ya da çizime
  dokunmaz. Yalnızca veri okur, durumu değiştirir ve sinyal yayar.
- Görsel taraf durumu **doğrudan değiştirmez**; emir işlevlerini çağırır
  (ör. `hareket_emri_ver(birlik_id, hedef_bolge)`) ve sinyalleri dinleyerek
  kendini günceller (ör. `bolge_sahibi_degisti`, `birlik_tasindi`).
- Böylece simülasyon ekran olmadan da çalıştırılıp sınanabilir.

---

## 13. Geliştirme adımları

Her adım tek başına çalıştırılıp sınanabilir. Bir adım bitmeden sonrakine
geçilmez; bir seferde yalnızca bir adım yapılır.

| # | Adım | Nasıl sınanır |
|---|---|---|
| 1 | **Proje ayarları ve boş ana sahne.** Oyun adı, 1280×720, yatay yön, fareyle dokunma taklidi; ortasında oyun adı yazan `scenes/ana.tscn`. | Oyun çalışınca yatay pencerede "Altı Sancak" yazısı görünür. |
| 2 | **Sabit veri dosyaları ve yükleyici.** `arazi.json`, `birlik_tipleri.json`, `ulkeler.json`, `denge.json` ve bunları okuyup doğrulayan yükleyici. | Konsolda "6 ülke, 3 birlik tipi, 5 arazi yüklendi" yazar; bozuk veri anlaşılır hata verir. |
| 3 | **Harita üretici araç.** 72 bölgeyi üretip `bolgeler.json`'a yazan tek seferlik betik. | Dosya oluşur; doğrulama: 72 bölge, komşuluk iki yönlü, her ülkede 12 bölge ve 1 başkent. |
| 4 | **Harita çizimi.** Bölgeler sahip rengiyle çokgen olarak çizilir, sınırlar ve bölge adları görünür. | Ekranda altı renkli 72 bölge görünür. |
| 5 | **Kamera.** Tek parmakla kaydırma, iki parmakla yakınlaştırma, harita dışına çıkmama. | Harita kaydırılıp yakınlaştırılır, kenarda durur. |
| 6 | **Bölge seçimi ve bilgi paneli.** Dokunulan bölge vurgulanır, sağ panelde bilgisi açılır. | Bölgeye dokununca doğru ad, sahip ve arazi görünür; sürükleme seçim yapmaz. |
| 7 | **Oyun durumu.** Veriden yeni oyun kuran saf simülasyon sınıfları (bölge, ülke, birlik durumu). | Ekransız sınama betiği: 6 ülke, 72 bölge, başlangıç birlikleri doğru sayıda. |
| 8 | **Zaman sistemi ve üst çubuk.** Tick, durdurma, 3 hız, tarih-saat göstergesi. | Tarih ilerler; durdur ve hız düğmeleri çalışır; her hızda bir günün süresi tabloya uyar. |
| 9 | **Birliklerin haritada gösterimi.** Başlangıç birlikleri bölge merkezinde simge ve sayı olarak çizilir. | Her ülkenin birlikleri doğru bölgede, doğru sayıda görünür. |
| 10 | **Birlik seçimi ve hareket.** Seçme, emir verme, rota bulma, zamanla ilerleme, emir oku (yalnızca dost bölgeler). | Birlik seçilip uzak bir dost bölgeye gönderilir; formüldeki sürede varır. |
| 11 | **Ele geçirme.** Boş düşman bölgesine giren birlik bölgeyi alır, harita rengi değişir. | Boş düşman bölgesine yürüyen birlik bölgenin rengini değiştirir. |
| 12 | **Savaş.** Savaşın başlaması, saatlik çözüm, geri çekilme, yok olma, savaş göstergesi. | Ekransız sınama: bölüm 6'daki örnek yaklaşık 21 saatte biter. Oyunda saldırı sonucu görünür. |
| 13 | **Org yenileme, takviye ve birlik paneli.** Güç ve org çubukları. | Savaştan çıkan birliğin çubukları zamanla dolar; insan gücü azalır. |
| 14 | **Ekonomi.** Günlük gelir, üst çubukta kaynaklar. | Kaynaklar her gün formüle göre artar; bölge el değiştirince gelir değişir. |
| 15 | **Üretim.** Üretim paneli, kuyruk, birlik ve fabrika üretimi. | Sipariş kaynağı düşer, doğru günde başkentte birlik doğar; fabrika üretim hızını artırır. |
| 16 | **Teslim olma ve oyun sonu.** Teslim kuralı, zafer / yenilgi / süre sonu ekranı. | Zafer puanı yarının altına düşen ülke teslim olur; üç düşman teslim olunca zafer ekranı çıkar. |
| 17 | **Yapay zekâ: savunma ve üretim.** Bölüm 8'deki 1., 3. ve 4. kurallar. | Yapay zekâ ülkeleri cepheyi doldurur ve birlik üretir. |
| 18 | **Yapay zekâ: saldırı.** Bölüm 8'deki 2. kural. | Yapay zekâ zayıf bölgelere saldırır; oyuncusuz bir oyun kendiliğinden sonuçlanır. |
| 19 | **Ana menü ve ülke seçimi.** Yeni oyun, ülke seçme ekranı. | Seçilen ülkeyle oyun başlar; diğer beşi yapay zekâ oynar. |
| 20 | **Kaydet / yükle.** Oyun durumunu `user://` altına JSON olarak yazma ve okuma. | Kaydedip kapatıp açınca oyun aynı tarih ve aynı durumla sürer. |
| 21 | **Mobil cilâ ve Android dışa aktarma.** Güvenli alan, dokunma hedefleri, arka planda durdurma, APK. | APK telefona kurulur; bütün düğmelere parmakla rahat basılır. |
| 22 | **Denge ayarı.** `data/denge.json` ve başlangıç verileriyle oynama. | Oyuncusuz 10 oyunda iki blok da en az birkaç kez kazanır; bir oyun 4 yılı aşmaz. |
