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

C) SAVAŞ — muharebe tamamlandı:
- `Oyun._muharebeleri_isle()`: her saat, birden çok ülkenin tümeni bulunan her bölgede
  `_muharebeyi_coz()` çağrılır. Her taraf, karşı tarafın etkin (bonus/ceza uygulanmış)
  toplam gücüyle orantılı kayıp alır (`saatlik_kayip_orani`); savunan `savunan_avantaji`
  (×1,25) avantajlı, son adımı deniz yoluyla gelen saldırgan `deniz_cezasi` (×0,70) cezalı.
  Sabitler data/balance.json → "savas".
- Güç `ASGARI_GUC` (1.0) altına düşen tümen silinir. Bir taraf tükenirse ya da karşı
  tarafın `cekilme_esigi`'nin (×0,25) altına düşerse geri çekilir (`_geri_cek`): en yakın
  dost komşuya taşınır, yoksa yok olur.
  - **Bulunup düzeltilen hata:** savunan geri çekildiğinde bölge sahipliği değişmiyordu
    (savunan fiilen terk etmiş olsa da bölge hâlâ eski sahibindeydi, saldırgan asla
    ele geçiremiyordu — "yarı boş" bir durumda kalıyordu). Savunan tükenince ya da
    çekilince (ikisinde de bölgede artık savunan kalmaz) bölge hemen saldırganın olacak
    şekilde düzeltildi. Sınamalarla (2000 saate kadar ilerleterek) yakalandı.
- Harita: birlik kutusunun yanında, birden çok ülkenin tümeni olan bölgede kırmızı bir
  daire (muharebe işareti); kutu iki tarafın toplam gücünü gösterir. Ekran görüntüsüyle
  doğrulandı.
- `Birlik.son_adim_deniz_mi`: `Oyun.birlikleri_yurut()` içinde, YolBulucu'nun bulduğu
  yolun son adımı deniz yoluysa işaretlenir; muharebede saldırgan deniz cezası için kullanılır.
- 4 yeni sınama (`tests/sim/muharebe_testi.gd`): ezici saldırgan bölgeyi alır, savunan
  avantajıyla eşit güçte saldırganı yener (geri çekilir/tükenir), deniz cezası saldırganı
  gerçekten zayıflatır (karşılaştırmalı sınama), gerçek başlangıç ordusuyla (savaş yokken)
  200 saat hatasız ilerliyor (performans/çökme regresyon sınaması). Toplam 36/36 sınama
  geçiyor.

C) SAVAŞ tamamlandı (TASARIM.md yol haritasında ✅):
- `Oyun._bolgeyi_devret(bolge, yeni_sahip)`: bölge sahipliği değiştiren TEK yer (işgal ve
  muharebe artık bunu çağırıyor); sinyal yayar ve eski sahibin teslim olup olmadığını
  denetler (`_teslimi_kontrol_et`). Başkenti düşmüş VE oyun başındaki bölge sayısının
  yarısından fazlasını kaybetmiş ülke teslim olur: kalan bölgeleri galibe geçer, bütün
  tümenleri silinir (`ulke_teslim_oldu` sinyali). `Ulke.baslangic_bolgeleri` (zaten A
  aşamasından vardı) bu yüzden ilk kez kullanıldı.
- `Oyun.savas_ilan_et()` artık savaşın başladığı saati de saklıyor (`_savaslar` artık
  `Dictionary[String, int]`, değer = ilan saati); `Oyun.baris_teklif_et()`: hedef, kendi
  toplam askeri gücü teklif edenden azsa ya da savaş 180 günden (`BARIS_ESIGI_SAAT`) uzun
  sürdüyse kabul eder.
- Bölge panelinde savaşta olunan ülkenin bölgesi gösterilince "Savaş ilan et" yerine
  "Barış teklif et" düğmesi görünür (onaysız, tek dokunuş).
