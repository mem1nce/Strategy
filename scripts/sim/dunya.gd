class_name Dunya
extends RefCounted
## Dünya haritasının verisi: ülkeler, bölgeler, toprak parçaları ve sınırlar.
##
## data/world.json ve data/regions.json dosyalarından kurulur. Görsel katman bunu yalnızca okur.

const DUNYA_DOSYASI: String = "res://data/world.json"
const BOLGE_DOSYASI: String = "res://data/regions.json"

## Haritanın birim cinsinden boyutu.
var boyut: Vector2 = Vector2.ZERO
var ulkeler: Dictionary[String, Ulke] = {}
var ulke_listesi: Array[Ulke] = []
var bolgeler: Dictionary[String, Bolge] = {}
var bolge_listesi: Array[Bolge] = []
## Bütün toprak parçaları, büyükten küçüğe sıralı. Bu sırayla çizilince küçük
## parçalar üstte kalır (ör. Lesotho, Güney Afrika'nın üstünde).
var cokgenler: Array[Cokgen] = []
var sinirlar: Array[Sinir] = []
## Ülke id'si -> o ülkenin bölgeleri (bkz. ulkenin_bolgeleri). Yüklerken kurulur, sonra her
## sahiplik değişiminde yalnızca o bölge eski sahibinin listesinden yenisininkine taşınır.
var _ulke_bolgeleri_onbellegi: Dictionary[String, Array] = {}
## Bölgeler arası, saat cinsinden süreye göre en hızlı yolu bulur (kara + deniz yolu).
var yol_bulucu: YolBulucu = null


## Veri dosyalarını okuyup dünyayı kurar. Veri hatalıysa nedenini yazar ve null döndürür.
static func yukle() -> Dunya:
	var dunya_verisi: Dictionary = VeriOkuyucu.sozluk_oku(DUNYA_DOSYASI)
	var bolge_verisi: Dictionary = VeriOkuyucu.sozluk_oku(BOLGE_DOSYASI)
	if dunya_verisi.is_empty() or bolge_verisi.is_empty():
		return null

	var dunya: Dunya = Dunya.new()
	dunya.boyut = Vector2(float(dunya_verisi.get("genislik", 0)), float(dunya_verisi.get("yukseklik", 0)))

	var ulke_kayitlari: Array = dunya_verisi.get("ulkeler", [])
	for kayit: Dictionary in ulke_kayitlari:
		var ulke: Ulke = Ulke.sozlukten(kayit)
		dunya.ulkeler[ulke.id] = ulke
		dunya.ulke_listesi.append(ulke)

	var bolge_kayitlari: Array = bolge_verisi.get("bolgeler", [])
	for kayit: Dictionary in bolge_kayitlari:
		var bolge: Bolge = Bolge.sozlukten(kayit)
		dunya.bolgeler[bolge.id] = bolge
		dunya.bolge_listesi.append(bolge)
		dunya.cokgenler.append_array(bolge.cokgenler)
	dunya.cokgenler.sort_custom(func(a: Cokgen, b: Cokgen) -> bool: return a.alan > b.alan)

	var sinir_kayitlari: Array = bolge_verisi.get("sinirlar", [])
	for kayit: Dictionary in sinir_kayitlari:
		dunya.sinirlar.append(Sinir.sozlukten(kayit))

	if not dunya._dogrula():
		return null
	dunya.yol_bulucu = YolBulucu.kur(dunya)
	for bolge: Bolge in dunya.bolge_listesi:
		var liste: Array = dunya._ulke_bolgeleri_onbellegi.get(bolge.sahip, [])
		liste.append(bolge)
		dunya._ulke_bolgeleri_onbellegi[bolge.sahip] = liste
		bolge.sahip_dinleyicisi = dunya._bolgenin_sahibi_degisti
	return dunya


# --- Sorgular --------------------------------------------------------------

