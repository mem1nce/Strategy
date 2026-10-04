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

## Sıradaki iş

B) BİRLİKLER VE HAREKET — ilk alt adım: birlik verisi + haritada gösterim.
- Tek birlik türü: tümen, güç 0-100.
- Haritada ülke renginde sade bir kutu, içinde güç yazsın; aynı bölgedeki tümenler tek
  işaret ve sayı olarak görünsün.
- Bu alt adımda henüz: başlangıç ordusu dağıtımı, seçme, hareket YOK (sıradaki alt adımlar).

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

## Bilinen sorunlar

- Henüz yok.
