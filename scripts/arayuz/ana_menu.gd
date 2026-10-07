class_name AnaMenu
extends CanvasLayer
## Açılışta gösterilen ana menü: Yeni oyun, Devam et, Nasıl oynanır, Ayarlar. "Yeni oyun"
## önce oyun seçeneklerini (savaş sisi) soran küçük bir panel açar.
##
## Oyuncu bir seçim yapana kadar haritanın üstünde durur ve dokunuşu yutar. "Devam et" ve
## "Ayarlar -> Kaydı sil" yalnızca bir kayıt varken etkindir.

## Oyuncu yeni oyun panelinde "Başla"yı onayladığında (varsa eski kayıt zaten silindikten
## sonra) seçtiği savaş sisi tercihiyle yayılır.
signal yeni_oyun_istendi(savas_sisi: bool)
## Oyuncu "Devam et"e bastığında yayılır (yalnızca kayıt varken düğme etkindir).
signal devam_istendi

const BASLIK: String = "Yerküre"
const DUGME_BOYUTU: Vector2 = Vector2(420.0, 112.0)
const METIN_GENISLIGI: float = 1400.0
## "Nasıl oynanır" metninin görünen yüksekliği; daha uzun metin kaydırılır.
const METIN_YUKSEKLIGI: float = 720.0
const METIN_YAZI_BOYUTU: int = 30
## Paragraflar arasındaki boşluk (piksel); boş satırdan daha az yer kaplar.
const PARAGRAF_ARALIGI: int = 18

const NASIL_OYNANIR_METNI_BICIMI: String = (
		"Bir bölgeye dokunup \"Bu ülkeyle oyna\" ile ülkeni seç.\n" +
		"Bölgelere dokunarak bilgi al; kendi tümenlerinin olduğu bölgeye dokunup " +
		"başka bir bölgeye yürüt.\n" +
		"Komşu bir ülkeye savaş ilan edebilir, savaştaki bir ülkeye barış teklif " +
		"edebilirsin.\n" +
		"Hazinenle kendi bölgelerinde tümen, fabrika ya da tahkimat kur.\n" +
		"Tümen türleri: zırhlı piyadeyi, piyade topçuyu, topçu zırhlıyı yener (%%50 fazla " +
		"hasar). Zırhlı hızlı ama pahalı, piyade ucuz ama yavaş.\n" +
		"Teknoloji: üst çubuktaki düğmeden aynı anda bir araştırma seç. Sanayi geliri, " +
		"Silah saldırıyı, Savunma dayanıklılığı, Lojistik hızı artırır.\n" +
		"Tahkimat: her seviye bölgeni savunanlara %%15 güç katar; bölge el değiştirince " +
		"bir seviye düşer.\n" +
		"Amaç: kıtandaki bölgelerin %%%d'ı ya da daha fazlasını ele geçirmek ya da " +
		"ülkeni teslim olmaktan korumak.")

var _kok: Control = null
var _kayit_var: bool = false
var _devam: Button = null
## Kayıt dosyası eski bir sürüme aitse (açılamaz) başlığın altında görünen uyarı.
var _eski_kayit_yazisi: Label = null
var _kaydi_sil: Button = null
var _yeni_oyun_onayi: ConfirmationDialog = null
var _kaydi_sil_onayi: ConfirmationDialog = null
var _nasil_oynanir_paneli: CenterContainer = null
var _ayarlar_paneli: CenterContainer = null
var _yeni_oyun_paneli: CenterContainer = null
## Ana düğmelerin paneli; bir alt panel (yeni oyun, ayarlar) açıkken gizlenir ki arkadan sızmasın.
var _ana_ortalayici: CenterContainer = null
var _savas_sisi: Button = null


