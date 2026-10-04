class_name BirlikPaneli
extends PanelContainer
## Alt panel: dokunulan bölgedeki, oyuncuya ait tümenleri gösterir. Seçim yokken gizlidir.
##
## Yalnızca oyuncunun kendi tümenlerinin olduğu bir bölgeye dokununca açılır (bkz. main.gd).
## Hedef seçip birlik yürütme ve "Yarısını ayır" henüz yok (sıradaki adım).

var _renk_kutusu: ColorRect = null
var _ad: Label = null
var _tumen_sayisi: Label = null
var _toplam_guc: Label = null


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

	hide()


## Bölgedeki tümenleri gösterir. `birlikler` boş olmamalı (main.gd çağırmadan önce denetler).
func goster(bolge: Bolge, birlikler: Array[Birlik], ulke: Ulke) -> void:
	_renk_kutusu.color = HaritaGorunumu.ulke_rengi(ulke)
	_ad.text = bolge.ad
	var toplam: float = 0.0
	for birlik: Birlik in birlikler:
		toplam += birlik.guc
	_tumen_sayisi.text = "Tümen: %d" % birlikler.size()
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
