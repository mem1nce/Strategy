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
const ALT_BASLIK: String = "Gerçek dünya haritasında strateji"
const BASLIK_BOYUTU: int = 104
## Başlık ve düğme sütununun ekranın solundan uzaklığı.
const SOL_BOSLUK: float = 140.0
const LISANS_KLASORU: String = "res://lisanslar"
const LISANS_DOSYALARI: Array[String] = ["NaturalEarth.txt", "flag-icons_MIT.txt", "Cinzel_OFL.txt", "Inter_OFL.txt"]
const LISANS_GIRISI: String = ("Harita ve kabartma: Natural Earth (kamu malı).\n" +
		"Bayraklar: lipis/flag-icons (MIT).\n" +
		"Yazı tipleri: Cinzel ve Inter (SIL Open Font License 1.1).\n" +
		"Simgeler bu oyun için çizilmiştir.")
const DUGME_BOYUTU: Vector2 = Vector2(420.0, 112.0)
const METIN_GENISLIGI: float = 1400.0
## "Nasıl oynanır" metninin görünen yüksekliği; daha uzun metin kaydırılır.
const METIN_YUKSEKLIGI: float = 720.0
const METIN_YAZI_BOYUTU: int = 30
## Paragraflar arasındaki boşluk (piksel); boş satırdan daha az yer kaplar.
const PARAGRAF_ARALIGI: int = 18
## Ses düzeyi "−" / "+" düğmelerinin boyutu ve her basışta değişim miktarı.
const KUCUK_DUGME_BOYUTU: Vector2 = Vector2(112.0, 112.0)
const SES_ADIMI: float = 0.1

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
		"Savaş sisi: yalnızca kendi bölgelerini, tümenlerinin olduğu yerleri ve bunların " +
		"komşularını görürsün; karanlık bölgelerdeki düşman tümenleri görünmez.\n" +
		"Her ülkenin küçük bir bonusu var (en çok %%15); bölge panelinde yazar.\n" +
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
var _lisanslar_paneli: CenterContainer = null
## Ana düğmelerin paneli; bir alt panel (yeni oyun, ayarlar) açıkken gizlenir ki arkadan sızmasın.
var _ana_ortalayici: CenterContainer = null
var _savas_sisi: Button = null
var _animasyonlar: Button = null
var _ses_duzeyi: Label = null
var _sessiz: Button = null