- 6 yeni sınama (`tests/sim/teslim_ve_baris_testi.gd`): başkent+yarı kaybıyla teslim,
  zayıf taraf barışı kabul eder, kazanan erken teklifi reddeder, 180 günden uzun savaşta
  barış kabul edilir, savaşta olmayanlar arasında teklif reddedilir. Toplam 41/41 sınama
  geçiyor.
  - **Test yazarken bulunan GDScript gotcha'sı (üretim kodu değil):** lambda'lar yerel
    değişkenleri değer olarak yakalar; sinyal geri çağrımı içinde `bool`/`String`
    değişkenine atama yapmak dışarıdaki değişkeni GÜNCELLEMEZ. Çözüm: değiştirilebilir
    bir konteyner (`Array`) kullanmak. Gelecekte sinyal dinleyen sınamalar yazılırken
    hatırlanmalı.
- Ekran görüntüsüyle doğrulandı (geçici debug, geri alındı): "Barış teklif et" düğmesi
  savaş sırasında "Savaş ilan et" yerine doğru görünüyor.

D) EKONOMİ — üretim ve gelir tamamlandı:
- `Bolge.isgal_saati`: son ele geçirilme saati (-1 = hiç); `Oyun._bolgeyi_devret()` ve
  `_teslimi_kontrol_et()` içinde kaydediliyor (iki yerde de su_anki_saat parametresi
  eklendi — bu, `_bos_dusman_bolgesini_isgal_et`, `_muharebeleri_isle`, `_muharebeyi_coz`
  zincirine de yayıldı).
- `Oyun.bolge_sanayisi(bolge, saat)`: bölgenin "ev sahibi" ülkesinin (id önekinden, ör.
  "TUR_1"→"TUR") GSYH'sinden `sqrt` ile yumuşatılıp nüfus payına göre dağıtılır — kimin
  elinde olduğundan bağımsız (toprağın kendi niteliği); işgal altındaysa (ele geçirileli
  `isgal_cezasi_gun` (60) günden az olmuş VE hâlâ ev sahibinde değilse) `isgal_cezasi_orani`
  (×0,5) uygulanır.
- `Oyun.ulkenin_geliri()`: o an sahip olunan bölgelerin sanayileri toplamı.
- `Oyun.gun_basladi(saat)`: her ülkenin günlük geliri hazinesine eklenir
  (`Oyun.hazineler`, `hazine_degisti` sinyali). `Zaman.gun_basladi` main.gd'de saate
  çevrilip (`gun*24`) çağrılıyor — Oyun yine Zaman autoload'ına bağlı değil.
- Üst çubukta oyuncunun hazinesi yazılı ("Hazine: N").
- 6 yeni sınama (`tests/sim/ekonomi_testi.gd`): sanayi pozitif ve cezasız başlar, işgal
  altında yarı üretir, 60 günden sonra ceza kalkar, ev sahibi geri alınca ceza olmaz,
  ülke geliri bölge toplamına eşit, gün başlayınca hazine artıyor (iki kez, sinyal
  sayısıyla doğrulandı). Toplam 47/47 sınama geçiyor.
- Ekran görüntüsüyle doğrulandı (geçici debug, geri alındı): "Hazine: 12" üst çubukta
  doğru görünüyor.
- Henüz yok: harcama (tümen kur, fabrika kur — tek kuyruk, en fazla 5 iş), bakım (her
  tümen günlük üretim yer; gelir eksiye düşerse tümenler güç kaybeder).

D) EKONOMİ tamamlandı (TASARIM.md yol haritasında ✅):
- `InsaIsi` (sim/insa_isi.gd): tek bir inşa işi (tür, sahip, bölge, kalan saat).
- `Oyun.tumen_sirala()`/`fabrika_sirala()`: kendi bölgende, maliyet hemen hazineden
  düşülerek sıralanır (yetmezse ya da kuyruk (5 iş) doluysa false). Tek kuyruk: yalnızca
  önündeki iş ilerler (`Oyun._insa_islerini_isle()`, saat_ilerledi içinden her saat
  çağrılır). Süresi dolan tümen işi `baslangic_gucu` ile yeni tümen doğurur; fabrika işi
  `Bolge.fabrika_sanayisi`'ni kalıcı artırır (artık `bolge_sanayisi()`'ne ekleniyor).
