class_name UlkePaneli
extends PanelContainer
## Alt panel: dokunulan ülkenin bilgilerini gösterir. Seçim yokken gizlidir.
## Oyuncu henüz ülkesini seçmediyse "Bu ülkeyle oyna" düğmesi de görünür.

## "Bu ülkeyle oyna" düğmesine basıldığında, gösterilen ülkenin id'siyle yayılır.
signal oyna_basildi(ulke_id: String)

const OYNA_DUGMESI_BOYUTU: Vector2 = Vector2(380.0, 112.0)

var _ulke_id: String = ""
var _renk_kutusu: ColorRect = null
var _ad: Label = null
var _kita: Label = null
var _nufus: Label = null
var _gsyh: Label = null
var _komsular: Label = null
var _oyna: Button = null


func _ready() -> void:
	var yatay: HBoxContainer = HBoxContainer.new()
	yatay.add_theme_constant_override("separation", 24)
	add_child(yatay)

	var bilgi: VBoxContainer = VBoxContainer.new()
	bilgi.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bilgi.add_theme_constant_override("separation", 8)
	yatay.add_child(bilgi)

	var ust_sira: HBoxContainer = HBoxContainer.new()
	ust_sira.add_theme_constant_override("separation", 20)
	bilgi.add_child(ust_sira)

	_renk_kutusu = ColorRect.new()
	_renk_kutusu.custom_minimum_size = Vector2(44.0, 44.0)
	_renk_kutusu.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_renk_kutusu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ust_sira.add_child(_renk_kutusu)

	_ad = Label.new()
	_ad.add_theme_font_size_override("font_size", ArayuzTemasi.BASLIK_BOYUTU)
	_ad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_ad.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	ust_sira.add_child(_ad)

	var orta_sira: HBoxContainer = HBoxContainer.new()
	orta_sira.add_theme_constant_override("separation", 56)
	bilgi.add_child(orta_sira)
	_kita = _etiket_ekle(orta_sira)
	_nufus = _etiket_ekle(orta_sira)
	_gsyh = _etiket_ekle(orta_sira)

	# Komşu listesi uzun olabilir; en çok iki satır gösterilir, fazlası "…" ile kesilir.
	_komsular = _etiket_ekle(bilgi)
	_komsular.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_komsular.max_lines_visible = 2
	_komsular.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS

	_oyna = Button.new()
	_oyna.text = "Bu ülkeyle oyna"
	_oyna.custom_minimum_size = OYNA_DUGMESI_BOYUTU
	_oyna.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_oyna.focus_mode = Control.FOCUS_NONE
	_oyna.theme_type_variation = ArayuzTemasi.VURGULU_DUGME
	_oyna.pressed.connect(func() -> void: oyna_basildi.emit(_ulke_id))
	yatay.add_child(_oyna)

	hide()


## Ülkenin bilgilerini gösterir. Ülke null ise paneli gizler.
func goster(ulke: Ulke, dunya: Dunya, oyna_dugmesi_gorunur: bool) -> void:
	if ulke == null:
		_ulke_id = ""
		hide()
		return
	_ulke_id = ulke.id
	_renk_kutusu.color = HaritaGorunumu.ulke_rengi(ulke)
	_ad.text = ulke.ad
	_kita.text = "Kıta: %s" % ulke.kita
	_nufus.text = "Nüfus: %s" % Bicim.nufus(ulke.nufus)
	_gsyh.text = "GSYH: %s" % Bicim.para(ulke.gsyh_milyon_dolar)
	var komsu_adlari: PackedStringArray = dunya.komsu_adlari(ulke.id)
	if komsu_adlari.is_empty():
		_komsular.text = "Komşular: yok"
	else:
		_komsular.text = "Komşular: %s" % ", ".join(komsu_adlari)
	_oyna.visible = oyna_dugmesi_gorunur
	show()


func _etiket_ekle(ust: Container) -> Label:
	var etiket: Label = Label.new()
	ust.add_child(etiket)
	return etiket