func kur() -> void:
	layer = 10

	_kok = Control.new()
	_kok.theme = ArayuzTemasi.olustur()
	_kok.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_kok)

	# Arkada harita yavaşça kayar (bkz. HaritaKamerasi.menu_gezintisi); üstünde soldan sağa
	# açılan koyu bir örtü, sol taraftaki başlık ve düğmeler okunaklı kalsın diye. Örtü
	# dokunuşu yutar: menü açıkken harita kımıldamaz.
	var ortu: TextureRect = TextureRect.new()
	ortu.texture = _ortu_dokusu()
	ortu.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ortu.stretch_mode = TextureRect.STRETCH_SCALE
	ortu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_kok.add_child(ortu)

	var ana_ortalayici: CenterContainer = CenterContainer.new()
	ana_ortalayici.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
	ana_ortalayici.offset_left = SOL_BOSLUK
	ana_ortalayici.offset_right = SOL_BOSLUK + DUGME_BOYUTU.x + 80.0
	ana_ortalayici.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_kok.add_child(ana_ortalayici)
	_ana_ortalayici = ana_ortalayici

	var dikey: VBoxContainer = Bilesenler.yigin(ArayuzTemasi.BOSLUK_2)
	dikey.custom_minimum_size = Vector2(DUGME_BOYUTU.x, 0.0)
	ana_ortalayici.add_child(dikey)

	var baslik: Label = Bilesenler.baslik(Bicim.buyuk_harf(BASLIK), BASLIK_BOYUTU)
	baslik.add_theme_color_override("font_color", ArayuzTemasi.VURGU)
	dikey.add_child(baslik)
	var alt_baslik: Label = Bilesenler.ikincil_yazi(ALT_BASLIK)
	alt_baslik.add_theme_font_size_override("font_size", ArayuzTemasi.YAZI_GOVDE)
	dikey.add_child(alt_baslik)
	var cizgi: ColorRect = ColorRect.new()
	cizgi.color = ArayuzTemasi.VURGU
	cizgi.custom_minimum_size = Vector2(120.0, 3.0)
	cizgi.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	dikey.add_child(cizgi)
	var ara: Control = Control.new()
	ara.custom_minimum_size = Vector2(0.0, ArayuzTemasi.BOSLUK_3)
	dikey.add_child(ara)

	_eski_kayit_yazisi = Label.new()
	_eski_kayit_yazisi.text = "Bu kayıt eski bir sürüme ait.\nYeni oyun başlat."
	_eski_kayit_yazisi.add_theme_color_override("font_color", ArayuzTemasi.VURGU)
	_eski_kayit_yazisi.hide()
	dikey.add_child(_eski_kayit_yazisi)

	var yeni_oyun: Button = _dugme_ekle(dikey, "Yeni oyun", "oynat")
	yeni_oyun.theme_type_variation = ArayuzTemasi.BIRINCIL_DUGME
	yeni_oyun.pressed.connect(_yeni_oyun_basildi)

	_devam = _dugme_ekle(dikey, "Devam et", "tarih")
	_devam.pressed.connect(func() -> void:
		_kok.hide()
		devam_istendi.emit())

	_yeni_oyun_onayi = ArayuzTemasi.onay_penceresi_olustur()
	_yeni_oyun_onayi.dialog_text = "Mevcut kayıt silinip yeni bir oyuna başlanacak. Emin misin?"
	_yeni_oyun_onayi.confirmed.connect(_yeni_oyun_onaylandi)
	_kok.add_child(_yeni_oyun_onayi)

	_nasil_oynanir_paneli = _bilgi_paneli_olustur("Nasıl oynanır", "bilgi",
			NASIL_OYNANIR_METNI_BICIMI % roundi(Oyun.ZAFER_ORANI * 100))
	var nasil_oynanir: Button = _dugme_ekle(dikey, "Nasıl oynanır", "bilgi")
	nasil_oynanir.pressed.connect(func() -> void: _alt_paneli_ac(_nasil_oynanir_paneli))

	_lisanslar_paneli = _bilgi_paneli_olustur("Lisanslar", "lisans", _lisans_metni())
	_ayarlar_paneli = _ayarlar_paneli_olustur()
	_yeni_oyun_paneli = _yeni_oyun_paneli_olustur()
	var ayarlar: Button = _dugme_ekle(dikey, "Ayarlar", "ayarlar")
	ayarlar.pressed.connect(func() -> void: _alt_paneli_ac(_ayarlar_paneli))

	_kok.hide()


## Soldan sağa koyudan yarı saydama giden örtü dokusu.
static func _ortu_dokusu() -> GradientTexture2D:
	var gecis: Gradient = Gradient.new()
	gecis.colors = PackedColorArray([Color(ArayuzTemasi.ZEMIN, 0.92), Color(ArayuzTemasi.ZEMIN, 0.72),
			Color(ArayuzTemasi.ZEMIN, 0.35)])
	gecis.offsets = PackedFloat32Array([0.0, 0.4, 1.0])
	var doku: GradientTexture2D = GradientTexture2D.new()
	doku.gradient = gecis
	doku.fill_from = Vector2(0.0, 0.5)
	doku.fill_to = Vector2(1.0, 0.5)
	doku.width = 256
	doku.height = 4
	return doku


## lisanslar/ klasöründeki her metni başlığıyla birlikte tek metinde toplar.
static func _lisans_metni() -> String:
	var parcalar: PackedStringArray = PackedStringArray([LISANS_GIRISI])
	for dosya: String in LISANS_DOSYALARI:
		var metin: String = FileAccess.get_file_as_string(LISANS_KLASORU.path_join(dosya))
		if metin == "":
			metin = "(lisans dosyası bulunamadı: %s)" % dosya
		parcalar.append("— %s —\n%s" % [dosya.get_basename().replace("_", " "), metin.strip_edges()])
	return "\n\n".join(parcalar)


## Menüyü gösterir. `kayit_var`, "Devam et" ve "Kaydı sil" düğmelerinin başlangıç durumunu
## belirler (main.gd, açılabilen bir kayıt bulunca true verir). `eski_kayit` true ise kayıt
## dosyası var ama eski bir sürüme ait: "Devam et" kapalı kalır, uyarı yazısı görünür ve
## "Yeni oyun" onay sormadan eski kaydı silip yeni oyuna başlar.
## Menü ekranda mı?
func gorunur_mu() -> bool:
	return _kok.visible


