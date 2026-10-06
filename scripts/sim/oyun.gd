class_name Oyun
extends RefCounted
## Oyunun durumu: dünya ve oyuncunun seçtiği ülke.
##
## Birlik, savaş ve ekonomi eklendikçe onların durumu da buraya bağlanacak.

## Oyuncu ülkesini seçtiğinde bir kez yayılır.
signal oyuncu_secildi(ulke_id: String)
## Bir tümen yürümeye başladığında ya da vardığında yayılır.
signal birlikler_degisti
## İki ülke arasında savaş ilan edildiğinde yayılır.
signal savas_ilan_edildi(ulke_a: String, ulke_b: String)
## Bir bölgenin sahibi değiştiğinde (ör. boş düşman bölgesi ele geçirilince) yayılır.
signal bolge_sahipligi_degisti
## Bir ülke teslim olduğunda yayılır (başkent düşer ve bölgelerinin yarısından fazlasını
## kaybedince): kalan bölgeleri galibe geçer, birlikleri silinir.
signal ulke_teslim_oldu(ulke_id: String, galip_id: String)
## İki ülke barış yaptığında yayılır.
signal baris_yapildi(ulke_a: String, ulke_b: String)
## Bir ülkenin hazinesi değiştiğinde (her oyun günü başında gelir eklenince) yayılır.
signal hazine_degisti
## Bir ülkenin inşa kuyruğuna iş eklendiğinde ya da bir iş tamamlandığında yayılır.
signal insa_kuyrugu_degisti(ulke_id: String)
## Bir ülkenin araştırması başladığında ya da bittiğinde yayılır.
signal teknoloji_degisti(ulke_id: String)
## Bir bölgenin tahkimatı inşa bitince yükseldiğinde yayılır (el değiştirirken düşmesi
## bolge_sahipligi_degisti ile birlikte gelir).
signal tahkimat_degisti(bolge_id: String)
## Oyuncu teslim olunca bir kez yayılır (kaybetme).
signal oyun_kaybedildi
## Oyuncunun kıtasındaki bölgelerin ZAFER_ORANI (×0,6) kadarı kendisinin olunca bir kez
## yayılır (zafer); sonrasında oynamaya devam edilebilir, oyun kilitlenmez.
signal oyun_kazanildi
## Oyuncuyla ilgili önemli bir olay olduğunda (sana savaş ilanı, bölge kaybı/kazancı,
## üretim bitti) kısa bir bildirim metni ve -varsa, kamerayı odaklamak için- ilgili
## bölge id'siyle yayılır. Bölge id'si yoksa (ör. gelecekte eklenebilecek bölgesiz bir
## olay) boş metindir.
signal bildirim_gonder(metin: String, bolge_id: String)

const DENGE_DOSYASI: String = "res://data/balance.json"
## Tümenin güç altına düştüğünde yok sayıldığı eşik.
const ASGARI_GUC: float = 1.0
## Barış teklifinin otomatik kabul edilmesi için bir savaşın en az bu kadar sürmesi gerekir.
const BARIS_ESIGI_SAAT: int = 180 * 24
## İnşa kuyruğunda aynı anda en fazla bu kadar iş bekleyebilir.
const AZAMI_KUYRUK_UZUNLUGU: int = 5
## Zafer için, oyuncunun kıtasındaki bölgelerin gereken sahiplik oranı.
const ZAFER_ORANI: float = 0.6

var dunya: Dunya = null
## Oyuncunun yönettiği ülkenin id'si. Seçim yapılmadıysa boştur.
var oyuncu_ulkesi: String = ""
## Dünyadaki bütün tümenler.
var birlikler: Array[Birlik] = []
## Savaştaki ülke çiftleri. Anahtar iki ülke id'sinin sıralı birleşimi (bkz. _savas_anahtari),
## değer savaşın ilan edildiği saat (Zaman.toplam_saat) — barış teklifinde süreyi ölçmek için.
var _savaslar: Dictionary[String, int] = {}

# Muharebe sabitleri (data/balance.json -> "savas"); varsayılanlar dosya okunamazsa kullanılır.
var _savunan_avantaji: float = 1.25
var _deniz_cezasi: float = 0.70
var _saatlik_kayip_orani: float = 0.05
var _cekilme_esigi: float = 0.25

# Ekonomi sabitleri (data/balance.json -> "ekonomi").
var _sanayi_gsyh_bolen: float = 5000.0
var _isgal_cezasi_gun: int = 60
var _isgal_cezasi_orani: float = 0.5
## Türü belirtilmeyen (piyade) tümenin maliyeti ve süresi; sınamalar ve eski çağrılar için
## (türlerin asıl değerleri BirlikTurleri'nde).
var _tumen_maliyeti: float = 40.0
var _tumen_suresi_saat: int = 96
var _fabrika_maliyeti: float = 500.0
var _fabrika_suresi_saat: int = 720
var _fabrika_sanayi_artisi: float = 2.0

# Tahkimat sabitleri (data/balance.json -> "tahkimat").
var _tahkimat_azami: int = 3
var _tahkimat_avantaji: float = 0.15
var _tahkimat_taban_maliyet: float = 80.0
var _tahkimat_suresi_saat: int = 240
## Yeni kurulan tümenin başlangıç gücü (OrduKurucu'nun kullandığı değerle aynı; bkz.
## data/balance.json -> "ordu").
var _baslangic_gucu: float = 100.0
## Yapay zekânın, kurabileceği bir tümen yerine fabrika kurmayı seçme olasılığı.
var _yz_fabrika_olasiligi: float = 0.2
## Savaştaki yapay zekâ, bir sınır bölgesindeki gücü karşı bölgedekinin bu katıysa saldırır.
var _yz_saldiri_esigi: float = 1.3
## Savaş ilanını kaç günde bir değerlendireceği (yaklaşık "ayda bir").
var _yz_savas_ilani_gun_araligi: int = 30
## Savaş ilan edebilmesi için hedeften en az bu kat güçlü olması gerekir.
var _yz_savas_ilani_esigi: float = 2.0
## Koşullar sağlansa bile savaş ilan etme olasılığı ("küçük bir olasılıkla").
var _yz_savas_ilani_olasiligi: float = 0.1
var _yz_azami_eszamanli_savas: int = 2
## Oyun başından bu kadar gün geçmeden yapay zekâ oyuncuya savaş ilan etmez.
var _yz_oyuncuya_dokunulmazlik_gun: int = 90
## Barıştaki yapay zekânın tümen türü seçerken kullandığı taban ağırlıklar.
var _yz_tur_agirliklari: Dictionary = {"piyade": 0.45, "zirhli": 0.3, "topcu": 0.25}
## Komşularının en çok kullandığı türe üstün gelen türün ağırlığına eklenen pay.
var _yz_karsi_tur_bonusu: float = 0.6
var _yz_arastirma_olasiligi: float = 0.3
var _yz_tahkimat_olasiligi: float = 0.08
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
## Ülke id'si -> günde bir kez düşündüğü saat (bkz. _ulkenin_dusunme_saati).
var _dusunme_saatleri: Dictionary[String, int] = {}
## Ülke id'si -> {tür: toplam güç}; her oyun günü başında bir kez hesaplanır, yapay zekânın
## tür seçimi için (bkz. _yz_tur_sec).
var _ulke_tur_gucleri: Dictionary[String, Dictionary] = {}
## Ülke id'si -> yapay zekânın kurmaya karar verdiği ama henüz parası yetmeyen tümen türü.
## Para birikene kadar karar değişmez; yoksa ucuz piyade hep önce alınır, pahalı türler
## neredeyse hiç kurulmazdı. Kaydedilmez (yüklenince yeniden seçilir).
var _yz_bekleyen_tur: Dictionary[String, String] = {}

## Ülke id'si -> {dal: seviye} (bkz. Teknoloji). Kaydı olmayan dal 0. seviyededir.
var teknolojiler: Dictionary[String, Dictionary] = {}
## Ülke id'si -> süren araştırma: {"dal": String, "kalan_saat": int, "toplam_saat": int}.
## Her ülkenin aynı anda en fazla bir araştırması olur.
var arastirmalar: Dictionary[String, Dictionary] = {}

## Ülke id'si -> birikmiş üretim. Her oyun günü başında gelir eklenir (bkz. gun_basladi).
var hazineler: Dictionary[String, float] = {}
## Ülke id'si -> o ülkenin inşa kuyruğu (Array[InsaIsi], en fazla AZAMI_KUYRUK_UZUNLUGU).
## Yalnızca kuyruğun önündeki iş ilerler (tek kuyruk).
var insa_kuyruklari: Dictionary[String, Array] = {}
## oyun_kazanildi tekrar tekrar yayılmasın diye.
var _zafer_kazanildi: bool = false
## Açıksa, oyuncunun ülkesi de (barışta kurma, savaşta saldırma, savaş ilanı) aynı yapay
## zekâ tarafından yönetilir.
var yz_oyuncuyu_yonetsin: bool = false


