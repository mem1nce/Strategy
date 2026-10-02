class_name Dunya
extends RefCounted
## Dünya haritasının verisi: ülkeler ve toprak parçaları (çokgenler).
##
## data/world.json dosyasından kurulur. Görsel katman bunu yalnızca okur.

const DUNYA_DOSYASI: String = "res://data/world.json"

## Haritanın birim cinsinden boyutu.
var boyut: Vector2 = Vector2.ZERO
var ulkeler: Dictionary[String, Ulke] = {}
var ulke_listesi: Array[Ulke] = []
## Bütün toprak parçaları, büyükten küçüğe sıralı. Bu sırayla çizilince küçük
## parçalar üstte kalır (ör. Lesotho, Güney Afrika'nın üstünde).
var cokgenler: Array[Cokgen] = []


## Veri dosyasını okuyup dünyayı kurar. Veri hatalıysa nedenini yazar ve null döndürür.
static func yukle(yol: String = DUNYA_DOSYASI) -> Dunya:
	var veri: Dictionary = VeriOkuyucu.sozluk_oku(yol)
	if veri.is_empty():
		return null
	var dunya: Dunya = Dunya.new()
	dunya.boyut = Vector2(float(veri.get("genislik", 0)), float(veri.get("yukseklik", 0)))

	var ulke_kayitlari: Array = veri.get("ulkeler", [])
	for kayit: Dictionary in ulke_kayitlari:
		var ulke: Ulke = Ulke.sozlukten(kayit)
		dunya.ulkeler[ulke.id] = ulke
		dunya.ulke_listesi.append(ulke)
		var cokgen_listesi: Array = kayit.get("cokgenler", [])
		for nokta_listesi: Array in cokgen_listesi:
			var cokgen: Cokgen = Cokgen.listeden(nokta_listesi, ulke.id)
			if cokgen.noktalar.size() >= 3:
				dunya.cokgenler.append(cokgen)
	dunya.cokgenler.sort_custom(func(a: Cokgen, b: Cokgen) -> bool: return a.alan > b.alan)

	if not dunya._dogrula():
		return null
	return dunya


## Verilen noktayı içeren toprak parçasını döndürür; nokta denizdeyse null döner.
## İç içe parçalarda en küçüğü seçilir (Lesotho'ya dokununca Güney Afrika gelmez).
func noktadaki_cokgen(nokta: Vector2) -> Cokgen:
	for i: int in range(cokgenler.size() - 1, -1, -1):
		if cokgenler[i].icinde_mi(nokta):
			return cokgenler[i]
	return null


## Noktaya en çok `azami_uzaklik` kadar uzaktaki en yakın toprak parçasını döndürür.
## Küçük ülkelere dokunmayı kolaylaştırmak içindir. Yakında parça yoksa null döner.
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


func ulkenin_cokgenleri(ulke_id: String) -> Array[Cokgen]:
	var sonuc: Array[Cokgen] = []
	for cokgen: Cokgen in cokgenler:
		if cokgen.sahip == ulke_id:
			sonuc.append(cokgen)
	return sonuc


## Ülkenin en büyük toprak parçası (anakarası). Ülkenin toprağı yoksa null döner.
func ulkenin_anakarasi(ulke_id: String) -> Cokgen:
	# Liste büyükten küçüğe sıralı olduğu için ilk bulunan en büyüğüdür.
	for cokgen: Cokgen in cokgenler:
		if cokgen.sahip == ulke_id:
			return cokgen
	return null


## Ülkenin komşularının adlarını alfabe sırasıyla döndürür.
func komsu_adlari(ulke_id: String) -> PackedStringArray:
	var adlar: PackedStringArray = PackedStringArray()
	if not ulkeler.has(ulke_id):
		return adlar
	for komsu_id: String in ulkeler[ulke_id].komsular:
		if ulkeler.has(komsu_id):
			adlar.append(ulkeler[komsu_id].ad)
	adlar.sort()
	return adlar


## Verinin kendi içinde tutarlı olduğunu denetler.
func _dogrula() -> bool:
	var hatalar: PackedStringArray = PackedStringArray()
	if boyut.x <= 0.0 or boyut.y <= 0.0:
		hatalar.append("harita boyutu eksik")
	if ulke_listesi.is_empty():
		hatalar.append("hiç ülke yok")
	if cokgenler.is_empty():
		hatalar.append("hiç çokgen yok")
	for ulke: Ulke in ulke_listesi:
		if ulke.id == "":
			hatalar.append("id'si olmayan bir ülke var")
		for komsu_id: String in ulke.komsular:
			if not ulkeler.has(komsu_id):
				hatalar.append("%s: bilinmeyen komşu '%s'" % [ulke.id, komsu_id])
			elif not ulkeler[komsu_id].komsular.has(ulke.id):
				hatalar.append("%s ile %s arasındaki komşuluk tek yönlü" % [ulke.id, komsu_id])
	for cokgen: Cokgen in cokgenler:
		if not ulkeler.has(cokgen.sahip):
			hatalar.append("sahibi bilinmeyen çokgen: '%s'" % cokgen.sahip)

	for hata: String in hatalar:
		push_error("Dünya verisi hatalı: %s" % hata)
	return hatalar.is_empty()
