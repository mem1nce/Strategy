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
   alt panelde "Tümen: N (Piyade … · Zırhlı … · Topçu …)", "Toplam güç: …" kartı açılmalı. Sonra komşu kendi bölgene tıkla
   → iki bölge arasında sarı yol çizgisi çıkmalı. "Devam"a bas; kutu hedef bölgeye geçmeli.
   Süre bölgeler arasındaki uzaklığa bağlıdır (en az 8, en çok 48 oyun saati): Hollanda'da
   iki komşu bölge arası, Rusya'da ya da Kanada'da iki komşu bölge arasından belirgin kısa sürmeli.

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

12. **Üretim kuyruğu** — Kendi bölgende "Fabrika kur"a bas → hazine düşmeli, sol üstte
    "İnşa: Fabrika (… sa)" satırı görünmeli ve saat geri saymalı. "Ordu: YZ"yi açıp birkaç
    gün ilerletince senin ülken de kendi kendine iş sıralamalı.

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

16. **Tümen türü seçimi** — Kendi bölgende "Tümen kur"a bas → ortada "Hangi tümeni
    kuralım?" paneli açılmalı: Piyade (Fiyat 40, 4 gün, topçuya karşı güçlü), Zırhlı (90,
    7 gün, piyadeye karşı), Topçu (60, 5 gün, zırhlıya karşı) ve "Vazgeç". Zırhlı'ya bas →
    panel kapanmalı, hazine 90 düşmeli, "Zırhlı tümen sıraya alındı" bildirimi çıkmalı, sol
    üstte "İnşa: Zırhlı (… sa)" yazmalı. "Vazgeç" hiçbir şey sıralamamalı.

17. **Haritada tür işaretleri** — Kendi ülkene yakınlaş → tümen kutularında önce toplam güç,
    sonra her tür için işaret ve sayı görünmeli: çarpı = piyade, yatay oval = zırhlı, dolu
    daire = topçu (ör. "520 ✕3 ⬭2 ●1"). Zengin bir ülkede (ABD, Almanya) oval ve daireler,
    yoksul bir ülkede (ör. Çad, Nijer) çarpılar daha çok olmalı.

18. **Üstünlük üçgeni ve hız** — Savaşta, aynı güçte zırhlı ağırlıklı bir yığınla düşmanın
    piyade ağırlıklı yığınına saldır → senin tarafın belirgin daha az kayıp vermeli. Bir
    zırhlı tümeni ve bir piyadeyi aynı anda komşu bölgeye yürüt → zırhlı daha önce varmalı;
    zırhlı ile topçuyu birlikte yürütürsen yığın topçunun (en yavaşın) hızıyla gitmeli.

19. **Teknoloji paneli** — Üst çubukta "Teknoloji"ye bas → alt panel kapanmalı, ortada 4
    satır (Sanayi, Silah, Savunma, Lojistik) × 3 kutu açılmalı; her kutuda "Seviye n", ne
    verdiği (ör. "Gelir +%10") ve "Fiyat 150 · 30 gün" yazmalı. Bir 1. seviye kutusuna bas →
    hazine 150 düşmeli, başlığın yanında "… araştırılıyor, 30 gün kaldı" ve ilerleme çubuğu
    çıkmalı, diğer kutular basılamaz olmalı. Oyun akarken çubuk dolmalı. Bir bölgeye
    dokununca panel kapanmalı; "Teknoloji" düğmesi tekrar basınca da kapanmalı. "Sıralama"
    açılınca teknoloji paneli kapanmalı (ikisi üst üste binmemeli).

20. **Araştırma bitince** — 3x hızda araştırmayı bekle (30 gün) → sağ üstte "Araştırma
    tamamlandı: Sanayi 1 (Gelir +%10)." bildirimi çıkmalı; panelde o kutu sarı ("tamam")
    olmalı ve 2. seviye basılabilir hâle gelmeli. Sanayi'den sonra günlük hazine artışı
    biraz büyümeli.

21. **Tahkimat** — Kendi bölgende "Tahkimat 0/3 · Kur (40)" düğmesine bas → hazine 40 düşmeli,
    düğme "Tahkimat 0/3 · Kur (80)" olmalı (kuyruktaki iş sayılır). 10 gün sonra haritada
    bölge adının solunda gri kule ve içinde "1" görünmeli. Üç seviye sıralayınca düğme
    "Tam" yazıp soluklaşmalı. Başka bir ülkenin tahkimatlı bölgesine dokununca panelde
    "Tahkimat: n/3" yazmalı. Tahkimatlı bir bölge el değiştirince seviyesi bir düşmeli.

22. **Eski kayıt** — Bölgeler yeniden üretilmeden önce kaydedilmiş bir oyunun varsa oyunu aç →
    ana menüde başlığın altında sarı "Bu kayıt eski bir sürüme ait. Yeni oyun başlat." yazmalı,
    "Devam et" soluk (basılamaz) olmalı. "Yeni oyun"a bas → onay sormadan yeni oyun başlamalı;
    oyunu kapatıp açınca uyarı kalkmış olmalı. Oyun hiçbir adımda çökmemeli.

23. **Nasıl oynanır ve geniş ekran** — Ana menüde "Nasıl oynanır"a bas → tümen türleri,
    teknoloji ve tahkimat paragrafları görünmeli, "Kapat" ekranın içinde olmalı. Pencereyi
    genişletip (ör. 2400 × 1080 gibi geniş, telefona benzer oran) ve daraltıp (16:9) üst
    çubuğa, alt panele ve teknoloji paneline bak → hiçbir düğme ekran dışına taşmamalı.

24. **Yeni bölgeler** — Haritayı uzaktan aç → yalnızca ülkeler, ülke sınırları ve ülke adları
    görünmeli (bölge sınırı, kutu yok). Avrupa'ya yavaşça yakınlaş → önce ince bölge sınırları
    ve adlar, biraz daha yakında tümen kutuları belirmeli; adlar ve kutular üst üste binmemeli.
    Benelüks, Lübnan-İsrail ve Kore gibi sık yerlerde kutu yerinden kaydıysa bölgesine ince
    siyah bir çizgiyle bağlı olmalı.

25. **Bölge sayıları ve adları** — Türkiye'yi seç → 10 bölge olmalı: Ankara, İstanbul, İzmir,
    Antalya, Tarsus, Gaziantep, Diyarbakır, Van, Trabzon, Samsun. Rusya, ABD, Çin, Kanada,
    Brezilya, Hindistan ve Avustralya'da 25 ile 40 arası, Hollanda ve Portekiz'de 3 bölge
    görmelisin. Sibirya ve Avustralya'nın içi de birkaç bölgeye bölünmüş olmalı.
