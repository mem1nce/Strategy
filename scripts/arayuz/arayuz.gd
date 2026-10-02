class_name Arayuz
extends CanvasLayer
## Haritanın üstündeki arayüz: üst çubuk, alt bölge paneli ve "Süre doldu" yazısı.
##
## Paneller ve düğmeler dokunuşu yutar, aralarındaki boşluklar haritaya geçirir.

## Ekran kenarıyla arayüz arasındaki boşluk (piksel).
const KENAR_BOSLUGU: int = 20

var _dunya: Dunya = null
var _kenar: MarginContainer = null
var _bolge_paneli: BolgePaneli = null
var _sure_doldu: PanelContainer = null


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

	dikey.add_child(UstCubuk.new())

	var bosluk: Control = Control.new()
	bosluk.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bosluk.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dikey.add_child(bosluk)

	_bolge_paneli = BolgePaneli.new()
	dikey.add_child(_bolge_paneli)

	_sure_doldu_yazisini_kur(kok)

	get_viewport().size_changed.connect(_guvenli_alani_uygula)
	_guvenli_alani_uygula()
	Zaman.sure_doldu.connect(_sure_doldu.show)
	if Zaman.bitti:
		_sure_doldu.show()


## Alt panelde verilen bölgeyi gösterir. Null verilirse panel gizlenir.
func bolgeyi_goster(bolge: Bolge) -> void:
	_bolge_paneli.goster(bolge, _dunya)


func _sure_doldu_yazisini_kur(kok: Control) -> void:
	var ortalayici: CenterContainer = CenterContainer.new()
	ortalayici.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ortalayici.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	kok.add_child(ortalayici)

	_sure_doldu = PanelContainer.new()
	_sure_doldu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ortalayici.add_child(_sure_doldu)

	var yazi: Label = Label.new()
	yazi.text = "Süre doldu"
	yazi.add_theme_font_size_override("font_size", 96)
	yazi.custom_minimum_size = Vector2(640.0, 160.0)
	yazi.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	yazi.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_sure_doldu.add_child(yazi)
	_sure_doldu.hide()


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
