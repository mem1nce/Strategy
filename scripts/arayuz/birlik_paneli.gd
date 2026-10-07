class_name BirlikPaneli
extends PanelContainer
## Alt panel: dokunulan bölgedeki, oyuncuya ait tümenleri gösterir. Seçim yokken gizlidir.
##
## Yalnızca oyuncunun kendi tümenlerinin olduğu bir bölgeye dokununca açılır (bkz. main.gd).
## Bayraklı başlık, tür başına simgeli satırlar, ortalama güç çubuğu ve "başka bölgeye dokun"
## ipucu. "Yarısını ayır" gösterilen tümenlerin yarısını ayırır; sonraki hedef seçimi yalnızca
## ayrılan yarıyı yürütür. "Tümen kur" (ana düğme), "Fabrika kur" ve "Tahkimat kur" bu bölgede
## üretim sıralar.

## "Yarısını ayır" düğmesine basıldığında yayılır.
signal yarisini_ayir_basildi
## "Tümen kur" ("tumen"), "Fabrika kur" ("fabrika") ya da "Tahkimat kur" ("tahkimat")
## düğmesine basıldığında yayılır.
signal insa_istendi(tur: String)

const DUGME_BOYUTU: Vector2 = Vector2(210.0, 112.0)
const BAYRAK_YUKSEKLIGI: float = 40.0

var _bayrak_yeri: HBoxContainer = null
var _ad: Label = null
var _sayi_rozeti: HBoxContainer = null
var _turler: HBoxContainer = null
var _guc: ProgressBar = null
var _guc_yazisi: Label = null


func _ready() -> void:
	var yatay: HBoxContainer = Bilesenler.sira(ArayuzTemasi.BOSLUK_3)
	add_child(yatay)

	var bilgi: VBoxContainer = Bilesenler.yigin(ArayuzTemasi.BOSLUK_1)
	bilgi.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	yatay.add_child(bilgi)

	var baslik: HBoxContainer = Bilesenler.sira(ArayuzTemasi.BOSLUK_2)
	bilgi.add_child(baslik)
	_bayrak_yeri = Bilesenler.sira(0)
	baslik.add_child(_bayrak_yeri)
	_ad = Bilesenler.baslik("", ArayuzTemasi.YAZI_ALT_BASLIK)
	baslik.add_child(_ad)
	_sayi_rozeti = Bilesenler.sira(0)
	baslik.add_child(_sayi_rozeti)
	var ipucu: Label = Bilesenler.ikincil_yazi("Yürütmek için hedefe dokun")
	ipucu.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ipucu.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ipucu.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	ipucu.custom_minimum_size.x = 120.0
	baslik.add_child(ipucu)

	_turler = Bilesenler.sira(ArayuzTemasi.BOSLUK_4)
	bilgi.add_child(_turler)

	var guc_sirasi: HBoxContainer = Bilesenler.sira(ArayuzTemasi.BOSLUK_1)
	bilgi.add_child(guc_sirasi)
	guc_sirasi.add_child(Simgeler.dugum("ordu", 28.0))
	guc_sirasi.add_child(Bilesenler.ikincil_yazi("Güç"))
	_guc = Bilesenler.ilerleme_cubugu(ArayuzTemasi.BASARI, 14.0)
	_guc.custom_minimum_size.x = 220.0
	guc_sirasi.add_child(_guc)
	_guc_yazisi = Label.new()
	_guc_yazisi.add_theme_font_override("font", ArayuzTemasi.arayuz_fontu(600))
	_guc_yazisi.add_theme_font_size_override("font_size", ArayuzTemasi.YAZI_KUCUK)
	guc_sirasi.add_child(_guc_yazisi)

	var ayir: Button = Bilesenler.ikincil_dugme("Yarısını
ayır", "", Vector2(170.0, DUGME_BOYUTU.y))
	ayir.add_theme_font_size_override("font_size", ArayuzTemasi.YAZI_KUCUK)
	ayir.pressed.connect(func() -> void: yarisini_ayir_basildi.emit())
	yatay.add_child(ayir)
	yatay.add_child(InsaDugmeleri.dugme_olustur("fabrika", DUGME_BOYUTU, insa_istendi))
	yatay.add_child(InsaDugmeleri.dugme_olustur("tahkimat", DUGME_BOYUTU, insa_istendi))
	yatay.add_child(InsaDugmeleri.dugme_olustur("tumen", DUGME_BOYUTU, insa_istendi, true))
	hide()


## Bölgedeki tümenleri gösterir. `birlikler` boş olmamalı (main.gd çağırmadan önce denetler).
func goster(bolge: Bolge, birlikler: Array[Birlik], ulke: Ulke) -> void:
	for cocuk: Node in _bayrak_yeri.get_children():
		cocuk.queue_free()
	_bayrak_yeri.add_child(Bayraklar.dugum(ulke, BAYRAK_YUKSEKLIGI))
	_ad.text = bolge.ad
	for cocuk: Node in _sayi_rozeti.get_children():
		cocuk.queue_free()
	_sayi_rozeti.add_child(Bilesenler.rozet("%d tümen" % birlikler.size(), ArayuzTemasi.VURGU, ArayuzTemasi.VURGU_USTU))

	var toplam: float = 0.0
	var sayilar: Dictionary[String, int] = {}
	for birlik: Birlik in birlikler:
		toplam += birlik.guc
		sayilar[birlik.tur] = sayilar.get(birlik.tur, 0) + 1
	for cocuk: Node in _turler.get_children():
		cocuk.queue_free()
	for tur: String in BirlikTurleri.SIRA:
		if sayilar.has(tur):
			var satir: IstatistikSatiri = IstatistikSatiri.new(tur, BirlikTurleri.ad(tur))
			satir.deger_ayarla(str(sayilar[tur]))
			_turler.add_child(satir)
	var oran: float = toplam / maxf(birlikler.size() * 100.0, 1.0)
	_guc.value = clampf(oran, 0.0, 1.0)
	_guc_yazisi.text = "%d" % roundi(toplam)
	show()