- `Oyun._bakimi_uygula()`: her gün başı (gelir eklendikten sonra), tümen sayısı ×
  bakim_birim_maliyeti hazineden düşülür; yetmezse açık, muharebedeki `_guc_azalt` ile
  AYNI mekanizma kullanılarak tümenlere orantılı güç kaybı olarak yansıtılır (kod tekrarı
  yerine var olan yardımcı yeniden kullanıldı).
- 9 yeni sınama (`tests/sim/insa_testi.gd`): başkasının bölgesine sıralanamaz, hazine
  yetmezse sıralanamaz, sıralanınca maliyet düşer, kuyruk 5'i aşamaz, süre dolunca tümen
  doğar, tek kuyrukta ikinci iş ilerlemez, fabrika tamamlanınca sanayi artar, bakım
  karşılanamazsa güç azalır, karşılanırsa etkilemez. Toplam 56/56 sınama geçiyor.
  - **Testte bulunan kurulum hatası (üretim kodu değil):** "hazine yetersiz" sınaması
    `gun_basladi()` üzerinden kurulmuştu, ama `gun_basladi` önce geliri EKLİYOR —
    TUR'un gerçek geliri bakım masrafını karşılayabildiği için önkoşul hiç
    sağlanmıyordu. `_bakimi_uygula()` doğrudan çağrılarak (gelirden izole) düzeltildi.
- Ekran görüntüsüyle doğrulandı (geçici debug, geri alındı): tümen sıralanıp süresi
  dolunca Ankara kutusu 200→300 oldu, hazine 1000→950 düştü.
- **Henüz yok (bilinçli olarak bu aşamaya dahil edilmedi):** tümen/fabrika kurma
  düğmeleri arayüzde yok — yalnızca `Oyun` sim katmanında var (YolBulucu'nun da önce
  sadece backend olarak eklenip sonra arayüze bağlanması gibi). Hangi bölgede
  kurulacağını seçme arayüzü de yok ("başkentte ya da seçilen bölgede" — şimdilik
  yalnızca `tumen_sirala(ulke_id, bolge_id)` çağrısı herhangi bir kendi bölgeni kabul
  ediyor, main.gd'den henüz çağrılmıyor).

E) YAPAY ZEKÂ — ilk alt adım (barış davranışı) tamamlandı:
- `OrduKurucu._yerlesim_bolgeleri` → `yerlesim_bolgeleri` (artık public): başlangıç
  ordusu VE yapay zekânın yeni tümenleri aynı "başkent + sınır bölgeleri" mantığını
  paylaşıyor; kod tekrarı yerine yeniden kullanıldı.
- `Oyun._yapay_zekayi_isle(saat)`: her saat çağrılır (saat_ilerledi içinden). Her ülkenin
  sabit bir "düşünme saati" vardır (`absi(ulke_id.hash()) % 24`), günde tam bir kez o
  saat gelince düşünür — 176 ülke 24 saate yayılır, tek karede yığılma olmaz. Oyuncunun
  ülkesi ve bölgesi kalmamış (teslim olmuş) ülkeler düşünmez.
- `Oyun._baristaki_ulke_dusun()`: kuyrukta yer ve hazine varsa iş sıralar — %20
  olasılıkla (yapay_zeka.fabrika_olasiligi) fabrika, yoksa tümen; başkente ya da rastgele
  bir sınır bölgesine. Savaştaki ülkeler şimdilik hiçbir şey yapmaz (sıradaki alt adım).
  `Oyun._rng: RandomNumberGenerator` rastgelelik için (GDScript'in `randf()`'i değil,
  ileride sınamalarda tohumlanabilsin diye örnek değişkeni).
