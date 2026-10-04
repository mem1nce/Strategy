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

## Sıradaki iş

B) BİRLİKLER VE HAREKET — sıradaki alt adım: seçme ve emir.
- Kendi birliğinin olduğu bölgeye dokun → birlik kartı açılsın.
- Hedef bölgeye dokun → yol çizgisi görünsün, birlik yürüsün. "Yarısını ayır" düğmesi.
- Kara komşusuna geçiş 24 saat; deniz yolu mesafeyle orantılı ve belirgin yavaş; yol bulma
  AStar ile. Savaşta olmadığın ülkenin toprağına girilemez (henüz savaş yok, o yüzden bu
  kısıtlama şimdilik "kendi ülken değilse giremezsin" olarak uygulanabilir; savaş eklenince
  gevşetilir).

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

## Bilinen sorunlar

- Henüz yok.