func _init(yeni_dunya: Dunya) -> void:
	dunya = yeni_dunya
	birlikler = OrduKurucu.baslangic_birliklerini_olustur(dunya)

	var ayarlar: Dictionary = VeriOkuyucu.sozluk_oku(DENGE_DOSYASI).get("savas", {})
	_savunan_avantaji = float(ayarlar.get("savunan_avantaji", _savunan_avantaji))
	_deniz_cezasi = float(ayarlar.get("deniz_cezasi", _deniz_cezasi))
	_saatlik_kayip_orani = float(ayarlar.get("saatlik_kayip_orani", _saatlik_kayip_orani))
	_cekilme_esigi = float(ayarlar.get("cekilme_esigi", _cekilme_esigi))

	var ekonomi_ayarlari: Dictionary = VeriOkuyucu.sozluk_oku(DENGE_DOSYASI).get("ekonomi", {})
	_sanayi_gsyh_bolen = float(ekonomi_ayarlari.get("sanayi_gsyh_bolen", _sanayi_gsyh_bolen))
	_isgal_cezasi_gun = int(ekonomi_ayarlari.get("isgal_cezasi_gun", _isgal_cezasi_gun))
	_isgal_cezasi_orani = float(ekonomi_ayarlari.get("isgal_cezasi_orani", _isgal_cezasi_orani))
	_tumen_maliyeti = BirlikTurleri.maliyet(BirlikTurleri.VARSAYILAN)
	_tumen_suresi_saat = BirlikTurleri.sure_saat(BirlikTurleri.VARSAYILAN)
	_fabrika_maliyeti = float(ekonomi_ayarlari.get("fabrika_maliyeti", _fabrika_maliyeti))
	_fabrika_suresi_saat = int(ekonomi_ayarlari.get("fabrika_suresi_saat", _fabrika_suresi_saat))
	_fabrika_sanayi_artisi = float(ekonomi_ayarlari.get("fabrika_sanayi_artisi", _fabrika_sanayi_artisi))

	var tahkimat_ayarlari: Dictionary = VeriOkuyucu.sozluk_oku(DENGE_DOSYASI).get("tahkimat", {})
	_tahkimat_azami = int(tahkimat_ayarlari.get("azami_seviye", _tahkimat_azami))
	_tahkimat_avantaji = float(tahkimat_ayarlari.get("seviye_avantaji", _tahkimat_avantaji))
	_tahkimat_taban_maliyet = float(tahkimat_ayarlari.get("taban_maliyet", _tahkimat_taban_maliyet))
	_tahkimat_suresi_saat = int(tahkimat_ayarlari.get("sure_saat", _tahkimat_suresi_saat))

	var ordu_ayarlari: Dictionary = VeriOkuyucu.sozluk_oku(DENGE_DOSYASI).get("ordu", {})
	_baslangic_gucu = float(ordu_ayarlari.get("baslangic_gucu", _baslangic_gucu))

	var yz_ayarlari: Dictionary = VeriOkuyucu.sozluk_oku(DENGE_DOSYASI).get("yapay_zeka", {})
	_yz_fabrika_olasiligi = float(yz_ayarlari.get("fabrika_olasiligi", _yz_fabrika_olasiligi))
	_yz_saldiri_esigi = float(yz_ayarlari.get("saldiri_esigi", _yz_saldiri_esigi))
	_yz_savas_ilani_gun_araligi = int(yz_ayarlari.get("savas_ilani_gun_araligi", _yz_savas_ilani_gun_araligi))
	_yz_savas_ilani_esigi = float(yz_ayarlari.get("savas_ilani_esigi", _yz_savas_ilani_esigi))
	_yz_savas_ilani_olasiligi = float(yz_ayarlari.get("savas_ilani_olasiligi", _yz_savas_ilani_olasiligi))
	_yz_azami_eszamanli_savas = int(yz_ayarlari.get("azami_eszamanli_savas", _yz_azami_eszamanli_savas))
	_yz_oyuncuya_dokunulmazlik_gun = int(yz_ayarlari.get("oyuncuya_dokunulmazlik_gun", _yz_oyuncuya_dokunulmazlik_gun))
	_yz_tur_agirliklari = yz_ayarlari.get("tur_agirliklari", _yz_tur_agirliklari)
	_yz_karsi_tur_bonusu = float(yz_ayarlari.get("karsi_tur_bonusu", _yz_karsi_tur_bonusu))
	_yz_arastirma_olasiligi = float(yz_ayarlari.get("arastirma_olasiligi", _yz_arastirma_olasiligi))
	_yz_tahkimat_olasiligi = float(yz_ayarlari.get("tahkimat_olasiligi", _yz_tahkimat_olasiligi))
	_ulke_tur_guclerini_hesapla()


## Verilen bölgedeki tümenler.
func bolgedeki_birlikler(bolge_id: String) -> Array[Birlik]:
	var sonuc: Array[Birlik] = []
	for birlik: Birlik in birlikler:
		if birlik.bolge_id == bolge_id:
			sonuc.append(birlik)
	return sonuc


## Verilen tümenleri (hepsi aynı bölgede olmalı) hedef bölgeye yürütür. Süre, YolBulucu'dan
## (kara komşuluğu 24 saat, deniz yolu daha yavaş) gelir. Hedef kendi toprağın değilse,
## yalnızca hedefin sahibiyle savaştaysan kabul edilir. `su_anki_saat`, Zaman.toplam_saat
## değeridir; Oyun'un Zaman autoload'ına bağlı olmadan sınanabilmesi için parametre olarak
## alınır. `tasinacaklar` boşsa ya da yürütme kabul edilmezse false döner.
func birlikleri_yurut(tasinacaklar: Array[Birlik], hedef_bolge_id: String, su_anki_saat: int) -> bool:
	if tasinacaklar.is_empty():
		return false
	var kaynak_bolge_id: String = tasinacaklar[0].bolge_id
	var kaynak_sahibi: Ulke = dunya.bolgenin_sahibi(kaynak_bolge_id)
	var hedef_sahibi: Ulke = dunya.bolgenin_sahibi(hedef_bolge_id)
	if kaynak_sahibi == null or hedef_sahibi == null:
		return false
	if kaynak_sahibi.id != hedef_sahibi.id and not savasta_mi(kaynak_sahibi.id, hedef_sahibi.id):
		return false
	var yol: Array[String] = dunya.yol_bulucu.en_kisa_yol(kaynak_bolge_id, hedef_bolge_id)
	if yol.size() < 2:
		return false
	var sure: float = dunya.yol_bulucu.en_kisa_sure(kaynak_bolge_id, hedef_bolge_id)
	if sure < 0.0:
		return false
	# Yığın en yavaş türünün hızıyla yürür; Lojistik teknolojisi süreyi kısaltır.
	var carpan: float = 0.0
	for birlik: Birlik in tasinacaklar:
		carpan = maxf(carpan, BirlikTurleri.hareket_carpani(birlik.tur))
	sure *= carpan / Teknoloji.hiz_carpani(teknoloji_seviyesi(kaynak_sahibi.id, "lojistik"))
	# Son adım deniz yoluysa, muharebede saldırgan deniz cezası alır (bkz. _muharebeyi_coz).
	var onceki_bolge_id: String = yol[yol.size() - 2]
	var denizden: bool = dunya.bolgeler[onceki_bolge_id].deniz_gecisleri.has(hedef_bolge_id)

	var varis: int = su_anki_saat + maxi(1, roundi(sure))
	for birlik: Birlik in tasinacaklar:
		birlik.hedef_bolge_id = hedef_bolge_id
		birlik.varis_saati = varis
		birlik.son_adim_deniz_mi = denizden
	birlikler_degisti.emit()
	return true


## Verilen tümenleri yarıya ayırır ve ayrılan yarıyı döndürür; kalan yarı `stok`ta, aynı
## bölgede kalır. Tek tümen varsa gücü ikiye bölünüp yeni bir tümen oluşturulur (güç 2'den
## azsa bölünemeyecek kadar küçüktür, boş dizi döner). Birden çok tümen varsa sayıca yarısı
## ayrılır (3 tümende 1'i ayrılır, 2'si kalır).
func yariya_ayir(stok: Array[Birlik]) -> Array[Birlik]:
	if stok.is_empty():
		return []
	if stok.size() == 1:
		var tek: Birlik = stok[0]
		if tek.guc < 2.0:
			return []
		var yeni: Birlik = Birlik.new()
		yeni.sahip = tek.sahip
		yeni.tur = tek.tur
		yeni.bolge_id = tek.bolge_id
		yeni.guc = tek.guc / 2.0
		tek.guc -= yeni.guc
		birlikler.append(yeni)
		birlikler_degisti.emit()
		return [yeni]
	return stok.slice(0, stok.size() / 2)


