class_name Bolge
extends RefCounted
## Haritadaki tek bir bölgenin verisi.

var id: String = ""
var ad: String = ""
## Bölgenin şu anki sahibi olan ülkenin id'si. Oyun içinde değişebilir.
var sahip: String = ""
var arazi: String = ""
var komsular: PackedStringArray = PackedStringArray()
var zafer_puani: int = 0
## Günlük gelirler.
var insan_gucu: int = 0
var celik: int = 0
var petrol: int = 0
var fabrika: int = 0
## Simge ve yazıların çizileceği nokta.
var merkez: Vector2 = Vector2.ZERO
var kose_noktalari: PackedVector2Array = PackedVector2Array()
## Çokgeni saran dikdörtgen; dokunulan bölgeyi hızlı bulmak için.
var sinir_kutusu: Rect2 = Rect2()
## Bir ülkenin başkenti mi? Ülke verisinden doldurulur.
var baskent: bool = false


static func sozlukten(veri: Dictionary) -> Bolge:
	var bolge: Bolge = Bolge.new()
	bolge.id = str(veri.get("id", ""))
	bolge.ad = str(veri.get("ad", bolge.id))
	bolge.sahip = str(veri.get("sahip", ""))
	bolge.arazi = str(veri.get("arazi", ""))
	bolge.zafer_puani = int(veri.get("zafer_puani", 0))
	bolge.insan_gucu = int(veri.get("insan_gucu", 0))
	bolge.celik = int(veri.get("celik", 0))
	bolge.petrol = int(veri.get("petrol", 0))
	bolge.fabrika = int(veri.get("fabrika", 0))

	var komsu_listesi: Array = veri.get("komsular", [])
	for komsu: Variant in komsu_listesi:
		bolge.komsular.append(str(komsu))

	bolge.merkez = _noktaya_cevir(veri.get("merkez", []))
	var kose_listesi: Array = veri.get("kose_noktalari", [])
	for kose: Variant in kose_listesi:
		bolge.kose_noktalari.append(_noktaya_cevir(kose))

	if not bolge.kose_noktalari.is_empty():
		var kutu: Rect2 = Rect2(bolge.kose_noktalari[0], Vector2.ZERO)
		for nokta: Vector2 in bolge.kose_noktalari:
			kutu = kutu.expand(nokta)
		bolge.sinir_kutusu = kutu
	return bolge


## Verilen dünya noktası bu bölgenin içinde mi?
func icinde_mi(nokta: Vector2) -> bool:
	if not sinir_kutusu.has_point(nokta):
		return false
	return Geometry2D.is_point_in_polygon(nokta, kose_noktalari)


static func _noktaya_cevir(deger: Variant) -> Vector2:
	if not deger is Array:
		return Vector2.ZERO
	var cift: Array = deger
	if cift.size() < 2:
		return Vector2.ZERO
	return Vector2(float(cift[0]), float(cift[1]))
