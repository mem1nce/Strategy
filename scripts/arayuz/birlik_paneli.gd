class_name BirlikPaneli
extends PanelContainer
## Alt panel: dokunulan bölgedeki, oyuncuya ait tümenleri gösterir. Seçim yokken gizlidir.
##
## Yalnızca oyuncunun kendi tümenlerinin olduğu bir bölgeye dokununca açılır (bkz. main.gd).
## "Yarısını ayır" düğmesi gösterilen tümenlerin yarısını ayırır; sonraki hedef seçimi
## yalnızca ayrılan yarıyı yürütür. "Tümen kur", "Fabrika kur" ve "Tahkimat kur" bu bölgede
## üretim sıralar. Tümen sayısı türlere göre ayrı ayrı yazar.

const AYIR_DUGMESI_BOYUTU: Vector2 = Vector2(260.0, 112.0)

## "Yarısını ayır" düğmesine basıldığında yayılır.
signal yarisini_ayir_basildi
## "Tümen kur" ("tumen"), "Fabrika kur" ("fabrika") ya da "Tahkimat kur" ("tahkimat")
## düğmesine basıldığında yayılır.
signal insa_istendi(tur: String)

const INSA_DUGMESI_BOYUTU: Vector2 = Vector2(250.0, 112.0)

var _renk_kutusu: ColorRect = null
var _ad: Label = null
var _tumen_sayisi: Label = null
var _toplam_guc: Label = null
var _ayir: Button = null


func _ready() -> void:
	var yatay: HBoxContainer = HBoxContainer.new()
	yatay.add_theme_constant_override("separation", 20)
	add_child(yatay)

	var bilgi: VBoxContainer = VBoxContainer.new()
	bilgi.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bilgi.add_theme_constant_override("separation", 8)
	yatay.add_child(bilgi)

	var ust_sira: HBoxContainer = _sira_ekle(bilgi, 20)
	_renk_kutusu = _renk_kutusu_ekle(ust_sira, 44.0)
	_ad = _etiket_ekle(ust_sira)
	_ad.add_theme_font_size_override("font_size", ArayuzTemasi.BASLIK_BOYUTU)

	_tumen_sayisi = _etiket_ekle(bilgi)
	_toplam_guc = _etiket_ekle(bilgi)

	_ayir = Button.new()
	_ayir.text = "Yarısını ayır"
	_ayir.custom_minimum_size = AYIR_DUGMESI_BOYUTU
	_ayir.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_ayir.focus_mode = Control.FOCUS_NONE
	_ayir.pressed.connect(func() -> void: yarisini_ayir_basildi.emit())
	yatay.add_child(_ayir)

	yatay.add_child(InsaDugmeleri.dugme_olustur("tumen", INSA_DUGMESI_BOYUTU, insa_istendi))
	yatay.add_child(InsaDugmeleri.dugme_olustur("fabrika", INSA_DUGMESI_BOYUTU, insa_istendi))
	yatay.add_child(InsaDugmeleri.dugme_olustur("tahkimat", INSA_DUGMESI_BOYUTU, insa_istendi))

	hide()


## Bölgedeki tümenleri gösterir. `birlikler` boş olmamalı (main.gd çağırmadan önce denetler).
func goster(bolge: Bolge, birlikler: Array[Birlik], ulke: Ulke) -> void:
	_renk_kutusu.color = HaritaGorunumu.ulke_rengi(ulke)
	_ad.text = bolge.ad
	var toplam: float = 0.0
	var sayilar: Dictionary[String, int] = {}
	for birlik: Birlik in birlikler:
		toplam += birlik.guc
		sayilar[birlik.tur] = sayilar.get(birlik.tur, 0) + 1
	var parcalar: PackedStringArray = PackedStringArray()
	for tur: String in BirlikTurleri.SIRA:
		if sayilar.has(tur):
			parcalar.append("%s %d" % [BirlikTurleri.ad(tur), sayilar[tur]])
	_tumen_sayisi.text = "Tümen: %d  (%s)" % [birlikler.size(), "  ·  ".join(parcalar)]
	_toplam_guc.text = "Toplam güç: %d" % roundi(toplam)
	show()


func _sira_ekle(ust: Container, aralik: int) -> HBoxContainer:
	var sira: HBoxContainer = HBoxContainer.new()
	sira.add_theme_constant_override("separation", aralik)
	ust.add_child(sira)
	return sira


func _etiket_ekle(ust: Container) -> Label:
	var etiket: Label = Label.new()
	ust.add_child(etiket)
	return etiket


func _renk_kutusu_ekle(ust: Container, boyut: float) -> ColorRect:
	var kutu: ColorRect = ColorRect.new()
	kutu.custom_minimum_size = Vector2(boyut, boyut)
	kutu.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	kutu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ust.add_child(kutu)
	return kutu
