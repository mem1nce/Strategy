class_name HaritaGorunumu
extends Node2D
## Haritayı çizer. Dunya verisini yalnızca okur; hiçbir şeyi değiştirmez.
##
## İki katman vardır:
## - Bu düğüm denizi ve bölge dolgularını çizer (yalnızca sahiplik değişince yenilenir).
## - Üst katman sınırları, simgeleri, yazıları ve seçim çerçevesini çizer. Bunlar ekranda
##   hep aynı kalınlıkta ve boyutta görünsün diye yakınlık her değiştiğinde yenilenir.

const DENIZ_RENGI: Color = Color("#27445f")
const KIYI_RENGI: Color = Color("#0e1c29")
const BOLGE_SINIRI_RENGI: Color = Color(0.0, 0.0, 0.0, 0.4)
const ULKE_SINIRI_RENGI: Color = Color("#15171c")
const CEPHE_RENGI: Color = Color("#ff3b30")
const CEPHE_ALT_RENGI: Color = Color("#1a0505")
const SECIM_RENGI: Color = Color("#fff36b")
const SECIM_ALT_RENGI: Color = Color(0.0, 0.0, 0.0, 0.85)
const YAZI_RENGI: Color = Color.WHITE
const YAZI_KENAR_RENGI: Color = Color(0.0, 0.0, 0.0, 0.85)

# Kalınlıklar ve boyutlar ekran pikseli cinsindendir.
const BOLGE_SINIRI_KALINLIGI: float = 1.5
const KIYI_KALINLIGI: float = 3.0
const ULKE_SINIRI_KALINLIGI: float = 5.0
const CEPHE_KALINLIGI: float = 7.0
const CEPHE_ALT_KALINLIGI: float = 12.0
const SECIM_KALINLIGI: float = 6.0
const SECIM_ALT_KALINLIGI: float = 11.0
const BOLGE_ADI_BOYUTU: int = 30
const ULKE_ADI_BOYUTU: int = 76

## Yakınlık bu değerin altındayken bölge adları gizlenir, ülke adları görünür.
const BOLGE_ADI_ESIGI: float = 0.8

enum SinirTuru { BOLGE, KIYI, ULKE, CEPHE }


## İki bölge arasındaki (ya da bölge ile deniz arasındaki) kesintisiz sınır çizgisi.
class SinirParcasi extends RefCounted:
	var noktalar: PackedVector2Array = PackedVector2Array()
	var a: Bolge = null
	## Kıyı parçalarında null'dır.
	var b: Bolge = null


var _dunya: Dunya = null
var _yakinlik: float = 1.0
var _secili: Bolge = null
var _ust_katman: Node2D = null
var _sinir_parcalari: Array[SinirParcasi] = []
var _yazi_tipi: Font = null


func kur(dunya: Dunya) -> void:
	_dunya = dunya
	_yazi_tipi = ThemeDB.fallback_font
	_sinir_parcalarini_cikar()

	_ust_katman = Node2D.new()
	_ust_katman.name = "UstKatman"
	add_child(_ust_katman)
	_ust_katman.draw.connect(_ust_katmani_ciz)
	queue_redraw()


## Kamera yakınlığı değişince çağrılır.
func yakinligi_ayarla(yakinlik: float) -> void:
	_yakinlik = maxf(yakinlik, 0.01)
	if _ust_katman != null:
		_ust_katman.queue_redraw()


## Seçili bölgeyi değiştirir. Seçimi kaldırmak için null verilir.
func secimi_ayarla(bolge: Bolge) -> void:
	_secili = bolge
	if _ust_katman != null:
		_ust_katman.queue_redraw()


## Bölgelerin sahipliği değiştiğinde haritayı baştan boyar.
func yenile() -> void:
	queue_redraw()
	if _ust_katman != null:
		_ust_katman.queue_redraw()


