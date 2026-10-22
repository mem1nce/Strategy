class_name ButcePaneli
extends PanelContainer
## Üst çubuktaki ülke kartına dokununca açılan Bütçe paneli (STIL.md): gelir ve gider
## kalemleri, günlük net, borç ve limiti, iflas durumu, son 90 günün hazine grafiği.
## Yalnızca gösterir; veriyi main.gd hazırlar (bkz. main.gd, _butce_ozeti).

signal kapat_basildi

const GENISLIK: float = 1080.0
const GRAFIK_BOYUTU: Vector2 = Vector2(0.0, 120.0)

var _gelirler: VBoxContainer = null
var _giderler: VBoxContainer = null
var _net: IstatistikSatiri = null
var _borc: IstatistikSatiri = null
var _borc_cubugu: ProgressBar = null
var _durum_yeri: HBoxContainer = null
var _grafik: HazineGrafigi = null
var _kaynaklar: GridContainer = null


func _ready() -> void:
	custom_minimum_size = Vector2(GENISLIK, 0.0)
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	var panel: BaslikliPanel = BaslikliPanel.new("Bütçe")
	panel.isaret_ayarla(Simgeler.dugum("para", 40.0, ArayuzTemasi.VURGU))
	add_child(panel)
	_durum_yeri = Bilesenler.sira(ArayuzTemasi.BOSLUK_1)
	panel.sag_alan.add_child(_durum_yeri)
	var kapat: Button = Bilesenler.ikincil_dugme("", "kapat", Vector2(96.0, 96.0))
	kapat.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kapat.pressed.connect(func() -> void: kapat_basildi.emit())
	panel.sag_alan.add_child(kapat)

	var govde: VBoxContainer = panel.govde
	govde.add_theme_constant_override("separation", ArayuzTemasi.BOSLUK_2)
	var sutunlar: HBoxContainer = Bilesenler.sira(ArayuzTemasi.BOSLUK_4)
	govde.add_child(sutunlar)
	_gelirler = _sutun(sutunlar, "Gelir (günlük)", ArayuzTemasi.BASARI)
	_giderler = _sutun(sutunlar, "Gider (günlük)", ArayuzTemasi.TEHLIKE)

	var ozet: PanelContainer = Bilesenler.kart()
	govde.add_child(ozet)
	var ozet_ic: VBoxContainer = Bilesenler.yigin(ArayuzTemasi.BOSLUK_1)
	ozet.add_child(ozet_ic)
	_net = IstatistikSatiri.new("gelir", "Günlük net")
	ozet_ic.add_child(_net)
	_borc = IstatistikSatiri.new("para", "Borç / limit (90 günlük gelir)")
	ozet_ic.add_child(_borc)
	_borc_cubugu = Bilesenler.ilerleme_cubugu(ArayuzTemasi.TEHLIKE, 12.0)
	ozet_ic.add_child(_borc_cubugu)

	_kaynaklar = GridContainer.new()
	_kaynaklar.columns = 5
	_kaynaklar.add_theme_constant_override("h_separation", ArayuzTemasi.BOSLUK_4)
	_kaynaklar.add_theme_constant_override("v_separation", 4)
	govde.add_child(_kaynaklar)

	govde.add_child(Bilesenler.ikincil_yazi("Hazine, son 90 gün"))
	_grafik = HazineGrafigi.new()
	_grafik.custom_minimum_size = GRAFIK_BOYUTU
	govde.add_child(_grafik)
	hide()


func _sutun(ust: HBoxContainer, baslik: String, renk: Color) -> VBoxContainer:
	var sutun: VBoxContainer = Bilesenler.yigin(4)
	sutun.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ust.add_child(sutun)
	var yazi: Label = Bilesenler.baslik(baslik, ArayuzTemasi.YAZI_KUCUK)
	yazi.add_theme_color_override("font_color", renk)
	sutun.add_child(yazi)
	var liste: VBoxContainer = Bilesenler.yigin(2)
	sutun.add_child(liste)
	return liste


