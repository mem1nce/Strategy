class_name BolgePaneli
extends PanelContainer
## Alt panel: dokunulan bölgenin ve ülkesinin bilgilerini gösterir. Seçim yokken gizlidir.
##
## İki görünümü vardır (STIL.md):
## - Bölge görünümü: bayraklı başlık (bölge adı, başkent / ilişki rozetleri, ülke ve kıta),
##   simgeli istatistik satırları, ülke bonusu ve sağda düğmeler. Kara komşusu ve deniz geçişi
##   sayıları haritadaki vurgu renkleriyle yazılır (renk açıklaması da olur).
## - Ülke seçimi (oyuncu henüz ülkesini seçmediyse): büyük bayrak, ülke adı, nüfus / sanayi /
##   ordu çubukları (dünyadaki en büyüğe göre) ve tek ana düğme "Bu ülkeyle oyna".
## Her görünümde en çok bir düğme birincildir (vurgu renginde).

## "Bu ülkeyle oyna" düğmesine basıldığında, gösterilen bölgenin ülkesinin id'siyle yayılır.
signal oyna_basildi(ulke_id: String)
## "Komşuları göster" düğmesi açılıp kapandığında yayılır.
signal komsular_degisti(acik: bool)
## "Savaş ilan et" onaylandığında, gösterilen bölgenin ülkesinin id'siyle yayılır.
signal savas_istendi(ulke_id: String)
## "Barış teklif et" düğmesine basıldığında, gösterilen bölgenin ülkesinin id'siyle yayılır.
signal baris_istendi(ulke_id: String)
## "Tümen kur" ("tumen"), "Fabrika kur" ("fabrika") ya da "Tahkimat kur" ("tahkimat")
## düğmesine basıldığında yayılır.
signal insa_istendi(tur: String)

const DUGME_BOYUTU: Vector2 = Vector2(210.0, 112.0)
const ANA_DUGME_BOYUTU: Vector2 = Vector2(340.0, 112.0)
const BAYRAK_YUKSEKLIGI: float = 40.0
const BUYUK_BAYRAK_YUKSEKLIGI: float = 84.0
const CUBUK_GENISLIGI: float = 300.0

var _ulke_id: String = ""
var _ulke_adi: String = ""

var _bolge_gorunumu: VBoxContainer = null
var _bayrak_yeri: HBoxContainer = null
var _ad: Label = null
var _baskent: Control = null
var _iliski_yeri: HBoxContainer = null
var _ulke: Label = null
var _nufus: IstatistikSatiri = null
var _gsyh: IstatistikSatiri = null
var _birlikler: IstatistikSatiri = null
var _kara: IstatistikSatiri = null
var _deniz: IstatistikSatiri = null
var _tahkimat: IstatistikSatiri = null
var _bonus: Label = null

var _secim_gorunumu: HBoxContainer = null
var _buyuk_bayrak_yeri: HBoxContainer = null
var _secim_adi: Label = null
var _secim_alt: Label = null
var _secim_bonus: Label = null
## Seçim kartındaki çubuklar: ad -> [ProgressBar, değer Label].
var _cubuklar: Dictionary[String, Array] = {}

var _komsular: Button = null
var _oyna: Button = null
var _savas: Button = null
var _savas_onayi: ConfirmationDialog = null
var _tumen_kur: Button = null
var _fabrika_kur: Button = null
var _tahkimat_kur: Button = null
var _baris: Button = null


