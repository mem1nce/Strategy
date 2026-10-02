class_name HaritaGorunumu
extends Node2D
## Dünya haritasını çizer. Dunya verisini yalnızca okur; hiçbir şeyi değiştirmez.
##
## Harita "çokgen + sahip ülke" mantığıyla çizilir: her çokgen, sahibi olan ülkenin
## rengini alır. İleride ülkeler bölgelere ayrıldığında da aynı kod çalışır.
##
## İki katman vardır:
## - Bu düğüm bütün çokgen dolgularını tek bir ağ (mesh) olarak çizer.
## - Üst katman sınırları, çerçeveleri ve ülke adlarını çizer. Bunlar ekranda hep aynı
##   kalınlıkta ve boyutta görünsün diye yakınlık her değiştiğinde yenilenir.

const DENIZ_RENGI: Color = Color("#1e2a36")
## Ülkelerin renk indeksine (1-9) karşılık gelen dokuz sakin renk.
const PALET: Array[Color] = [
	Color("#c97b6b"), Color("#d9a066"), Color("#d8c878"),
	Color("#9dbb6f"), Color("#6fae8f"), Color("#6fa8b8"),
	Color("#7f8fc4"), Color("#a584bd"), Color("#c487a6"),
]
const SINIR_RENGI: Color = Color(0.07, 0.09, 0.11, 0.85)
const SECIM_RENGI: Color = Color("#fff36b")
const OYUNCU_RENGI: Color = Color.WHITE
const CERCEVE_ALT_RENGI: Color = Color(0.0, 0.0, 0.0, 0.85)
const YAZI_RENGI: Color = Color.WHITE
const YAZI_KENAR_RENGI: Color = Color(0.0, 0.0, 0.0, 0.8)

# Kalınlıklar ve boyutlar ekran pikseli cinsindendir.
const SINIR_KALINLIGI: float = 1.5
const SECIM_KALINLIGI: float = 4.0
const OYUNCU_KALINLIGI: float = 6.0
## Çerçevelerin altındaki koyu şeridin, çerçeveden ne kadar taştığı.
const CERCEVE_ALT_PAYI: float = 5.0

const ASGARI_YAZI_BOYUTU: int = 24
const AZAMI_YAZI_BOYUTU: int = 52
## Yazı boyutu, ülkenin ekrandaki büyüklüğünün bu oranı kadardır.
const YAZI_ORANI: float = 0.16
## Ülke adı, ülkenin ekrandaki büyüklüğünün bu katından genişse gizlenir.
const YAZI_SIGMA_ORANI: float = 1.5
## Ülke ekranda bundan büyükse adı sığmasa da gösterilir (piksel).
const HER_ZAMAN_YAZ_ESIGI: float = 100.0
## İki ülke adı arasında bırakılan en az boşluk (piksel).
const YAZI_ARALIGI: float = 6.0

## Dolgusu çizilemeyen çokgenlerin sahibi olan ülkelerin adları.
var ucgenlenemeyenler: PackedStringArray = PackedStringArray()

var _dunya: Dunya = null
var _yakinlik: float = 1.0
## Seçili ülkenin id'si; seçim yoksa boş.
var _secili: String = ""
## Oyuncunun ülkesinin id'si; seçilmediyse boş.
var _oyuncu: String = ""
var _ust_katman: Node2D = null
var _yazi_tipi: Font = null
var _ag: ArrayMesh = null
## Her çokgenin üçgen indisleri (Dunya.cokgenler ile aynı sırada). Üçgenlenemeyenlerde boştur.
var _ucgenler: Array[PackedInt32Array] = []
## Her çokgenin kapalı sınır çizgisi.
var _cerceveler: Array[PackedVector2Array] = []
## Ülke id'si -> anakarasının yaklaşık genişliği (harita birimi). Ad yazarken kullanılır.
var _ulke_buyuklugu: Dictionary[String, float] = {}
## Ülkeler, anakarası büyük olandan küçüğe. Adlar bu sırayla yazılır.
var _yazi_sirasi: Array[Ulke] = []


## Ülkenin haritadaki rengi.
static func ulke_rengi(ulke: Ulke) -> Color:
	return PALET[posmod(ulke.renk_indeksi - 1, PALET.size())]


