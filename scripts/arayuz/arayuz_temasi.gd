class_name ArayuzTemasi
extends RefCounted
## Arayüzün ortak görünümünü (renkler, yazı boyutu, düğme biçimi) kurar.

const YAZI_BOYUTU: int = 36
const BASLIK_BOYUTU: int = 48
## Dokunulabilir öğelerin en küçük boyutu. Alt sınır 96 x 96 pikseldir.
const DUGME_BOYUTU: Vector2 = Vector2(132.0, 104.0)

const PANEL_RENGI: Color = Color(0.08, 0.1, 0.13, 0.95)
const DUGME_RENGI: Color = Color(0.2, 0.24, 0.3)
const ETKIN_RENK: Color = Color(0.98, 0.8, 0.25)
const SOLUK_RENK: Color = Color(0.14, 0.16, 0.2)
const YAZI_RENGI: Color = Color(0.96, 0.96, 0.96)
const KOYU_YAZI_RENGI: Color = Color(0.1, 0.1, 0.1)
const SOLUK_YAZI_RENGI: Color = Color(0.5, 0.52, 0.55)


static func olustur() -> Theme:
	var tema: Theme = Theme.new()
	tema.default_font_size = YAZI_BOYUTU

	var panel: StyleBoxFlat = _kutu(PANEL_RENGI, 18)
	panel.set_content_margin_all(18.0)
	tema.set_stylebox("panel", "PanelContainer", panel)

	tema.set_color("font_color", "Label", YAZI_RENGI)

	# Dokunmatik ekranda "üzerine gelme" olmadığı için hover görünümü normalle aynıdır.
	var normal: StyleBoxFlat = _kutu(DUGME_RENGI, 14)
	var etkin: StyleBoxFlat = _kutu(ETKIN_RENK, 14)
	tema.set_stylebox("normal", "Button", normal)
	tema.set_stylebox("hover", "Button", normal)
	tema.set_stylebox("pressed", "Button", etkin)
	tema.set_stylebox("hover_pressed", "Button", etkin)
	tema.set_stylebox("disabled", "Button", _kutu(SOLUK_RENK, 14))
	tema.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	tema.set_color("font_color", "Button", YAZI_RENGI)
	tema.set_color("font_hover_color", "Button", YAZI_RENGI)
	tema.set_color("font_focus_color", "Button", YAZI_RENGI)
	tema.set_color("font_pressed_color", "Button", KOYU_YAZI_RENGI)
	tema.set_color("font_hover_pressed_color", "Button", KOYU_YAZI_RENGI)
	tema.set_color("font_disabled_color", "Button", SOLUK_YAZI_RENGI)
	return tema


static func _kutu(renk: Color, kose: int) -> StyleBoxFlat:
	var kutu: StyleBoxFlat = StyleBoxFlat.new()
	kutu.bg_color = renk
	kutu.set_corner_radius_all(kose)
	kutu.set_content_margin_all(10.0)
	return kutu
