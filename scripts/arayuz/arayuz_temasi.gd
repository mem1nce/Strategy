class_name ArayuzTemasi
extends RefCounted
## Arayüzün tek ortak teması: renkler, yazı tipleri, yazı ölçeği, boşluk ızgarası, köşe
## yarıçapı, gölge ve bileşen türleri. Kural ve değerler STIL.md'dedir; yeni her ekran bu temayı
## ve buradaki sabitleri kullanır (renk ya da yazı boyutu koda elle yazılmaz).

# --- Renkler (STIL.md → Renkler) ----------------------------------------------
const ZEMIN: Color = Color("#0E141D")
const YUZEY: Color = Color(0.082, 0.114, 0.165, 0.95)
const YUKSEK_YUZEY: Color = Color("#1E2838")
const BASILI_YUZEY: Color = Color("#28354A")
const KENAR: Color = Color("#2E3B52")
const YAZI: Color = Color("#ECEFF4")
const IKINCIL_YAZI: Color = Color("#A3ADBF")
const SOLUK_YAZI: Color = Color("#677287")
const VURGU: Color = Color("#E6AE48")
const BASILI_VURGU: Color = Color("#C8902F")
const VURGU_USTU: Color = Color("#1B1406")
const BASARI: Color = Color("#4FB985")
const TEHLIKE: Color = Color("#E25B5B")
const GOLGE_RENGI: Color = Color(0.0, 0.0, 0.0, 0.4)

# --- Yazı ölçeği (STIL.md → Yazı) ---------------------------------------------
const YAZI_DEV: int = 72
const YAZI_BASLIK: int = 44
const YAZI_ALT_BASLIK: int = 34
const YAZI_GOVDE: int = 30
const YAZI_KUCUK: int = 25
const YAZI_MINIK: int = 21

# --- Boşluk ızgarası, köşe, gölge (STIL.md) -----------------------------------
const BOSLUK_1: int = 8
const BOSLUK_2: int = 16
const BOSLUK_3: int = 24
const BOSLUK_4: int = 32
const BOSLUK_6: int = 48
const KOSE: int = 12
const KOSE_BUYUK: int = 16
const KOSE_HAP: int = 999

## Dokunulabilir öğelerin en küçük boyutu: 96 x 96'nın altına inilmez.
const DUGME_BOYUTU: Vector2 = Vector2(132.0, 104.0)

# --- Tür adları (theme_type_variation) -----------------------------------------
const BIRINCIL_DUGME: StringName = &"BirincilDugme"
## Geri dönüşü zor eylemler (ör. savaş ilanı): tehlike renginde düğme.
const TEHLIKE_DUGME: StringName = &"TehlikeDugme"
const SEKME: StringName = &"Sekme"
const KART: StringName = &"Kart"
const ROZET: StringName = &"Rozet"
const BASLIK_YAZISI: StringName = &"BaslikYazisi"
const ALT_BASLIK_YAZISI: StringName = &"AltBaslikYazisi"
const IKINCIL_YAZI_TURU: StringName = &"IkincilYazi"
const MINIK_YAZI_TURU: StringName = &"MinikYazi"

# --- Eski adlar (önceki paketlerdeki kod bunları kullanır; yeni değerlere bağlıdır) ----
const YAZI_BOYUTU: int = YAZI_GOVDE
const BASLIK_BOYUTU: int = YAZI_BASLIK
const VURGULU_DUGME: StringName = BIRINCIL_DUGME
const PANEL_RENGI: Color = YUZEY
const DUGME_RENGI: Color = YUKSEK_YUZEY
const ETKIN_RENK: Color = VURGU
const BASILI_ETKIN_RENK: Color = BASILI_VURGU
const SOLUK_RENK: Color = ZEMIN
const YAZI_RENGI: Color = YAZI
const KOYU_YAZI_RENGI: Color = VURGU_USTU
const SOLUK_YAZI_RENGI: Color = SOLUK_YAZI

const INTER: String = "res://assets/fonts/Inter.ttf"
const CINZEL: String = "res://assets/fonts/Cinzel.ttf"

