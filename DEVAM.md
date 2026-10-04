# DEVAM

Bu dosya, uzun bir otomatik çalışma oturumunun durumunu tutar. Yeni bir oturum yalnızca
bu dosyayı okuyarak devam edebilmeli.

## Durum (en son güncelleme: bu oturumun başı)

- Aşama 1 (Dünya haritası temeli) ✅ — önceki oturumlardan, git geçmişinden doğrulandı.
- Aşama 2 / A) BÖLGELER ✅ — bu oturumda tamamlandı:
  - `kiyi` alanı: bölge en az bir deniz sınırına değiyorsa `true` (data/regions.json,
    scripts/sim/bolge.gd).
  - Deniz yolu kuralı değişti: iki kıyı bölgesi arasında çizgi karadan geçmiyorsa ve 220
    birimden kısaysa deniz yoludur; her bölge için en yakın 3 tanesi tutulur (eski kural
    yalnızca 6 birimden dar sularda deniz geçişi sayıyordu — HOI4 tarzı uzun deniz
    yolculuklarını kapsamıyordu).
  - Dünya bağlantısı: kara + deniz yollarıyla her bölgeye her bölgeden ulaşılabildiği
    doğrulanıyor; 220 birim içinde deniz yolu bulamayan adalar (ör. Hawaii, Fransız Güney
    Toprakları) en yakın erişilebilir kıyıya otomatik bağlanıyor.
  - Yeni sonuç: 516 bölge, 314 kıyı bölgesi, 1121 kara komşuluğu, 450 deniz yolu.
  - TASARIM.md güncellendi (Deniz yolu + Doğrulama bölümleri).
  - `tools/dunya_donustur.py` güncellendi, yeniden çalıştırıldı, doğrulama geçti.
  - Godot headless import + run testi geçti (176 ülke, 516 bölge, 637 çokgen,
    üçgenlenemeyen 0).

## Ortam notları

- Bu makinede (macOS) Godot PATH'te değil; şu yolda bulundu:
  `/Users/aysegulkahraman/Downloads/Godot.app/Contents/MacOS/Godot`
  (CLAUDE.md'deki Windows yolu bu makineye uymuyor; macOS yolu burada not edildi.)
- Python 3.12 kurulu; shapely bu oturumda `python3 -m pip install -r tools/requirements.txt`
  ile kuruldu.
- `node` bu makinede yok (kullanılmıyor zaten).
- Headless import: `Godot --headless --path . --import`
- Headless çalıştırma: `Godot --headless --path . --quit-after <tick>`

## Kendi kendini test etme

Altyapı bu oturumda kuruldu:
- `tests/calistirici.gd`: `tests/sim/` altındaki `sina_` işlevlerini çalıştıran headless
  sınama çalıştırıcısı. `Godot --headless --path . --script res://tests/calistirici.gd`.
  Şu an 13 sınama var (Dünya yükleme/sorgular, Takvim, Zaman) — hepsi geçiyor.
- Uzun koşu sınaması (`tests/sim/zaman_testi.gd`): 5 oyun yılını (43800 saat) anında,
  çerçeveye bağlı olmadan ilerletiyor; hata/sonsuz döngü yok. Yapay zekâ/savaş/ekonomi
  eklendikçe gerçek bir oyun döngüsünü kapsayacak şekilde büyütülmeli.
- Ekran görüntüsü aracı (`scripts/main.gd`): `Godot --path . -- --ekran-goruntusu <dosya>`
  (headless OLMADAN) 2 saniye bekleyip PNG kaydediyor, denendi ve çalıştı.
- CLAUDE.md'nin Sınama bölümü bu makineye göre güncellendi (macOS Godot yolu, yeni komutlar).

B) BİRLİKLER VE HAREKET — ilk alt adım tamamlandı: birlik verisi, başlangıç ordusu ve
haritada gösterim.
- `sim/birlik.gd`: tümen verisi (sahip, bölge, güç 0-100).
- `sim/ordu_kurucu.gd`: ülke başına 1-24 tümen, nüfus+GSYH puanıyla (data/balance.json →
  "ordu"); başkente ve kara sınırı olan bölgelere sırayla dağıtılır.
