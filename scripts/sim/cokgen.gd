class_name Cokgen
extends RefCounted
## Haritadaki tek bir toprak parçası: bir çokgen ve ait olduğu bölge.
##
## Harita "çokgen -> bölge -> sahip ülke" mantığıyla çalışır. Bir bölge birden çok
## çokgenden oluşabilir (anakara ve adalar). Çokgenin rengi bölgesinin sahibinden gelir;
## bölge el değiştirince çokgenleri de yeni sahibin rengini alır.

var noktalar: PackedVector2Array = PackedVector2Array()
## Bu parçanın ait olduğu bölgenin id'si.
var bolge_id: String = ""
var alan: float = 0.0
## Çokgeni saran dikdörtgen; dokunulan parçayı hızlı bulmak için.
var sinir_kutusu: Rect2 = Rect2()


## JSON'daki [[x, y], ...] listesinden çokgen kurar.
static func listeden(nokta_listesi: Array, bolgenin_idsi: String) -> Cokgen:
	var cokgen: Cokgen = Cokgen.new()
	cokgen.bolge_id = bolgenin_idsi
	cokgen.noktalar = noktalara_cevir(nokta_listesi)
	if cokgen.noktalar.is_empty():
		return cokgen

	var kutu: Rect2 = Rect2(cokgen.noktalar[0], Vector2.ZERO)
	var capraz_toplam: float = 0.0
	var adet: int = cokgen.noktalar.size()
	for i: int in adet:
		kutu = kutu.expand(cokgen.noktalar[i])
		capraz_toplam += cokgen.noktalar[i].cross(cokgen.noktalar[(i + 1) % adet])
	cokgen.sinir_kutusu = kutu
	cokgen.alan = absf(capraz_toplam) * 0.5
	return cokgen


static func noktalara_cevir(nokta_listesi: Array) -> PackedVector2Array:
	var sonuc: PackedVector2Array = PackedVector2Array()
	for nokta: Variant in nokta_listesi:
		sonuc.append(noktaya_cevir(nokta))
	return sonuc


static func noktaya_cevir(deger: Variant) -> Vector2:
	if not deger is Array:
		return Vector2.ZERO
	var cift: Array = deger
	if cift.size() < 2:
		return Vector2.ZERO
	return Vector2(float(cift[0]), float(cift[1]))


## Verilen nokta bu çokgenin içinde mi?
func icinde_mi(nokta: Vector2) -> bool:
	if not sinir_kutusu.has_point(nokta):
		return false
	return Geometry2D.is_point_in_polygon(nokta, noktalar)


## Noktanın çokgenin kenarına olan en kısa uzaklığı.
func kenara_uzaklik(nokta: Vector2) -> float:
	var en_yakin: float = INF
	var adet: int = noktalar.size()
	for i: int in adet:
		var yakin_nokta: Vector2 = Geometry2D.get_closest_point_to_segment(nokta, noktalar[i], noktalar[(i + 1) % adet])
		en_yakin = minf(en_yakin, nokta.distance_squared_to(yakin_nokta))
	return sqrt(en_yakin)