## `ozet`: {"gelirler": [[simge, ad, değer]], "giderler": [[simge, ad, değer]], "net": float,
## "hazine": float, "borc": float, "limit": float, "iflas": bool, "gecmis": PackedFloat32Array}
func goster(ozet: Dictionary) -> void:
	_listeyi_doldur(_gelirler, ozet.get("gelirler", []), ArayuzTemasi.BASARI)
	_listeyi_doldur(_giderler, ozet.get("giderler", []), ArayuzTemasi.TEHLIKE)
	var net: float = float(ozet.get("net", 0.0))
	_net.deger_ayarla("%s%s/gün" % ["+" if net >= 0.0 else "", Bicim.tutar(net)],
			ArayuzTemasi.BASARI if net >= 0.0 else ArayuzTemasi.TEHLIKE)
	var borc: float = float(ozet.get("borc", 0.0))
	var limit: float = maxf(float(ozet.get("limit", 1.0)), 1.0)
	_borc.deger_ayarla("%s / %s" % [Bicim.kisa(borc), Bicim.kisa(limit)],
			ArayuzTemasi.TEHLIKE if borc > 0.0 else ArayuzTemasi.YAZI)
	_borc_cubugu.value = clampf(borc / limit, 0.0, 1.0)
	for cocuk: Node in _durum_yeri.get_children():
		cocuk.queue_free()
	if bool(ozet.get("iflas", false)):
		_durum_yeri.add_child(Bilesenler.rozet("İflas: inşaat durdu", ArayuzTemasi.TEHLIKE))
	elif borc > 0.0:
		_durum_yeri.add_child(Bilesenler.rozet("Borçta: faiz işliyor", ArayuzTemasi.VURGU, ArayuzTemasi.VURGU_USTU))
	_grafik.degerleri_ayarla(ozet.get("gecmis", PackedFloat32Array()))
	_kaynaklari_doldur(ozet.get("kaynaklar", []))
	show()


## Petrol ve maden: üretim, tüketim, dünya fiyatı (eğilim okuyla) ve durum (ihraç / ithal / açık).
## Her satır: [simge, ad, üretim, tüketim, fiyat, önceki fiyat, açık].
func _kaynaklari_doldur(satirlar: Array) -> void:
	for cocuk: Node in _kaynaklar.get_children():
		cocuk.queue_free()
	for baslik: String in ["Kaynak", "Üretim", "Tüketim", "Dünya fiyatı", "Durum"]:
		_kaynaklar.add_child(Bilesenler.ikincil_yazi(baslik))
	for satir: Array in satirlar:
		var ad: HBoxContainer = Bilesenler.sira(ArayuzTemasi.BOSLUK_1)
		ad.add_child(Simgeler.dugum(satir[0], 30.0))
		ad.add_child(_deger_yazisi(satir[1], ArayuzTemasi.YAZI))
		_kaynaklar.add_child(ad)
		var uretim: float = satir[2]
		var talep: float = satir[3]
		_kaynaklar.add_child(_deger_yazisi(Bicim.tutar(uretim), ArayuzTemasi.YAZI))
		_kaynaklar.add_child(_deger_yazisi(Bicim.tutar(talep), ArayuzTemasi.YAZI))
		var fiyat: float = satir[4]
		var onceki: float = satir[5]
		var ok: String = "→"
		var ok_rengi: Color = ArayuzTemasi.IKINCIL_YAZI
		if fiyat > onceki + 0.0005:
			ok = "↑"
			ok_rengi = ArayuzTemasi.TEHLIKE
		elif fiyat < onceki - 0.0005:
			ok = "↓"
			ok_rengi = ArayuzTemasi.BASARI
		_kaynaklar.add_child(_deger_yazisi("%s %s" % [("%.2f" % fiyat).replace(".", ","), ok], ok_rengi))
		var acik: float = satir[6]
		var durum: String = "Dengede"
		var renk: Color = ArayuzTemasi.IKINCIL_YAZI
		if acik > 0.005:
			durum = "Açık: %s (alınamıyor)" % Bicim.tutar(acik)
			renk = ArayuzTemasi.TEHLIKE
		elif uretim - talep > 0.005:
			durum = "İhraç: %s" % Bicim.tutar(uretim - talep)
			renk = ArayuzTemasi.BASARI
		elif talep - uretim > 0.005:
			durum = "İthal: %s" % Bicim.tutar(talep - uretim)
			renk = ArayuzTemasi.VURGU
		_kaynaklar.add_child(_deger_yazisi(durum, renk))


static func _deger_yazisi(metin: String, renk: Color) -> Label:
	var yazi: Label = Label.new()
	yazi.text = metin
	yazi.add_theme_font_override("font", ArayuzTemasi.arayuz_fontu(600))
	yazi.add_theme_font_size_override("font_size", ArayuzTemasi.YAZI_KUCUK)
	yazi.add_theme_color_override("font_color", renk)
	return yazi


func _listeyi_doldur(liste: VBoxContainer, satirlar: Array, renk: Color) -> void:
	for cocuk: Node in liste.get_children():
		cocuk.queue_free()
	for satir: Array in satirlar:
		var oge: IstatistikSatiri = IstatistikSatiri.new(satir[0], satir[1])
		var deger: float = float(satir[2])
		oge.deger_ayarla(Bicim.tutar(deger), renk if absf(deger) >= 0.05 else ArayuzTemasi.SOLUK_YAZI)
		liste.add_child(oge)
