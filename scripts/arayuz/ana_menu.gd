class_name AnaMenu
extends CanvasLayer
## Açılışta gösterilen ana menü: Yeni oyun, Devam et, Nasıl oynanır, Ayarlar.
##
## Oyuncu bir seçim yapana kadar haritanın üstünde durur ve dokunuşu yutar. "Devam et" ve
## "Ayarlar -> Kaydı sil" yalnızca bir kayıt varken etkindir.

## Oyuncu "Yeni oyun"u onayladığında (varsa eski kayıt zaten silindikten sonra) yayılır.
signal yeni_oyun_istendi
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
var _kaydi_sil: Button = null
var _yeni_oyun_onayi: ConfirmationDialog = null
var _kaydi_sil_onayi: ConfirmationDialog = null
var _nasil_oynanir_paneli: CenterContainer = null
var _ayarlar_paneli: CenterContainer = null


func kur() -> void:
	layer = 10

	_kok = Control.new()
	_kok.theme = ArayuzTemasi.olustur()
	_kok.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_kok)

	var ana_ortalayici: CenterContainer = CenterContainer.new()
	ana_ortalayici.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_kok.add_child(ana_ortalayici)

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
	var ayarlar: Button = _dugme_ekle(dikey, "Ayarlar")
	ayarlar.pressed.connect(func() -> void: _ayarlar_paneli.show())

	_kok.hide()


## Menüyü gösterir. `kayit_var`, "Devam et" ve "Kaydı sil" düğmelerinin başlangıç durumunu
## belirler (main.gd, KayitYoneticisi.kayit_var_mi() ile çağırır).
func goster(kayit_var: bool) -> void:
	_kayit_var_ayarla(kayit_var)
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
	kapat.pressed.connect(func() -> void: ortalayici.hide())

	ortalayici.hide()
	return ortalayici


func _yeni_oyun_basildi() -> void:
	if _kayit_var:
		_yeni_oyun_onayi.popup_centered()
	else:
		_yeni_oyun_onaylandi()


func _yeni_oyun_onaylandi() -> void:
	KayitYoneticisi.sil()
	_kok.hide()
	yeni_oyun_istendi.emit()


func _kaydi_silindi() -> void:
	KayitYoneticisi.sil()
	_kayit_var_ayarla(false)
