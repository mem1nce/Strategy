class_name SonucPaneli
extends PanelContainer
## Ekranın ortasında zafer ya da kaybetme bildirimi gösterir (bkz. Arayuz.zaferi_goster,
## kaybi_goster). Oyunu kilitlemez; "Kapat" ile gizlenir, oyun arka planda sürer.

## "Kapat" düğmesine basıldığında yayılır.
signal kapat_basildi

const DUGME_BOYUTU: Vector2 = Vector2(220.0, 112.0)
const METIN_GENISLIGI: float = 600.0

var _baslik: Label = null
var _metin: Label = null


func _ready() -> void:
	var dikey: VBoxContainer = VBoxContainer.new()
	dikey.add_theme_constant_override("separation", 16)
	dikey.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(dikey)

	_baslik = Label.new()
	_baslik.add_theme_font_size_override("font_size", 60)
	_baslik.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dikey.add_child(_baslik)

	_metin = Label.new()
	_metin.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_metin.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_metin.custom_minimum_size = Vector2(METIN_GENISLIGI, 0.0)
	dikey.add_child(_metin)

	var kapat: Button = Button.new()
	kapat.text = "Kapat"
	kapat.custom_minimum_size = DUGME_BOYUTU
	kapat.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	kapat.focus_mode = Control.FOCUS_NONE
	kapat.theme_type_variation = ArayuzTemasi.VURGULU_DUGME
	kapat.pressed.connect(func() -> void:
		Gecis.kapat(self)
		kapat_basildi.emit())
	dikey.add_child(kapat)

	hide()


func goster(baslik: String, metin: String, baslik_rengi: Color) -> void:
	_baslik.text = baslik
	_baslik.add_theme_color_override("font_color", baslik_rengi)
	_metin.text = metin
	show()
