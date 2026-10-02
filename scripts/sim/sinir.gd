class_name Sinir
extends RefCounted
## İki bölge arasındaki (ya da bir bölge ile deniz arasındaki) kesintisiz sınır çizgisi.
##
## Sınırın türü saklanmaz; iki yanındaki bölgelerin o anki sahibine bakılarak anlaşılır.
## Böylece bir bölge el değiştirince ülke sınırı kendiliğinden yer değiştirir.

## Çizginin bir yanındaki bölgenin id'si.
var a: String = ""
## Öbür yanındaki bölgenin id'si. Kıyı çizgilerinde boştur.
var b: String = ""
var noktalar: PackedVector2Array = PackedVector2Array()


static func sozlukten(veri: Dictionary) -> Sinir:
	var sinir: Sinir = Sinir.new()
	sinir.a = str(veri.get("a", ""))
	sinir.b = str(veri.get("b", ""))
	var nokta_listesi: Array = veri.get("noktalar", [])
	sinir.noktalar = Cokgen.noktalara_cevir(nokta_listesi)
	return sinir


func kiyi_mi() -> bool:
	return b == ""


## Bu sınır verilen bölgeye değiyor mu?
func bolgeye_degiyor_mu(bolge_id: String) -> bool:
	return a == bolge_id or b == bolge_id