func _draw() -> void:
	if _dunya == null:
		return
	draw_rect(Rect2(Vector2.ZERO, _dunya.boyut), DENIZ_RENGI)
	for bolge: Bolge in _dunya.bolge_listesi:
		draw_colored_polygon(bolge.kose_noktalari, _dolgu_rengi(bolge))


## Bölge, sahibinin rengiyle boyanır; arazi türü rengin tonunu değiştirir.
func _dolgu_rengi(bolge: Bolge) -> Color:
	var renk: Color = _dunya.ulkeler[bolge.sahip].renk
	match bolge.arazi:
		"orman":
			return renk.darkened(0.2)
		"dag":
			return renk.lerp(Color(0.42, 0.4, 0.38), 0.4).darkened(0.1)
		"sehir":
			return renk.lightened(0.18)
	return renk


# --- Sınırlar --------------------------------------------------------------

## Bölge çokgenlerinden sınır çizgilerini çıkarır. Komşu iki bölge aynı köşe noktalarını
## paylaştığı için ortak kenarlar bulunup tek bir çizgide birleştirilir.
func _sinir_parcalarini_cikar() -> void:
	_sinir_parcalari = []

	# Her kenarı hangi bölgelerin kullandığını bul.
	var kenar_bolgeleri: Dictionary[Vector4i, Array] = {}
	for bolge: Bolge in _dunya.bolge_listesi:
		var adet: int = bolge.kose_noktalari.size()
		for k: int in adet:
			var anahtar: Vector4i = _kenar_anahtari(bolge.kose_noktalari[k], bolge.kose_noktalari[(k + 1) % adet])
			if not kenar_bolgeleri.has(anahtar):
				kenar_bolgeleri[anahtar] = []
			kenar_bolgeleri[anahtar].append(bolge)

	for bolge: Bolge in _dunya.bolge_listesi:
		var noktalar: PackedVector2Array = bolge.kose_noktalari
		var adet: int = noktalar.size()

		# Her kenarın öbür yanındaki bölge (deniz ise null).
		var karsi: Array[Bolge] = []
		for k: int in adet:
			var diger: Bolge = null
			for aday: Bolge in kenar_bolgeleri[_kenar_anahtari(noktalar[k], noktalar[(k + 1) % adet])]:
				if aday != bolge:
					diger = aday
			karsi.append(diger)

		# Komşunun değiştiği bir köşeden başla ki parçalar ortadan bölünmesin.
		var baslangic: int = 0
		for k: int in adet:
			if karsi[k] != karsi[(k - 1 + adet) % adet]:
				baslangic = k
				break

		var sira: int = 0
		while sira < adet:
			var diger: Bolge = karsi[(baslangic + sira) % adet]
			var parca: SinirParcasi = SinirParcasi.new()
			parca.a = bolge
			parca.b = diger
			parca.noktalar.append(noktalar[(baslangic + sira) % adet])
			while sira < adet and karsi[(baslangic + sira) % adet] == diger:
				parca.noktalar.append(noktalar[(baslangic + sira + 1) % adet])
				sira += 1
			# Ortak sınır iki bölgede de bulunur; yalnızca birinden ekle.
			if diger == null or bolge.id < diger.id:
				_sinir_parcalari.append(parca)


static func _kenar_anahtari(p: Vector2, q: Vector2) -> Vector4i:
	var a: Vector2i = Vector2i(p.round())
	var b: Vector2i = Vector2i(q.round())
	if a.x < b.x or (a.x == b.x and a.y <= b.y):
		return Vector4i(a.x, a.y, b.x, b.y)
	return Vector4i(b.x, b.y, a.x, a.y)


## Sınırın türü o anki sahipliğe göre belirlenir; bölge el değiştirince kendiliğinden değişir.
func _sinir_turu(parca: SinirParcasi) -> SinirTuru:
	if parca.b == null:
		return SinirTuru.KIYI
	if parca.a.sahip == parca.b.sahip:
		return SinirTuru.BOLGE
	if _dunya.dusman_mi(parca.a.sahip, parca.b.sahip):
		return SinirTuru.CEPHE
	return SinirTuru.ULKE