- `Oyun.birlikler` + `Oyun.bolgedeki_birlikler()`: oyunun o anki tümen listesi ve sorgusu.
- Harita: aynı bölgedeki tümenler tek kutuda (ülke rengi, toplam güç yazılı) gösterilir;
  kutular bölge sınırları/adlarıyla aynı yakınlık eşiğinde belirir (ilk sürümde her zaman
  açıktı, dünya görünümünü karmaşıklaştırdığı için eşik eklendi — ekran görüntüsüyle
  görüldü ve düzeltildi).
- 3 yeni sınama (`tests/sim/ordu_kurucu_testi.gd`): her ülkenin 1-24 tümeni var, başkentte
  tümen var, tümenler kendi sahibinin bölgesinde. Toplam 16/16 sınama geçiyor.
- Ekran görüntüsüyle sınandı: dünya görünümü temiz (kutular gizli); yakınlaşınca
  belirmesi, bölge adları gibi aynı koddan geldiği için güvenilir ama ayrıca ekran
  görüntüsüyle doğrulanmadı (kamerayı sınama aracından yakınlaştırmanın bir yolu yok).

B) BİRLİKLER VE HAREKET — yol bulma alt yapısı tamamlandı:
- `sim/yol_bulucu.gd` (`YolBulucu extends AStar2D`): bölgeler arası en hızlı yolu saat
  cinsinden bulur. Kara komşuluğu sabit `kara_saat` (24); deniz yolu
  `deniz_taban_saat + uzaklık * deniz_saat_birim_basi` (data/balance.json → "hareket").
  `_compute_cost`/`_estimate_cost` override edilerek AStar2D'nin varsayılan Öklid
  maliyeti yerine gerçek saat kullanılıyor; tahmini maliyet her zaman 0 (her zaman
  kabul edilebilir/admissible, performans yerine doğruluk tercih edildi — 516 düğümde
  fark etmiyor).
  `Dunya.yol_bulucu`, `Dunya.yukle()` içinde bir kez kuruluyor.
- 4 yeni sınama (`tests/sim/yol_bulucu_testi.gd`): aynı bölgeye süre 0, kara komşuluğu tam
  24 saat, deniz yolu karadan belirgin yavaş, uzak bölgeler (TUR_1 -> AUS_1) arasında yol
  bulunuyor. Toplam 20/20 sınama geçiyor.
- Henüz yok: "savaşta olmadığın ülkeye giremezsin" kısıtlaması (hareket emri verildiğinde
  uygulanacak, henüz emir arayüzü yok), gerçek birlik hareketi/animasyon.

B) BİRLİKLER VE HAREKET — seçme (birlik kartı) tamamlandı:
- `arayuz/birlik_paneli.gd` (BirlikPaneli): bölge paneliyle aynı alt panel yuvasını
  paylaşır, ikisi karşılıklı dışlanır (`Arayuz.bolgeyi_goster`/`birligi_goster` birbirini
  gizler).
- `main.gd._bolgeyi_sec()`: dokunulan bölge oyuncunun kendi ülkesine aitse ve orada tümen
  varsa birlik paneli açılır (bölge adı, tümen sayısı, toplam güç); değilse eskisi gibi
  bölge paneli açılır.
- Geçici bir hata ayıklama satırıyla (oyuncu=TUR, TUR_1 seçili) ekran görüntüsü alınıp
  panel doğrulandı, sonra kod geri alındı (commit edilen kodda yok).
- Henüz yok: hedef bölge seçip birlik yürütme, "Yarısını ayır" düğmesi.

