class_name Bilesenler
extends RefCounted
## Ortak arayüz bileşenlerinin kurucuları (bkz. STIL.md → Ortak bileşenler). Yeni ekranlar
## düğme, kart, rozet ve ilerleme çubuğunu buradan alır; başlıklı panel, istatistik satırı ve
## sekme grubu kendi sınıflarıdır (BaslikliPanel, IstatistikSatiri, SekmeGrubu).

const SIMGE_BOYUTU: float = 40.0


## Ekrandaki tek ana eylem: vurgu zeminli düğme. `simge` art/icons içindeki bir addır (boş olabilir).
static func birincil_dugme(metin: String, simge: String = "", boyut: Vector2 = ArayuzTemasi.DUGME_BOYUTU) -> Button:
	var dugme: Button = ikincil_dugme(metin, simge, boyut)
	dugme.theme_type_variation = ArayuzTemasi.BIRINCIL_DUGME
	return dugme


## Varsayılan düğme: yüksek yüzey zeminli, ince kenarlı.
static func ikincil_dugme(metin: String, simge: String = "", boyut: Vector2 = ArayuzTemasi.DUGME_BOYUTU) -> Button:
	var dugme: Button = Button.new()
	dugme.text = metin
	dugme.custom_minimum_size = boyut
	dugme.focus_mode = Control.FOCUS_NONE
	dugme.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if simge != "":
		dugme.icon = Simgeler.doku(simge)
		dugme.expand_icon = false
	return dugme


## Araç düğmesi: üstte simge, altında küçük yazı; açılıp kapanır (ör. Sıralama, Teknoloji).
static func arac_dugmesi(metin: String, simge: String, boyut: Vector2 = Vector2(124.0, 104.0)) -> Button:
	var dugme: Button = ikincil_dugme(metin, simge, boyut)
	dugme.toggle_mode = true
	dugme.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dugme.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	dugme.add_theme_font_size_override("font_size", ArayuzTemasi.YAZI_MINIK)
	dugme.add_theme_constant_override("icon_max_width", 36)
	return dugme


## Simgeli küçük değer: soluk simge ve yanında yarı kalın yazı (üst çubuktaki kaynaklar gibi).
## Yazıya `get_child(1)` ile ulaşılır.
static func simgeli_deger(simge: String, renk: Color = ArayuzTemasi.YAZI) -> HBoxContainer:
	var sonuc: HBoxContainer = sira(6)
	sonuc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sonuc.add_child(Simgeler.dugum(simge, 28.0, ArayuzTemasi.IKINCIL_YAZI))
	var yazi: Label = Label.new()
	yazi.add_theme_font_override("font", ArayuzTemasi.arayuz_fontu(600))
	yazi.add_theme_font_size_override("font_size", ArayuzTemasi.YAZI_KUCUK)
	yazi.add_theme_color_override("font_color", renk)
	sonuc.add_child(yazi)
	return sonuc


## Panel içindeki ikinci katman kart.
static func kart() -> PanelContainer:
	var sonuc: PanelContainer = PanelContainer.new()
	sonuc.theme_type_variation = ArayuzTemasi.KART
	return sonuc


## Küçük hap: renkli zemin, minik yazı.
static func rozet(metin: String, renk: Color = ArayuzTemasi.KENAR, yazi_rengi: Color = ArayuzTemasi.YAZI) -> PanelContainer:
	var sonuc: PanelContainer = PanelContainer.new()
	sonuc.theme_type_variation = ArayuzTemasi.ROZET
	sonuc.add_theme_stylebox_override("panel", _rozet_kutusu(renk))
	sonuc.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	sonuc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var yazi: Label = Label.new()
	yazi.text = metin
	yazi.theme_type_variation = ArayuzTemasi.MINIK_YAZI_TURU
	yazi.add_theme_color_override("font_color", yazi_rengi)
	sonuc.add_child(yazi)
	return sonuc


static func _rozet_kutusu(renk: Color) -> StyleBoxFlat:
	var kutu: StyleBoxFlat = ArayuzTemasi.kutu(renk, ArayuzTemasi.KOSE_HAP, 0)
	kutu.content_margin_left = ArayuzTemasi.BOSLUK_1 + 4
	kutu.content_margin_right = ArayuzTemasi.BOSLUK_1 + 4
	kutu.content_margin_top = 2
	kutu.content_margin_bottom = 2
	return kutu


## İnce, yuvarlak ilerleme çubuğu; dolgu rengi verilebilir (varsayılan vurgu).
static func ilerleme_cubugu(renk: Color = ArayuzTemasi.VURGU, yukseklik: float = 16.0) -> ProgressBar:
	var cubuk: ProgressBar = ProgressBar.new()
	cubuk.custom_minimum_size = Vector2(0.0, yukseklik)
	cubuk.show_percentage = false
	cubuk.max_value = 1.0
	cubuk.step = 0.0
	cubuk.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	cubuk.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if renk != ArayuzTemasi.VURGU:
		cubuk.add_theme_stylebox_override("fill", ArayuzTemasi.kutu(renk, ArayuzTemasi.KOSE_HAP, 0))
	return cubuk


## Başlık yazısı (Cinzel).
static func baslik(metin: String, boyut: int = ArayuzTemasi.YAZI_BASLIK) -> Label:
	var yazi: Label = Label.new()
	yazi.text = metin
	yazi.theme_type_variation = ArayuzTemasi.BASLIK_YAZISI
	if boyut != ArayuzTemasi.YAZI_BASLIK:
		yazi.add_theme_font_size_override("font_size", boyut)
	return yazi


## İkincil renkte küçük yazı.
static func ikincil_yazi(metin: String = "") -> Label:
	var yazi: Label = Label.new()
	yazi.text = metin
	yazi.theme_type_variation = ArayuzTemasi.IKINCIL_YAZI_TURU
	return yazi


## Yatay sıra (8'in katı aralıkla).
static func sira(aralik: int = ArayuzTemasi.BOSLUK_2) -> HBoxContainer:
	var sonuc: HBoxContainer = HBoxContainer.new()
	sonuc.add_theme_constant_override("separation", aralik)
	return sonuc


## Dikey yığın (8'in katı aralıkla).
static func yigin(aralik: int = ArayuzTemasi.BOSLUK_1) -> VBoxContainer:
	var sonuc: VBoxContainer = VBoxContainer.new()
	sonuc.add_theme_constant_override("separation", aralik)
	return sonuc