func _ready() -> void:
	var yatay: HBoxContainer = Bilesenler.sira(ArayuzTemasi.BOSLUK_3)
	add_child(yatay)
	_bolge_gorunumunu_kur(yatay)
	_secim_gorunumunu_kur(yatay)

	_komsular = Bilesenler.ikincil_dugme("", "diplomasi", DUGME_BOYUTU)
	_komsular.add_theme_font_size_override("font_size", ArayuzTemasi.YAZI_KUCUK)
	_komsular.toggle_mode = true
	_komsular.toggled.connect(_komsular_basildi)
	yatay.add_child(_komsular)

	_oyna = Bilesenler.birincil_dugme("Bu ülkeyle oyna", "oynat", ANA_DUGME_BOYUTU)
	_oyna.pressed.connect(func() -> void: oyna_basildi.emit(_ulke_id))
	yatay.add_child(_oyna)

	_savas = Bilesenler.ikincil_dugme("Savaş ilan et", "savas", ANA_DUGME_BOYUTU)
	_savas.theme_type_variation = ArayuzTemasi.TEHLIKE_DUGME
	_savas.pressed.connect(_savas_basildi)
	yatay.add_child(_savas)

	_savas_onayi = ArayuzTemasi.onay_penceresi_olustur()
	_savas_onayi.confirmed.connect(func() -> void: savas_istendi.emit(_ulke_id))
	add_child(_savas_onayi)

	_baris = Bilesenler.birincil_dugme("Barış teklif et", "baris", ANA_DUGME_BOYUTU)
	_baris.pressed.connect(func() -> void: baris_istendi.emit(_ulke_id))
	yatay.add_child(_baris)

	_fabrika_kur = InsaDugmeleri.dugme_olustur("fabrika", DUGME_BOYUTU, insa_istendi)
	yatay.add_child(_fabrika_kur)
	_tahkimat_kur = InsaDugmeleri.dugme_olustur("tahkimat", DUGME_BOYUTU, insa_istendi)
	yatay.add_child(_tahkimat_kur)
	_tumen_kur = InsaDugmeleri.dugme_olustur("tumen", DUGME_BOYUTU, insa_istendi, true)
	yatay.add_child(_tumen_kur)

	_komsu_dugmesini_yenile()
	hide()


func _bolge_gorunumunu_kur(yatay: HBoxContainer) -> void:
	_bolge_gorunumu = Bilesenler.yigin(ArayuzTemasi.BOSLUK_1)
	_bolge_gorunumu.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	yatay.add_child(_bolge_gorunumu)

	var baslik: HBoxContainer = Bilesenler.sira(ArayuzTemasi.BOSLUK_2)
	_bolge_gorunumu.add_child(baslik)
	_bayrak_yeri = Bilesenler.sira(0)
	baslik.add_child(_bayrak_yeri)
	_ad = Bilesenler.baslik("", ArayuzTemasi.YAZI_ALT_BASLIK)
	baslik.add_child(_ad)
	_baskent = Bilesenler.rozet("Başkent", ArayuzTemasi.VURGU, ArayuzTemasi.VURGU_USTU)
	baslik.add_child(_baskent)
	_iliski_yeri = Bilesenler.sira(0)
	baslik.add_child(_iliski_yeri)
	_ulke = Bilesenler.ikincil_yazi()
	_ulke.custom_minimum_size.x = 160.0
	_ulke.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_ulke.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_ulke.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	baslik.add_child(_ulke)

	var izgara: GridContainer = GridContainer.new()
	izgara.columns = 2
	izgara.add_theme_constant_override("h_separation", ArayuzTemasi.BOSLUK_4)
	izgara.add_theme_constant_override("v_separation", 2)
	_bolge_gorunumu.add_child(izgara)
	_nufus = IstatistikSatiri.new("nufus", "Nüfus")
	_gsyh = IstatistikSatiri.new("para", "Ülke GSYH")
	_birlikler = IstatistikSatiri.new("ordu", "Birlikler")
	_kara = IstatistikSatiri.new("alan", "Kara komşusu")
	_deniz = IstatistikSatiri.new("baris", "Deniz geçişi")
	_tahkimat = IstatistikSatiri.new("tahkimat", "Tahkimat")
	for satir: IstatistikSatiri in [_nufus, _gsyh, _birlikler, _kara, _deniz, _tahkimat]:
		satir.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		izgara.add_child(satir)

	_bonus = _bonus_satiri(_bolge_gorunumu)