## Android geri tuşu: açık bir onay penceresi ya da alt panel (yeni oyun, ayarlar, nasıl
## oynanır) varsa onu kapatır ve true döner; menünün kendisindeyse false döner (main.gd
## uygulamadan çıkar).
func geri_basildi() -> bool:
	for pencere: ConfirmationDialog in [_yeni_oyun_onayi, _kaydi_sil_onayi]:
		if pencere.visible:
			pencere.hide()
			return true
	if _lisanslar_paneli.visible:
		_lisanslar_paneli.hide()
		Gecis.ac(_ayarlar_paneli)
		return true
	for panel: CenterContainer in [_yeni_oyun_paneli, _ayarlar_paneli, _nasil_oynanir_paneli]:
		if panel.visible:
			_alt_paneli_kapat(panel)
			return true
	return false


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


func _dugme_ekle(ebeveyn: Control, metin: String, simge: String = "") -> Button:
	var dugme: Button = Bilesenler.ikincil_dugme(metin, simge, DUGME_BOYUTU)
	dugme.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	dugme.alignment = HORIZONTAL_ALIGNMENT_LEFT if simge != "" else HORIZONTAL_ALIGNMENT_CENTER
	ebeveyn.add_child(dugme)
	return dugme


## Ortalanmış, başlık + kaydırılabilir metin + "Kapat" düğmesinden oluşan, başlangıçta
## gizli bir bilgi paneli kurar (Nasıl oynanır için kullanılır). Döndürülen CenterContainer
## göster/gizle için kullanılır (içindeki PanelContainer değil — gizli bir ebeveynin
## görünür bir çocuğu yine görünmez).
func _bilgi_paneli_olustur(baslik_metni: String, simge: String, govde_metni: String) -> CenterContainer:
	var ortalayici: CenterContainer = CenterContainer.new()
	ortalayici.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_kok.add_child(ortalayici)

	var panel: BaslikliPanel = BaslikliPanel.new(baslik_metni)
	panel.isaret_ayarla(Simgeler.dugum(simge, 44.0, ArayuzTemasi.VURGU))
	ortalayici.add_child(panel)
	var dikey: VBoxContainer = panel.govde
	dikey.custom_minimum_size = Vector2(METIN_GENISLIGI, 0.0)
	dikey.add_theme_constant_override("separation", ArayuzTemasi.BOSLUK_2)

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
	kapat.pressed.connect(func() -> void: _alt_paneli_kapat(ortalayici))

	ortalayici.hide()
	return ortalayici