## Bölgenin o anki sahibi olan ülke.
func bolgenin_sahibi(bolge_id: String) -> Ulke:
	if not bolgeler.has(bolge_id):
		return null
	return ulkeler.get(bolgeler[bolge_id].sahip)


## Ülkenin o an elinde tuttuğu bölgeler.
##
## Bu sorgu yapay zekâ, ekonomi ve teslim denetiminden saatte yüzlerce kez çağrılır. Her
## seferinde ~1100 bölgeyi taramamak için sonuçlar ülkelere göre önbellekte tutulur ve bir
## bölgenin sahibi değişince yalnızca o bölge taşınır (bkz. _bolgenin_sahibi_degisti).
## Dönen dizi önbelleğin bir kopyasıdır; çağıran onu değiştirebilir.
func ulkenin_bolgeleri(ulke_id: String) -> Array[Bolge]:
	var sonuc: Array[Bolge] = []
	sonuc.assign(_ulke_bolgeleri_onbellegi.get(ulke_id, []))
	return sonuc


## Ülkenin o an elinde tuttuğu bölge sayısı (kopya oluşturmadan).
func ulkenin_bolge_sayisi(ulke_id: String) -> int:
	return (_ulke_bolgeleri_onbellegi.get(ulke_id, []) as Array).size()


func _bolgenin_sahibi_degisti(bolge: Bolge, eski_sahip: String) -> void:
	var eski_liste: Array = _ulke_bolgeleri_onbellegi.get(eski_sahip, [])
	eski_liste.erase(bolge)
	var yeni_liste: Array = _ulke_bolgeleri_onbellegi.get(bolge.sahip, [])
	yeni_liste.append(bolge)
	_ulke_bolgeleri_onbellegi[bolge.sahip] = yeni_liste


## Bölgeyle ortak sınırı olan bölgeler (başka ülkelerinkiler dahil).
func bolgenin_kara_komsulari(bolge_id: String) -> Array[Bolge]:
	if not bolgeler.has(bolge_id):
		return []
	return _bolgelere_cevir(bolgeler[bolge_id].kara_komsulari)


## Bölgeye dar bir sudan geçilerek ulaşılan bölgeler.
func bolgenin_deniz_gecisleri(bolge_id: String) -> Array[Bolge]:
	if not bolgeler.has(bolge_id):
		return []
	return _bolgelere_cevir(bolgeler[bolge_id].deniz_gecisleri)


## Bölgenin karadan ya da denizden ulaşılabilen bütün komşuları.
func bolgenin_komsulari(bolge_id: String) -> Array[Bolge]:
	var sonuc: Array[Bolge] = bolgenin_kara_komsulari(bolge_id)
	sonuc.append_array(bolgenin_deniz_gecisleri(bolge_id))
	return sonuc


## Verilen noktayı içeren toprak parçasını döndürür; nokta denizdeyse null döner.
## İç içe parçalarda en küçüğü seçilir (Lesotho'ya dokununca Güney Afrika gelmez).
func noktadaki_cokgen(nokta: Vector2) -> Cokgen:
	for i: int in range(cokgenler.size() - 1, -1, -1):
		if cokgenler[i].icinde_mi(nokta):
			return cokgenler[i]
	return null


## Noktaya en çok `azami_uzaklik` kadar uzaktaki en yakın toprak parçasını döndürür.
## Küçük bölgelere dokunmayı kolaylaştırmak içindir. Yakında parça yoksa null döner.
func en_yakin_cokgen(nokta: Vector2, azami_uzaklik: float) -> Cokgen:
	var en_iyi: Cokgen = null
	var en_iyi_uzaklik: float = azami_uzaklik
	for cokgen: Cokgen in cokgenler:
		if not cokgen.sinir_kutusu.grow(azami_uzaklik).has_point(nokta):
			continue
		var uzaklik: float = cokgen.kenara_uzaklik(nokta)
		if uzaklik <= en_iyi_uzaklik:
			en_iyi_uzaklik = uzaklik
			en_iyi = cokgen
	return en_iyi