func _secim_gorunumunu_kur(yatay: HBoxContainer) -> void:
	_secim_gorunumu = Bilesenler.sira(ArayuzTemasi.BOSLUK_3)
	_secim_gorunumu.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	yatay.add_child(_secim_gorunumu)
	_buyuk_bayrak_yeri = Bilesenler.sira(0)
	_buyuk_bayrak_yeri.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_secim_gorunumu.add_child(_buyuk_bayrak_yeri)

	var orta: VBoxContainer = Bilesenler.yigin(ArayuzTemasi.BOSLUK_1)
	orta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_secim_gorunumu.add_child(orta)
	_secim_adi = Bilesenler.baslik("")
	_secim_adi.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	orta.add_child(_secim_adi)
	_secim_alt = Bilesenler.ikincil_yazi()
	orta.add_child(_secim_alt)
	_secim_bonus = _bonus_satiri(orta)

	var cubuklar: GridContainer = GridContainer.new()
	cubuklar.columns = 3
	cubuklar.add_theme_constant_override("h_separation", ArayuzTemasi.BOSLUK_2)
	cubuklar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_secim_gorunumu.add_child(cubuklar)
	for bilgi: Array in [["nufus", "Nüfus", ArayuzTemasi.IKINCIL_YAZI], ["sanayi", "Sanayi", ArayuzTemasi.VURGU],
			["ordu", "Ordu", ArayuzTemasi.BASARI]]:
		var etiket: HBoxContainer = Bilesenler.sira(ArayuzTemasi.BOSLUK_1)
		etiket.add_child(Simgeler.dugum(bilgi[0], 30.0))
		etiket.add_child(Bilesenler.ikincil_yazi(bilgi[1]))
		cubuklar.add_child(etiket)
		var cubuk: ProgressBar = Bilesenler.ilerleme_cubugu(bilgi[2], 14.0)
		cubuk.custom_minimum_size.x = CUBUK_GENISLIGI
		cubuklar.add_child(cubuk)
		var deger: Label = Label.new()
		deger.add_theme_font_override("font", ArayuzTemasi.arayuz_fontu(600))
		deger.add_theme_font_size_override("font_size", ArayuzTemasi.YAZI_KUCUK)
		deger.custom_minimum_size.x = 150.0
		cubuklar.add_child(deger)
		_cubuklar[bilgi[0]] = [cubuk, deger]


func _bonus_satiri(ust: Container) -> Label:
	var sira: HBoxContainer = Bilesenler.sira(ArayuzTemasi.BOSLUK_1)
	sira.add_child(Simgeler.dugum("bilgi", 28.0, ArayuzTemasi.VURGU))
	var yazi: Label = Bilesenler.ikincil_yazi()
	yazi.add_theme_color_override("font_color", ArayuzTemasi.VURGU)
	yazi.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	yazi.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	sira.add_child(yazi)
	ust.add_child(sira)
	return yazi


## Bölgenin ve ülkesinin bilgilerini gösterir. Bölge null ise paneli gizler.
## `insa_dugmeleri_gorunur`, bölge oyuncunun kendi bölgesiyse true verilir. `ulke_ozeti`
## yalnızca ülke seçiminde verilir (bkz. main.gd, _ulke_ozeti).
func goster(bolge: Bolge, dunya: Dunya, oyna_dugmesi_gorunur: bool,
		savas_dugmesi_gorunur: bool = false, baris_dugmesi_gorunur: bool = false,
		insa_dugmeleri_gorunur: bool = false, ulke_ozeti: Dictionary = {}) -> void:
	if bolge == null:
		_ulke_id = ""
		hide()
		return
	var ulke: Ulke = dunya.bolgenin_sahibi(bolge.id)
	_ulke_id = ulke.id
	_ulke_adi = ulke.ad
	var secim: bool = oyna_dugmesi_gorunur
	_bolge_gorunumu.visible = not secim
	_secim_gorunumu.visible = secim
	if secim:
		_secimi_doldur(ulke, bolge, ulke_ozeti)
	else:
		_bolgeyi_doldur(ulke, bolge, insa_dugmeleri_gorunur, savas_dugmesi_gorunur or baris_dugmesi_gorunur,
				baris_dugmesi_gorunur)
	_oyna.visible = oyna_dugmesi_gorunur
	_savas.visible = savas_dugmesi_gorunur
	_baris.visible = baris_dugmesi_gorunur
	_tumen_kur.visible = insa_dugmeleri_gorunur
	_fabrika_kur.visible = insa_dugmeleri_gorunur
	_tahkimat_kur.visible = insa_dugmeleri_gorunur
	show()