- 7 yeni sınama (`tests/sim/yapay_zeka_testi.gd`): düşünme saatleri 0-23 ve deterministik,
  oyuncu düşünmez, sırası gelmeyen ülke düşünmez, zengin ülke sırası gelince kurar, fakir
  ülke kurmaz, savaştaki ülke şimdilik kurmaz, teslim olmuş ülke düşünmez. Toplam 63/63
  sınama geçiyor.
  - **Testlerde bulunan izolasyon hatası (üretim kodu değil):** `insa_testi.gd`'deki
    (`tests/sim/insa_testi.gd`) üç sınama, hazine yüksek ayarlayıp `saat_ilerledi()`'yi
    uzun döngüde çağırıyordu; oyuncu hiç seçilmediği için (oyuncu_ulkesi == "") yapay
    zekâ TUR için de çalışıp kuyruğa beklenmedik işler ekleyebiliyordu. `_kurulu_oyun()`
    yardımcısına `oyuncuyu_sec("TUR")` eklenerek düzeltildi (gerçek oyunda zaman zaten
    oyuncu seçilene kadar kilitli, bu senaryo hiç oluşmaz — yalnızca testin saat_ilerledi'yi
    doğrudan çağırması bunu ortaya çıkardı).
- Diyagnostik betikle (geçici, silindi) doğrulandı: GEO'ya yüksek hazine verilip 360 saat
  ilerletilince tümen sayısı 1'den 3'e çıktı, hazine doğru düştü.
- **Performans gözlemi:** tam sınama takımı artık ~20 saniye sürüyor (önceki ~birkaç
  saniyeye göre belirgin artış); muharebe_testi.gd'nin 2000 saatlik döngüsü ve her saat
  176 ülke üzerinde gezinen yapay zekâ kontrolü muhtemel nedenler. Henüz optimize
  edilmedi — I) PERFORMANS VE ANDROID aşamasının işi (TASARIM.md'de zaten "uzun koşu
  testi 2 dakikadan kısa sürsün" hedefi var); şimdilik dokunulmadı.

E) YAPAY ZEKÂ tamamlandı (TASARIM.md yol haritasında ✅; kalan tek parça "ordumu yapay
zekâ yönetsin" anahtarı, bkz. Sıradaki iş):
- `Oyun._savastaki_ulke_dusun()`: her sınır bölgesinde (başkent HARİÇ — başkent hiç
  saldırmaz, böylece hep korunur) kendi gücünü savaştaki komşu bölgenin gücüyle kıyaslar;
  `yz_saldiri_esigi` (×1,3) katıysa `birlikleri_yurut()` ile saldırır.
- `Oyun._savas_ilanini_degerlendir()`: yaklaşık ayda bir (gün % 30 == 0) değerlendirilir;
  azami savaş sayısına (2) ulaşmışsa ya da zar (%10) tutmazsa hiçbir şey yapmaz. Tutarsa,
  doğrudan komşu ve kendisinden 2 kat güçsüz ilk ülkeye ilan eder. Oyuncu, ilk 90 gün aday
  sayılmaz — bu kısıtlama yalnızca YZ'nin kendi kararında (Oyun.savas_ilan_et API'si
  kendisi serbest bırakır, oyuncu da istediği an herhangi bir komşuya ilan edebilir).
- 9 yeni sınama (`tests/sim/yz_savas_testi.gd`): güçlü sınır bölgesi saldırır, zayıf
  saldırmaz, başkent ezici üstünlükte bile saldırmaz, gün uyumsuzsa/zar tutmazsa/komşu
  değilse/güç farkı yetersizse/azami savaşa ulaşılmışsa ilan edilmez, ilk 90 gün oyuncuya
  ilan edilmez, 90 günden sonra edilebilir. Toplam 73/73 sınama geçiyor.
  - **Testte bulunan kurulum hatası (üretim kodu değil):** oyuncu dokunulmazlığı
    sınamalarında ilan EDEN ülkenin değil, HEDEFİN (TUR/oyuncu) güçlü bırakılmıştı — bu
    yüzden güç eşiği hiç sağlanmıyor, sınama yanlış sebeple "geçiyordu" (dokunulmazlık
    hiç sınanmamış oluyordu). İlan edeni güçlü, hedefi zayıf bırakacak şekilde düzeltildi.