## Zaman ilerledikçe çağrılır; varış saatine ulaşan tümenleri hedeflerine taşır. Boş bir
## düşman bölgesine varan tümen orayı ele geçirir. Ardından bütün muharebeler bir saat ilerler.
func saat_ilerledi(su_anki_saat: int) -> void:
	var tasima_oldu: bool = false
	for birlik: Birlik in birlikler:
		# yuruyor_mu() yerine alan doğrudan okunur: bu döngü her saat bütün tümenleri gezer.
		if birlik.hedef_bolge_id != "" and su_anki_saat >= birlik.varis_saati:
			birlik.bolge_id = birlik.hedef_bolge_id
			birlik.hedef_bolge_id = ""
			birlik.varis_saati = -1
			tasima_oldu = true
			_bos_dusman_bolgesini_isgal_et(birlik, su_anki_saat)
	if tasima_oldu:
		birlikler_degisti.emit()
	_muharebeleri_isle(su_anki_saat)
	_insa_islerini_isle()
	_arastirmalari_isle()
	_yapay_zekayi_isle(su_anki_saat)


## Gelen tümen, savaşta olduğu ve içinde savunan (bölgenin o anki sahibine ait) tümen
## kalmamış bir düşman bölgesine girdiyse orayı ele geçirir. Savunan varsa (muharebe
## sürüyorsa) işgal gerçekleşmez.
func _bos_dusman_bolgesini_isgal_et(gelen: Birlik, su_anki_saat: int) -> void:
	var bolge: Bolge = dunya.bolgeler.get(gelen.bolge_id)
	if bolge == null or bolge.sahip == gelen.sahip or not savasta_mi(bolge.sahip, gelen.sahip):
		return
	for digeri: Birlik in bolgedeki_birlikler(gelen.bolge_id):
		if digeri.sahip == bolge.sahip:
			return
	_bolgeyi_devret(bolge, gelen.sahip, su_anki_saat)


## Birden çok ülkenin tümeni bulunan (dolayısıyla savaşan) her bölgede muharebeyi bir saat
## ilerletir.
##
## Bu işlev her oyun saatinde çalışır ve dünyadaki bütün tümenlere bakar; o yüzden önce
## yalnızca hangi bölgelerde birden çok ülkenin tümeni olduğu (çekişmeli bölgeler) bulunur,
## tümen listeleri yalnızca o bölgeler için kurulur. Bölgeler, ilk tümenlerinin listede
## göründüğü sırayla işlenir.
func _muharebeleri_isle(su_anki_saat: int) -> void:
	var ilk_sahip: Dictionary[String, String] = {}
	var cekismeli: Dictionary[String, bool] = {}
	for birlik: Birlik in birlikler:
		if birlik.hedef_bolge_id != "":
			continue  # Yürüyor.
		var sahip: String = ilk_sahip.get(birlik.bolge_id, "")
		if sahip == "":
			ilk_sahip[birlik.bolge_id] = birlik.sahip
		elif sahip != birlik.sahip:
			cekismeli[birlik.bolge_id] = true
	if cekismeli.is_empty():
		return

	var bolge_gruplari: Dictionary[String, Array] = {}
	for birlik: Birlik in birlikler:
		if birlik.hedef_bolge_id != "" or not cekismeli.has(birlik.bolge_id):
			continue
		if not bolge_gruplari.has(birlik.bolge_id):
			bolge_gruplari[birlik.bolge_id] = [] as Array[Birlik]
		(bolge_gruplari[birlik.bolge_id] as Array[Birlik]).append(birlik)

	for bolge_id: String in bolge_gruplari:
		_muharebeyi_coz(dunya.bolgeler[bolge_id], bolge_gruplari[bolge_id], su_anki_saat)


## Bir bölgedeki muharebeyi bir saat ilerletir: her iki taraf, karşı tarafın verdiği hasarla
## orantılı kayıp alır (bkz. _verilen_hasar: tür, üstünlük üçgeni, teknoloji, savunan
## avantajı, tahkimat ve deniz cezası orada hesaplanır). Aynı bölgedeki karışık yığın tek bir
## muharebedir. Güç ASGARI_GUC altına düşen tümen yok sayılır. Bir taraf tükenirse ya da belirgin biçimde geride kalırsa (CEKILME_ESIGI)
## geri çekilir: en yakın dost komşu bölgeye taşınır, yoksa yok olur. Savunan tükenir ya da
## çekilirse (ikisinde de bölgede artık savunan kalmaz) bölge hemen saldırganın olur.
func _muharebeyi_coz(bolge: Bolge, katilanlar: Array[Birlik], su_anki_saat: int) -> void:
	var savunanlar: Array[Birlik] = []
	var saldiranlar: Array[Birlik] = []
	for birlik: Birlik in katilanlar:
		if birlik.sahip == bolge.sahip:
			savunanlar.append(birlik)
		else:
			saldiranlar.append(birlik)
	if savunanlar.is_empty() or saldiranlar.is_empty():
		return

	var savunanin_hasari: float = _verilen_hasar(savunanlar, saldiranlar, false, bolge)
	var saldiranin_hasari: float = _verilen_hasar(saldiranlar, savunanlar, true, bolge)
	_hasar_uygula(savunanlar, saldiranin_hasari * _saatlik_kayip_orani)
	_hasar_uygula(saldiranlar, savunanin_hasari * _saatlik_kayip_orani)
	_olenleri_temizle(savunanlar)
	_olenleri_temizle(saldiranlar)
	birlikler_degisti.emit()

	if saldiranlar.is_empty():
		return  # Saldırgan tükendi; savunan (varsa) bölgede kalır.
	if savunanlar.is_empty():
		_bolgeyi_devret(bolge, saldiranlar[0].sahip, su_anki_saat)
		return

	# Taraflardan biri belirgin şekilde geride kaldıysa geri çekilir. Savunan çekilirse
	# bölgeyi fiilen terk etmiş olur; bölge hemen saldırganın olur (boş bölge gibi).
	var yeni_savunan_guc: float = _toplam_guc(savunanlar)
	var yeni_saldiran_guc: float = _toplam_guc(saldiranlar)
	if yeni_savunan_guc < _cekilme_esigi * yeni_saldiran_guc:
		_geri_cek(savunanlar, bolge.id)
		_bolgeyi_devret(bolge, saldiranlar[0].sahip, su_anki_saat)
	elif yeni_saldiran_guc < _cekilme_esigi * yeni_savunan_guc:
		_geri_cek(saldiranlar, bolge.id)


## Bir tarafın karşı tarafa bir saatte verdiği hasar (kayıp oranı uygulanmadan önce).
##
## Her tümen gücü × türünün saldırı (saldırıyorsa) ya da savunma (savunuyorsa) çarpanı kadar
## hasar verir. Üstünlük üçgeni: karşı tarafta, bu tümenin üstün geldiği türün güç payı
## kadar `ustunluk_bonusu` (%50) eklenir; karşı taraf tamamen o türdense hasar 1,5 katıdır.
## Silah teknolojisi hasarı artırır; denizden gelen saldırgan deniz cezası alır (Lojistik
## bunu hafifletir). Savunan taraf ayrıca savunan avantajı ve bölgenin tahkimatı kadar güçlüdür.
func _verilen_hasar(verenler: Array[Birlik], alanlar: Array[Birlik], saldiriyor: bool, bolge: Bolge) -> float:
	var alan_toplam: float = _toplam_guc(alanlar)
	var paylar: Dictionary[String, float] = {}
	if alan_toplam > 0.0:
		for birlik: Birlik in alanlar:
			paylar[birlik.tur] = paylar.get(birlik.tur, 0.0) + birlik.guc / alan_toplam
	var bonus: float = BirlikTurleri.ustunluk_bonusu()

	var toplam: float = 0.0
	for birlik: Birlik in verenler:
		var carpan: float = BirlikTurleri.saldiri(birlik.tur) if saldiriyor else BirlikTurleri.savunma(birlik.tur)
		carpan *= 1.0 + bonus * paylar.get(BirlikTurleri.yener(birlik.tur), 0.0)
		carpan *= Teknoloji.saldiri_carpani(teknoloji_seviyesi(birlik.sahip, "silah"))
		if saldiriyor and birlik.son_adim_deniz_mi:
			carpan *= minf(1.0, _deniz_cezasi + Teknoloji.deniz_cezasi_azalisi(teknoloji_seviyesi(birlik.sahip, "lojistik")))
		toplam += birlik.guc * carpan
	if not saldiriyor:
		toplam *= _savunan_avantaji * tahkimat_carpani(bolge)
	return toplam


## Bölgede savunanın tahkimattan aldığı çarpan (seviye başına +%15).
func tahkimat_carpani(bolge: Bolge) -> float:
	return 1.0 + _tahkimat_avantaji * bolge.tahkimat


## Muharebe hasarını tümenlere güçleriyle orantılı dağıtır; her tümenin payı, sahibinin
## Savunma teknolojisi çarpanına bölünür (Savunma araştırmış ülke daha az kayıp verir).
func _hasar_uygula(liste: Array[Birlik], toplam_kayip: float) -> void:
	var toplam_guc: float = _toplam_guc(liste)
	if toplam_guc <= 0.0:
		return
	var oran: float = toplam_kayip / toplam_guc
	for birlik: Birlik in liste:
		var kayip: float = birlik.guc * oran / Teknoloji.savunma_carpani(teknoloji_seviyesi(birlik.sahip, "savunma"))
		birlik.guc -= minf(birlik.guc, kayip)


