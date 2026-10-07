class_name Simgeler
extends RefCounted
## Arayüz ve harita simgeleri (art/icons/*.svg, tools/simgeler_uret.py; bkz. STIL.md → Simgeler).
## Simgeler beyaz çizilir; renk `modulate` (Control) ya da çizim rengi ile verilir.

static var _dokular: Dictionary[String, Texture2D] = {}


static func doku(ad: String) -> Texture2D:
	if not _dokular.has(ad):
		_dokular[ad] = load("res://art/icons/%s.svg" % ad)
	return _dokular[ad]


## Verilen boyutta, verilen renkte bir simge düğümü (kendi başına dokunuşu yutmaz).
static func dugum(ad: String, boyut: float, renk: Color = ArayuzTemasi.IKINCIL_YAZI) -> TextureRect:
	var simge: TextureRect = TextureRect.new()
	simge.texture = doku(ad)
	simge.custom_minimum_size = Vector2(boyut, boyut)
	simge.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	simge.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	simge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	simge.modulate = renk
	simge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return simge
