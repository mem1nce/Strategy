class_name Arayuz
extends CanvasLayer
## Haritanın üstündeki arayüz: üst çubuk ve alt bölge paneli.
##
## Paneller ve düğmeler dokunuşu yutar, aralarındaki boşluklar haritaya geçirir.

## Oyuncu "Bu ülkeyle oyna" düğmesine bastığında yayılır.
signal oyna_istendi(ulke_id: String)
## Oyuncu "Komşuları göster" düğmesini açıp kapadığında yayılır.
signal komsular_degisti(acik: bool)

## Ekran kenarıyla arayüz arasındaki boşluk (piksel).
const KENAR_BOSLUGU: int = 20

var _dunya: Dunya = null
var _kenar: MarginContainer = null
var _ust_cubuk: UstCubuk = null
var _bolge_paneli: BolgePaneli = null
var _birlik_paneli: BirlikPaneli = null


func kur(dunya: Dunya) -> void:
	_dunya = dunya

	var kok: Control = Control.new()
	kok.name = "Kok"
	kok.theme = ArayuzTemasi.olustur()
	kok.mouse_filter = Control.MOUSE_FILTER_IGNORE
	kok.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(kok)

	_kenar = MarginContainer.new()
	_kenar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_kenar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	kok.add_child(_kenar)

	var dikey: VBoxContainer = VBoxContainer.new()
	dikey.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_kenar.add_child(dikey)

	_ust_cubuk = UstCubuk.new()
	dikey.add_child(_ust_cubuk)

	var bosluk: Control = Control.new()
	bosluk.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bosluk.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dikey.add_child(bosluk)

	_bolge_paneli = BolgePaneli.new()
	dikey.add_child(_bolge_paneli)
	_bolge_paneli.oyna_basildi.connect(func(ulke_id: String) -> void: oyna_istendi.emit(ulke_id))
	_bolge_paneli.komsular_degisti.connect(func(acik: bool) -> void: komsular_degisti.emit(acik))

	_birlik_paneli = BirlikPaneli.new()
	dikey.add_child(_birlik_paneli)

	get_viewport().size_changed.connect(_guvenli_alani_uygula)
	_guvenli_alani_uygula()


## Alt panelde verilen bölgeyi ve ülkesini gösterir. Null verilirse panel gizlenir.
func bolgeyi_goster(bolge: Bolge, oyna_dugmesi_gorunur: bool) -> void:
	_birlik_paneli.hide()
	_bolge_paneli.goster(bolge, _dunya, oyna_dugmesi_gorunur)


## Alt panelde, verilen bölgedeki oyuncu tümenlerini gösterir (bölge paneli yerine).
func birligi_goster(bolge: Bolge, birlikler: Array[Birlik], ulke: Ulke) -> void:
	_bolge_paneli.hide()
	_birlik_paneli.goster(bolge, birlikler, ulke)


## Oyuncunun ülkesini üst çubuğa yazar.
func oyuncuyu_goster(ulke: Ulke) -> void:
	_ust_cubuk.oyuncuyu_goster(ulke)


## Arayüzü çentik ve yuvarlak köşelerin dışında, güvenli alanın içinde tutar.
func _guvenli_alani_uygula() -> void:
	var sol: float = 0.0
	var ust: float = 0.0
	var sag: float = 0.0
	var alt: float = 0.0
	# Güvenli alan yalnızca telefonda anlamlıdır; bilgisayarda bütün pencere güvenlidir.
	if OS.has_feature("mobile"):
		var pencere: Vector2 = Vector2(DisplayServer.window_get_size())
		var guvenli: Rect2 = Rect2(DisplayServer.get_display_safe_area())
		if pencere.x > 0.0 and pencere.y > 0.0 and guvenli.size.x > 0.0 and guvenli.size.y > 0.0:
			# Güvenli alan gerçek ekran pikseliyle gelir; arayüzün birimine çevrilir.
			var olcek: Vector2 = get_viewport().get_visible_rect().size / pencere
			sol = maxf(0.0, guvenli.position.x) * olcek.x
			ust = maxf(0.0, guvenli.position.y) * olcek.y
			sag = maxf(0.0, pencere.x - guvenli.end.x) * olcek.x
			alt = maxf(0.0, pencere.y - guvenli.end.y) * olcek.y
	_kenar.add_theme_constant_override("margin_left", KENAR_BOSLUGU + int(ceilf(sol)))
	_kenar.add_theme_constant_override("margin_top", KENAR_BOSLUGU + int(ceilf(ust)))
	_kenar.add_theme_constant_override("margin_right", KENAR_BOSLUGU + int(ceilf(sag)))
	_kenar.add_theme_constant_override("margin_bottom", KENAR_BOSLUGU + int(ceilf(alt)))
