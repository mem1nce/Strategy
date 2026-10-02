class_name BolgePaneli
extends PanelContainer
## Alt panel: seçili bölgenin bilgilerini gösterir. Seçim yokken gizlidir.

var _renk_kutusu: ColorRect = null
var _ad: Label = null
var _sahip: Label = null
var _arazi: Label = null
var _zafer: Label = null
var _insan_gucu: Label = null
var _celik: Label = null
var _petrol: Label = null
var _fabrika: Label = null


func _ready() -> void:
	var dikey: VBoxContainer = VBoxContainer.new()
	dikey.add_theme_constant_override("separation", 10)
	add_child(dikey)

	var ust_sira: HBoxContainer = HBoxContainer.new()
	ust_sira.add_theme_constant_override("separation", 20)
	dikey.add_child(ust_sira)

	_renk_kutusu = ColorRect.new()
	_renk_kutusu.custom_minimum_size = Vector2(44.0, 44.0)
	_renk_kutusu.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_renk_kutusu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ust_sira.add_child(_renk_kutusu)

	_ad = Label.new()
	_ad.add_theme_font_size_override("font_size", ArayuzTemasi.BASLIK_BOYUTU)
	ust_sira.add_child(_ad)

	_sahip = Label.new()
	_sahip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_sahip.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ust_sira.add_child(_sahip)

	var alt_sira: HBoxContainer = HBoxContainer.new()
	alt_sira.add_theme_constant_override("separation", 48)
	dikey.add_child(alt_sira)
	_arazi = _bilgi_ekle(alt_sira)
	_zafer = _bilgi_ekle(alt_sira)
	_insan_gucu = _bilgi_ekle(alt_sira)
	_celik = _bilgi_ekle(alt_sira)
	_petrol = _bilgi_ekle(alt_sira)
	_fabrika = _bilgi_ekle(alt_sira)

	hide()


## Bölgenin bilgilerini gösterir. Bölge null ise paneli gizler.
func goster(bolge: Bolge, dunya: Dunya) -> void:
	if bolge == null:
		hide()
		return
	var ulke: Ulke = dunya.ulkeler[bolge.sahip]
	_renk_kutusu.color = ulke.renk
	_ad.text = "%s (Başkent)" % bolge.ad if bolge.baskent else bolge.ad
	_sahip.text = "%s · %s" % [ulke.ad, dunya.blok_adi(ulke.blok)]
	_arazi.text = "Arazi: %s" % dunya.arazi_adi(bolge.arazi)
	_zafer.text = "Zafer puanı: %d" % bolge.zafer_puani
	_insan_gucu.text = "İnsan gücü: +%d" % bolge.insan_gucu
	_celik.text = "Çelik: +%d" % bolge.celik
	_petrol.text = "Petrol: +%d" % bolge.petrol
	_fabrika.text = "Fabrika: %d" % bolge.fabrika
	show()


func _bilgi_ekle(sira: HBoxContainer) -> Label:
	var etiket: Label = Label.new()
	sira.add_child(etiket)
	return etiket