- Ekran görüntüsü bu adımda alınmadı (saf sim mantığı, UI yok); 9 hedefli sınama ve
  temiz headless çalıştırma ile doğrulandı.

F) OYUN AKIŞI — ilk alt adım, kayıt/yükleme, tamamlandı (TASARIM.md yol haritasında
"7. Kayıt" artık ✅):
- `Oyun.kaydet_icin_veri()`/`kayittan_yukle()`: oyunun tüm durumunu (oyuncu ülkesi,
  değişmiş bölgeler — hiç değişmemiş olanlar atlanır, tümenler, savaşlar, hazineler, inşa
  kuyrukları) düz bir sözlüğe çevirir/geri uygular.
- `Zaman.durumu_al()`/`durumu_uygula()`: aynı şey zaman için. `KayitYoneticisi`
  (`sim/kayit_yoneticisi.gd`) ikisini birleştirip `user://kayit.json`'a JSON olarak
  yazar/okur; tek kayıt yuvası, sürüm numarası (uyuşmazsa kayıt yok sayılır).
- Otomatik kayıt: her oyun günü başında (`Zaman.gun_basladi`) ve uygulama arka plana
  geçince/kapatılmak istenince (`_notification`, `NOTIFICATION_APPLICATION_PAUSED` /
  `NOTIFICATION_WM_CLOSE_REQUEST`). Oyuncu seçilmediyse kaydedilmez.
- Açılışta (`main.gd _ready()`) kayıt varsa otomatik yüklenir (henüz "Yeni oyun/Devam et"
  seçen bir ana menü yok — bu F'nin sıradaki alt adımı).
- 9 yeni sınama (`tests/sim/kayit_testi.gd`): kayıt yoksa boş döner, oyuncu ülkesi/birlik
  gücü/bölge sahipliği-işgal saati-fabrika sanayisi/savaş/hazine/inşa kuyruğu doğru
  korunur, sürüm uyuşmazsa yok sayılır. GERÇEK user:// kayıt yuvasını kullanır (ayrı bir
  sınama yolu yok); her sınama başında ve sonunda dosyayı siler ki ne sınamalar birbirini
  etkilesin ne de gerçek bir oturumun kaydını ezsin. Toplam 81/81 sınama geçiyor.
- **Uçtan uca ekran görüntüsüyle doğrulandı** (iki ayrı süreç): birinci çalıştırmada
  (geçici debug ile) TUR seçilip 24 saat ilerletildi, otomatik kayıt tetiklendi; kayıt
  dosyası gerçek, tutarlı veri içeriyordu (176 ülkenin tümenleri, bir YZ hareket emri
  dahil). İKİNCİ, debug'sız TEMİZ bir çalıştırmada oyun "2 Ocak 2026" ve "Hazine: 10" ile
  açıldı — kayıt gerçekten otomatik yüklendi. Test dosyaları temizlendi.

## Sıradaki iş

İki seçenek var:
1. F) OYUN AKIŞI'nın geri kalanı: ana menü (Yeni oyun/Devam et/Nasıl oynanır/Ayarlar),
   kaybetme (teslim) / zafer (kıtanın %60'ı) koşulları, güç sıralaması paneli, bildirimler.
2. E) YAPAY ZEKÂ'nın kalan parçası: "Ordumu yapay zekâ yönetsin" anahtarı.
Her ikisi de bağımsız, küçük parçalara bölünebilir. Kayıt/yükleme artık çalıştığı için
oyun gerçek anlamda "oturumlar arası sürüyor" — bu, bu oturumun en büyük tek boşluğunu
kapattı.

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
