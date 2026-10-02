class_name UstCubuk
extends HBoxContainer
## Üst çubuk: solda oyuncunun ülkesi ve tarih, ortada "Ülkeni seç" yazısı (seçim
## yapılana kadar), sağda durdur/devam ve hız düğmeleri.
## Zaman yöneticisini (Zaman) okur ve düğmelerle ona emir verir.

const SOL_PANEL_GENISLIGI: float = 560.0

var _ulke_sirasi: HBoxContainer = null
var _ulke_rengi: ColorRect = null
var _ulke_adi: Label = null
var _tarih: Label = null
var _secim_yazisi: PanelContainer = null
var _durdur: Button = null
var _hiz_dugmeleri: Array[Button] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("separation", 16)
	_sol_paneli_kur()
	_secim_yazisini_kur()
	_dugme_panelini_kur()

	Zaman.saat_gecti.connect(_saat_gecti)
	Zaman.durum_degisti.connect(_yenile)
	_yenile()


## Oyuncunun ülkesini üst çubuğa yazar ve "Ülkeni seç" yazısını kaldırır.
func oyuncuyu_goster(ulke: Ulke) -> void:
	_ulke_rengi.color = HaritaGorunumu.ulke_rengi(ulke)
	_ulke_adi.text = ulke.ad
	_ulke_sirasi.show()
	_secim_yazisi.hide()


func _sol_paneli_kur() -> void:
	var panel: PanelContainer = PanelContainer.new()
	panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	add_child(panel)
	var dikey: VBoxContainer = VBoxContainer.new()
	dikey.alignment = BoxContainer.ALIGNMENT_CENTER
	# Tarih değiştikçe panel genişleyip daralmasın.
	dikey.custom_minimum_size = Vector2(SOL_PANEL_GENISLIGI, ArayuzTemasi.DUGME_BOYUTU.y)
	panel.add_child(dikey)

	_ulke_sirasi = HBoxContainer.new()
	_ulke_sirasi.add_theme_constant_override("separation", 16)
	dikey.add_child(_ulke_sirasi)
	_ulke_rengi = ColorRect.new()
	_ulke_rengi.custom_minimum_size = Vector2(40.0, 40.0)
	_ulke_rengi.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_ulke_rengi.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ulke_sirasi.add_child(_ulke_rengi)
	_ulke_adi = Label.new()
	_ulke_adi.add_theme_font_size_override("font_size", ArayuzTemasi.BASLIK_BOYUTU)
	_ulke_adi.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# Uzun ülke adları paneli genişletmesin, "…" ile kesilsin.
	_ulke_adi.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_ulke_sirasi.add_child(_ulke_adi)
	_ulke_sirasi.hide()

	_tarih = Label.new()
	dikey.add_child(_tarih)


## Ortadaki boşluğu doldurur. Dokunuşu haritaya geçirir.
func _secim_yazisini_kur() -> void:
	var ortalayici: CenterContainer = CenterContainer.new()
	ortalayici.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ortalayici.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ortalayici)

	_secim_yazisi = PanelContainer.new()
	_secim_yazisi.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ortalayici.add_child(_secim_yazisi)
	var yazi: Label = Label.new()
	yazi.text = "Ülkeni seç"
	yazi.add_theme_font_size_override("font_size", 60)
	yazi.add_theme_color_override("font_color", ArayuzTemasi.ETKIN_RENK)
	yazi.custom_minimum_size = Vector2(380.0, ArayuzTemasi.DUGME_BOYUTU.y)
	yazi.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	yazi.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_secim_yazisi.add_child(yazi)


func _dugme_panelini_kur() -> void:
	var panel: PanelContainer = PanelContainer.new()
	panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
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
## Zaman kilitliyken (ülke seçilmeden önce) bütün düğmeler kapalıdır.
func _yenile() -> void:
	_tarih.text = Zaman.tarih_metni()
	_durdur.text = "Devam" if Zaman.durdu else "Durdur"
	_durdur.set_pressed_no_signal(Zaman.durdu and not Zaman.kilitli)
	_durdur.disabled = Zaman.kilitli
	for i: int in _hiz_dugmeleri.size():
		_hiz_dugmeleri[i].set_pressed_no_signal(Zaman.hiz == i + 1 and not Zaman.kilitli)
		_hiz_dugmeleri[i].disabled = Zaman.kilitli