func kur() -> void:
	layer = 10

	_kok = Control.new()
	_kok.theme = ArayuzTemasi.olustur()
	_kok.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_kok)

	var ana_ortalayici: CenterContainer = CenterContainer.new()
	ana_ortalayici.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_kok.add_child(ana_ortalayici)
	_ana_ortalayici = ana_ortalayici

	var ana_panel: PanelContainer = PanelContainer.new()
	ana_ortalayici.add_child(ana_panel)
	var dikey: VBoxContainer = VBoxContainer.new()
	dikey.custom_minimum_size = Vector2(DUGME_BOYUTU.x + 80.0, 0.0)
	dikey.alignment = BoxContainer.ALIGNMENT_CENTER
	dikey.add_theme_constant_override("separation", 20)
	ana_panel.add_child(dikey)

	var baslik: Label = Label.new()
	baslik.text = BASLIK
	baslik.add_theme_font_size_override("font_size", 72)
	baslik.add_theme_color_override("font_color", ArayuzTemasi.ETKIN_RENK)
	baslik.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dikey.add_child(baslik)

	_eski_kayit_yazisi = Label.new()
	_eski_kayit_yazisi.text = "Bu kayıt eski bir sürüme ait.\nYeni oyun başlat."
	_eski_kayit_yazisi.add_theme_color_override("font_color", ArayuzTemasi.ETKIN_RENK)
	_eski_kayit_yazisi.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_eski_kayit_yazisi.hide()
	dikey.add_child(_eski_kayit_yazisi)

	var yeni_oyun: Button = _dugme_ekle(dikey, "Yeni oyun")
	yeni_oyun.theme_type_variation = ArayuzTemasi.VURGULU_DUGME
	yeni_oyun.pressed.connect(_yeni_oyun_basildi)

	_devam = _dugme_ekle(dikey, "Devam et")
	_devam.pressed.connect(func() -> void:
		_kok.hide()
		devam_istendi.emit())

	_yeni_oyun_onayi = ArayuzTemasi.onay_penceresi_olustur()
	_yeni_oyun_onayi.dialog_text = "Mevcut kayıt silinip yeni bir oyuna başlanacak. Emin misin?"
	_yeni_oyun_onayi.confirmed.connect(_yeni_oyun_onaylandi)
	_kok.add_child(_yeni_oyun_onayi)

	_nasil_oynanir_paneli = _bilgi_paneli_olustur("Nasıl oynanır",
			NASIL_OYNANIR_METNI_BICIMI % roundi(Oyun.ZAFER_ORANI * 100))
	var nasil_oynanir: Button = _dugme_ekle(dikey, "Nasıl oynanır")
	nasil_oynanir.pressed.connect(func() -> void: _nasil_oynanir_paneli.show())

	_ayarlar_paneli = _ayarlar_paneli_olustur()
	_yeni_oyun_paneli = _yeni_oyun_paneli_olustur()
	var ayarlar: Button = _dugme_ekle(dikey, "Ayarlar")
	ayarlar.pressed.connect(func() -> void: _alt_paneli_ac(_ayarlar_paneli))

	_kok.hide()


## Menüyü gösterir. `kayit_var`, "Devam et" ve "Kaydı sil" düğmelerinin başlangıç durumunu
## belirler (main.gd, açılabilen bir kayıt bulunca true verir). `eski_kayit` true ise kayıt
## dosyası var ama eski bir sürüme ait: "Devam et" kapalı kalır, uyarı yazısı görünür ve
## "Yeni oyun" onay sormadan eski kaydı silip yeni oyuna başlar.
func goster(kayit_var: bool, eski_kayit: bool = false) -> void:
	_kayit_var_ayarla(kayit_var)
	_eski_kayit_yazisi.visible = eski_kayit
	if eski_kayit:
		_kaydi_sil.disabled = false
	_kok.show()


func _kayit_var_ayarla(kayit_var: bool) -> void:
	_kayit_var = kayit_var
	_devam.disabled = not kayit_var
	_kaydi_sil.disabled = not kayit_var


func _dugme_ekle(ebeveyn: Control, metin: String) -> Button:
	var dugme: Button = Button.new()
	dugme.text = metin
	dugme.custom_minimum_size = DUGME_BOYUTU
	dugme.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	dugme.focus_mode = Control.FOCUS_NONE
	ebeveyn.add_child(dugme)
	return dugme


## Ortalanmış, başlık + kaydırılabilir metin + "Kapat" düğmesinden oluşan, başlangıçta
## gizli bir bilgi paneli kurar (Nasıl oynanır için kullanılır). Döndürülen CenterContainer
## göster/gizle için kullanılır (içindeki PanelContainer değil — gizli bir ebeveynin
## görünür bir çocuğu yine görünmez).
func _bilgi_paneli_olustur(baslik_metni: String, govde_metni: String) -> CenterContainer:
	var ortalayici: CenterContainer = CenterContainer.new()
	ortalayici.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_kok.add_child(ortalayici)

	var panel: PanelContainer = PanelContainer.new()
	ortalayici.add_child(panel)
	var dikey: VBoxContainer = VBoxContainer.new()
	dikey.custom_minimum_size = Vector2(METIN_GENISLIGI, 0.0)
	dikey.add_theme_constant_override("separation", 20)
	panel.add_child(dikey)

	var baslik: Label = Label.new()
	baslik.text = baslik_metni
	baslik.add_theme_font_size_override("font_size", 56)
	baslik.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dikey.add_child(baslik)

	# Metin uzarsa ekrandan taşmasın: belli bir yükseklikten sonra parmakla kaydırılır.
	var kaydirici: ScrollContainer = ScrollContainer.new()
	kaydirici.custom_minimum_size = Vector2(0.0, METIN_YUKSEKLIGI)
	kaydirici.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	dikey.add_child(kaydirici)
	var govde: Label = Label.new()
	govde.text = govde_metni
	govde.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	govde.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	govde.add_theme_font_size_override("font_size", METIN_YAZI_BOYUTU)
	govde.add_theme_constant_override("paragraph_spacing", PARAGRAF_ARALIGI)
	kaydirici.add_child(govde)

	var kapat: Button = _dugme_ekle(dikey, "Kapat")
	kapat.pressed.connect(func() -> void: ortalayici.hide())

	ortalayici.hide()
	return ortalayici


