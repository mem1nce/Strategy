class_name Oyun
extends RefCounted
## Oyunun durumu: dünya ve oyuncunun seçtiği ülke.
##
## Birlik, savaş ve ekonomi eklendikçe onların durumu da buraya bağlanacak.

## Oyuncu ülkesini seçtiğinde bir kez yayılır.
signal oyuncu_secildi(ulke_id: String)
## Bir tümen yürümeye başladığında ya da vardığında yayılır.
signal birlikler_degisti

var dunya: Dunya = null
## Oyuncunun yönettiği ülkenin id'si. Seçim yapılmadıysa boştur.
var oyuncu_ulkesi: String = ""
## Dünyadaki bütün tümenler.
var birlikler: Array[Birlik] = []


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
## (kara komşuluğu 24 saat, deniz yolu daha yavaş) gelir. Savaş henüz olmadığından, yalnızca
## iki bölge de aynı ülkeye aitse yürütme kabul edilir (savaş eklenince gevşetilecek bir
## kural; bkz. DEVAM.md). `su_anki_saat`, Zaman.toplam_saat değeridir; Oyun'un Zaman
## autoload'ına bağlı olmadan sınanabilmesi için parametre olarak alınır. `tasinacaklar`
## boşsa ya da yürütme kabul edilmezse false döner.
func birlikleri_yurut(tasinacaklar: Array[Birlik], hedef_bolge_id: String, su_anki_saat: int) -> bool:
	if tasinacaklar.is_empty():
		return false
	var kaynak_bolge_id: String = tasinacaklar[0].bolge_id
	var kaynak_sahibi: Ulke = dunya.bolgenin_sahibi(kaynak_bolge_id)
	var hedef_sahibi: Ulke = dunya.bolgenin_sahibi(hedef_bolge_id)
	if kaynak_sahibi == null or hedef_sahibi == null or kaynak_sahibi.id != hedef_sahibi.id:
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


## Zaman ilerledikçe çağrılır; varış saatine ulaşan tümenleri hedeflerine taşır.
func saat_ilerledi(su_anki_saat: int) -> void:
	var degisti: bool = false
	for birlik: Birlik in birlikler:
		if birlik.yuruyor_mu() and su_anki_saat >= birlik.varis_saati:
			birlik.bolge_id = birlik.hedef_bolge_id
			birlik.hedef_bolge_id = ""
			birlik.varis_saati = -1
			degisti = true
	if degisti:
		birlikler_degisti.emit()


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