func kur(dunya: Dunya) -> void:
	_dunya = dunya
	_yazi_tipi = ThemeDB.fallback_font
	RenderingServer.set_default_clear_color(DENIZ_RENGI)

	_cokgenleri_hazirla()
	_agi_kur()

	_ust_katman = Node2D.new()
	_ust_katman.name = "UstKatman"
	add_child(_ust_katman)
	_ust_katman.draw.connect(_ust_katmani_ciz)
	queue_redraw()


## Kamera yakınlığı değişince çağrılır.
func yakinligi_ayarla(yakinlik: float) -> void:
	_yakinlik = maxf(yakinlik, 0.01)
	_ust_katmani_yenile()


## Seçili ülkeyi değiştirir. Seçimi kaldırmak için boş metin verilir.
func secimi_ayarla(ulke_id: String) -> void:
	_secili = ulke_id
	_ust_katmani_yenile()


## Oyuncunun ülkesini belirgin bir çerçeveyle işaretler.
func oyuncuyu_ayarla(ulke_id: String) -> void:
	_oyuncu = ulke_id
	_ust_katmani_yenile()


## Çokgenlerin sahipliği değiştiğinde haritayı baştan boyar.
func yenile() -> void:
	_agi_kur()
	queue_redraw()
	_ust_katmani_yenile()


func _ust_katmani_yenile() -> void:
	if _ust_katman != null:
		_ust_katman.queue_redraw()


func _draw() -> void:
	if _ag != null:
		draw_mesh(_ag, null)


# --- Hazırlık --------------------------------------------------------------

## Her çokgeni üçgenlere böler ve sınır çizgisini hazırlar. Üçgenlenemeyen çokgen
## oyunu durdurmaz: uyarı yazılır, dolgusu atlanır, sınırı yine çizilir.
func _cokgenleri_hazirla() -> void:
	_ucgenler = []
	_cerceveler = []
	_ulke_buyuklugu = {}
	_yazi_sirasi = []
	ucgenlenemeyenler = PackedStringArray()

	for cokgen: Cokgen in _dunya.cokgenler:
		var ucgenler: PackedInt32Array = Geometry2D.triangulate_polygon(cokgen.noktalar)
		if ucgenler.is_empty():
			var ad: String = _dunya.ulkeler[cokgen.sahip].ad
			ucgenlenemeyenler.append(ad)
			push_warning("Harita: %s ülkesinin bir çokgeni üçgenlenemedi (%d nokta); dolgusu çizilmeyecek."
					% [ad, cokgen.noktalar.size()])
		_ucgenler.append(ucgenler)

		var cerceve: PackedVector2Array = cokgen.noktalar.duplicate()
		cerceve.append(cerceve[0])
		_cerceveler.append(cerceve)

		# Çokgenler büyükten küçüğe sıralı olduğu için ülkenin ilk görülen parçası anakarasıdır.
		if not _ulke_buyuklugu.has(cokgen.sahip):
			_ulke_buyuklugu[cokgen.sahip] = sqrt(cokgen.alan)
			_yazi_sirasi.append(_dunya.ulkeler[cokgen.sahip])


## Bütün dolguları tek bir ağda toplar. Üçgenler çokgen sırasıyla (büyükten küçüğe)
## eklendiği için küçük ülkeler büyüklerin üstünde kalır.
func _agi_kur() -> void:
	var koseler: PackedVector2Array = PackedVector2Array()
	var renkler: PackedColorArray = PackedColorArray()
	var indisler: PackedInt32Array = PackedInt32Array()

	for i: int in _dunya.cokgenler.size():
		if _ucgenler[i].is_empty():
			continue
		var cokgen: Cokgen = _dunya.cokgenler[i]
		var renk: Color = ulke_rengi(_dunya.ulkeler[cokgen.sahip])
		var taban: int = koseler.size()
		koseler.append_array(cokgen.noktalar)
		for n: int in cokgen.noktalar.size():
			renkler.append(renk)
		for indis: int in _ucgenler[i]:
			indisler.append(taban + indis)

	if indisler.is_empty():
		_ag = null
		return
	var diziler: Array = []
	diziler.resize(Mesh.ARRAY_MAX)
	diziler[Mesh.ARRAY_VERTEX] = koseler
	diziler[Mesh.ARRAY_COLOR] = renkler
	diziler[Mesh.ARRAY_INDEX] = indisler
	_ag = ArrayMesh.new()
	_ag.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, diziler)


# --- Üst katman ------------------------------------------------------------