# --- Üst katman ------------------------------------------------------------

func _ust_katmani_ciz() -> void:
	if _dunya == null:
		return
	var olcek: float = 1.0 / _yakinlik

	var turler: Array[SinirTuru] = []
	for parca: SinirParcasi in _sinir_parcalari:
		turler.append(_sinir_turu(parca))

	# İnce çizgiler altta, kalın çizgiler üstte kalsın diye türe göre sırayla çizilir.
	_sinirlari_ciz(turler, SinirTuru.BOLGE, BOLGE_SINIRI_RENGI, BOLGE_SINIRI_KALINLIGI * olcek, false)
	_sinirlari_ciz(turler, SinirTuru.KIYI, KIYI_RENGI, KIYI_KALINLIGI * olcek, false)
	_sinirlari_ciz(turler, SinirTuru.ULKE, ULKE_SINIRI_RENGI, ULKE_SINIRI_KALINLIGI * olcek, true)
	_sinirlari_ciz(turler, SinirTuru.CEPHE, CEPHE_ALT_RENGI, CEPHE_ALT_KALINLIGI * olcek, true)
	_sinirlari_ciz(turler, SinirTuru.CEPHE, CEPHE_RENGI, CEPHE_KALINLIGI * olcek, true)

	if _secili != null:
		var cerceve: PackedVector2Array = _secili.kose_noktalari.duplicate()
		cerceve.append(cerceve[0])
		cerceve.append(cerceve[1])
		_ust_katman.draw_polyline(cerceve, SECIM_ALT_RENGI, SECIM_ALT_KALINLIGI * olcek, true)
		_ust_katman.draw_polyline(cerceve, SECIM_RENGI, SECIM_KALINLIGI * olcek, true)

	var adlar_gorunur: bool = _yakinlik >= BOLGE_ADI_ESIGI
	for bolge: Bolge in _dunya.bolge_listesi:
		_ust_katman.draw_set_transform(bolge.merkez, 0.0, Vector2(olcek, olcek))
		var simgeli: bool = bolge.baskent or bolge.arazi != "ova"
		if adlar_gorunur:
			if simgeli:
				_simge_ciz(bolge, Vector2(0.0, -20.0))
				_yazi_ciz(bolge.ad, 34.0, BOLGE_ADI_BOYUTU)
			else:
				_yazi_ciz(bolge.ad, 11.0, BOLGE_ADI_BOYUTU)
		elif simgeli:
			_simge_ciz(bolge, Vector2.ZERO)

	if not adlar_gorunur:
		for ulke: Ulke in _dunya.ulke_listesi:
			_ust_katman.draw_set_transform(_ulke_merkezi(ulke), 0.0, Vector2(olcek, olcek))
			_yazi_ciz(ulke.ad, ULKE_ADI_BOYUTU * 0.35, ULKE_ADI_BOYUTU)

	_ust_katman.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _sinirlari_ciz(turler: Array[SinirTuru], tur: SinirTuru, renk: Color, kalinlik: float, yuvarlak_uc: bool) -> void:
	for i: int in _sinir_parcalari.size():
		if turler[i] != tur:
			continue
		var noktalar: PackedVector2Array = _sinir_parcalari[i].noktalar
		_ust_katman.draw_polyline(noktalar, renk, kalinlik, true)
		if yuvarlak_uc:
			# Kalın çizgilerin birleştiği köşelerde boşluk kalmasın.
			_ust_katman.draw_circle(noktalar[0], kalinlik * 0.5, renk)
			_ust_katman.draw_circle(noktalar[noktalar.size() - 1], kalinlik * 0.5, renk)


## Ülkenin elindeki bölgelerin ortası; ülke adı buraya yazılır.
func _ulke_merkezi(ulke: Ulke) -> Vector2:
	var toplam: Vector2 = Vector2.ZERO
	var adet: int = 0
	for bolge: Bolge in _dunya.bolge_listesi:
		if bolge.sahip == ulke.id:
			toplam += bolge.merkez
			adet += 1
	if adet == 0:
		return Vector2.ZERO
	return toplam / float(adet)