B) BİRLİKLER VE HAREKET — emir (hedef seçip yürütme) tamamlandı:
- `Birlik.hedef_bolge_id`/`varis_saati`; `Oyun.birlikleri_yurut(kaynak, hedef, su_anki_saat)`
  (yalnızca aynı ülkeye ait iki bölge arasında kabul edilir — savaş henüz yok) ve
  `Oyun.saat_ilerledi(su_anki_saat)` (varış saatine ulaşanları hedefe taşır). İkisi de
  `Zaman` autoload'ına değil, parametre olarak verilen saate bağlı; `zaman_testi.gd`'deki
  gibi autoload'sız sınanabilir.
- `main.gd`: birlik kartı açıkken başka bir bölgeye dokunmak hareket emri verir (kabul
  edilmezse dokunulan bölge normal gösterilir); `Zaman.saat_gecti` → `Oyun.saat_ilerledi`,
  `Oyun.birlikler_degisti` → `HaritaGorunumu.birlikleri_yenile()` bağlandı.
- Harita: yürüyen tümenlerin kaynak-hedef çizgisi sarı bir çizgiyle gösterilir (yakınlıktan
  bağımsız her zaman görünür).
- 3 yeni sınama (`tests/sim/hareket_testi.gd`): kendi toprağına yürüyüp süresi dolunca
  varıyor, düşman toprağına yürütme reddediliyor, var olmayan bölgeden yürütme false
  dönüyor. Toplam 23/23 sınama geçiyor.
- **Ekran görüntüsüyle bulunan ve düzeltilen hata:** tümen kutusunun konum payı
  (BIRLIK_KONUM_PAYI) yanlışlıkla dönüşüm KÖKENİNE ekleniyordu; bu da kamera yakınlığıyla
  birlikte ekranda büyüyüp kutuyu bölge etiketinden uzaklaştırıyordu (dünya görünümünde
  fark edilmiyordu, bir ülkeye yakınlaşınca kutu yıldızdan uzağa kayıyordu). Payı,
  ölçeklenmiş yerel çerçeve içine taşıyarak (adlar/yıldız gibi) düzeltildi; ekran
  görüntüsüyle doğrulandı.
- Henüz yok: "Yarısını ayır" düğmesi, birlik hareketinin görsel animasyonu (şu an anlık
  ışınlanma gibi; yalnızca varış anında bölge değişir).

B) BİRLİKLER VE HAREKET tamamlandı (TASARIM.md yol haritasında ✅):
- `Oyun.birlikleri_yurut()` artık bir bölge id'si değil, doğrudan `Array[Birlik]` alıyor
  (daha genel: "yarısını ayır" gibi alt kümeleri de yürütebilsin diye). Çağıran taraf
  (main.gd) `_secili_birlikler: Array[Birlik]` tutar.
  - `Oyun.yariya_ayir(stok)`: tek tümende gücü ikiye böler (yeni bir Birlik oluşturur,
    `Oyun.birlikler`e ekler); birden çok tümende sayıca yarısını (aşağı yuvarlayarak)
    ayırıp döndürür. Ayrılan liste, main.gd'nin `_secili_birlikler`'i olur.
  - `BirlikPaneli`'ye "Yarısını ayır" düğmesi eklendi (`yarisini_ayir_basildi` sinyali,
    `Arayuz.yarisini_ayir_istendi` ile main.gd'ye kadar iletiliyor).
- 5 yeni sınama (`tests/sim/hareket_testi.gd`): boş listeden yürütme false döner, tek
  tümen tam ortadan ikiye bölünür (yeni tümen `Oyun.birlikler`e eklenir), çoklu tümen
  sayıca yarıya ayrılır (3'te 1 ayrılır), gücü 2'den az tek tümen ayrılmaz. Toplam
  26/26 sınama geçiyor.
- Ekran görüntüsüyle doğrulandı (geçici debug, geri alındı): düğme panelde doğru görünüyor.

C) SAVAŞ — savaş ilanı ve boş bölge işgali tamamlandı:
- `Dunya.ulkeler_komsu_mu(a, b)`: iki ülke o anki bölge sahipliklerine göre kara/deniz
  yoluyla DOĞRUDAN komşu mu (üçüncü ülke toprağından "geçerek" ulaşmak sayılmaz — savaş
  yalnızca gerçek komşulara ilan edilebilir, tam dünya bağlantısı değil; TASARIM.md'nin
  "yalnızca ulaşabildiğin ülkelere" ifadesi böyle yorumlandı, bkz. Kararlar).
