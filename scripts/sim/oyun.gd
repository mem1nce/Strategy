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

const DENGE_DOSYASI: String = "res://data/balance.json"
## Tümenin güç altına düştüğünde yok sayıldığı eşik.
const ASGARI_GUC: float = 1.0
## Barış teklifinin otomatik kabul edilmesi için bir savaşın en az bu kadar sürmesi gerekir.
const BARIS_ESIGI_SAAT: int = 180 * 24
## İnşa kuyruğunda aynı anda en fazla bu kadar iş bekleyebilir.
const AZAMI_KUYRUK_UZUNLUGU: int = 5

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
var _tumen_maliyeti: float = 50.0
var _tumen_suresi_saat: int = 120
var _fabrika_maliyeti: float = 500.0
var _fabrika_suresi_saat: int = 720
var _fabrika_sanayi_artisi: float = 2.0
var _bakim_birim_maliyeti: float = 0.5
## Yeni kurulan tümenin başlangıç gücü (OrduKurucu'nun kullandığı değerle aynı; bkz.
## data/balance.json -> "ordu").
var _baslangic_gucu: float = 100.0

## Ülke id'si -> birikmiş üretim. Her oyun günü başında gelir eklenir (bkz. gun_basladi).
var hazineler: Dictionary[String, float] = {}
## Ülke id'si -> o ülkenin inşa kuyruğu (Array[InsaIsi], en fazla AZAMI_KUYRUK_UZUNLUGU).
## Yalnızca kuyruğun önündeki iş ilerler (tek kuyruk).
var insa_kuyruklari: Dictionary[String, Array] = {}


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
	_tumen_maliyeti = float(ekonomi_ayarlari.get("tumen_maliyeti", _tumen_maliyeti))
	_tumen_suresi_saat = int(ekonomi_ayarlari.get("tumen_suresi_saat", _tumen_suresi_saat))
	_fabrika_maliyeti = float(ekonomi_ayarlari.get("fabrika_maliyeti", _fabrika_maliyeti))
	_fabrika_suresi_saat = int(ekonomi_ayarlari.get("fabrika_suresi_saat", _fabrika_suresi_saat))
	_fabrika_sanayi_artisi = float(ekonomi_ayarlari.get("fabrika_sanayi_artisi", _fabrika_sanayi_artisi))
	_bakim_birim_maliyeti = float(ekonomi_ayarlari.get("bakim_birim_maliyeti", _bakim_birim_maliyeti))

	var ordu_ayarlari: Dictionary = VeriOkuyucu.sozluk_oku(DENGE_DOSYASI).get("ordu", {})
	_baslangic_gucu = float(ordu_ayarlari.get("baslangic_gucu", _baslangic_gucu))


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
		if birlik.yuruyor_mu() and su_anki_saat >= birlik.varis_saati:
			birlik.bolge_id = birlik.hedef_bolge_id
			birlik.hedef_bolge_id = ""
			birlik.varis_saati = -1
			tasima_oldu = true
			_bos_dusman_bolgesini_isgal_et(birlik, su_anki_saat)
	if tasima_oldu:
		birlikler_degisti.emit()
	_muharebeleri_isle(su_anki_saat)
	_insa_islerini_isle()


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
func _muharebeleri_isle(su_anki_saat: int) -> void:
	var bolge_gruplari: Dictionary[String, Array] = {}
	for birlik: Birlik in birlikler:
		if birlik.yuruyor_mu():
			continue
		if not bolge_gruplari.has(birlik.bolge_id):
			bolge_gruplari[birlik.bolge_id] = [] as Array[Birlik]
		(bolge_gruplari[birlik.bolge_id] as Array[Birlik]).append(birlik)

	for bolge_id: String in bolge_gruplari:
		var katilanlar: Array[Birlik] = bolge_gruplari[bolge_id]
		var sahipler: Dictionary[String, bool] = {}
		for birlik: Birlik in katilanlar:
			sahipler[birlik.sahip] = true
		if sahipler.size() > 1:
			_muharebeyi_coz(dunya.bolgeler[bolge_id], katilanlar, su_anki_saat)


