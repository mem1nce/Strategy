class_name UstCubuk
extends HBoxContainer
## Üst çubuk: solda tarih ve saat, sağda durdur/devam ve hız düğmeleri.
## Zaman yöneticisini (Zaman) okur ve düğmelerle ona emir verir.

var _tarih: Label = null
var _durdur: Button = null
var _hiz_dugmeleri: Array[Button] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tarih_panelini_kur()

	# Ortadaki boşluk dokunuşları haritaya geçirir.
	var bosluk: Control = Control.new()
	bosluk.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bosluk.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bosluk)

	_dugme_panelini_kur()

	Zaman.saat_gecti.connect(_saat_gecti)
	Zaman.durum_degisti.connect(_yenile)
	_yenile()


func _tarih_panelini_kur() -> void:
	var panel: PanelContainer = PanelContainer.new()
	add_child(panel)
	_tarih = Label.new()
	_tarih.add_theme_font_size_override("font_size", ArayuzTemasi.BASLIK_BOYUTU)
	_tarih.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tarih.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	# Tarih değiştikçe panel genişleyip daralmasın.
	_tarih.custom_minimum_size = Vector2(560.0, ArayuzTemasi.DUGME_BOYUTU.y)
	panel.add_child(_tarih)


func _dugme_panelini_kur() -> void:
	var panel: PanelContainer = PanelContainer.new()
	add_child(panel)
	var sira: HBoxContainer = HBoxContainer.new()
	sira.add_theme_constant_override("separation", 12)
	panel.add_child(sira)

	_durdur = _dugme_olustur("", Vector2(210.0, ArayuzTemasi.DUGME_BOYUTU.y))
	_durdur.pressed.connect(_durdur_basildi)
	sira.add_child(_durdur)

	for i: int in Zaman.hiz_sayisi():
		var dugme: Button = _dugme_olustur("%dx" % (i + 1), ArayuzTemasi.DUGME_BOYUTU)
		dugme.pressed.connect(_hiz_basildi.bind(i + 1))
		sira.add_child(dugme)
		_hiz_dugmeleri.append(dugme)


func _dugme_olustur(metin: String, boyut: Vector2) -> Button:
	var dugme: Button = Button.new()
	dugme.text = metin
	dugme.custom_minimum_size = boyut
	dugme.toggle_mode = true
	dugme.focus_mode = Control.FOCUS_NONE
	return dugme


func _durdur_basildi() -> void:
	Zaman.durdurmayi_degistir()
	_yenile()


func _hiz_basildi(hiz: int) -> void:
	Zaman.hiz_sec(hiz)
	_yenile()


func _saat_gecti(_toplam_saat: int) -> void:
	_tarih.text = Zaman.tarih_metni()


## Düğmelerin görünümünü zamanın durumuna uydurur: etkin hız ve durdurma vurgulanır.
func _yenile() -> void:
	_tarih.text = Zaman.tarih_metni()
	_durdur.text = "Devam" if Zaman.durdu else "Durdur"
	_durdur.set_pressed_no_signal(Zaman.durdu)
	_durdur.disabled = Zaman.bitti
	for i: int in _hiz_dugmeleri.size():
		_hiz_dugmeleri[i].set_pressed_no_signal(Zaman.hiz == i + 1)
		_hiz_dugmeleri[i].disabled = Zaman.bitti