- `Oyun._savaslar` (çift başına), `savasta_mi()`, `savas_ilan_et()` (komşu değilse ya da
  zaten savaştaysa reddeder), `savas_ilan_edildi` sinyali.
- `Oyun.birlikleri_yurut()`: hedef kendi toprağın değilse artık yalnızca o ülkeyle
  savaştaysan kabul ediyor (önceki "yalnızca kendi toprağın" kısıtlaması gevşetildi).
- `Oyun.saat_ilerledi()`: varan tümen, savaşta olunan ve savunanı kalmamış bir bölgeye
  giriyorsa bölgeyi hemen ele geçirir (`bolge_sahipligi_degisti` sinyali →
  `HaritaGorunumu.yenile()`). Savunan varsa (muharebe yok) işgal olmaz.
- Arayüz: bölge panelinde (düşman + komşu + henüz savaşılmayan ülkenin bölgesi
  gösterildiğinde) "Savaş ilan et" düğmesi + onay penceresi (ConfirmationDialog).
  Henüz tam bir "ülke paneli" yok; mevcut bölge paneli (zaten ülke bilgisi gösteriyordu)
  yeniden kullanıldı — G) ARAYÜZ aşamasında "bağlama göre değişen panel" ile resmîleşecek.
- 6 yeni sınama (`tests/sim/savas_testi.gd`): komşu olmayana ilan edilemez, komşuya
  edilebilir (iki yönde de), aynı savaş tekrar ilan edilemez, kendine ilan edilemez, boş
  düşman bölgesi işgal edilir, savunması olan bölge işgal edilmez. Toplam 32/32 sınama
  geçiyor. Ekran görüntüsüyle doğrulandı (geçici debug, geri alındı).
- Henüz yok: muharebe, teslim, barış teklifi.

## Sıradaki iş

C) SAVAŞ — sıradaki alt adım: muharebe.
- Dolu düşman bölgesine giren birlik savaşır: saatlik çarpışma, kayıplar karşı tarafın
  toplam gücüyle orantılı. Savunan %25 avantajlı, denizden gelen saldırgan %30 cezalı.
  Kaybeden komşu dost bölgeye çekilir, yoksa yok olur. Haritada muharebe işareti.
- Bu tamamlanınca: teslim (başkenti düşen ve bölgelerinin yarısını kaybeden ülke teslim
  olur) ve barış teklifi (kaybeden ya da 180 gün bölge el değiştirmediyse).

## Kararlar

- 2026-10-04: Deniz yolu uzaklık sınırı 220 harita birimi, bölge başına en yakın 3 olarak
  uygulandı (kullanıcının verdiği sayılar). Bir kenar, iki ucundan BİRİNİN en yakın 3'üne
  giriyorsa tutulur (simetrik ve her bölge için "yeterli" olacak şekilde) — bu yüzden bir
  bölgenin toplam deniz yolu sayısı 3'ü geçebilir.
- 2026-10-04: Dünya bağlantısı tamamlama adımı, ayrık kalan her kümeyi en büyük kümeye en
  yakın kıyı-kıyı çiftiyle bağlıyor; 220 birim sınırı bu ek bağlantıya uygulanmıyor (amaç
  "hiçbir ada ulaşılamaz kalmasın" garantisi).
- 2026-10-04: Tüm oturum boyunca, görev kapsamı ve kurallar kullanıcının verdiği uzun
  talimat metninden geliyor (A-J aşamaları, self-test kurulumu, commit/push disiplini).
  Belirsiz noktalarda en sade seçenek seçiliyor ve buraya not düşülüyor.
