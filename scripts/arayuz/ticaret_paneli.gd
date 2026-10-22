class_name TicaretPaneli
extends PanelContainer
## Üst çubuktaki "Ticaret" düğmesiyle açılan panel (STIL.md): başlıkta kapasite rozeti, dört
## sekme — anlaşmalar (ortak, günlük değer, rota uzunluğu, geçtiği geçitler), en iyi aday
## ortaklar ("Teklif et"), gelen teklifler (Kabul / Reddet) ve ambargolar ("Kaldır").
## Yalnızca gösterir; veriyi main.gd hazırlar (bkz. main.gd, _ticaret_ozeti).

signal kapat_basildi
## "Teklif et" (aday sekmesi) basıldı.
signal teklif_istendi(ulke_id: String)
## Bir anlaşmanın "Bitir" düğmesi basıldı.
signal bitir_istendi(ulke_id: String)
## Gelen bir teklif kabul ya da reddedildi.
signal teklif_yanitlandi(ulke_id: String, kabul: bool)
## Oyuncunun uyguladığı bir ambargonun "Kaldır" düğmesi basıldı.
signal ambargo_kaldir_istendi(ulke_id: String)

const GENISLIK: float = 1100.0
const LISTE_YUKSEKLIGI: float = 520.0
const BAYRAK_YUKSEKLIGI: float = 36.0
const SATIR_DUGMESI: Vector2 = Vector2(170.0, 96.0)
const DEGER_GENISLIGI: float = 170.0
const SEKMELER: Array[String] = ["Anlaşmalar", "Adaylar", "Teklifler", "Ambargolar"]

var _kapasite_yeri: HBoxContainer = null
var _sekmeler: SekmeGrubu = null
var _sekme_dugmeleri: Array[Button] = []
var _liste: VBoxContainer = null
var _secili: int = 0
var _ozet: Dictionary = {}
var _dunya: Dunya = null


func _ready() -> void:
	custom_minimum_size = Vector2(GENISLIK, 0.0)
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	var panel: BaslikliPanel = BaslikliPanel.new("Ticaret")
	panel.isaret_ayarla(Simgeler.dugum("ticaret", 40.0, ArayuzTemasi.VURGU))
	add_child(panel)
	_kapasite_yeri = Bilesenler.sira(ArayuzTemasi.BOSLUK_1)
	panel.sag_alan.add_child(_kapasite_yeri)
	var kapat: Button = Bilesenler.ikincil_dugme("", "kapat", Vector2(96.0, 96.0))
	kapat.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kapat.pressed.connect(func() -> void: kapat_basildi.emit())
	panel.sag_alan.add_child(kapat)

	var govde: VBoxContainer = panel.govde
	govde.add_theme_constant_override("separation", ArayuzTemasi.BOSLUK_2)
	_sekmeler = SekmeGrubu.new()
	_sekmeler.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	for ad: String in SEKMELER:
		_sekme_dugmeleri.append(_sekmeler.ekle(ad, "", Vector2(240.0, 96.0)))
	_sekmeler.secildi.connect(func(sira: int) -> void:
		_secili = sira
		_listeyi_kur())
	govde.add_child(_sekmeler)

	var kaydirma: ScrollContainer = ScrollContainer.new()
	kaydirma.custom_minimum_size = Vector2(0.0, LISTE_YUKSEKLIGI)
	kaydirma.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	govde.add_child(kaydirma)
	_liste = Bilesenler.yigin(ArayuzTemasi.BOSLUK_1)
	_liste.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	kaydirma.add_child(_liste)
	hide()


## `ozet`: {"kapasite": int, "sayi": int,
##   "anlasmalar": [{"ulke", "deger", "km", "gecitler": Array[String]}],
##   "adaylar": [{"ulke", "deger"}], "teklifler": [{"ulke", "deger", "kalan_gun"}],
##   "ambargolar": [{"ulke", "uygulayan_sen": bool}]}
## `ulke` alanları ülke id'sidir. Teklif varsa ve panel yeni açılıyorsa Teklifler sekmesi seçilir.
func goster(ozet: Dictionary, dunya: Dunya) -> void:
	_dunya = dunya
	if not visible and not (ozet.get("teklifler", []) as Array).is_empty():
		_secili = 2
		_sekmeler.sec(_secili)
	_ozet = ozet
	for cocuk: Node in _kapasite_yeri.get_children():
		cocuk.queue_free()
	var sayi: int = int(ozet.get("sayi", 0))
	var kapasite: int = int(ozet.get("kapasite", 0))
	_kapasite_yeri.add_child(Bilesenler.rozet("Kapasite %d/%d" % [sayi, kapasite],
			ArayuzTemasi.VURGU if sayi < kapasite else ArayuzTemasi.KENAR,
			ArayuzTemasi.VURGU_USTU if sayi < kapasite else ArayuzTemasi.YAZI))
	var teklif_sayisi: int = (ozet.get("teklifler", []) as Array).size()
	_sekme_dugmeleri[2].text = "Teklifler (%d)" % teklif_sayisi if teklif_sayisi > 0 else "Teklifler"
	_listeyi_kur()
	show()


func _listeyi_kur() -> void:
	for cocuk: Node in _liste.get_children():
		_liste.remove_child(cocuk)
		cocuk.queue_free()
	match _secili:
		0:
			_anlasmalari_yaz()
		1:
			_adaylari_yaz()
		2:
			_teklifleri_yaz()
		3:
			_ambargolari_yaz()