## Bir bölgenin sahibini değiştirir, tahkimatını bir seviye düşürür, ele geçirilme saatini
## (ekonomide işgal cezası için) kaydeder, haritanın güncellenmesi için sinyal yayar ve eski sahibinin teslim olup
## olmadığını denetler.
func _bolgeyi_devret(bolge: Bolge, yeni_sahip: String, su_anki_saat: int) -> void:
	var eski_sahip: String = bolge.sahip
	if eski_sahip != yeni_sahip:
		bolge.tahkimat = maxi(0, bolge.tahkimat - 1)
	bolge.sahip = yeni_sahip
	bolge.isgal_saati = su_anki_saat
	bolge_sahipligi_degisti.emit()
	if oyuncu_ulkesi != "" and eski_sahip != yeni_sahip:
		if yeni_sahip == oyuncu_ulkesi:
			bildirim_gonder.emit("%s bölgesini ele geçirdin." % bolge.ad, bolge.id)
		elif eski_sahip == oyuncu_ulkesi:
			bildirim_gonder.emit("%s bölgesini kaybettin." % bolge.ad, bolge.id)
	_teslimi_kontrol_et(eski_sahip, su_anki_saat)
	_zaferi_kontrol_et()


## Başkenti düşmüş ve oyun başındaki bölgelerinin yarısından fazlasını kaybetmiş bir ülke
## teslim olur: kalan bölgeleri başkentini alan ülkeye geçer, bütün tümenleri silinir.
func _teslimi_kontrol_et(ulke_id: String, su_anki_saat: int) -> void:
	var ulke: Ulke = dunya.ulkeler.get(ulke_id)
	if ulke == null:
		return
	var su_anki_bolgeler: Array[Bolge] = dunya.ulkenin_bolgeleri(ulke_id)
	if su_anki_bolgeler.is_empty():
		return
	var baskent_sahibi: Ulke = dunya.bolgenin_sahibi(ulke.baskent_bolgesi)
	if baskent_sahibi == null or baskent_sahibi.id == ulke_id:
		return
	@warning_ignore("integer_division")
	if su_anki_bolgeler.size() > ulke.baslangic_bolgeleri.size() / 2:
		return

	var galip_id: String = baskent_sahibi.id
	for bolge: Bolge in su_anki_bolgeler:
		bolge.sahip = galip_id
		bolge.isgal_saati = su_anki_saat
		bolge.tahkimat = maxi(0, bolge.tahkimat - 1)
	var kalanlar: Array[Birlik] = []
	for birlik: Birlik in birlikler:
		if birlik.sahip != ulke_id:
			kalanlar.append(birlik)
	birlikler = kalanlar

	bolge_sahipligi_degisti.emit()
	birlikler_degisti.emit()
	ulke_teslim_oldu.emit(ulke_id, galip_id)
	if ulke_id == oyuncu_ulkesi:
		oyun_kaybedildi.emit()
	_zaferi_kontrol_et()


## Oyuncunun kıtasındaki bölgelerin ZAFER_ORANI (×0,6) kadarı kendisinin olunca bir kez
## oyun_kazanildi yayar. Bir bölgenin kıtası, "ev sahibi" ülkesinin (bkz. _bolge_ev_sahibi)
## kıtasıdır; kimin elinde olduğundan bağımsızdır.
func _zaferi_kontrol_et() -> void:
	if oyuncu_ulkesi == "" or _zafer_kazanildi:
		return
	var oyuncu: Ulke = dunya.ulkeler.get(oyuncu_ulkesi)
	if oyuncu == null:
		return
	var toplam: int = 0
	var sahip_olunan: int = 0
	for bolge: Bolge in dunya.bolge_listesi:
		var ev_ulke: Ulke = _bolge_ev_sahibi(bolge)
		if ev_ulke == null or ev_ulke.kita != oyuncu.kita:
			continue
		toplam += 1
		if bolge.sahip == oyuncu_ulkesi:
			sahip_olunan += 1
	if toplam > 0 and float(sahip_olunan) / float(toplam) >= ZAFER_ORANI:
		_zafer_kazanildi = true
		oyun_kazanildi.emit()


func _toplam_guc(liste: Array[Birlik]) -> float:
	var toplam: float = 0.0
	for birlik: Birlik in liste:
		toplam += birlik.guc
	return toplam


## Verilen toplam kaybı listedeki tümenlere, güçleriyle orantılı dağıtır.
func _guc_azalt(liste: Array[Birlik], toplam_kayip: float) -> void:
	var toplam_guc: float = _toplam_guc(liste)
	if toplam_guc <= 0.0:
		return
	var oran: float = minf(1.0, toplam_kayip / toplam_guc)
	for birlik: Birlik in liste:
		birlik.guc -= birlik.guc * oran


## Güç altına düşen tümenleri hem verilen listeden hem de Oyun.birlikler'den siler.
func _olenleri_temizle(liste: Array[Birlik]) -> void:
	var i: int = liste.size() - 1
	while i >= 0:
		if liste[i].guc < ASGARI_GUC:
			birlikler.erase(liste[i])
			liste.remove_at(i)
		i -= 1


## Listedeki her tümeni kendi ülkesine ait en yakın (ilk bulunan) komşu bölgeye çeker;
## öyle bir komşu yoksa tümen yok olur.
func _geri_cek(liste: Array[Birlik], bolge_id: String) -> void:
	for birlik: Birlik in liste.duplicate():
		var hedef: Bolge = null
		for komsu: Bolge in dunya.bolgenin_komsulari(bolge_id):
			if komsu.sahip == birlik.sahip:
				hedef = komsu
				break
		if hedef != null:
			birlik.bolge_id = hedef.id
		else:
			birlikler.erase(birlik)


## İki ülke savaşta mı?
func savasta_mi(ulke_a: String, ulke_b: String) -> bool:
	return _savaslar.has(_savas_anahtari(ulke_a, ulke_b))


## Savaş ilan eder. Yalnızca doğrudan (kara ya da deniz yoluyla) komşu, henüz savaşılmayan,
## var olan iki farklı ülke arasında kabul edilir. `su_anki_saat`, barış teklifinde savaşın
## ne kadar sürdüğünü ölçmek için saklanır. Kabul edilirse true döner.
func savas_ilan_et(ilan_eden: String, hedef: String, su_anki_saat: int) -> bool:
	if ilan_eden == hedef or not dunya.ulkeler.has(ilan_eden) or not dunya.ulkeler.has(hedef):
		return false
	if savasta_mi(ilan_eden, hedef) or not dunya.ulkeler_komsu_mu(ilan_eden, hedef):
		return false
	_savaslar[_savas_anahtari(ilan_eden, hedef)] = su_anki_saat
	savas_ilan_edildi.emit(ilan_eden, hedef)
	if hedef == oyuncu_ulkesi and ilan_eden != oyuncu_ulkesi:
		var ilan_eden_ulke: Ulke = dunya.ulkeler[ilan_eden]
		bildirim_gonder.emit("%s sana savaş ilan etti." % ilan_eden_ulke.ad, ilan_eden_ulke.baskent_bolgesi)
	return true


## Barış teklif eder. Hedef, kendisi kaybediyorsa (toplam askeri gücü teklif edenden azsa)
## ya da savaş BARIS_ESIGI_SAAT'ten (180 gün) uzun sürdüyse kabul eder: ikisi de savaştan
## çıkar, herkes elindekini tutar. Savaşta değillerse ya da teklif reddedilirse false döner.
func baris_teklif_et(teklif_eden: String, hedef: String, su_anki_saat: int) -> bool:
	var anahtar: String = _savas_anahtari(teklif_eden, hedef)
	if not _savaslar.has(anahtar):
		return false
	var uzun_surdu: bool = su_anki_saat - _savaslar[anahtar] >= BARIS_ESIGI_SAAT
	if not uzun_surdu and _ulkenin_toplam_gucu(hedef) >= _ulkenin_toplam_gucu(teklif_eden):
		return false
	_savaslar.erase(anahtar)
	baris_yapildi.emit(teklif_eden, hedef)
	return true


func _ulkenin_toplam_gucu(ulke_id: String) -> float:
	var toplam: float = 0.0
	for birlik: Birlik in birlikler:
		if birlik.sahip == ulke_id:
			toplam += birlik.guc
	return toplam


## Hâlâ var olan (en az bir bölgesi kalan) her ülkeyi toplam askeri gücüne göre büyükten
## küçüğe sıralar. Her öge `{"ulke_id": String, "guc": float}`. Arayüzdeki güç sıralaması
## paneli için.
func guc_siralamasi() -> Array[Dictionary]:
	var sonuc: Array[Dictionary] = []
	for ulke: Ulke in dunya.ulke_listesi:
		if dunya.ulkenin_bolgeleri(ulke.id).is_empty():
			continue
		sonuc.append({"ulke_id": ulke.id, "guc": _ulkenin_toplam_gucu(ulke.id)})
	sonuc.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["guc"] > b["guc"])
	return sonuc


func _savas_anahtari(ulke_a: String, ulke_b: String) -> String:
	return "%s|%s" % [ulke_a, ulke_b] if ulke_a < ulke_b else "%s|%s" % [ulke_b, ulke_a]