## Tek paylaşılan Theme kaynağı; ilk çağrıda kurulur, sonrasında aynı nesne döner.
static var _tema: Theme = null
static var _yazi_tipleri: Dictionary[String, Font] = {}


## Arayüz yazı tipi (Inter) verilen ağırlıkta (400 normal, 600 yarı kalın).
static func arayuz_fontu(agirlik: int = 400) -> Font:
	return _font(INTER, agirlik)


## Başlık yazı tipi (Cinzel) verilen ağırlıkta.
static func baslik_fontu(agirlik: int = 700) -> Font:
	return _font(CINZEL, agirlik)


static func _font(yol: String, agirlik: int) -> Font:
	var anahtar: String = "%s:%d" % [yol, agirlik]
	if _yazi_tipleri.has(anahtar):
		return _yazi_tipleri[anahtar]
	var taban: Font = load(yol)
	var sonuc: Font = ThemeDB.fallback_font
	if taban != null:
		var cesit: FontVariation = FontVariation.new()
		cesit.base_font = taban
		cesit.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): agirlik}
		sonuc = cesit
	_yazi_tipleri[anahtar] = sonuc
	return sonuc


static func olustur() -> Theme:
	if _tema != null:
		return _tema
	var tema: Theme = Theme.new()
	tema.default_font = arayuz_fontu(400)
	tema.default_font_size = YAZI_GOVDE

	# Paneller: yüzey zemin, ince kenar, gölge.
	var panel: StyleBoxFlat = kutu(YUZEY, KOSE_BUYUK, BOSLUK_3)
	panel.border_color = KENAR
	panel.set_border_width_all(1)
	panel.shadow_color = GOLGE_RENGI
	panel.shadow_size = 10
	panel.shadow_offset = Vector2(0.0, 4.0)
	tema.set_stylebox("panel", "PanelContainer", panel)

	# Kart: panel içindeki ikinci katman.
	tema.set_type_variation(KART, "PanelContainer")
	tema.set_stylebox("panel", KART, kutu(YUKSEK_YUZEY, KOSE, BOSLUK_2))
	# Rozet: küçük hap.
	tema.set_type_variation(ROZET, "PanelContainer")
	var rozet: StyleBoxFlat = kutu(KENAR, KOSE_HAP, 0)
	rozet.content_margin_left = BOSLUK_1 + 4
	rozet.content_margin_right = BOSLUK_1 + 4
	rozet.content_margin_top = 2
	rozet.content_margin_bottom = 2
	tema.set_stylebox("panel", ROZET, rozet)

	# Yazılar.
	tema.set_color("font_color", "Label", YAZI)
	tema.set_type_variation(BASLIK_YAZISI, "Label")
	tema.set_font("font", BASLIK_YAZISI, baslik_fontu(700))
	tema.set_font_size("font_size", BASLIK_YAZISI, YAZI_BASLIK)
	tema.set_type_variation(ALT_BASLIK_YAZISI, "Label")
	tema.set_font("font", ALT_BASLIK_YAZISI, arayuz_fontu(600))
	tema.set_font_size("font_size", ALT_BASLIK_YAZISI, YAZI_ALT_BASLIK)
	tema.set_type_variation(IKINCIL_YAZI_TURU, "Label")
	tema.set_color("font_color", IKINCIL_YAZI_TURU, IKINCIL_YAZI)
	tema.set_font_size("font_size", IKINCIL_YAZI_TURU, YAZI_KUCUK)
	tema.set_type_variation(MINIK_YAZI_TURU, "Label")
	tema.set_font_size("font_size", MINIK_YAZI_TURU, YAZI_MINIK)

	# İkincil (varsayılan) düğme. Dokunmatik ekranda "üzerine gelme" olmadığı için hover
	# görünümü normalle aynıdır. Toggle düğmenin basılı (açık) hâli vurgu rengindedir.
	var normal: StyleBoxFlat = _dugme_kutusu(YUKSEK_YUZEY, KENAR)
	var basili: StyleBoxFlat = _dugme_kutusu(VURGU, VURGU)
	tema.set_stylebox("normal", "Button", normal)
	tema.set_stylebox("hover", "Button", normal)
	tema.set_stylebox("pressed", "Button", basili)
	tema.set_stylebox("hover_pressed", "Button", basili)
	tema.set_stylebox("disabled", "Button", _dugme_kutusu(ZEMIN, KENAR))
	tema.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	tema.set_color("font_color", "Button", YAZI)
	tema.set_color("font_hover_color", "Button", YAZI)
	tema.set_color("font_focus_color", "Button", YAZI)
	tema.set_color("font_pressed_color", "Button", VURGU_USTU)
	tema.set_color("font_hover_pressed_color", "Button", VURGU_USTU)
	tema.set_color("font_disabled_color", "Button", SOLUK_YAZI)
	tema.set_color("icon_normal_color", "Button", IKINCIL_YAZI)
	tema.set_color("icon_hover_color", "Button", IKINCIL_YAZI)
	tema.set_color("icon_pressed_color", "Button", VURGU_USTU)
	tema.set_color("icon_hover_pressed_color", "Button", VURGU_USTU)
	tema.set_color("icon_disabled_color", "Button", SOLUK_YAZI)
	tema.set_constant("h_separation", "Button", BOSLUK_1 + 4)
	tema.set_constant("icon_max_width", "Button", 44)

	# Birincil düğme: hep vurgu renginde, basılıyken biraz koyulaşır, yarı kalın yazı.
	var vurgu: StyleBoxFlat = _dugme_kutusu(VURGU, VURGU)
	var basili_vurgu: StyleBoxFlat = _dugme_kutusu(BASILI_VURGU, BASILI_VURGU)
	tema.set_type_variation(BIRINCIL_DUGME, "Button")
	tema.set_stylebox("normal", BIRINCIL_DUGME, vurgu)
	tema.set_stylebox("hover", BIRINCIL_DUGME, vurgu)
	tema.set_stylebox("pressed", BIRINCIL_DUGME, basili_vurgu)
	tema.set_stylebox("hover_pressed", BIRINCIL_DUGME, basili_vurgu)
	tema.set_font("font", BIRINCIL_DUGME, arayuz_fontu(600))
	for renk_adi: String in ["font_color", "font_hover_color", "font_focus_color",
			"font_pressed_color", "font_hover_pressed_color", "icon_normal_color", "icon_hover_color",
			"icon_pressed_color", "icon_hover_pressed_color"]:
		tema.set_color(renk_adi, BIRINCIL_DUGME, VURGU_USTU)

	# Tehlike düğmesi: tehlike renginde, açık yazı.
	tema.set_type_variation(TEHLIKE_DUGME, "Button")
	var tehlike: StyleBoxFlat = _dugme_kutusu(TEHLIKE, TEHLIKE)
	var basili_tehlike: StyleBoxFlat = _dugme_kutusu(TEHLIKE.darkened(0.2), TEHLIKE.darkened(0.2))
	tema.set_stylebox("normal", TEHLIKE_DUGME, tehlike)
	tema.set_stylebox("hover", TEHLIKE_DUGME, tehlike)
	tema.set_stylebox("pressed", TEHLIKE_DUGME, basili_tehlike)
	tema.set_stylebox("hover_pressed", TEHLIKE_DUGME, basili_tehlike)
	tema.set_font("font", TEHLIKE_DUGME, arayuz_fontu(600))
	for renk_adi: String in ["font_color", "font_hover_color", "font_focus_color",
			"font_pressed_color", "font_hover_pressed_color", "icon_normal_color", "icon_hover_color",
			"icon_pressed_color", "icon_hover_pressed_color"]:
		tema.set_color(renk_adi, TEHLIKE_DUGME, YAZI)

	# Sekme: hap içinde yan yana; seçili olan vurgu renginde, diğerleri saydam.
	tema.set_type_variation(SEKME, "Button")
	var sekme_bos: StyleBoxFlat = _dugme_kutusu(Color(0, 0, 0, 0), Color(0, 0, 0, 0))
	tema.set_stylebox("normal", SEKME, sekme_bos)
	tema.set_stylebox("hover", SEKME, sekme_bos)
	tema.set_stylebox("pressed", SEKME, basili)
	tema.set_stylebox("hover_pressed", SEKME, basili)

	# İlerleme çubuğu: ince, yuvarlak.
	tema.set_stylebox("background", "ProgressBar", kutu(BASILI_YUZEY, KOSE_HAP, 0))
	tema.set_stylebox("fill", "ProgressBar", kutu(VURGU, KOSE_HAP, 0))
	tema.set_color("font_color", "ProgressBar", YAZI)
	tema.set_font_size("font_size", "ProgressBar", YAZI_MINIK)

	# Ayraç ve kaydırma çubuğu.
	var ayrac: StyleBoxLine = StyleBoxLine.new()
	ayrac.color = KENAR
	ayrac.thickness = 2
	tema.set_stylebox("separator", "HSeparator", ayrac)
	tema.set_constant("separation", "HSeparator", BOSLUK_2)
	tema.set_stylebox("scroll", "VScrollBar", kutu(Color(0, 0, 0, 0), KOSE_HAP, 0))
	tema.set_stylebox("grabber", "VScrollBar", kutu(KENAR, KOSE_HAP, 4))
	tema.set_stylebox("grabber_highlight", "VScrollBar", kutu(KENAR, KOSE_HAP, 4))
	tema.set_stylebox("grabber_pressed", "VScrollBar", kutu(IKINCIL_YAZI, KOSE_HAP, 4))

	# Onay pencereleri: panel gibi görünür; düğmeler 96 x 96 dokunma sınırının üstünde.
	var pencere: StyleBoxFlat = kutu(YUZEY, KOSE_BUYUK, BOSLUK_3)
	pencere.border_color = KENAR
	pencere.set_border_width_all(1)
	tema.set_stylebox("panel", "AcceptDialog", pencere)
	tema.set_stylebox("embedded_border", "Window", pencere)
	tema.set_color("title_color", "Window", YAZI)
	tema.set_font("title_font", "Window", baslik_fontu(700))
	tema.set_font_size("title_font_size", "Window", YAZI_ALT_BASLIK)
	tema.set_constant("buttons_min_width", "AcceptDialog", int(DUGME_BOYUTU.x * 1.6))
	tema.set_constant("buttons_min_height", "AcceptDialog", int(DUGME_BOYUTU.y))
	tema.set_constant("buttons_separation", "AcceptDialog", BOSLUK_3)
	_tema = tema
	return tema


