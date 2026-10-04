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

var dunya: Dunya = null
## Oyuncunun yönettiği ülkenin id'si. Seçim yapılmadıysa boştur.
var oyuncu_ulkesi: String = ""
## Dünyadaki bütün tümenler.
var birlikler: Array[Birlik] = []
## Savaştaki ülke çiftleri. Anahtar iki ülke id'sinin sıralı birleşimidir (bkz. _savas_anahtari).
var _savaslar: Dictionary[String, bool] = {}


func _init(yeni_dunya: Dunya) -> void:
	dunya = yeni_dunya
	birlikler = OrduKurucu.baslangic_birliklerini_olustur(dunya)


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
	var sure: float = dunya.yol_bulucu.en_kisa_sure(kaynak_bolge_id, hedef_bolge_id)
	if sure < 0.0:
		return false

	var varis: int = su_anki_saat + maxi(1, roundi(sure))
	for birlik: Birlik in tasinacaklar:
		birlik.hedef_bolge_id = hedef_bolge_id
		birlik.varis_saati = varis
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
## düşman bölgesine varan tümen orayı ele geçirir.
func saat_ilerledi(su_anki_saat: int) -> void:
	var degisti: bool = false
	var sahiplik_degisti: bool = false
	for birlik: Birlik in birlikler:
		if birlik.yuruyor_mu() and su_anki_saat >= birlik.varis_saati:
			birlik.bolge_id = birlik.hedef_bolge_id
			birlik.hedef_bolge_id = ""
			birlik.varis_saati = -1
			degisti = true
			if _bos_dusman_bolgesini_isgal_et(birlik):
				sahiplik_degisti = true
	if degisti:
		birlikler_degisti.emit()
	if sahiplik_degisti:
		bolge_sahipligi_degisti.emit()


## Gelen tümen, savaşta olduğu ve içinde savunan (bölgenin o anki sahibine ait) tümen
## kalmamış bir düşman bölgesine girdiyse orayı ele geçirir. Muharebe henüz yok; savunan
## varsa işgal gerçekleşmez (bkz. DEVAM.md, sıradaki iş: çarpışma).
func _bos_dusman_bolgesini_isgal_et(gelen: Birlik) -> bool:
	var bolge: Bolge = dunya.bolgeler.get(gelen.bolge_id)
	if bolge == null or bolge.sahip == gelen.sahip or not savasta_mi(bolge.sahip, gelen.sahip):
		return false
	for digeri: Birlik in bolgedeki_birlikler(gelen.bolge_id):
		if digeri.sahip == bolge.sahip:
			return false
	bolge.sahip = gelen.sahip
	return true


## İki ülke savaşta mı?
func savasta_mi(ulke_a: String, ulke_b: String) -> bool:
	return _savaslar.has(_savas_anahtari(ulke_a, ulke_b))


## Savaş ilan eder. Yalnızca doğrudan (kara ya da deniz yoluyla) komşu, henüz savaşılmayan,
## var olan iki farklı ülke arasında kabul edilir. Kabul edilirse true döner.
func savas_ilan_et(ilan_eden: String, hedef: String) -> bool:
	if ilan_eden == hedef or not dunya.ulkeler.has(ilan_eden) or not dunya.ulkeler.has(hedef):
		return false
	if savasta_mi(ilan_eden, hedef) or not dunya.ulkeler_komsu_mu(ilan_eden, hedef):
		return false
	_savaslar[_savas_anahtari(ilan_eden, hedef)] = true
	savas_ilan_edildi.emit(ilan_eden, hedef)
	return true


func _savas_anahtari(ulke_a: String, ulke_b: String) -> String:
	return "%s|%s" % [ulke_a, ulke_b] if ulke_a < ulke_b else "%s|%s" % [ulke_b, ulke_a]


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
