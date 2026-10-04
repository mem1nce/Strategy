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


## Kaynak bölgedeki bütün tümenleri hedef bölgeye yürütür. Süre, YolBulucu'dan (kara
## komşuluğu 24 saat, deniz yolu daha yavaş) gelir. Savaş henüz olmadığından, yalnızca
## iki bölge de aynı ülkeye aitse yürütme kabul edilir (savaş eklenince gevşetilecek bir
## kural; bkz. DEVAM.md). `su_anki_saat`, Zaman.toplam_saat değeridir; Oyun'un Zaman
## autoload'ına bağlı olmadan sınanabilmesi için parametre olarak alınır. Kaynakta hiç
## tümen yoksa ya da yürütme kabul edilmezse false döner.
func birlikleri_yurut(kaynak_bolge_id: String, hedef_bolge_id: String, su_anki_saat: int) -> bool:
	var tasinacaklar: Array[Birlik] = bolgedeki_birlikler(kaynak_bolge_id)
	if tasinacaklar.is_empty():
		return false
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