## Türkçe yazılı bir onay penceresi kurar. Metni çağıran `dialog_text` ile verir.
static func onay_penceresi_olustur() -> ConfirmationDialog:
	var pencere: ConfirmationDialog = ConfirmationDialog.new()
	pencere.title = "Onay"
	pencere.ok_button_text = "Evet"
	pencere.cancel_button_text = "Vazgeç"
	return pencere


## Düz renkli, köşe yarıçaplı kutu. `ic_bosluk` her kenardaki iç boşluktur.
static func kutu(renk: Color, kose: int, ic_bosluk: int = BOSLUK_1) -> StyleBoxFlat:
	var sonuc: StyleBoxFlat = StyleBoxFlat.new()
	sonuc.bg_color = renk
	sonuc.set_corner_radius_all(kose)
	sonuc.set_content_margin_all(float(ic_bosluk))
	sonuc.anti_aliasing = true
	return sonuc


static func _dugme_kutusu(renk: Color, kenar: Color) -> StyleBoxFlat:
	var sonuc: StyleBoxFlat = kutu(renk, KOSE, BOSLUK_2)
	sonuc.content_margin_left = BOSLUK_3
	sonuc.content_margin_right = BOSLUK_3
	sonuc.border_color = kenar
	sonuc.set_border_width_all(1)
	return sonuc
