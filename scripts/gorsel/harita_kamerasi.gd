class_name HaritaKamerasi
extends Camera2D
## Harita kamerası: tek parmakla kaydırma, iki parmakla yakınlaştırma, dokunuşu ayırt etme.
##
## Bilgisayarda "Emulate Touch From Mouse" ayarı sayesinde fareyle sürükleme tek parmak
## gibi çalışır; ayrıca fare tekerleği yakınlaştırır. Arayüze gelen dokunuşlar buraya
## ulaşmaz, çünkü yalnızca arayüzün kullanmadığı girdiler (_unhandled_input) dinlenir.

## Parmak kaydırmadan kaldırıldığında, dokunulan dünya noktasıyla yayılır.
signal dokunuldu(dunya_konumu: Vector2)
signal yakinlik_degisti(yakinlik: float)

## Parmak bundan az oynadıysa dokunuş, fazla oynadıysa kaydırma sayılır (piksel).
const DOKUNMA_ESIGI: float = 12.0
const AZAMI_YAKINLIK: float = 2.5
const TEKERLEK_CARPANI: float = 1.12

var _alan: Rect2 = Rect2()
var _asgari_yakinlik: float = 0.1
## Ekrandaki parmaklar: parmak sırası -> ekran konumu.
var _parmaklar: Dictionary[int, Vector2] = {}
var _baslangic: Vector2 = Vector2.ZERO
## Bu dokunuş sırasında parmak eşikten fazla oynadı mı?
var _kaydirma: bool = false
## Bu dokunuş sırasında ekrana ikinci bir parmak değdi mi?
var _cok_parmak: bool = false


## Kameranın gezebileceği alanı ayarlar ve haritanın tamamını gösterir.
func kur(alan: Rect2) -> void:
	_alan = alan
	position = alan.get_center()
	get_viewport().size_changed.connect(_gorunum_degisti)
	_asgari_yakinligi_hesapla()
	zoom = Vector2(_asgari_yakinlik, _asgari_yakinlik)
	_sinirla()
	yakinlik_degisti.emit(zoom.x)


func yakinlik() -> float:
	return zoom.x


func ekrandan_dunyaya(ekran_konumu: Vector2) -> Vector2:
	return position + (ekran_konumu - get_viewport_rect().size * 0.5) / zoom.x


func _unhandled_input(olay: InputEvent) -> void:
	if olay is InputEventScreenTouch:
		_dokunma(olay as InputEventScreenTouch)
	elif olay is InputEventScreenDrag:
		_surukleme(olay as InputEventScreenDrag)
	elif olay is InputEventMouseButton:
		_tekerlek(olay as InputEventMouseButton)


func _dokunma(olay: InputEventScreenTouch) -> void:
	if olay.pressed:
		if _parmaklar.is_empty():
			_baslangic = olay.position
			_kaydirma = false
			_cok_parmak = false
		else:
			_cok_parmak = true
		_parmaklar[olay.index] = olay.position
		return

	if not _parmaklar.has(olay.index):
		return
	_parmaklar.erase(olay.index)
	# Yalnızca hiç kaydırılmamış tek parmak dokunuşu seçim sayılır.
	if _parmaklar.is_empty() and not _kaydirma and not _cok_parmak:
		dokunuldu.emit(ekrandan_dunyaya(olay.position))


func _surukleme(olay: InputEventScreenDrag) -> void:
	if not _parmaklar.has(olay.index):
		return
	var onceki: Vector2 = _parmaklar[olay.index]
	_parmaklar[olay.index] = olay.position

	if _parmaklar.size() == 1:
		if not _kaydirma and olay.position.distance_to(_baslangic) >= DOKUNMA_ESIGI:
			_kaydirma = true
		if _kaydirma or _cok_parmak:
			position -= (olay.position - onceki) / zoom.x
			_sinirla()
	elif _parmaklar.size() == 2:
		var diger: Vector2 = olay.position
		for sira: int in _parmaklar:
			if sira != olay.index:
				diger = _parmaklar[sira]
		var onceki_orta: Vector2 = (onceki + diger) * 0.5
		var yeni_orta: Vector2 = (olay.position + diger) * 0.5
		var onceki_mesafe: float = onceki.distance_to(diger)
		var yeni_mesafe: float = olay.position.distance_to(diger)
		# İki parmağın ortası haritada aynı noktanın üstünde kalsın.
		position -= (yeni_orta - onceki_orta) / zoom.x
		if onceki_mesafe > 1.0:
			_yakinlastir(yeni_mesafe / onceki_mesafe, yeni_orta)
		else:
			_sinirla()


func _tekerlek(olay: InputEventMouseButton) -> void:
	if not olay.pressed:
		return
	if olay.button_index == MOUSE_BUTTON_WHEEL_UP:
		_yakinlastir(TEKERLEK_CARPANI, olay.position)
	elif olay.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		_yakinlastir(1.0 / TEKERLEK_CARPANI, olay.position)


## Yakınlığı çarpar; `ekran_noktasi`nın altındaki harita noktası yerinde kalır.
func _yakinlastir(carpan: float, ekran_noktasi: Vector2) -> void:
	var yeni: float = clampf(zoom.x * carpan, _asgari_yakinlik, AZAMI_YAKINLIK)
	if is_equal_approx(yeni, zoom.x):
		_sinirla()
		return
	var once: Vector2 = ekrandan_dunyaya(ekran_noktasi)
	zoom = Vector2(yeni, yeni)
	position += once - ekrandan_dunyaya(ekran_noktasi)
	_sinirla()
	yakinlik_degisti.emit(yeni)


## Kameranın harita dışını göstermesini engeller.
func _sinirla() -> void:
	var yari: Vector2 = get_viewport_rect().size * 0.5 / zoom.x
	position.x = _eksende_sinirla(position.x, _alan.position.x + yari.x, _alan.end.x - yari.x)
	position.y = _eksende_sinirla(position.y, _alan.position.y + yari.y, _alan.end.y - yari.y)


static func _eksende_sinirla(deger: float, alt: float, ust: float) -> float:
	if alt > ust:
		return (alt + ust) * 0.5
	return clampf(deger, alt, ust)


## En uzak görünümde bile ekran haritayla dolu kalsın diye alt sınırı hesaplar.
func _asgari_yakinligi_hesapla() -> void:
	var ekran: Vector2 = get_viewport_rect().size
	_asgari_yakinlik = minf(maxf(ekran.x / _alan.size.x, ekran.y / _alan.size.y), AZAMI_YAKINLIK)


func _gorunum_degisti() -> void:
	_asgari_yakinligi_hesapla()
	if zoom.x < _asgari_yakinlik:
		zoom = Vector2(_asgari_yakinlik, _asgari_yakinlik)
		yakinlik_degisti.emit(zoom.x)
	_sinirla()
