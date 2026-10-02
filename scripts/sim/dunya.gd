class_name Dunya
extends RefCounted
## Haritanın ve ülkelerin oyun içi durumu.
##
## data/ klasöründeki dosyalardan kurulur. Görsel katman bunu yalnızca okur.

const BOLGE_DOSYASI: String = "res://data/provinces.json"
const ULKE_DOSYASI: String = "res://data/countries.json"
const ARAZI_DOSYASI: String = "res://data/terrain.json"

## Haritanın piksel cinsinden boyutu (deniz dahil).
var boyut: Vector2 = Vector2.ZERO
var bolgeler: Dictionary[String, Bolge] = {}
var bolge_listesi: Array[Bolge] = []
var ulkeler: Dictionary[String, Ulke] = {}
var ulke_listesi: Array[Ulke] = []
var araziler: Dictionary[String, Arazi] = {}
## Blok id'si -> ekranda görünen adı.
var blok_adlari: Dictionary[String, String] = {}


## Veri dosyalarını okuyup dünyayı kurar. Veri hatalıysa nedenini yazar ve null döndürür.
static func yukle() -> Dunya:
	var dunya: Dunya = Dunya.new()
	if not dunya._araziyi_oku():
		return null
	if not dunya._ulkeleri_oku():
		return null
	if not dunya._bolgeleri_oku():
		return null
	if not dunya._dogrula():
		return null
	return dunya


## Verilen dünya noktasındaki bölgeyi döndürür. Nokta denizdeyse null döner.
func noktadaki_bolge(nokta: Vector2) -> Bolge:
	for bolge: Bolge in bolge_listesi:
		if bolge.icinde_mi(nokta):
			return bolge
	return null


func ulkenin_bolgeleri(ulke_id: String) -> Array[Bolge]:
	var sonuc: Array[Bolge] = []
	for bolge: Bolge in bolge_listesi:
		if bolge.sahip == ulke_id:
			sonuc.append(bolge)
	return sonuc


## İki ülke farklı bloktaysa düşmandır.
func dusman_mi(ulke_a: String, ulke_b: String) -> bool:
	if not ulkeler.has(ulke_a) or not ulkeler.has(ulke_b):
		return false
	return ulkeler[ulke_a].blok != ulkeler[ulke_b].blok


func blok_adi(blok_id: String) -> String:
	return blok_adlari.get(blok_id, blok_id)


func arazi_adi(arazi_id: String) -> String:
	if araziler.has(arazi_id):
		return araziler[arazi_id].ad
	return arazi_id


func _araziyi_oku() -> bool:
	var veri: Dictionary = VeriOkuyucu.sozluk_oku(ARAZI_DOSYASI)
	if veri.is_empty():
		return false
	for arazi_id: String in veri:
		var kayit: Dictionary = veri[arazi_id]
		araziler[arazi_id] = Arazi.sozlukten(arazi_id, kayit)
	return true


func _ulkeleri_oku() -> bool:
	var veri: Dictionary = VeriOkuyucu.sozluk_oku(ULKE_DOSYASI)
	if veri.is_empty():
		return false
	var blok_listesi: Array = veri.get("bloklar", [])
	for kayit: Dictionary in blok_listesi:
		blok_adlari[str(kayit.get("id", ""))] = str(kayit.get("ad", ""))
	var ulke_kayitlari: Array = veri.get("ulkeler", [])
	for kayit: Dictionary in ulke_kayitlari:
		var ulke: Ulke = Ulke.sozlukten(kayit)
		ulkeler[ulke.id] = ulke
		ulke_listesi.append(ulke)
	return true


func _bolgeleri_oku() -> bool:
	var veri: Dictionary = VeriOkuyucu.sozluk_oku(BOLGE_DOSYASI)
	if veri.is_empty():
		return false
	var dunya_verisi: Dictionary = veri.get("dunya", {})
	boyut = Vector2(float(dunya_verisi.get("genislik", 0)), float(dunya_verisi.get("yukseklik", 0)))
	var bolge_kayitlari: Array = veri.get("bolgeler", [])
	for kayit: Dictionary in bolge_kayitlari:
		var bolge: Bolge = Bolge.sozlukten(kayit)
		bolgeler[bolge.id] = bolge
		bolge_listesi.append(bolge)
	return true


## Verinin kendi içinde tutarlı olduğunu denetler.
func _dogrula() -> bool:
	var hatalar: PackedStringArray = PackedStringArray()
	if boyut.x <= 0.0 or boyut.y <= 0.0:
		hatalar.append("dünya boyutu eksik")
	if bolge_listesi.is_empty():
		hatalar.append("hiç bölge yok")
	if ulke_listesi.is_empty():
		hatalar.append("hiç ülke yok")

	for bolge: Bolge in bolge_listesi:
		if not ulkeler.has(bolge.sahip):
			hatalar.append("%s: bilinmeyen sahip '%s'" % [bolge.id, bolge.sahip])
		if not araziler.has(bolge.arazi):
			hatalar.append("%s: bilinmeyen arazi '%s'" % [bolge.id, bolge.arazi])
		if bolge.kose_noktalari.size() < 3:
			hatalar.append("%s: çokgeni eksik" % bolge.id)
		for komsu_id: String in bolge.komsular:
			if not bolgeler.has(komsu_id):
				hatalar.append("%s: bilinmeyen komşu '%s'" % [bolge.id, komsu_id])
			elif not bolgeler[komsu_id].komsular.has(bolge.id):
				hatalar.append("%s ile %s arasındaki komşuluk tek yönlü" % [bolge.id, komsu_id])

	for ulke: Ulke in ulke_listesi:
		if not blok_adlari.has(ulke.blok):
			hatalar.append("%s: bilinmeyen blok '%s'" % [ulke.id, ulke.blok])
		if not bolgeler.has(ulke.baskent):
			hatalar.append("%s: başkenti '%s' bulunamadı" % [ulke.id, ulke.baskent])
		elif bolgeler[ulke.baskent].sahip != ulke.id:
			hatalar.append("%s: başkenti kendi bölgesi değil" % ulke.id)
		else:
			bolgeler[ulke.baskent].baskent = true

	for hata: String in hatalar:
		push_error("Harita verisi hatalı: %s" % hata)
	return hatalar.is_empty()
