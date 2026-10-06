# Elle test listesi

Her madde "şunu yap → şunu görmelisin" biçimindedir. Beklenen sonucu görmezsen maddenin
numarasını, ne yaptığını ve ne gördüğünü not al.

Bilgisayarda fare parmak yerine geçer: tıklama = dokunma, basılı tutup sürükleme =
kaydırma, tekerlek = yakınlaştırma.

## Oyunu açmak (3 adım)

1. Godot 4.7.2'yi aç, proje listesinden **Yerküre**'yi seç. Liste boşsa **İçe Aktar**'a
   bas ve `Documents\yeni-oyun-projesi\project.godot` dosyasını göster.
2. Düzenleyici açılınca sağ üstteki **▶ (Projeyi Çalıştır)** düğmesine ya da **F5**'e bas.
3. 1280 × 720 bir pencere açılır ve ana menü görünür. Kapatmak için pencereyi kapat ya da
   düzenleyicide **■ (Durdur)**'a bas.

## Maddeler

1. **Ana menü** — Oyunu aç → haritanın ortasında "Yerküre" başlıklı panelde Yeni oyun,
   Devam et, Nasıl oynanır, Ayarlar düğmeleri görünmeli. Kayıt yoksa "Devam et" soluk ve
   basılamaz olmalı. "Nasıl oynanır" ve "Ayarlar" panelleri açılıp kapanmalı.

2. **Yeni oyun (kayıt varken)** — Kayıt varken "Yeni oyun"a bas → "Mevcut kayıt
   silinecek" onay penceresi çıkmalı. Onaylayınca menü kapanmalı ve haritada bir ülkeye
   tıklayınca bilgi paneli açılmalı. Onay penceresindeki düğmelerin parmakla rahat
   basılacak büyüklükte olup olmadığına da bak.

3. **Ülke seçimi** — "Ülkeni seç" yazısı varken bir ülkeye tıkla → alt panelde bölge adı,
   ülke bilgileri, "Komşuları göster" ve "Bu ülkeyle oyna" düğmeleri görünmeli; iki düğme
   de **ekranın içinde, tam görünür** olmalı. "Bu ülkeyle oyna"ya basınca kamera ülkeye
   kaymalı, ülke beyaz çerçeve almalı, sol üstte ülke adı ve hazine yazmalı, zaman
   düğmeleri etkinleşmeli.

4. **Birlik yürütme** — Kendi ülkende üstünde sayılı kutu (tümen) olan bir bölgeye tıkla →
   alt panelde "Tümen: N, Toplam güç: …" kartı açılmalı. Sonra komşu kendi bölgene tıkla
   → iki bölge arasında sarı yol çizgisi çıkmalı. "Devam"a bas; yaklaşık 24 oyun saati
   sonra kutu hedef bölgeye geçmeli.

5. **Yarısını ayırma** — İki ya da daha fazla tümenli bir bölgenin kartını aç, "Yarısını
   ayır"a bas → karttaki tümen sayısı yarıya inmeli (tek tümense güç ikiye bölünmeli).
   Sonra bir hedefe tıkla → yalnızca ayrılan kısım yürümeli, kalanı yerinde durmalı.

6. **Deniz yolu** — Kıyıdaki bir bölgendeki tümeni, denizin karşısındaki kendi
   bölgene (ya da komşusu olmayan uzak bir kıyı bölgene) gönder → emir kabul edilmeli;
   varış, kara komşusuna gitmekten belirgin daha uzun sürmeli (48 saatten fazla).

7. **Savaş ilanı** — Komşu bir ülkenin bölgesine tıkla → panelde "Savaş ilan et" düğmesi
   olmalı. Bas, onay penceresini onayla → o ülke haritada kırmızı çerçeveyle işaretlenmeli.
   Komşu olmayan bir ülkenin bölgesinde bu düğme görünmemeli.

8. **Muharebe** — Savaştığın ülkenin tümenli bir bölgesine kendi tümenlerini yürüt →
   varınca bölgede kırmızı bir daire (muharebe işareti) çıkmalı ve iki tarafın gücü saat
   saat azalmalı; zayıf taraf geri çekilmeli ya da yok olmalı.

9. **İşgal** — Savaştığın ülkenin boş (tümensiz) bir bölgesine yürü ya da muharebeyi kazan
   → bölge senin rengine dönmeli, turuncu "yeni işgal" çerçevesi almalı ve sağ üstte bölge
   kazanıldı bildirimi çıkmalı.

10. **Teslim** — Küçük bir komşunun başkentini ve bölgelerinin yarısından fazlasını al →
    o ülke teslim olmalı: kalan bütün bölgeleri sana geçmeli, tümenleri haritadan silinmeli.

11. **Barış teklifi** — Savaştığın ülkenin bir bölgesine tıkla → panelde "Savaş ilan et"
    yerine "Barış teklif et" görünmeli. Karşı taraf senden zayıfsa ya da savaş 180 günden
    uzun sürdüyse kabul etmeli (kırmızı çerçeve kalkmalı); güçlü bir rakip erken teklifi
    reddetmeli (savaş sürmeli).

12. **Üretim kuyruğu** — Oyuncunun tümen ya da fabrika sıralayacağı bir düğme şu an **yok**
    (bkz. TEST_RAPORU.md). Bunu doğrula: kendi bölgelerinde ve panellerde "Tümen kur" /
    "Fabrika kur" gibi bir düğme arama. Sonra "Ordu: YZ"yi aç ve birkaç gün ilerlet → sol
    üstte "İnşa: Tümen (… sa)" ya da "İnşa: Fabrika (… sa)" satırı görünmeli, saat geri
    saymalı, iş bitince hazine düşmüş ve bölgede yeni tümen belirmiş olmalı.

13. **Bildirimler** — Bir bölge kazan, bir bölge kaybet ya da bir üretim işini bitir → sağ
    üstte üst çubuğun altında bir kart çıkmalı. Karta tıklayınca kart kapanmalı ve kamera
    ilgili bölgeye kaymalı. Dörtten fazla bildirim gelirse en eskisi kaybolmalı.

14. **"Ordumu YZ yönetsin" ve hız düğmeleri** — "Ordu: YZ"ye bas → düğme sarı (açık) olmalı;
    oyun akarken senin ülken de kendi kendine tümen/fabrika kurmalı, savaştaysa saldırmalı.
    Tekrar basınca kapanmalı. "Devam"/"Durdur" zamanı başlatıp durdurmalı; 1x, 2x, 3x'te
    bir oyun günü yaklaşık 12, 4 ve 1 saniye sürmeli, etkin hız sarı görünmeli. Ülke
    seçilmeden önce bu düğmelerin hepsi soluk (kilitli) olmalı ve **"Sıralama" dahil hepsi
    ekranda görünmeli**.

15. **Kapatıp kayıttan devam** — Ülke seç, birkaç gün oynat (savaş, hareket emri olsun),
    tarihi ve hazineyi not et, pencereyi kapat. Oyunu yeniden aç → "Devam et" etkin olmalı;
    basınca aynı ülke, tarih, hazine, bölgeler, tümenler ve savaşlarla devam etmeli. "Ordu:
    YZ" açık bıraktıysan açık gelmeli.