func _bolgeyi_doldur(ulke: Ulke, bolge: Bolge, kendi: bool, yabanci_oyunda: bool, savasta: bool) -> void:
	_bayragi_koy(_bayrak_yeri, ulke, BAYRAK_YUKSEKLIGI)
	_ad.text = bolge.ad
	_baskent.visible = bolge.baskent
	for cocuk: Node in _iliski_yeri.get_children():
		cocuk.queue_free()
	if kendi:
		_iliski_yeri.add_child(Bilesenler.rozet("Senin", ArayuzTemasi.BASARI, ArayuzTemasi.VURGU_USTU))
	elif savasta:
		_iliski_yeri.add_child(Bilesenler.rozet("Savaşta", ArayuzTemasi.TEHLIKE))
	elif yabanci_oyunda:
		_iliski_yeri.add_child(Bilesenler.rozet("Tarafsız"))
	_ulke.text = "%s · %s" % [ulke.ad, ulke.kita]
	_nufus.deger_ayarla(Bicim.nufus(bolge.nufus))
	_gsyh.deger_ayarla(Bicim.para(ulke.gsyh_milyon_dolar))
	_kara.deger_ayarla(str(bolge.kara_komsulari.size()), HaritaGorunumu.KARA_KOMSUSU_RENGI)
	_deniz.deger_ayarla(str(bolge.deniz_gecisleri.size()), HaritaGorunumu.DENIZ_GECISI_RENGI)
	_tahkimat.deger_ayarla("%d/%d" % [bolge.tahkimat, InsaDugmeleri.tahkimat_azami])
	_tahkimat.visible = bolge.tahkimat > 0
	_bonus.text = UlkeBonuslari.metin(ulke.id)


func _secimi_doldur(ulke: Ulke, bolge: Bolge, ozet: Dictionary) -> void:
	_bayragi_koy(_buyuk_bayrak_yeri, ulke, BUYUK_BAYRAK_YUKSEKLIGI)
	_secim_adi.text = ulke.ad
	_secim_alt.text = "%s · Dokunulan bölge: %s" % [ulke.kita, bolge.ad]
	_secim_bonus.text = UlkeBonuslari.metin(ulke.id)
	_cubugu_ayarla("nufus", float(ozet.get("nufus_orani", 0.0)), Bicim.nufus(ulke.nufus))
	_cubugu_ayarla("sanayi", float(ozet.get("sanayi_orani", 0.0)), "+%s/gün" % Bicim.kisa(float(ozet.get("sanayi", 0.0))))
	_cubugu_ayarla("ordu", float(ozet.get("ordu_orani", 0.0)), "%d tümen" % int(ozet.get("tumen", 0)))


func _cubugu_ayarla(ad: String, oran: float, metin: String) -> void:
	(_cubuklar[ad][0] as ProgressBar).value = clampf(oran, 0.0, 1.0)
	(_cubuklar[ad][1] as Label).text = metin


static func _bayragi_koy(yer: HBoxContainer, ulke: Ulke, yukseklik: float) -> void:
	for cocuk: Node in yer.get_children():
		cocuk.queue_free()
	yer.add_child(Bayraklar.dugum(ulke, yukseklik))


## Bölgedeki tümenlerin bilgisini yazar (bkz. main.gd: savaş sisi altında görünmeyen bölgede
## "bilinmiyor"). `gorunur` false ise yabancı tahkimat da gizlenir.
func birlikleri_yaz(metin: String, gorunur: bool) -> void:
	_birlikler.deger_ayarla(metin)
	if not gorunur:
		_tahkimat.hide()


func _savas_basildi() -> void:
	_savas_onayi.dialog_text = "%s'a savaş ilan etmek istiyor musun?" % _ulke_adi
	_savas_onayi.popup_centered()


func _komsular_basildi(acik: bool) -> void:
	_komsu_dugmesini_yenile()
	komsular_degisti.emit(acik)


func _komsu_dugmesini_yenile() -> void:
	_komsular.text = "Komşuları\ngizle" if _komsular.button_pressed else "Komşuları\ngöster"