## Bir bölgedeki muharebeyi bir saat ilerletir: her iki taraf, karşı tarafın etkin (bonus/
## ceza uygulanmış) toplam gücüyle orantılı kayıp alır. Savunan %25 avantajlıdır; son adımı
## deniz yoluyla gelen saldırgan tümenler %30 cezalıdır. Güç ASGARI_GUC altına düşen tümen
## yok sayılır. Bir taraf tükenirse ya da belirgin biçimde geride kalırsa (CEKILME_ESIGI)
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

	var savunan_guc: float = _toplam_guc(savunanlar)
	var saldiran_guc: float = 0.0
	for birlik: Birlik in saldiranlar:
		saldiran_guc += birlik.guc * (_deniz_cezasi if birlik.son_adim_deniz_mi else 1.0)
	var etkin_savunan: float = savunan_guc * _savunan_avantaji

	_guc_azalt(savunanlar, saldiran_guc * _saatlik_kayip_orani)
	_guc_azalt(saldiranlar, etkin_savunan * _saatlik_kayip_orani)
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


## Bir bölgenin sahibini değiştirir, ele geçirilme saatini (ekonomide işgal cezası için)
## kaydeder, haritanın güncellenmesi için sinyal yayar ve eski sahibinin teslim olup
## olmadığını denetler.
func _bolgeyi_devret(bolge: Bolge, yeni_sahip: String, su_anki_saat: int) -> void:
	var eski_sahip: String = bolge.sahip
	bolge.sahip = yeni_sahip
	bolge.isgal_saati = su_anki_saat
	bolge_sahipligi_degisti.emit()
	_teslimi_kontrol_et(eski_sahip, su_anki_saat)


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
	var kalanlar: Array[Birlik] = []
	for birlik: Birlik in birlikler:
		if birlik.sahip != ulke_id:
			kalanlar.append(birlik)
	birlikler = kalanlar

	bolge_sahipligi_degisti.emit()
	birlikler_degisti.emit()
	ulke_teslim_oldu.emit(ulke_id, galip_id)


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
	hazine_degisti.emit()
	birlikler_degisti.emit()


## Her ülkenin tümen başına günlük bakım masrafını hazinesinden düşer. Hazine yetmezse
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
		var bakim: float = liste.size() * _bakim_birim_maliyeti
		var mevcut: float = hazineler.get(ulke_id, 0.0)
		if mevcut >= bakim:
			hazineler[ulke_id] = mevcut - bakim
			continue
		hazineler[ulke_id] = 0.0
		_guc_azalt(liste, bakim - mevcut)
		_olenleri_temizle(liste)


## Verilen ülkenin, verilen (kendi) bölgesinde yeni bir tümen sıralar. Kuyruk doluysa,
## bölge o ülkeye ait değilse ya da hazine yetmezse false döner (maliyet hemen kesilir).
func tumen_sirala(ulke_id: String, bolge_id: String) -> bool:
	return _ise_sirala(ulke_id, bolge_id, InsaIsi.Tur.TUMEN, _tumen_maliyeti, _tumen_suresi_saat)


## Verilen ülkenin, verilen (kendi) bölgesinde fabrika sıralar; tamamlanınca bölgenin
## sanayisini kalıcı olarak artırır.
func fabrika_sirala(ulke_id: String, bolge_id: String) -> bool:
	return _ise_sirala(ulke_id, bolge_id, InsaIsi.Tur.FABRIKA, _fabrika_maliyeti, _fabrika_suresi_saat)


func _ise_sirala(ulke_id: String, bolge_id: String, tur: InsaIsi.Tur, maliyet: float, sure_saat: int) -> bool:
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
	if is_.tur == InsaIsi.Tur.TUMEN:
		var yeni: Birlik = Birlik.new()
		yeni.sahip = is_.sahip
		yeni.bolge_id = is_.bolge_id
		yeni.guc = _baslangic_gucu
		birlikler.append(yeni)
		birlikler_degisti.emit()
	else:
		var bolge: Bolge = dunya.bolgeler.get(is_.bolge_id)
		if bolge != null:
			bolge.fabrika_sanayisi += _fabrika_sanayi_artisi


## Bir ülkenin günlük geliri: o an sahip olduğu bölgelerin sanayilerinin toplamı.
func ulkenin_geliri(ulke_id: String, su_anki_saat: int) -> float:
	var toplam: float = 0.0
	for bolge: Bolge in dunya.ulkenin_bolgeleri(ulke_id):
		toplam += bolge_sanayisi(bolge, su_anki_saat)
	return toplam


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
	var isgal_altinda: bool = ev_ulke != null and bolge.isgal_saati >= 0 and bolge.sahip != ev_ulke.id \
			and su_anki_saat - bolge.isgal_saati < _isgal_cezasi_gun * 24
	if isgal_altinda:
		sanayi *= _isgal_cezasi_orani
	return sanayi


func _bolge_ev_sahibi(bolge: Bolge) -> Ulke:
	return dunya.ulkeler.get(bolge.id.split("_")[0])


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