func _ayarlar_paneli_olustur() -> CenterContainer:
	var ortalayici: CenterContainer = CenterContainer.new()
	ortalayici.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_kok.add_child(ortalayici)

	var panel: BaslikliPanel = BaslikliPanel.new("Ayarlar")
	panel.isaret_ayarla(Simgeler.dugum("ayarlar", 44.0, ArayuzTemasi.VURGU))
	ortalayici.add_child(panel)
	var dikey: VBoxContainer = panel.govde
	dikey.custom_minimum_size = Vector2(DUGME_BOYUTU.x + 80.0, 0.0)
	dikey.add_theme_constant_override("separation", ArayuzTemasi.BOSLUK_2)

	_animasyonlar = _dugme_ekle(dikey, "")
	_animasyonlar.toggle_mode = true
	_animasyonlar.button_pressed = not Ayarlar.animasyonlar_azaltilmis
	_animasyonlar.toggled.connect(func(acik: bool) -> void:
		Ayarlar.animasyonlar_azaltilmis = not acik
		Ayarlar.kaydet()
		_ayar_yazilarini_yenile())

	var ses_sirasi: HBoxContainer = HBoxContainer.new()
	ses_sirasi.alignment = BoxContainer.ALIGNMENT_CENTER
	ses_sirasi.add_theme_constant_override("separation", 12)
	dikey.add_child(ses_sirasi)
	var azalt: Button = _dugme_ekle(ses_sirasi, "−")
	azalt.custom_minimum_size = KUCUK_DUGME_BOYUTU
	azalt.pressed.connect(_ses_duzeyini_degistir.bind(-SES_ADIMI))
	_ses_duzeyi = Label.new()
	_ses_duzeyi.custom_minimum_size = Vector2(200.0, 0.0)
	_ses_duzeyi.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ses_sirasi.add_child(_ses_duzeyi)
	var artir: Button = _dugme_ekle(ses_sirasi, "+")
	artir.custom_minimum_size = KUCUK_DUGME_BOYUTU
	artir.pressed.connect(_ses_duzeyini_degistir.bind(SES_ADIMI))

	_sessiz = _dugme_ekle(dikey, "")
	_sessiz.toggle_mode = true
	_sessiz.button_pressed = Ayarlar.sessiz
	_sessiz.toggled.connect(func(acik: bool) -> void:
		Ayarlar.sessiz = acik
		Ayarlar.kaydet()
		_ayar_yazilarini_yenile())
	_ayar_yazilarini_yenile()

	_kaydi_sil = _dugme_ekle(dikey, "Kaydı sil")
	_kaydi_sil.pressed.connect(func() -> void: _kaydi_sil_onayi.popup_centered())

	_kaydi_sil_onayi = ArayuzTemasi.onay_penceresi_olustur()
	_kaydi_sil_onayi.dialog_text = "Kayıtlı oyun silinecek. Emin misin?"
	_kaydi_sil_onayi.confirmed.connect(_kaydi_silindi)
	panel.add_child(_kaydi_sil_onayi)

	var lisanslar: Button = _dugme_ekle(dikey, "Lisanslar", "lisans")
	lisanslar.pressed.connect(func() -> void:
		ortalayici.hide()
		Gecis.ac(_lisanslar_paneli))

	var kapat: Button = _dugme_ekle(dikey, "Kapat")
	kapat.pressed.connect(func() -> void: _alt_paneli_kapat(ortalayici))

	ortalayici.hide()
	return ortalayici


func _ses_duzeyini_degistir(fark: float) -> void:
	Ayarlar.ses_duzeyi = clampf(snappedf(Ayarlar.ses_duzeyi + fark, SES_ADIMI), 0.0, 1.0)
	Ayarlar.kaydet()
	_ayar_yazilarini_yenile()


func _ayar_yazilarini_yenile() -> void:
	_animasyonlar.text = "Animasyonlar: Açık" if _animasyonlar.button_pressed else "Animasyonlar: Azaltılmış"
	_ses_duzeyi.text = "Ses: %%%d" % roundi(Ayarlar.ses_duzeyi * 100.0)
	_sessiz.text = "Sessiz: Açık" if _sessiz.button_pressed else "Sessiz: Kapalı"


func _alt_paneli_ac(panel: CenterContainer) -> void:
	_ana_ortalayici.hide()
	Gecis.ac(panel)


func _alt_paneli_kapat(panel: CenterContainer) -> void:
	panel.hide()
	Gecis.ac(_ana_ortalayici)


## Yeni oyun seçenekleri: "Savaş sisi: Açık / Kapalı" ve "Başla" / "Vazgeç".
func _yeni_oyun_paneli_olustur() -> CenterContainer:
	var ortalayici: CenterContainer = CenterContainer.new()
	ortalayici.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_kok.add_child(ortalayici)

	var panel: BaslikliPanel = BaslikliPanel.new("Yeni oyun")
	panel.isaret_ayarla(Simgeler.dugum("oynat", 44.0, ArayuzTemasi.VURGU))
	ortalayici.add_child(panel)
	var dikey: VBoxContainer = panel.govde
	dikey.custom_minimum_size = Vector2(DUGME_BOYUTU.x + 80.0, 0.0)
	dikey.add_theme_constant_override("separation", ArayuzTemasi.BOSLUK_2)

	_savas_sisi = _dugme_ekle(dikey, "")
	_savas_sisi.toggle_mode = true
	_savas_sisi.button_pressed = true
	_savas_sisi.toggled.connect(func(_acik: bool) -> void: _savas_sisi_yazisini_yenile())
	_savas_sisi_yazisini_yenile()

	var basla: Button = _dugme_ekle(dikey, "Başla")
	basla.theme_type_variation = ArayuzTemasi.BIRINCIL_DUGME
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