## İki ülkenin kara ya da deniz yoluyla doğrudan komşu olup olmadığını, o anki bölge
## sahipliklerine bakarak söyler (savaş yalnızca doğrudan komşu ülkelere ilan edilebilir;
## üçüncü bir ülkenin toprağından "geçerek" ulaşmak sayılmaz).
func ulkeler_komsu_mu(ulke_a: String, ulke_b: String) -> bool:
	for bolge: Bolge in ulkenin_bolgeleri(ulke_a):
		for komsu: Bolge in bolgenin_komsulari(bolge.id):
			if komsu.sahip == ulke_b:
				return true
	return false


func _bolgelere_cevir(idler: PackedStringArray) -> Array[Bolge]:
	var sonuc: Array[Bolge] = []
	for bolge_id: String in idler:
		if bolgeler.has(bolge_id):
			sonuc.append(bolgeler[bolge_id])
	return sonuc


# --- Doğrulama -------------------------------------------------------------

## Verinin kendi içinde tutarlı olduğunu denetler.
func _dogrula() -> bool:
	var hatalar: PackedStringArray = PackedStringArray()
	if boyut.x <= 0.0 or boyut.y <= 0.0:
		hatalar.append("harita boyutu eksik")
	if ulke_listesi.is_empty():
		hatalar.append("hiç ülke yok")
	if bolge_listesi.is_empty():
		hatalar.append("hiç bölge yok")

	for ulke: Ulke in ulke_listesi:
		if ulke.id == "":
			hatalar.append("id'si olmayan bir ülke var")
		if not bolgeler.has(ulke.baskent_bolgesi):
			hatalar.append("%s: başkent bölgesi '%s' bulunamadı" % [ulke.id, ulke.baskent_bolgesi])
		for komsu_id: String in ulke.komsular:
			if not ulkeler.has(komsu_id):
				hatalar.append("%s: bilinmeyen komşu ülke '%s'" % [ulke.id, komsu_id])

	for bolge: Bolge in bolge_listesi:
		if not ulkeler.has(bolge.sahip):
			hatalar.append("%s: bilinmeyen sahip '%s'" % [bolge.id, bolge.sahip])
		if bolge.cokgenler.is_empty():
			hatalar.append("%s: çokgeni yok" % bolge.id)
		_komsulugu_denetle(bolge, bolge.kara_komsulari, true, hatalar)
		_komsulugu_denetle(bolge, bolge.deniz_gecisleri, false, hatalar)

	for sinir: Sinir in sinirlar:
		if not bolgeler.has(sinir.a) or (not sinir.kiyi_mi() and not bolgeler.has(sinir.b)):
			hatalar.append("bilinmeyen bölgeye değen sınır: '%s' - '%s'" % [sinir.a, sinir.b])
		if sinir.noktalar.size() < 2:
			hatalar.append("noktası eksik sınır: '%s' - '%s'" % [sinir.a, sinir.b])

	for hata: String in hatalar:
		push_error("Dünya verisi hatalı: %s" % hata)
	return hatalar.is_empty()


## Bir komşuluk listesindeki her bölgenin var olduğunu ve komşuluğun iki yönlü olduğunu denetler.
func _komsulugu_denetle(bolge: Bolge, idler: PackedStringArray, kara: bool, hatalar: PackedStringArray) -> void:
	for komsu_id: String in idler:
		if not bolgeler.has(komsu_id):
			hatalar.append("%s: bilinmeyen komşu bölge '%s'" % [bolge.id, komsu_id])
			continue
		var karsi: PackedStringArray = bolgeler[komsu_id].kara_komsulari if kara else bolgeler[komsu_id].deniz_gecisleri
		if not karsi.has(bolge.id):
			hatalar.append("%s ile %s arasındaki komşuluk tek yönlü" % [bolge.id, komsu_id])