## Yazıyı yatayda ortalayarak, okunaklı olsun diye koyu kenarlıkla çizer.
## `taban_y`, yazının oturduğu çizginin dikey konumudur.
func _yazi_ciz(metin: String, taban_y: float, boyut: int) -> void:
	var genislik: float = _yazi_tipi.get_string_size(metin, HORIZONTAL_ALIGNMENT_LEFT, -1.0, boyut).x
	var konum: Vector2 = Vector2(-genislik * 0.5, taban_y)
	_ust_katman.draw_string_outline(_yazi_tipi, konum, metin, HORIZONTAL_ALIGNMENT_LEFT, -1.0, boyut,
			maxi(4, roundi(boyut * 0.26)), YAZI_KENAR_RENGI)
	_ust_katman.draw_string(_yazi_tipi, konum, metin, HORIZONTAL_ALIGNMENT_LEFT, -1.0, boyut, YAZI_RENGI)


func _simge_ciz(bolge: Bolge, konum: Vector2) -> void:
	if bolge.baskent:
		_yildiz_ciz(konum)
		return
	match bolge.arazi:
		"dag":
			_dag_ciz(konum)
		"orman":
			_orman_ciz(konum)
		"sehir":
			_sehir_ciz(konum)


func _yildiz_ciz(konum: Vector2) -> void:
	var noktalar: PackedVector2Array = PackedVector2Array()
	for k: int in 10:
		var yaricap: float = 19.0 if k % 2 == 0 else 8.0
		noktalar.append(konum + Vector2.UP.rotated(TAU * float(k) / 10.0) * yaricap)
	_ust_katman.draw_colored_polygon(noktalar, Color("#ffd84a"))
	noktalar.append(noktalar[0])
	noktalar.append(noktalar[1])
	_ust_katman.draw_polyline(noktalar, Color("#201500"), 2.5, true)


func _dag_ciz(konum: Vector2) -> void:
	var koyu: Color = Color(0.16, 0.14, 0.13, 0.9)
	_ust_katman.draw_colored_polygon(PackedVector2Array([
		konum + Vector2(-19.0, 11.0), konum + Vector2(-6.0, -13.0), konum + Vector2(7.0, 11.0),
	]), koyu)
	_ust_katman.draw_colored_polygon(PackedVector2Array([
		konum + Vector2(1.0, 11.0), konum + Vector2(10.0, -5.0), konum + Vector2(19.0, 11.0),
	]), koyu)
	# Zirvedeki kar.
	_ust_katman.draw_colored_polygon(PackedVector2Array([
		konum + Vector2(-9.8, -6.0), konum + Vector2(-6.0, -13.0), konum + Vector2(-2.2, -6.0),
	]), Color(1.0, 1.0, 1.0, 0.9))


func _orman_ciz(konum: Vector2) -> void:
	var yesil: Color = Color(0.05, 0.22, 0.1, 0.9)
	_ust_katman.draw_colored_polygon(PackedVector2Array([
		konum + Vector2(-17.0, 10.0), konum + Vector2(-8.0, -12.0), konum + Vector2(1.0, 10.0),
	]), yesil)
	_ust_katman.draw_colored_polygon(PackedVector2Array([
		konum + Vector2(0.0, 12.0), konum + Vector2(9.0, -8.0), konum + Vector2(18.0, 12.0),
	]), yesil)


func _sehir_ciz(konum: Vector2) -> void:
	var koyu: Color = Color(0.1, 0.1, 0.12, 0.9)
	_ust_katman.draw_rect(Rect2(konum + Vector2(-16.0, -2.0), Vector2(10.0, 13.0)), koyu)
	_ust_katman.draw_rect(Rect2(konum + Vector2(-5.0, -13.0), Vector2(11.0, 24.0)), koyu)
	_ust_katman.draw_rect(Rect2(konum + Vector2(7.0, -6.0), Vector2(9.0, 17.0)), koyu)
