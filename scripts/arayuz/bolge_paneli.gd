class_name BolgePaneli
extends PanelContainer
## Alt panel: dokunulan bölgenin ve ülkesinin bilgilerini gösterir. Seçim yokken gizlidir.
##
## Üstte bölgenin adı, nüfusu ve başkent olup olmadığı; altında ülkenin adı, kıtası,
## toplam nüfusu ve GSYH'si yazar. "Komşuları göster" düğmesi haritada bölgenin
## komşularını vurgular. Oyuncu henüz ülkesini seçmediyse "Bu ülkeyle oyna" düğmesi de görünür.

## "Bu ülkeyle oyna" düğmesine basıldığında, gösterilen bölgenin ülkesinin id'siyle yayılır.
signal oyna_basildi(ulke_id: String)
## "Komşuları göster" düğmesi açılıp kapandığında yayılır.
signal komsular_degisti(acik: bool)

const KOMSU_DUGMESI_BOYUTU: Vector2 = Vector2(350.0, 112.0)
const OYNA_DUGMESI_BOYUTU: Vector2 = Vector2(350.0, 112.0)

var _ulke_id: String = ""
var _renk_kutusu: ColorRect = null
var _ad: Label = null
var _baskent: Label = null
var _nufus: Label = null
var _ulke: Label = null
var _kara_sayisi: Label = null
var _deniz_sayisi: Label = null
var _komsular: Button = null
var _oyna: Button = null


func _ready() -> void:
	var yatay: HBoxContainer = HBoxContainer.new()
	yatay.add_theme_constant_override("separation", 20)
	add_child(yatay)

	var bilgi: VBoxContainer = VBoxContainer.new()
	bilgi.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bilgi.add_theme_constant_override("separation", 8)
	yatay.add_child(bilgi)

	# Üst satır: bölge.
	var bolge_sirasi: HBoxContainer = _sira_ekle(bilgi, 20)
	_renk_kutusu = _renk_kutusu_ekle(bolge_sirasi, 44.0, Color.WHITE)
	_ad = _etiket_ekle(bolge_sirasi)
	_ad.add_theme_font_size_override("font_size", ArayuzTemasi.BASLIK_BOYUTU)
	_baskent = _etiket_ekle(bolge_sirasi)
	_baskent.text = "Başkent"
	_baskent.add_theme_color_override("font_color", ArayuzTemasi.ETKIN_RENK)
	_nufus = _etiket_ekle(bolge_sirasi)
	_nufus.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_nufus.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	# Orta satır: ülke. Uzun olabilir; en çok iki satıra sarılır.
	_ulke = _etiket_ekle(bilgi)
	_ulke.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_ulke.max_lines_visible = 2
	_ulke.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS

	# Alt satır: komşu sayıları. Renkli kutular haritadaki vurgu renklerini açıklar.
	var komsu_sirasi: HBoxContainer = _sira_ekle(bilgi, 14)
	_renk_kutusu_ekle(komsu_sirasi, 30.0, HaritaGorunumu.KARA_KOMSUSU_RENGI)
	_kara_sayisi = _etiket_ekle(komsu_sirasi)
	var ara: Control = Control.new()
	ara.custom_minimum_size = Vector2(28.0, 0.0)
	ara.mouse_filter = Control.MOUSE_FILTER_IGNORE
	komsu_sirasi.add_child(ara)
	_renk_kutusu_ekle(komsu_sirasi, 30.0, HaritaGorunumu.DENIZ_GECISI_RENGI)
	_deniz_sayisi = _etiket_ekle(komsu_sirasi)

	_komsular = Button.new()
	_komsular.custom_minimum_size = KOMSU_DUGMESI_BOYUTU
	_komsular.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_komsular.toggle_mode = true
	_komsular.focus_mode = Control.FOCUS_NONE
	_komsular.toggled.connect(_komsular_basildi)
	yatay.add_child(_komsular)

	_oyna = Button.new()
	_oyna.text = "Bu ülkeyle oyna"
	_oyna.custom_minimum_size = OYNA_DUGMESI_BOYUTU
	_oyna.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_oyna.focus_mode = Control.FOCUS_NONE
	_oyna.theme_type_variation = ArayuzTemasi.VURGULU_DUGME
	_oyna.pressed.connect(func() -> void: oyna_basildi.emit(_ulke_id))
	yatay.add_child(_oyna)

	_komsu_dugmesini_yenile()
	hide()


## Bölgenin ve ülkesinin bilgilerini gösterir. Bölge null ise paneli gizler.
func goster(bolge: Bolge, dunya: Dunya, oyna_dugmesi_gorunur: bool) -> void:
	if bolge == null:
		_ulke_id = ""
		hide()
		return
	var ulke: Ulke = dunya.bolgenin_sahibi(bolge.id)
	_ulke_id = ulke.id
	_renk_kutusu.color = HaritaGorunumu.ulke_rengi(ulke)
	_ad.text = bolge.ad
	_baskent.visible = bolge.baskent
	_nufus.text = "Nüfus: %s" % Bicim.nufus(bolge.nufus)
	_ulke.text = "%s  ·  %s  ·  Nüfus: %s  ·  GSYH: %s" % [
		ulke.ad, ulke.kita, Bicim.nufus(ulke.nufus), Bicim.para(ulke.gsyh_milyon_dolar)]
	_kara_sayisi.text = "Kara komşusu: %d" % bolge.kara_komsulari.size()
	_deniz_sayisi.text = "Deniz geçişi: %d" % bolge.deniz_gecisleri.size()
	_oyna.visible = oyna_dugmesi_gorunur
	show()


func _komsular_basildi(acik: bool) -> void:
	_komsu_dugmesini_yenile()
	komsular_degisti.emit(acik)


func _komsu_dugmesini_yenile() -> void:
	_komsular.text = "Komşuları gizle" if _komsular.button_pressed else "Komşuları göster"


func _sira_ekle(ust: Container, aralik: int) -> HBoxContainer:
	var sira: HBoxContainer = HBoxContainer.new()
	sira.add_theme_constant_override("separation", aralik)
	ust.add_child(sira)
	return sira


func _etiket_ekle(ust: Container) -> Label:
	var etiket: Label = Label.new()
	ust.add_child(etiket)
	return etiket


func _renk_kutusu_ekle(ust: Container, boyut: float, renk: Color) -> ColorRect:
	var kutu: ColorRect = ColorRect.new()
	kutu.color = renk
	kutu.custom_minimum_size = Vector2(boyut, boyut)
	kutu.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	kutu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ust.add_child(kutu)
	return kutu