## Her oyun günü başında (Zaman.gun_basladi) çağrılır: her ülkenin o günkü geliri
## hazinesine eklenir, ardından tümen bakımı düşülür. `su_anki_saat`, gün başındaki
## Zaman.toplam_saat değeridir.
func gun_basladi(su_anki_saat: int) -> void:
	for ulke: Ulke in dunya.ulke_listesi:
		var gelir: float = ulkenin_geliri(ulke.id, su_anki_saat)
		hazineler[ulke.id] = hazineler.get(ulke.id, 0.0) + gelir
	_bakimi_uygula()
	_ulke_tur_guclerini_hesapla()
	hazine_degisti.emit()
	birlikler_degisti.emit()


## Her ülkenin tümenlerinin günlük bakım masrafını (türe göre; zırhlının bakımı yüksektir)
## hazinesinden düşer. Hazine yetmezse
## (eksiye düşerse) açık, o ülkenin bütün tümenlerine güçleriyle orantılı kayıp olarak
## yansıtılır (bkz. _guc_azalt) ve hazine 0'da kalır.
func _bakimi_uygula() -> void:
	var ulke_birlikleri: Dictionary[String, Array] = {}
	for birlik: Birlik in birlikler:
		if not ulke_birlikleri.has(birlik.sahip):
			ulke_birlikleri[birlik.sahip] = [] as Array[Birlik]
		(ulke_birlikleri[birlik.sahip] as Array[Birlik]).append(birlik)

	for ulke_id: String in ulke_birlikleri:
		var liste: Array[Birlik] = ulke_birlikleri[ulke_id]
		var bakim: float = 0.0
		for birlik: Birlik in liste:
			bakim += BirlikTurleri.bakim(birlik.tur)
		var mevcut: float = hazineler.get(ulke_id, 0.0)
		if mevcut >= bakim:
			hazineler[ulke_id] = mevcut - bakim
			continue
		hazineler[ulke_id] = 0.0
		_guc_azalt(liste, bakim - mevcut)
		_olenleri_temizle(liste)


## Verilen ülkenin, verilen (kendi) bölgesinde verilen türde yeni bir tümen sıralar. Kuyruk
## doluysa, bölge o ülkeye ait değilse, tür bilinmiyorsa ya da hazine yetmezse false döner
## (maliyet hemen kesilir).
func tumen_sirala(ulke_id: String, bolge_id: String, tur: String = BirlikTurleri.VARSAYILAN) -> bool:
	if not BirlikTurleri.gecerli_mi(tur):
		return false
	return _ise_sirala(ulke_id, bolge_id, InsaIsi.Tur.TUMEN, BirlikTurleri.maliyet(tur),
			BirlikTurleri.sure_saat(tur), tur)


## Verilen ülkenin, verilen (kendi) bölgesinde tahkimatı bir seviye yükseltecek işi sıralar.
## Bölge (kuyrukta bekleyen tahkimat işleri de sayılarak) en yüksek seviyedeyse false döner.
func tahkimat_sirala(ulke_id: String, bolge_id: String) -> bool:
	var seviye: int = sonraki_tahkimat_seviyesi(ulke_id, bolge_id)
	if seviye < 1:
		return false
	return _ise_sirala(ulke_id, bolge_id, InsaIsi.Tur.TAHKIMAT, tahkimat_maliyeti(seviye), _tahkimat_suresi_saat)


## Bölgenin, bu ülkenin kuyruğundaki tahkimat işleri de bittiğinde ulaşacağı seviyenin bir
## fazlası; en yüksek seviyeye zaten ulaşılacaksa (ya da bölge yoksa) 0.
func sonraki_tahkimat_seviyesi(ulke_id: String, bolge_id: String) -> int:
	var bolge: Bolge = dunya.bolgeler.get(bolge_id)
	if bolge == null:
		return 0
	var seviye: int = bolge.tahkimat + 1
	for is_: InsaIsi in (insa_kuyruklari.get(ulke_id, []) as Array):
		if is_.tur == InsaIsi.Tur.TAHKIMAT and is_.bolge_id == bolge_id:
			seviye += 1
	return seviye if seviye <= _tahkimat_azami else 0


## `seviye`ye yükseltmenin maliyeti (seviye arttıkça pahalılaşır).
func tahkimat_maliyeti(seviye: int) -> float:
	return _tahkimat_taban_maliyet * seviye


func tahkimat_azami_seviye() -> int:
	return _tahkimat_azami


## Verilen ülkenin, verilen (kendi) bölgesinde fabrika sıralar; tamamlanınca bölgenin
## sanayisini kalıcı olarak artırır.
func fabrika_sirala(ulke_id: String, bolge_id: String) -> bool:
	return _ise_sirala(ulke_id, bolge_id, InsaIsi.Tur.FABRIKA, _fabrika_maliyeti, _fabrika_suresi_saat)


## Verilen ülkenin kuyruğunun önündeki (o an yürümekte olan) iş; kuyruk boşsa null.
## Üst çubuktaki üretim göstergesi için (bkz. Arayuz.uretimi_goster).
func onde_ki_is(ulke_id: String) -> InsaIsi:
	var kuyruk: Array = insa_kuyruklari.get(ulke_id, [])
	return kuyruk[0] if not kuyruk.is_empty() else null


## Bir tümen işinin maliyeti (bkz. BirlikTurleri); arayüzdeki düğme yazısı için.
func tumen_maliyeti(tur: String = BirlikTurleri.VARSAYILAN) -> float:
	return BirlikTurleri.maliyet(tur)


## Bir fabrika işinin maliyeti; arayüzdeki düğme yazısı için.
func fabrika_maliyeti() -> float:
	return _fabrika_maliyeti


## Verilen ülkenin kuyruğunda bekleyen iş sayısı (öndeki dahil).
func kuyruktaki_is_sayisi(ulke_id: String) -> int:
	return (insa_kuyruklari.get(ulke_id, []) as Array).size()


func _ise_sirala(ulke_id: String, bolge_id: String, tur: InsaIsi.Tur, maliyet: float, sure_saat: int,
		birlik_turu: String = BirlikTurleri.VARSAYILAN) -> bool:
	var bolge: Bolge = dunya.bolgeler.get(bolge_id)
	if bolge == null or bolge.sahip != ulke_id:
		return false
	var kuyruk: Array = insa_kuyruklari.get(ulke_id, [])
	if kuyruk.size() >= AZAMI_KUYRUK_UZUNLUGU or hazineler.get(ulke_id, 0.0) < maliyet:
		return false

	hazineler[ulke_id] = hazineler.get(ulke_id, 0.0) - maliyet
	var yeni_is: InsaIsi = InsaIsi.new()
	yeni_is.tur = tur
	yeni_is.sahip = ulke_id
	yeni_is.bolge_id = bolge_id
	yeni_is.kalan_saat = sure_saat
	yeni_is.birlik_turu = birlik_turu
	kuyruk.append(yeni_is)
	insa_kuyruklari[ulke_id] = kuyruk

	hazine_degisti.emit()
	insa_kuyrugu_degisti.emit(ulke_id)
	return true


## Her ülkenin kuyruğunun önündeki işi bir saat ilerletir; süresi dolan iş tamamlanır ve
## kuyruktan çıkar (tek kuyruk: arkadaki işler önceki bitmeden ilerlemez).
func _insa_islerini_isle() -> void:
	for ulke_id: String in insa_kuyruklari.keys():
		var kuyruk: Array = insa_kuyruklari[ulke_id]
		if kuyruk.is_empty():
			continue
		var on: InsaIsi = kuyruk[0]
		on.kalan_saat -= 1
		if on.kalan_saat > 0:
			continue
		kuyruk.pop_front()
		_insayi_tamamla(on)
		insa_kuyrugu_degisti.emit(ulke_id)


func _insayi_tamamla(is_: InsaIsi) -> void:
	var bolge: Bolge = dunya.bolgeler.get(is_.bolge_id)
	var ne: String = "Fabrika"
	match is_.tur:
		InsaIsi.Tur.TUMEN:
			var yeni: Birlik = Birlik.new()
			yeni.sahip = is_.sahip
			yeni.tur = is_.birlik_turu
			yeni.bolge_id = is_.bolge_id
			yeni.guc = _baslangic_gucu
			birlikler.append(yeni)
			birlikler_degisti.emit()
			ne = "%s tümen" % BirlikTurleri.ad(is_.birlik_turu)
		InsaIsi.Tur.TAHKIMAT:
			# Bölge bu arada el değiştirdiyse iş boşa gider.
			if bolge != null and bolge.sahip == is_.sahip:
				bolge.tahkimat = mini(_tahkimat_azami, bolge.tahkimat + 1)
				tahkimat_degisti.emit(bolge.id)
			ne = "Tahkimat"
		_:
			if bolge != null:
				bolge.fabrika_sanayisi += _fabrika_sanayi_artisi
	if is_.sahip == oyuncu_ulkesi and bolge != null:
		bildirim_gonder.emit("%s tamamlandı: %s." % [ne, bolge.ad], is_.bolge_id)


# --- Teknoloji ---------------------------------------------------------------