func _anlasmalari_yaz() -> void:
	var liste: Array = _ozet.get("anlasmalar", [])
	if liste.is_empty():
		_bos_yaz("Henüz ticaret anlaşman yok. Adaylar sekmesinden teklif edebilirsin.")
		return
	for oge: Dictionary in liste:
		var gecitler: Array = oge.get("gecitler", [])
		var alt: String = "Rota ≈ %d km" % (roundi(float(oge.get("km", 0.0)) / 10.0) * 10)
		if float(oge.get("km", 0.0)) <= 0.0:
			alt = "Rota yok: yol kapalı"
		alt += " · Geçit: %s" % (", ".join(PackedStringArray(gecitler)) if not gecitler.is_empty() else "yok")
		var satir: HBoxContainer = _satir(oge["ulke"], alt, float(oge.get("deger", 0.0)))
		var bitir: Button = Bilesenler.ikincil_dugme("Bitir", "", SATIR_DUGMESI)
		bitir.theme_type_variation = ArayuzTemasi.TEHLIKE_DUGME
		var ulke_id: String = oge["ulke"]
		bitir.pressed.connect(func() -> void: bitir_istendi.emit(ulke_id))
		satir.add_child(bitir)


func _adaylari_yaz() -> void:
	var liste: Array = _ozet.get("adaylar", [])
	if liste.is_empty():
		_bos_yaz("Şu an anlaşma yapabileceğin uygun bir ülke yok.")
		return
	var dolu: bool = int(_ozet.get("sayi", 0)) >= int(_ozet.get("kapasite", 0))
	if dolu:
		_bos_yaz("Kapasiten dolu: kabul edilen yeni anlaşma en zayıf anlaşmanın yerini alır.")
	for oge: Dictionary in liste:
		var satir: HBoxContainer = _satir(oge["ulke"], "Tahmini günlük değer", float(oge.get("deger", 0.0)))
		var teklif: Button = Bilesenler.ikincil_dugme("Teklif et", "", SATIR_DUGMESI)
		var ulke_id: String = oge["ulke"]
		teklif.pressed.connect(func() -> void: teklif_istendi.emit(ulke_id))
		satir.add_child(teklif)


func _teklifleri_yaz() -> void:
	var liste: Array = _ozet.get("teklifler", [])
	if liste.is_empty():
		_bos_yaz("Gelen teklif yok.")
		return
	for oge: Dictionary in liste:
		var satir: HBoxContainer = _satir(oge["ulke"], "%d gün içinde yanıtla" % int(oge.get("kalan_gun", 0)),
				float(oge.get("deger", 0.0)))
		var ulke_id: String = oge["ulke"]
		var kabul: Button = Bilesenler.ikincil_dugme("Kabul", "", Vector2(140.0, 96.0))
		kabul.pressed.connect(func() -> void: teklif_yanitlandi.emit(ulke_id, true))
		satir.add_child(kabul)
		var red: Button = Bilesenler.ikincil_dugme("Reddet", "", Vector2(140.0, 96.0))
		red.pressed.connect(func() -> void: teklif_yanitlandi.emit(ulke_id, false))
		satir.add_child(red)


func _ambargolari_yaz() -> void:
	var liste: Array = _ozet.get("ambargolar", [])
	if liste.is_empty():
		_bos_yaz("Ambargo yok. Bir ülkeye ambargoyu onun panelinden uygulayabilirsin.")
		return
	for oge: Dictionary in liste:
		var sen: bool = bool(oge.get("uygulayan_sen", false))
		var satir: HBoxContainer = _satir(oge["ulke"], "Sen ambargo uyguluyorsun" if sen else "Sana ambargo uyguluyor", 0.0, false)
		if sen:
			var kaldir: Button = Bilesenler.ikincil_dugme("Kaldır", "", SATIR_DUGMESI)
			var ulke_id: String = oge["ulke"]
			kaldir.pressed.connect(func() -> void: ambargo_kaldir_istendi.emit(ulke_id))
			satir.add_child(kaldir)


## Bir liste satırı: kart içinde bayrak, ülke adı ve altında açıklama, sağda günlük değer.
## Düğmeler dönen sıraya eklenir.
func _satir(ulke_id: String, alt_yazi: String, deger: float, deger_goster: bool = true) -> HBoxContainer:
	var kart: PanelContainer = Bilesenler.kart()
	_liste.add_child(kart)
	var sira: HBoxContainer = Bilesenler.sira(ArayuzTemasi.BOSLUK_2)
	kart.add_child(sira)
	var ulke: Ulke = _dunya.ulkeler.get(ulke_id) if _dunya != null else null
	if ulke != null:
		var bayrak: Control = Bayraklar.dugum(ulke, BAYRAK_YUKSEKLIGI)
		bayrak.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		sira.add_child(bayrak)
	var yazilar: VBoxContainer = Bilesenler.yigin(2)
	yazilar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	yazilar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	sira.add_child(yazilar)
	var ad: Label = Label.new()
	ad.text = ulke.ad if ulke != null else ulke_id
	ad.add_theme_font_override("font", ArayuzTemasi.arayuz_fontu(600))
	ad.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	yazilar.add_child(ad)
	var alt: Label = Bilesenler.ikincil_yazi(alt_yazi)
	alt.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	yazilar.add_child(alt)
	if deger_goster:
		var deger_yazisi: Label = Label.new()
		deger_yazisi.text = "+%s/gün" % Bicim.tutar(deger)
		deger_yazisi.custom_minimum_size.x = DEGER_GENISLIGI
		deger_yazisi.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		deger_yazisi.add_theme_font_override("font", ArayuzTemasi.arayuz_fontu(600))
		deger_yazisi.add_theme_color_override("font_color", ArayuzTemasi.BASARI if deger > 0.0 else ArayuzTemasi.SOLUK_YAZI)
		sira.add_child(deger_yazisi)
	return sira


func _bos_yaz(metin: String) -> void:
	var yazi: Label = Bilesenler.ikincil_yazi(metin)
	yazi.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_liste.add_child(yazi)
