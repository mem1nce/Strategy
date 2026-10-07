class_name IstatistikSatiri
extends HBoxContainer
## Ortak "simgeli istatistik satırı" (STIL.md): soluk simge, ikincil renkte etiket, sağda
## yarı kalın değer. İsteğe bağlı olarak değerin altında/yanında bir ilerleme çubuğu taşır.

var etiket: Label = null
var deger: Label = null
var simge: TextureRect = null


func _init(simge_adi: String, etiket_metni: String) -> void:
	add_theme_constant_override("separation", ArayuzTemasi.BOSLUK_1 + 4)
	simge = Simgeler.dugum(simge_adi, 34.0)
	add_child(simge)
	etiket = Bilesenler.ikincil_yazi(etiket_metni)
	etiket.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(etiket)
	deger = Label.new()
	deger.add_theme_font_override("font", ArayuzTemasi.arayuz_fontu(600))
	deger.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(deger)


func deger_ayarla(metin: String, renk: Color = ArayuzTemasi.YAZI) -> void:
	deger.text = metin
	deger.add_theme_color_override("font_color", renk)