## Ülkenin bir teknoloji dalındaki seviyesi (0-3).
func teknoloji_seviyesi(ulke_id: String, dal: String) -> int:
	var seviyeler: Variant = teknolojiler.get(ulke_id)
	if seviyeler == null:
		return 0
	return int((seviyeler as Dictionary).get(dal, 0))


## Ülkenin süren araştırması; yoksa boş sözlük. {"dal", "kalan_saat", "toplam_saat"}
func suren_arastirma(ulke_id: String) -> Dictionary:
	return arastirmalar.get(ulke_id, {})


## Ülke, verilen dalda bir sonraki seviyenin araştırmasına başlar; maliyet hazineden peşin
## düşülür. Zaten bir araştırma sürüyorsa, dal en yüksek seviyedeyse ya da hazine yetmezse
## false döner.
func arastirma_baslat(ulke_id: String, dal: String) -> bool:
	if not Teknoloji.DALLAR.has(dal) or not dunya.ulkeler.has(ulke_id) or arastirmalar.has(ulke_id):
		return false
	var seviye: int = teknoloji_seviyesi(ulke_id, dal) + 1
	if seviye > Teknoloji.azami_seviye():
		return false
	var maliyet: float = Teknoloji.maliyet(seviye)
	if hazineler.get(ulke_id, 0.0) < maliyet:
		return false
	hazineler[ulke_id] = hazineler.get(ulke_id, 0.0) - maliyet
	var sure: int = Teknoloji.sure_saat(seviye)
	arastirmalar[ulke_id] = {"dal": dal, "kalan_saat": sure, "toplam_saat": sure}
	hazine_degisti.emit()
	teknoloji_degisti.emit(ulke_id)
	return true


## Her saat, süren araştırmaları bir saat ilerletir; biten araştırma dalın seviyesini artırır.
func _arastirmalari_isle() -> void:
	if arastirmalar.is_empty():
		return
	for ulke_id: String in arastirmalar.keys():
		var arastirma: Dictionary = arastirmalar[ulke_id]
		arastirma["kalan_saat"] = int(arastirma["kalan_saat"]) - 1
		if int(arastirma["kalan_saat"]) > 0:
			continue
		arastirmalar.erase(ulke_id)
		var dal: String = arastirma["dal"]
		var seviyeler: Dictionary = teknolojiler.get(ulke_id, {})
		seviyeler[dal] = int(seviyeler.get(dal, 0)) + 1
		teknolojiler[ulke_id] = seviyeler
		teknoloji_degisti.emit(ulke_id)
		if ulke_id == oyuncu_ulkesi:
			bildirim_gonder.emit("Araştırma tamamlandı: %s %d (%s)." % [
				Teknoloji.ad(dal), seviyeler[dal], Teknoloji.seviye_aciklamasi(dal, seviyeler[dal])],
				dunya.ulkeler[ulke_id].baskent_bolgesi)


## Bir ülkenin günlük geliri: o an sahip olduğu bölgelerin sanayilerinin toplamı, Sanayi
## teknolojisinin çarpanıyla.
func ulkenin_geliri(ulke_id: String, su_anki_saat: int) -> float:
	var toplam: float = 0.0
	for bolge: Bolge in dunya.ulkenin_bolgeleri(ulke_id):
		toplam += bolge_sanayisi(bolge, su_anki_saat)
	return toplam * Teknoloji.gelir_carpani(teknoloji_seviyesi(ulke_id, "sanayi"))


## Bir bölgenin günlük ürettiği sanayi. Taban değer, bölgenin "ev sahibi" ülkesinin (bölge
## id'sinin öneki, ör. "TUR_1" -> "TUR") GSYH'sinden ve o ülke içindeki nüfus payından türer;
## buna bölgedeki fabrikaların kattığı sanayi eklenir. Kimin elinde olduğundan bağımsızdır
## (toprağın kendi ekonomik niteliğini yansıtır). Son `isgal_cezasi_gun` gün içinde ele
## geçirilmiş ve hâlâ ev sahibinde olmayan bölge toplamın `isgal_cezasi_orani` kadarını üretir.
func bolge_sanayisi(bolge: Bolge, su_anki_saat: int) -> float:
	var ev_ulke: Ulke = _bolge_ev_sahibi(bolge)
	var taban: float = 0.0
	if ev_ulke != null and ev_ulke.nufus > 0:
		var ulke_sanayisi: float = sqrt(float(ev_ulke.gsyh_milyon_dolar) / _sanayi_gsyh_bolen)
		taban = ulke_sanayisi * (float(bolge.nufus) / float(ev_ulke.nufus))
	var sanayi: float = taban + bolge.fabrika_sanayisi
	if bolge_isgal_altinda_mi(bolge, su_anki_saat):
		sanayi *= _isgal_cezasi_orani
	return sanayi


## Bölge, son isgal_cezasi_gun (60) gün içinde ele geçirilmiş ve hâlâ ev sahibine
## dönmemiş mi (bkz. bolge_sanayisi'ndeki üretim cezası, harita_gorunumu.gd'deki turuncu
## çerçeve).
func bolge_isgal_altinda_mi(bolge: Bolge, su_anki_saat: int) -> bool:
	var ev_ulke: Ulke = _bolge_ev_sahibi(bolge)
	return ev_ulke != null and bolge.isgal_saati >= 0 and bolge.sahip != ev_ulke.id \
			and su_anki_saat - bolge.isgal_saati < _isgal_cezasi_gun * 24


func _bolge_ev_sahibi(bolge: Bolge) -> Ulke:
	return dunya.ulkeler.get(bolge.id.split("_")[0])


## Her saat çağrılır; o saat "düşünme sırası" gelen (elenmemiş) her ülke bir karar verir.
## Ülkeler saatlere yayılmıştır (bkz. _ulkenin_dusunme_saati) ki hepsi aynı karede
## düşünmeye çalışıp yığılma yapmasın; her ülke günde tam bir kez düşünür. Oyuncunun ülkesi,
## "ordumu yapay zekâ yönetsin" (yz_oyuncuyu_yonetsin) açık değilse atlanır.
func _yapay_zekayi_isle(su_anki_saat: int) -> void:
	var saat_dilimi: int = su_anki_saat % 24
	# Tümenlerin bölgelere göre dizini, bu saat savaştaki bir ülke düşündüğünde bir kez
	# kurulur ve o saatin bütün kararlarında kullanılır (bkz. _ulke_dusun).
	var onbellek: Dictionary = {}
	for ulke: Ulke in dunya.ulke_listesi:
		if ulke.id == oyuncu_ulkesi and not yz_oyuncuyu_yonetsin:
			continue
		if _ulkenin_dusunme_saati(ulke.id) != saat_dilimi:
			continue
		if dunya.ulkenin_bolgeleri(ulke.id).is_empty():
			continue  # Teslim olmuş; artık yok.
		_ulke_dusun(ulke.id, su_anki_saat, onbellek)


## Ülkenin günde bir kez düşündüğü saat (0-23); ülke id'sinden türer, hep aynıdır.
## Her saat 176 ülke için yeniden hesaplanmasın diye önbellekte tutulur.
func _ulkenin_dusunme_saati(ulke_id: String) -> int:
	if not _dusunme_saatleri.has(ulke_id):
		_dusunme_saatleri[ulke_id] = absi(ulke_id.hash()) % 24
	return _dusunme_saatleri[ulke_id]


## Bölge id'si -> o bölgedeki tümenler (yürüyenler dahil; bolgedeki_birlikler() ile aynı).
## Her saat çalışabildiği için tipsiz dizilerle, tek geçişte kurulur (daha hızlı).
func _bolgelere_gore_birlikler() -> Dictionary[String, Array]:
	var dizin: Dictionary[String, Array] = {}
	for birlik: Birlik in birlikler:
		var liste: Variant = dizin.get(birlik.bolge_id)
		if liste == null:
			dizin[birlik.bolge_id] = [birlik]
		else:
			(liste as Array).append(birlik)
	return dizin


## Bir ülkenin günlük kararı: önce (savaşta olsun olmasın) savaş ilanını değerlendirir,
## sonra savaştaysa saldırır, barıştaysa tümen/fabrika kurar.
## `onbellek`, aynı saat içinde düşünen ülkelerin paylaştığı bir sözlüktür; tümen dizini
## (bkz. _bolgelere_gore_birlikler) yalnızca savaştaki bir ülke düşünürken, saatte bir kez
## kurulup burada saklanır.
func _ulke_dusun(ulke_id: String, su_anki_saat: int, onbellek: Dictionary = {}) -> void:
	_savas_ilanini_degerlendir(ulke_id, su_anki_saat)
	_yz_arastirma_dusun(ulke_id)
	_yz_tahkimat_dusun(ulke_id)
	if _ulkenin_savasta_mi(ulke_id):
		if not onbellek.has("birlik_dizini"):
			onbellek["birlik_dizini"] = _bolgelere_gore_birlikler()
		_savastaki_ulke_dusun(ulke_id, su_anki_saat, onbellek["birlik_dizini"])
	else:
		_baristaki_ulke_dusun(ulke_id, su_anki_saat)


