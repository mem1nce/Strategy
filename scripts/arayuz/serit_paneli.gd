class_name SeritPaneli
extends Control
## Önemli anlarda (zafer, kaybetme, düşmanın teslimi) ekranın ortasından geçen kısa, tam
## genişlikte bir şerit. Dokunuşu yutmaz; birkaç saniye sonra kendiliğinden kaybolur.
## Animasyonlar açıksa soldan kayarak gelir ve solarak gider; azaltılmışsa yalnızca görünüp kaybolur.

const YUKSEKLIK: float = 170.0
const YAZI_BOYUTU: int = ArayuzTemasi.YAZI_DEV
const GELIS_SURESI: float = 0.35
const KALMA_SURESI: float = 1.8
const GIDIS_SURESI: float = 0.4


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func goster(metin: String, renk: Color) -> void:
	var serit: ColorRect = ColorRect.new()
	serit.color = Color(renk, 0.92)
	serit.mouse_filter = Control.MOUSE_FILTER_IGNORE
	serit.size = Vector2(size.x, YUKSEKLIK)
	serit.position = Vector2(0.0, (size.y - YUKSEKLIK) * 0.5)
	add_child(serit)
	# Şeridin üst ve alt kenarında ince koyu çizgi: haritadan ayrışsın.
	for kenar_y: float in [0.0, YUKSEKLIK - 4.0]:
		var cizgi: ColorRect = ColorRect.new()
		cizgi.color = Color(0.0, 0.0, 0.0, 0.35)
		cizgi.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cizgi.position = Vector2(0.0, kenar_y)
		cizgi.size = Vector2(size.x, 4.0)
		serit.add_child(cizgi)

	var yazi: Label = Bilesenler.baslik(metin, YAZI_BOYUTU)
	yazi.add_theme_color_override("font_color", ArayuzTemasi.KOYU_YAZI_RENGI)
	yazi.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	yazi.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	yazi.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	serit.add_child(yazi)

	var tween: Tween = serit.create_tween()
	if Ayarlar.animasyonlar_azaltilmis:
		tween.tween_interval(KALMA_SURESI + GELIS_SURESI)
	else:
		serit.position.x = -size.x
		tween.tween_property(serit, "position:x", 0.0, GELIS_SURESI).set_trans(Tween.TRANS_CUBIC) \
				.set_ease(Tween.EASE_OUT)
		tween.tween_interval(KALMA_SURESI)
		tween.tween_property(serit, "modulate:a", 0.0, GIDIS_SURESI)
	tween.tween_callback(serit.queue_free)