func _ust_katmani_ciz() -> void:
	if _dunya == null:
		return
	var olcek: float = 1.0 / _yakinlik

	for cerceve: PackedVector2Array in _cerceveler:
		_ust_katman.draw_polyline(cerceve, SINIR_RENGI, SINIR_KALINLIGI * olcek, true)

	_ulke_cercevesi_ciz(_oyuncu, OYUNCU_RENGI, OYUNCU_KALINLIGI * olcek, olcek)
	_ulke_cercevesi_ciz(_secili, SECIM_RENGI, SECIM_KALINLIGI * olcek, olcek)

	# Adlar üst üste binmesin: önce oyuncunun ve seçili ülkenin, sonra büyükten küçüğe
	# diğerlerinin adı yazılır; daha önce yazılmış bir ada çarpan ad atlanır.
	var dolu_alanlar: Array[Rect2] = []
	for oncelikli_id: String in [_oyuncu, _secili]:
		if _dunya.ulkeler.has(oncelikli_id):
			_ulke_adini_ciz(_dunya.ulkeler[oncelikli_id], olcek, dolu_alanlar, true)
	for ulke: Ulke in _yazi_sirasi:
		if ulke.id != _oyuncu and ulke.id != _secili:
			_ulke_adini_ciz(ulke, olcek, dolu_alanlar, false)
	_ust_katman.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Verilen ülkenin bütün parçalarının çevresine, koyu bir şeridin üstüne parlak çerçeve çizer.
func _ulke_cercevesi_ciz(ulke_id: String, renk: Color, kalinlik: float, olcek: float) -> void:
	if ulke_id == "":
		return
	for i: int in _dunya.cokgenler.size():
		if _dunya.cokgenler[i].sahip == ulke_id:
			_ust_katman.draw_polyline(_cerceveler[i], CERCEVE_ALT_RENGI, kalinlik + CERCEVE_ALT_PAYI * olcek, true)
	for i: int in _dunya.cokgenler.size():
		if _dunya.cokgenler[i].sahip == ulke_id:
			_ust_katman.draw_polyline(_cerceveler[i], renk, kalinlik, true)


## Ülke adını etiket noktasına yazar. Uzaktan yalnızca büyük ülkelerin adı görünür;
## yakınlaştıkça ülke ekranda büyür ve adı sığmaya başlar. `zorunlu` ise ad her
## koşulda yazılır. Yazılan adın kapladığı yer `dolu_alanlar` listesine eklenir.
func _ulke_adini_ciz(ulke: Ulke, olcek: float, dolu_alanlar: Array[Rect2], zorunlu: bool) -> void:
	if not _ulke_buyuklugu.has(ulke.id):
		return
	var ekran_buyuklugu: float = _ulke_buyuklugu[ulke.id] * _yakinlik
	# Yazı tipi her boyut için ayrı hazırlandığından boyut 4'ün katlarına yuvarlanır.
	var boyut: int = clampi(int(snappedf(ekran_buyuklugu * YAZI_ORANI, 4.0)), ASGARI_YAZI_BOYUTU, AZAMI_YAZI_BOYUTU)
	var genislik: float = _yazi_tipi.get_string_size(ulke.ad, HORIZONTAL_ALIGNMENT_LEFT, -1.0, boyut).x
	# Adın ekranda kaplayacağı yer (kamera kaymasından bağımsız, yalnızca yakınlığa bağlı).
	var alan: Rect2 = Rect2(ulke.etiket * _yakinlik + Vector2(-genislik * 0.5, -boyut * 0.65),
			Vector2(genislik, boyut)).grow(YAZI_ARALIGI)
	if not zorunlu:
		if genislik > ekran_buyuklugu * YAZI_SIGMA_ORANI and ekran_buyuklugu < HER_ZAMAN_YAZ_ESIGI:
			return
		for dolu: Rect2 in dolu_alanlar:
			if dolu.intersects(alan):
				return
	dolu_alanlar.append(alan)

	_ust_katman.draw_set_transform(ulke.etiket, 0.0, Vector2(olcek, olcek))
	var konum: Vector2 = Vector2(-genislik * 0.5, boyut * 0.35)
	_ust_katman.draw_string_outline(_yazi_tipi, konum, ulke.ad, HORIZONTAL_ALIGNMENT_LEFT, -1.0, boyut,
			maxi(4, roundi(boyut * 0.26)), YAZI_KENAR_RENGI)
	_ust_katman.draw_string(_yazi_tipi, konum, ulke.ad, HORIZONTAL_ALIGNMENT_LEFT, -1.0, boyut, YAZI_RENGI)