## Savaştaki ülke, başkenti HARİÇ her bölgesinde (başkent hiç saldırıya katılmaz, böylece
## her zaman korunur) kendi gücünü savaşta olduğu bir komşu bölgedeki düşman gücüyle
## kıyaslar; kendi gücü düşmanın yz_saldiri_esigi (×1,3) katı ya da daha fazlaysa oraya
## saldırır (bölge başına en fazla bir hedef).
##
## `birlik_dizini` verilirse (bkz. _bolgelere_gore_birlikler) bölgelerdeki tümenler oradan
## okunur; verilmezse (ör. sınamalarda) her bölge için bolgedeki_birlikler() çağrılır.
func _savastaki_ulke_dusun(ulke_id: String, su_anki_saat: int, birlik_dizini: Dictionary[String, Array] = {}) -> void:
	var ulke: Ulke = dunya.ulkeler.get(ulke_id)
	if ulke == null:
		return
	if birlik_dizini.is_empty():
		birlik_dizini = _bolgelere_gore_birlikler()
	for bolge: Bolge in dunya.ulkenin_bolgeleri(ulke_id):
		if bolge.id == ulke.baskent_bolgesi:
			continue
		var buradakiler: Array[Birlik] = []
		buradakiler.assign(birlik_dizini.get(bolge.id, []))
		if buradakiler.is_empty():
			continue
		var buradaki_guc: float = _toplam_guc(buradakiler)
		for komsu: Bolge in dunya.bolgenin_komsulari(bolge.id):
			if not savasta_mi(ulke_id, komsu.sahip):
				continue
			var dusman: Array[Birlik] = []
			dusman.assign(birlik_dizini.get(komsu.id, []))
			var dusman_guc: float = _toplam_guc(dusman)
			if buradaki_guc >= _yz_saldiri_esigi * dusman_guc:
				birlikleri_yurut(buradakiler, komsu.id, su_anki_saat)
				break


## Barıştaki ülke, gelirinin elverdiği ve kuyruğunda yer olduğu sürece tümen kurar (seçtiği
## türün parası birikene kadar bekler, bkz. _yz_bekleyen_tur); ara sıra (yz_fabrika_olasiligi)
## bunun yerine fabrika kurar. Hangisi olursa olsun,
## başkente ya da bir sınır bölgesine (rastgele) kurulur.
func _baristaki_ulke_dusun(ulke_id: String, _su_anki_saat: int) -> void:
	var kuyruk: Array = insa_kuyruklari.get(ulke_id, [])
	if kuyruk.size() >= AZAMI_KUYRUK_UZUNLUGU:
		return
	var ulke: Ulke = dunya.ulkeler.get(ulke_id)
	if ulke == null:
		return
	var secenekler: Array[String] = OrduKurucu.yerlesim_bolgeleri(dunya, ulke)
	if secenekler.is_empty():
		return
	var hedef_bolge_id: String = secenekler[_rng.randi() % secenekler.size()]
	var hazine: float = hazineler.get(ulke_id, 0.0)

	if _rng.randf() < _yz_fabrika_olasiligi and hazine >= _fabrika_maliyeti:
		fabrika_sirala(ulke_id, hedef_bolge_id)
		return
	var tur: String = _yz_bekleyen_tur.get(ulke_id, "")
	if tur == "":
		tur = _yz_tur_sec(ulke_id)
	if hazine >= BirlikTurleri.maliyet(tur) and tumen_sirala(ulke_id, hedef_bolge_id, tur):
		_yz_bekleyen_tur.erase(ulke_id)
	else:
		_yz_bekleyen_tur[ulke_id] = tur


## Yapay zekânın kuracağı tümen türü: taban ağırlıklara (karışık ordu) göre rastgele seçilir;
## komşu ülkelerin en çok kullandığı türe üstün gelen türün ağırlığı `karsi_tur_bonusu` kadar
## artırılır (bkz. _ulke_tur_gucleri, her gün başında hesaplanır).
func _yz_tur_sec(ulke_id: String) -> String:
	var agirliklar: Dictionary[String, float] = {}
	for tur: String in BirlikTurleri.SIRA:
		agirliklar[tur] = float(_yz_tur_agirliklari.get(tur, 0.0))

	var komsu_gucleri: Dictionary[String, float] = {}
	var ulke: Ulke = dunya.ulkeler.get(ulke_id)
	if ulke != null:
		for komsu_id: String in ulke.komsular:
			var gucler: Dictionary = _ulke_tur_gucleri.get(komsu_id, {})
			for tur: String in gucler:
				komsu_gucleri[tur] = komsu_gucleri.get(tur, 0.0) + float(gucler[tur])
	var en_cok: String = ""
	var en_cok_guc: float = 0.0
	for tur: String in komsu_gucleri:
		if komsu_gucleri[tur] > en_cok_guc:
			en_cok = tur
			en_cok_guc = komsu_gucleri[tur]
	var karsi: String = BirlikTurleri.yenildigi(en_cok) if en_cok != "" else ""
	if agirliklar.has(karsi):
		agirliklar[karsi] *= 1.0 + _yz_karsi_tur_bonusu

	var toplam: float = 0.0
	for tur: String in agirliklar:
		toplam += agirliklar[tur]
	var zar: float = _rng.randf() * toplam
	for tur: String in agirliklar:
		zar -= agirliklar[tur]
		if zar <= 0.0:
			return tur
	return BirlikTurleri.VARSAYILAN


## Her ülkenin tümenlerinin türlere göre toplam gücü (yapay zekânın tür seçimi için).
func _ulke_tur_guclerini_hesapla() -> void:
	_ulke_tur_gucleri = {}
	for birlik: Birlik in birlikler:
		var gucler: Dictionary = _ulke_tur_gucleri.get(birlik.sahip, {})
		gucler[birlik.tur] = float(gucler.get(birlik.tur, 0.0)) + birlik.guc
		_ulke_tur_gucleri[birlik.sahip] = gucler


## Bir araştırması yoksa ara sıra (arastirma_olasiligi) en geride kalan dalda araştırma başlatır.
func _yz_arastirma_dusun(ulke_id: String) -> void:
	if arastirmalar.has(ulke_id) or _rng.randf() >= _yz_arastirma_olasiligi:
		return
	var secilen: String = ""
	var en_dusuk: int = Teknoloji.azami_seviye()
	for dal: String in Teknoloji.DALLAR:
		var seviye: int = teknoloji_seviyesi(ulke_id, dal)
		if seviye < en_dusuk:
			en_dusuk = seviye
			secilen = dal
	if secilen != "":
		arastirma_baslat(ulke_id, secilen)


## Ara sıra (tahkimat_olasiligi) başkentini ya da savaştığı bir ülkeye komşu bölgelerinden
## en az tahkim edilmiş olanı bir seviye tahkim eder.
func _yz_tahkimat_dusun(ulke_id: String) -> void:
	if _rng.randf() >= _yz_tahkimat_olasiligi:
		return
	var ulke: Ulke = dunya.ulkeler.get(ulke_id)
	if ulke == null:
		return
	var adaylar: Array[Bolge] = []
	var baskent: Bolge = dunya.bolgeler.get(ulke.baskent_bolgesi)
	if baskent != null and baskent.sahip == ulke_id:
		adaylar.append(baskent)
	for bolge: Bolge in dunya.ulkenin_bolgeleri(ulke_id):
		for komsu: Bolge in dunya.bolgenin_komsulari(bolge.id):
			if komsu.sahip != ulke_id and savasta_mi(ulke_id, komsu.sahip):
				adaylar.append(bolge)
				break
	var secilen: Bolge = null
	for bolge: Bolge in adaylar:
		if sonraki_tahkimat_seviyesi(ulke_id, bolge.id) == 0:
			continue
		if secilen == null or bolge.tahkimat < secilen.tahkimat:
			secilen = bolge
	if secilen != null and hazineler.get(ulke_id, 0.0) >= tahkimat_maliyeti(sonraki_tahkimat_seviyesi(ulke_id, secilen.id)):
		tahkimat_sirala(ulke_id, secilen.id)


## Yaklaşık ayda bir (yz_savas_ilani_gun_araligi) değerlendirilir: zaten azami sayıda
## savaştaysa ya da zar (küçük bir olasılık) tutmazsa hiçbir şey yapmaz. Tutarsa, doğrudan
## komşu olup kendisinden en az yz_savas_ilani_esigi (×2) kat güçsüz, henüz savaşılmayan
## bir ülke arar (oyuncu, ilk yz_oyuncuya_dokunulmazlik_gun gün boyunca aday sayılmaz) ve
## bulduğu ilk adaya savaş ilan eder.
func _savas_ilanini_degerlendir(ulke_id: String, su_anki_saat: int) -> void:
	@warning_ignore("integer_division")
	var gun: int = su_anki_saat / 24
	if gun % _yz_savas_ilani_gun_araligi != 0:
		return
	if _ulkenin_savas_sayisi(ulke_id) >= _yz_azami_eszamanli_savas:
		return
	if _rng.randf() >= _yz_savas_ilani_olasiligi:
		return

	var kendi_guc: float = _ulkenin_toplam_gucu(ulke_id)
	if kendi_guc <= 0.0:
		return
	var dokunulmazlik_saati: int = _yz_oyuncuya_dokunulmazlik_gun * 24
	for diger: Ulke in dunya.ulke_listesi:
		if diger.id == ulke_id or savasta_mi(ulke_id, diger.id):
			continue
		if diger.id == oyuncu_ulkesi and su_anki_saat < dokunulmazlik_saati:
			continue
		if not dunya.ulkeler_komsu_mu(ulke_id, diger.id):
			continue
		var diger_guc: float = _ulkenin_toplam_gucu(diger.id)
		if diger_guc <= 0.0 or kendi_guc < _yz_savas_ilani_esigi * diger_guc:
			continue
		savas_ilan_et(ulke_id, diger.id, su_anki_saat)
		return