- 2026-10-04: Denge dosyasının adı `data/balance.json` olarak kaldı (kullanıcının talimatı
  "data/denge.json" diyordu, ama CLAUDE.md'nin kendi kuralı "data/ altındaki dosyalar
  İngilizce adlıdır" diyor ve dosya zaten balance.json olarak kurulu; gereksiz bir yeniden
  adlandırma yapılmadı).
- 2026-10-04: Başlangıç ordusu tümen sayısı formülü: `(sqrt(nüfus/2000000) +
  sqrt(gsyh_milyon_dolar/50000)) / 2`, 1-24 arasına sınırlı. Kaba bir ilk tahmindir;
  TASARIM.md'nin H) DENGE aşamasında uzun koşu sınamasıyla ayarlanacak.
- 2026-10-04: Tümen kutuları, bölge sınırları/adlarıyla aynı yakınlık eşiğinde (yakınlık
  > 1,7) görünür. İlk sürümde her zaman açıktı; dünya görünümünde yüzlerce kutu üst üste
  bindiği ekran görüntüsüyle görüldü, aynı eşik koda eklendi.
- 2026-10-04: Deniz yolu süresi `48 + uzaklık * 1,5` saat (taban + mesafeye bağlı). Yalnızca
  mesafeyle orantılı bir çarpan (ör. mesafe * 1,5) kısa boğazları (ör. Cebelitarık ~1-2
  birim) kara komşuluğundan (24 saat) HIZLI yapardı; "belirgin yavaş" isteğini karşılamak
  için bir taban süre eklendi. Sayılar kaba bir ilk tahmin, H) DENGE'de ayarlanacak.
- 2026-10-04: Oyun.birlikleri_yurut/saat_ilerledi, Zaman autoload'ına DOĞRUDAN bağlanmaz;
  çağıran (main.gd) güncel saati parametre olarak verir. Zaman'ın zaten kendi testinde
  (zaman_testi.gd) aynı sebeple autoload'sız örneklendiği görülmüştü; Oyun için de aynı
  deseni sürdürmek, --script sınama çalıştırıcısında autoload'ların kullanılabilir olup
  olmadığına güvenmeden sınanabilmesini sağlıyor.
- 2026-10-04: Savaş henüz yokken hareket, yalnızca kaynak ve hedef bölge aynı ülkeye aitse
  kabul edilir (Oyun.birlikleri_yurut içinde). Savaş eklenince ("savaşta olduğun ülkenin
  toprağına girebilirsin") bu denetim gevşetilecek.
- 2026-10-05: "Yalnızca kara ya da deniz yoluyla ulaşabildiğin ülkelere" savaş ilanı,
  DOĞRUDAN komşuluk olarak yorumlandı (Dunya.ulkeler_komsu_mu), tam dünya bağlantısı
  değil. Gerekçe: dünya zaten kara+deniz birleşimiyle tek parça (A aşamasında garanti
  edildi), yani "ulaşabilirlik" her ülkeye her ülkeden teknik olarak doğru olurdu —
  bu da kısıtlamayı anlamsızlaştırırdı. "Savaşta olmadığın toprağa giremezsin" kuralıyla
  birlikte okununca, asıl kısıtın "üçüncü bir ülkeden geçmeden ulaşabildiğin" (yani
  doğrudan komşu) ülkeler olduğu daha tutarlı.
- 2026-10-05: Savaş ilanı arayüzü, ayrı bir "ülke paneli" yerine mevcut bölge paneline
  eklendi (zaten ülke bilgisi gösteriyordu). G) ARAYÜZ aşamasında "bağlama göre değişen
  panel" ile resmîleştirilecek; şimdilik gereksiz bir UI bileşeni tekrarından kaçınıldı.

## Bilinen sorunlar

- Henüz yok.