func _ayarlar_paneli_olustur() -> CenterContainer:
	var ortalayici: CenterContainer = CenterContainer.new()
	ortalayici.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_kok.add_child(ortalayici)

	var panel: PanelContainer = PanelContainer.new()
	ortalayici.add_child(panel)
	var dikey: VBoxContainer = VBoxContainer.new()
	dikey.custom_minimum_size = Vector2(DUGME_BOYUTU.x + 80.0, 0.0)
	dikey.alignment = BoxContainer.ALIGNMENT_CENTER
	dikey.add_theme_constant_override("separation", 20)
	panel.add_child(dikey)

	var baslik: Label = Label.new()
	baslik.text = "Ayarlar"
	baslik.add_theme_font_size_override("font_size", 56)
	baslik.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dikey.add_child(baslik)

	_kaydi_sil = _dugme_ekle(dikey, "Kaydı sil")
	_kaydi_sil.pressed.connect(func() -> void: _kaydi_sil_onayi.popup_centered())

	_kaydi_sil_onayi = ArayuzTemasi.onay_penceresi_olustur()
	_kaydi_sil_onayi.dialog_text = "Kayıtlı oyun silinecek. Emin misin?"
	_kaydi_sil_onayi.confirmed.connect(_kaydi_silindi)
	panel.add_child(_kaydi_sil_onayi)

	var kapat: Button = _dugme_ekle(dikey, "Kapat")
	kapat.pressed.connect(func() -> void: _alt_paneli_kapat(ortalayici))

	ortalayici.hide()
	return ortalayici


func _alt_paneli_ac(panel: CenterContainer) -> void:
	_ana_ortalayici.hide()
	panel.show()


func _alt_paneli_kapat(panel: CenterContainer) -> void:
	panel.hide()
	_ana_ortalayici.show()


## Yeni oyun seçenekleri: "Savaş sisi: Açık / Kapalı" ve "Başla" / "Vazgeç".
func _yeni_oyun_paneli_olustur() -> CenterContainer:
	var ortalayici: CenterContainer = CenterContainer.new()
	ortalayici.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_kok.add_child(ortalayici)

	var panel: PanelContainer = PanelContainer.new()
	ortalayici.add_child(panel)
	var dikey: VBoxContainer = VBoxContainer.new()
	dikey.custom_minimum_size = Vector2(DUGME_BOYUTU.x + 80.0, 0.0)
	dikey.alignment = BoxContainer.ALIGNMENT_CENTER
	dikey.add_theme_constant_override("separation", 20)
	panel.add_child(dikey)

	var baslik: Label = Label.new()
	baslik.text = "Yeni oyun"
	baslik.add_theme_font_size_override("font_size", 56)
	baslik.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dikey.add_child(baslik)

	_savas_sisi = _dugme_ekle(dikey, "")
	_savas_sisi.toggle_mode = true
	_savas_sisi.button_pressed = true
	_savas_sisi.toggled.connect(func(_acik: bool) -> void: _savas_sisi_yazisini_yenile())
	_savas_sisi_yazisini_yenile()

	var basla: Button = _dugme_ekle(dikey, "Başla")
	basla.theme_type_variation = ArayuzTemasi.VURGULU_DUGME
	basla.pressed.connect(_basla_basildi)

	var vazgec: Button = _dugme_ekle(dikey, "Vazgeç")
	vazgec.pressed.connect(func() -> void: _alt_paneli_kapat(ortalayici))

	ortalayici.hide()
	return ortalayici


func _savas_sisi_yazisini_yenile() -> void:
	_savas_sisi.text = "Savaş sisi: Açık" if _savas_sisi.button_pressed else "Savaş sisi: Kapalı"


func _yeni_oyun_basildi() -> void:
	_alt_paneli_ac(_yeni_oyun_paneli)


func _basla_basildi() -> void:
	if _kayit_var:
		_yeni_oyun_onayi.popup_centered()
	else:
		_yeni_oyun_onaylandi()


func _yeni_oyun_onaylandi() -> void:
	KayitYoneticisi.sil()
	_alt_paneli_kapat(_yeni_oyun_paneli)
	_kok.hide()
	yeni_oyun_istendi.emit(_savas_sisi.button_pressed)


func _kaydi_silindi() -> void:
	KayitYoneticisi.sil()
	_kayit_var_ayarla(false)
	_eski_kayit_yazisi.hide()