func _ulkenin_savas_sayisi(ulke_id: String) -> int:
	var sayi: int = 0
	for anahtar: String in _savaslar:
		if anahtar.split("|").has(ulke_id):
			sayi += 1
	return sayi


## Ülke herhangi bir savaştaysa true döner.
func _ulkenin_savasta_mi(ulke_id: String) -> bool:
	for anahtar: String in _savaslar:
		var taraflar: PackedStringArray = anahtar.split("|")
		if taraflar.has(ulke_id):
			return true
	return false


func oyuncu_secildi_mi() -> bool:
	return oyuncu_ulkesi != ""


## Oyuncunun ülkesini belirler. Ülke yalnızca bir kez seçilebilir.
## Seçim geçerliyse true döner.
func oyuncuyu_sec(ulke_id: String) -> bool:
	if oyuncu_secildi_mi() or not dunya.ulkeler.has(ulke_id):
		return false
	oyuncu_ulkesi = ulke_id
	oyuncu_secildi.emit(ulke_id)
	return true


## Oyunun durumunu (zaman hariç; onu çağıran Zaman.durumu_al() ile ekler) kaydedilebilir
## düz bir sözlük olarak döndürür. KayitYoneticisi.kaydet() tarafından kullanılır.
func kaydet_icin_veri() -> Dictionary:
	var bolgeler: Array = []
	for bolge: Bolge in dunya.bolge_listesi:
		if bolge.isgal_saati == -1 and bolge.fabrika_sanayisi == 0.0 and bolge.tahkimat == 0 \
				and bolge.sahip == bolge.id.split("_")[0]:
			continue  # Hiç değişmemiş bölge; yer kaplamasın.
		bolgeler.append({
			"id": bolge.id, "sahip": bolge.sahip,
			"isgal_saati": bolge.isgal_saati, "fabrika_sanayisi": bolge.fabrika_sanayisi,
			"tahkimat": bolge.tahkimat,
		})

	var birlik_verisi: Array = []
	for birlik: Birlik in birlikler:
		birlik_verisi.append({
			"sahip": birlik.sahip, "tur": birlik.tur, "bolge_id": birlik.bolge_id, "guc": birlik.guc,
			"hedef_bolge_id": birlik.hedef_bolge_id, "varis_saati": birlik.varis_saati,
			"son_adim_deniz_mi": birlik.son_adim_deniz_mi,
		})

	var savas_verisi: Array = []
	for anahtar: String in _savaslar:
		savas_verisi.append({"anahtar": anahtar, "ilan_saati": _savaslar[anahtar]})

	var kuyruk_verisi: Dictionary = {}
	for ulke_id: String in insa_kuyruklari:
		var liste: Array = []
		for is_: InsaIsi in (insa_kuyruklari[ulke_id] as Array):
			liste.append({
				"tur": is_.tur, "sahip": is_.sahip, "birlik_turu": is_.birlik_turu,
				"bolge_id": is_.bolge_id, "kalan_saat": is_.kalan_saat,
			})
		kuyruk_verisi[ulke_id] = liste

	return {
		"oyuncu_ulkesi": oyuncu_ulkesi,
		"bolgeler": bolgeler,
		"birlikler": birlik_verisi,
		"savaslar": savas_verisi,
		"hazineler": hazineler,
		"insa_kuyruklari": kuyruk_verisi,
		"zafer_kazanildi": _zafer_kazanildi,
		"yz_oyuncuyu_yonetsin": yz_oyuncuyu_yonetsin,
		"teknolojiler": teknolojiler,
		"arastirmalar": arastirmalar,
	}


## kaydet_icin_veri()'nin ürettiği biçimdeki bir sözlüğü uygular; başlangıçta OrduKurucu'nun
## ürettiği taze orduyu ve dünyanın başlangıç sahipliklerini tamamen değiştirir. Eski (1.
## sürüm) kayıtlarda olmayan alanlar varsayılanını alır: tümenler piyade, teknoloji ve
## tahkimat sıfır.
func kayittan_yukle(veri: Dictionary) -> void:
	oyuncu_ulkesi = str(veri.get("oyuncu_ulkesi", ""))

	for b: Dictionary in (veri.get("bolgeler", []) as Array):
		var bolge: Bolge = dunya.bolgeler.get(str(b.get("id", "")))
		if bolge == null:
			continue
		bolge.sahip = str(b.get("sahip", bolge.sahip))
		bolge.isgal_saati = int(b.get("isgal_saati", -1))
		bolge.fabrika_sanayisi = float(b.get("fabrika_sanayisi", 0.0))
		bolge.tahkimat = clampi(int(b.get("tahkimat", 0)), 0, _tahkimat_azami)

	birlikler = []
	for b: Dictionary in (veri.get("birlikler", []) as Array):
		var birlik: Birlik = Birlik.new()
		birlik.sahip = str(b.get("sahip", ""))
		birlik.tur = _gecerli_tur(str(b.get("tur", BirlikTurleri.VARSAYILAN)))
		birlik.bolge_id = str(b.get("bolge_id", ""))
		birlik.guc = float(b.get("guc", 0.0))
		birlik.hedef_bolge_id = str(b.get("hedef_bolge_id", ""))
		birlik.varis_saati = int(b.get("varis_saati", -1))
		birlik.son_adim_deniz_mi = bool(b.get("son_adim_deniz_mi", false))
		birlikler.append(birlik)

	_savaslar = {}
	for s: Dictionary in (veri.get("savaslar", []) as Array):
		_savaslar[str(s.get("anahtar", ""))] = int(s.get("ilan_saati", 0))

	hazineler = {}
	var hazine_verisi: Dictionary = veri.get("hazineler", {})
	for ulke_id: String in hazine_verisi:
		hazineler[ulke_id] = float(hazine_verisi[ulke_id])

	insa_kuyruklari = {}
	var kuyruk_verisi: Dictionary = veri.get("insa_kuyruklari", {})
	for ulke_id: String in kuyruk_verisi:
		var liste: Array[InsaIsi] = []
		for is_verisi: Dictionary in (kuyruk_verisi[ulke_id] as Array):
			var is_: InsaIsi = InsaIsi.new()
			var is_turu: int = int(is_verisi.get("tur", 0))
			is_.tur = is_turu as InsaIsi.Tur if is_turu in InsaIsi.Tur.values() else InsaIsi.Tur.TUMEN
			is_.birlik_turu = _gecerli_tur(str(is_verisi.get("birlik_turu", BirlikTurleri.VARSAYILAN)))
			is_.sahip = str(is_verisi.get("sahip", ulke_id))
			is_.bolge_id = str(is_verisi.get("bolge_id", ""))
			is_.kalan_saat = int(is_verisi.get("kalan_saat", 0))
			liste.append(is_)
		insa_kuyruklari[ulke_id] = liste

	_zafer_kazanildi = bool(veri.get("zafer_kazanildi", false))
	yz_oyuncuyu_yonetsin = bool(veri.get("yz_oyuncuyu_yonetsin", false))

	teknolojiler = {}
	var teknoloji_verisi: Dictionary = veri.get("teknolojiler", {})
	for ulke_id: String in teknoloji_verisi:
		var seviyeler: Dictionary = {}
		var kayitli: Dictionary = teknoloji_verisi[ulke_id]
		for dal: String in kayitli:
			if Teknoloji.DALLAR.has(dal):
				seviyeler[dal] = clampi(int(kayitli[dal]), 0, Teknoloji.azami_seviye())
		teknolojiler[ulke_id] = seviyeler
	arastirmalar = {}
	var arastirma_verisi: Dictionary = veri.get("arastirmalar", {})
	for ulke_id: String in arastirma_verisi:
		var a: Dictionary = arastirma_verisi[ulke_id]
		if Teknoloji.DALLAR.has(str(a.get("dal", ""))):
			arastirmalar[ulke_id] = {"dal": str(a["dal"]), "kalan_saat": int(a.get("kalan_saat", 1)),
					"toplam_saat": int(a.get("toplam_saat", 1))}
	_ulke_tur_guclerini_hesapla()


## Kayıttaki tür bilinmiyorsa (ör. eski kayıt) piyade sayılır.
static func _gecerli_tur(tur: String) -> String:
	return tur if BirlikTurleri.gecerli_mi(tur) else BirlikTurleri.VARSAYILAN
