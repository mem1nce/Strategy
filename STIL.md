# STİL — Yerküre görsel kılavuzu

Her yeni ekran ve panel bu kılavuza ve ortak temaya (`scripts/arayuz/arayuz_temasi.gd`) uyar.
Renk, yazı boyutu, boşluk ya da köşe yarıçapı koda elle yazılmaz; buradaki sabitler kullanılır.
Hedef: koyu, sakin, modern bir strateji haritası. Başka oyunların görselleri, simgeleri, logoları
ya da ekran düzenleri kopyalanmaz.

## Renkler (`ArayuzTemasi`)

| Ad | Değer | Kullanım |
|---|---|---|
| `ZEMIN` | `#0E141D` | En arka zemin, ana menü karartması |
| `YUZEY` | `#151D2A` (%95 opak) | Panel ve kart zemini |
| `YUKSEK_YUZEY` | `#1E2838` | Kart içindeki kart, ikincil düğme |
| `BASILI_YUZEY` | `#28354A` | Basılı ikincil düğme, sekme seçili değilken |
| `KENAR` | `#2E3B52` | İnce kenarlık, ayraç |
| `YAZI` | `#ECEFF4` | Birincil yazı |
| `IKINCIL_YAZI` | `#A3ADBF` | Etiketler, açıklamalar |
| `SOLUK_YAZI` | `#677287` | Kapalı düğme, ipucu |
| `VURGU` | `#E6AE48` (altın-kehribar) | Tek sıcak vurgu: birincil düğme, seçim, oyuncunun ülkesi |
| `BASILI_VURGU` | `#C8902F` | Basılı birincil düğme |
| `VURGU_USTU` | `#1B1406` | Vurgu zemin üstündeki yazı |
| `BASARI` | `#4FB985` | Olumlu durum: kazanç, tamamlandı, barış |
| `TEHLIKE` | `#E25B5B` | Olumsuz durum: savaş, kayıp, hata |

Vurgu rengi ekranda azdır: bir panelde en çok bir birincil düğme. Başarı ve tehlike yalnızca
durum bildirir, süs için kullanılmaz.

## Yazı

İki yazı tipi (SIL OFL 1.1, `assets/fonts/`, Türkçe harfler doğrulandı):

- **Cinzel** (başlık): oyun adı, panel başlıkları, harita üstündeki ülke adları. Kalın (700).
- **Inter** (arayüz): her şeyin geri kalanı. Normal (400), vurgu için yarı kalın (600).

Ölçek (1920 × 1080 temel çözünürlükte, piksel):

| Ad | Boyut | Kullanım |
|---|---|---|
| `YAZI_DEV` | 72 | Oyun adı |
| `YAZI_BASLIK` | 44 | Panel başlığı |
| `YAZI_ALT_BASLIK` | 34 | Kart başlığı, bölge adı |
| `YAZI_GOVDE` | 30 | Varsayılan |
| `YAZI_KUCUK` | 25 | İkincil bilgi, istatistik etiketi |
| `YAZI_MINIK` | 21 | Rozet, harita üstü küçük yazılar |

Sayılar kısaltılır (`Bicim`): 1 250 → "1,2 B", 3 400 000 → "3,4 Mn", 2,7 milyar → "2,7 Mr".

## Boşluk, köşe, gölge

- **8 piksellik ızgara:** bütün boşluklar 8'in katıdır: `BOSLUK_1` 8, `BOSLUK_2` 16,
  `BOSLUK_3` 24, `BOSLUK_4` 32, `BOSLUK_6` 48.
- **Köşe yarıçapı:** düğme ve küçük kart 12 (`KOSE`), panel 16 (`KOSE_BUYUK`), hap ve rozet
  tam yuvarlak (`KOSE_HAP`).
- **Gölge:** paneller ve harita rozetleri altta hafif, keskin olmayan bir gölge taşır
  (`GOLGE_RENGI` siyah %40, boyut 10, aşağı 4). Bulanıklaştırma (blur) gölgelendiricisi
  kullanılmaz.
- **Dokunma:** her dokunulabilir öğe en az 96 × 96 (CLAUDE.md).

## Ortak bileşenler (`scripts/arayuz/bilesenler.gd`)

| Bileşen | İşlev | Görünüm |
|---|---|---|
| Birincil düğme | `Bilesenler.birincil_dugme(metin, simge)` | Vurgu zeminli, koyu yazı; ekrandaki tek ana eylem |
| İkincil düğme | `Bilesenler.ikincil_dugme(metin, simge)` | Yüksek yüzey zeminli, ince kenarlı |
| Kart | `Bilesenler.kart()` | Yüksek yüzey, köşe 12, iç boşluk 16 |
| Başlıklı panel | `BaslikliPanel` | Yüzey zemin, gölge; üstte isteğe bağlı bayrak/simge + Cinzel başlık, altında ince ayraç |
| İstatistik satırı | `IstatistikSatiri` | Soluk simge, ikincil renkte etiket, sağda kalın değer |
| Sekme | `SekmeGrubu` | Hap içinde yan yana düğmeler; seçili olan vurgu renginde |
| İlerleme çubuğu | `Bilesenler.ilerleme_cubugu(renk)` | Köşe yarıçaplı ince çubuk, dolgu vurgu (ya da verilen) renk |
| Rozet | `Bilesenler.rozet(metin, renk)` | Küçük hap, renkli zemin, minik yazı |
| Bildirim kartı | `BildirimKutusu` | Solda bayrak ve simge, sağda metin; kart zemin, sol kenarda durum rengi |

## Simgeler (`art/icons/`, `tools/simgeler_uret.py`)

- 24 × 24 ızgara, **tek çizgi kalınlığı (2)**, yuvarlak uç ve köşe, dolgusuz (küçük nokta
  vurguları hariç), beyaz çizilir; renk `modulate` ile verilir.
- Hepsi bu projede çizilmiştir. Yeni simge aynı betiğe eklenir.

## Harita

- Ülke paleti doygunluk ve parlaklığı denetlenmiş dokuz sakin renktir; komşular farklı renk
  alır (`HaritaPaleti.PALET`).
- Deniz koyu lacivertten açığa yumuşak geçiş, kıyıda açık bir kuşak, çok hafif dalga dokusu.
- Kara: ülke rengi × kabartma × hafif kâğıt dokusu. "Grafik: Düşük" ayarında dalga, kâğıt
  ve kabartma kapanır.
- Ülke sınırı koyu ve net, içinde ülke renginin koyusuyla yumuşak bir kuşak; bölge sınırı
  ince ve soluk; kıyı ayrı tonda.
- Ülke adları Cinzel, büyük harf, harf aralıklı, yarı saydam; ülkenin uzun eksenine göre döner.
- Oyuncunun ülkesi her zaman ince altın çerçeve; seçili bölge parlak kenar ve iç ışıma.
