class_name Arayuz
extends CanvasLayer
## Haritanın üstündeki arayüz: üst çubuk ve alt bölge paneli.
##
## Paneller ve düğmeler dokunuşu yutar, aralarındaki boşluklar haritaya geçirir.

## Oyuncu "Bu ülkeyle oyna" düğmesine bastığında yayılır.
signal oyna_istendi(ulke_id: String)
## Oyuncu "Komşuları göster" düğmesini açıp kapadığında yayılır.
signal komsular_degisti(acik: bool)
## Oyuncu bölge ya da birlik panelinde "Tümen kur" / "Fabrika kur"a bastığında yayılır
## (`tur`: "tumen" ya da "fabrika").
signal insa_istendi(tur: String)
## Oyuncu birlik panelinde "Yarısını ayır" düğmesine bastığında yayılır.
signal yarisini_ayir_istendi
## Oyuncu "Savaş ilan et" düğmesini onayladığında, hedef ülkenin id'siyle yayılır.
signal savas_istendi(ulke_id: String)
## Oyuncu "Barış teklif et" düğmesine bastığında, hedef ülkenin id'siyle yayılır.
signal baris_istendi(ulke_id: String)
## Oyuncu zafer/kaybetme bildirimini kapattığında yayılır.
signal sonuc_kapatildi
## Oyuncu "Ordu: YZ" düğmesini açıp kapadığında yayılır.
signal yz_yonetimi_degisti(acik: bool)
## Oyuncu "Sıralama" düğmesini açtığında yayılır (güncel veri main.gd'den istenir).
signal siralama_istendi
## Oyuncu bir bildirim kartına dokunduğunda, ilgili bölge id'siyle (yoksa boş) yayılır.
signal bildirime_dokunuldu(bolge_id: String)

## Kaybetme başlığının rengi (üzüntü/tehlike).
const KAYBETME_RENGI: Color = Color("#e05b5b")

## Ekran kenarıyla arayüz arasındaki boşluk (piksel).
const KENAR_BOSLUGU: int = 20
## Bildirim kartlarının üst çubuğun altında kalması için üstten boşluk (piksel).
const BILDIRIM_UST_BOSLUGU: float = 140.0
## Sıralama panelinin üst çubuğa ve alt panele binmemesi için bırakılan boşluklar (piksel).
const SIRALAMA_UST_BOSLUGU: float = 150.0
const SIRALAMA_ALT_BOSLUGU: float = 250.0

var _dunya: Dunya = null
var _kenar: MarginContainer = null
var _ust_cubuk: UstCubuk = null
var _bolge_paneli: BolgePaneli = null
var _birlik_paneli: BirlikPaneli = null
var _sonuc_paneli: SonucPaneli = null
var _siralama_paneli: SiralamaPaneli = null
var _bildirim_kutusu: BildirimKutusu = null


func kur(dunya: Dunya) -> void:
	_dunya = dunya

	var kok: Control = Control.new()
	kok.name = "Kok"
	kok.theme = ArayuzTemasi.olustur()
	kok.mouse_filter = Control.MOUSE_FILTER_IGNORE
	kok.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(kok)

	_kenar = MarginContainer.new()
	_kenar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_kenar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	kok.add_child(_kenar)

	var dikey: VBoxContainer = VBoxContainer.new()
	dikey.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_kenar.add_child(dikey)

	_ust_cubuk = UstCubuk.new()
	dikey.add_child(_ust_cubuk)
	_ust_cubuk.yz_yonetimi_degisti.connect(func(acik: bool) -> void: yz_yonetimi_degisti.emit(acik))
	_ust_cubuk.siralama_degisti.connect(_siralama_degisti)

	var bosluk: Control = Control.new()
	bosluk.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bosluk.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dikey.add_child(bosluk)

	_bolge_paneli = BolgePaneli.new()
	dikey.add_child(_bolge_paneli)
	_bolge_paneli.oyna_basildi.connect(func(ulke_id: String) -> void: oyna_istendi.emit(ulke_id))
	_bolge_paneli.komsular_degisti.connect(func(acik: bool) -> void: komsular_degisti.emit(acik))
	_bolge_paneli.savas_istendi.connect(func(ulke_id: String) -> void: savas_istendi.emit(ulke_id))
	_bolge_paneli.baris_istendi.connect(func(ulke_id: String) -> void: baris_istendi.emit(ulke_id))
	_bolge_paneli.insa_istendi.connect(func(tur: String) -> void: insa_istendi.emit(tur))

	_birlik_paneli = BirlikPaneli.new()
	dikey.add_child(_birlik_paneli)
	_birlik_paneli.yarisini_ayir_basildi.connect(func() -> void: yarisini_ayir_istendi.emit())
	_birlik_paneli.insa_istendi.connect(func(tur: String) -> void: insa_istendi.emit(tur))

	var sonuc_ortalayici: CenterContainer = CenterContainer.new()
	sonuc_ortalayici.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sonuc_ortalayici.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	kok.add_child(sonuc_ortalayici)
	_sonuc_paneli = SonucPaneli.new()
	sonuc_ortalayici.add_child(_sonuc_paneli)
	_sonuc_paneli.kapat_basildi.connect(func() -> void: sonuc_kapatildi.emit())

	# Sıralama paneli üst çubukla alt panel arasındaki boşluğun ortasında durur; ekranın
	# tam ortasında dursaydı alt panele biniyordu.
	var siralama_ortalayici: CenterContainer = CenterContainer.new()
	siralama_ortalayici.mouse_filter = Control.MOUSE_FILTER_IGNORE
	siralama_ortalayici.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	siralama_ortalayici.offset_top = SIRALAMA_UST_BOSLUGU
	siralama_ortalayici.offset_bottom = -SIRALAMA_ALT_BOSLUGU
	kok.add_child(siralama_ortalayici)
	_siralama_paneli = SiralamaPaneli.new()
	siralama_ortalayici.add_child(_siralama_paneli)

	# Sabit boyut: tek seferlik PRESET_TOP_RIGHT, kutu henüz boşken (sıfır içerik
	# genişliğinde) hesaplanıp donardı; sonradan eklenen kartlar büyümezdi.
	var bildirim_konumu: MarginContainer = MarginContainer.new()
	bildirim_konumu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bildirim_konumu.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	bildirim_konumu.offset_top = BILDIRIM_UST_BOSLUGU
	bildirim_konumu.offset_right = -KENAR_BOSLUGU
	bildirim_konumu.offset_left = -KENAR_BOSLUGU - BildirimKutusu.KART_BOYUTU.x
	bildirim_konumu.offset_bottom = BILDIRIM_UST_BOSLUGU + \
			(BildirimKutusu.KART_BOYUTU.y + 10.0) * BildirimKutusu.AZAMI_KART
	kok.add_child(bildirim_konumu)
	_bildirim_kutusu = BildirimKutusu.new()
	bildirim_konumu.add_child(_bildirim_kutusu)
	_bildirim_kutusu.bildirime_dokunuldu.connect(func(bolge_id: String) -> void: bildirime_dokunuldu.emit(bolge_id))

	get_viewport().size_changed.connect(_guvenli_alani_uygula)
	_guvenli_alani_uygula()


## Zafer bildirimini ortada gösterir. Oyun kilitlenmez; "sonrasında oynamaya devam edilebilir".
func zaferi_goster() -> void:
	_sonuc_paneli.goster("Zafer!",
			"Kıtandaki bölgelerin en az %%%d'i artık senin. Oynamaya devam edebilirsin." % roundi(Oyun.ZAFER_ORANI * 100),
			ArayuzTemasi.ETKIN_RENK)


## Kaybetme bildirimini ortada gösterir.
func kaybi_goster() -> void:
	_sonuc_paneli.goster("Kaybettin", "Ülken teslim oldu.", KAYBETME_RENGI)


## Alt panelde verilen bölgeyi ve ülkesini gösterir. Null verilirse panel gizlenir.
func bolgeyi_goster(bolge: Bolge, oyna_dugmesi_gorunur: bool,
		savas_dugmesi_gorunur: bool = false, baris_dugmesi_gorunur: bool = false,
		insa_dugmeleri_gorunur: bool = false) -> void:
	_birlik_paneli.hide()
	_bolge_paneli.goster(bolge, _dunya, oyna_dugmesi_gorunur, savas_dugmesi_gorunur, baris_dugmesi_gorunur,
			insa_dugmeleri_gorunur)


## Alt panelde, verilen bölgedeki oyuncu tümenlerini gösterir (bölge paneli yerine).
func birligi_goster(bolge: Bolge, birlikler: Array[Birlik], ulke: Ulke) -> void:
	_bolge_paneli.hide()
	_birlik_paneli.goster(bolge, birlikler, ulke)


## Oyuncunun ülkesini üst çubuğa yazar.
func oyuncuyu_goster(ulke: Ulke) -> void:
	_ust_cubuk.oyuncuyu_goster(ulke)


## Oyuncunun hazinesini üst çubuğa yazar.
func hazineyi_goster(miktar: float) -> void:
	_ust_cubuk.hazineyi_goster(miktar)


## Oyuncunun inşa kuyruğunun önündeki işi üst çubukta gösterir (bkz. UstCubuk.uretimi_goster).
func uretimi_goster(is_: InsaIsi, kuyrukta_baska: int) -> void:
	_ust_cubuk.uretimi_goster(is_, kuyrukta_baska)


## "Ordu: YZ" düğmesinin durumunu, sinyal yaymadan ayarlar (kayıttan yüklerken kullanılır).
func yz_yonetimini_goster(acik: bool) -> void:
	_ust_cubuk.yz_yonetimini_goster(acik)


## Güç sıralamasını ortada gösterir. `siralama`, Oyun.guc_siralamasi()'nin döndürdüğü listedir.
func siralamayi_goster(siralama: Array[Dictionary], oyuncu_ulkesi: String) -> void:
	_siralama_paneli.goster(siralama, _dunya, oyuncu_ulkesi)


## Yeni bir bildirim kartı gösterir (bkz. Oyun.bildirim_gonder).
func bildirim_goster(metin: String, bolge_id: String) -> void:
	_bildirim_kutusu.ekle(metin, bolge_id)


func _siralama_degisti(acik: bool) -> void:
	if acik:
		siralama_istendi.emit()
	else:
		_siralama_paneli.hide()


## Arayüzü çentik ve yuvarlak köşelerin dışında, güvenli alanın içinde tutar.
func _guvenli_alani_uygula() -> void:
	var sol: float = 0.0
	var ust: float = 0.0
	var sag: float = 0.0
	var alt: float = 0.0
	# Güvenli alan yalnızca telefonda anlamlıdır; bilgisayarda bütün pencere güvenlidir.
	if OS.has_feature("mobile"):
		var pencere: Vector2 = Vector2(DisplayServer.window_get_size())
		var guvenli: Rect2 = Rect2(DisplayServer.get_display_safe_area())
		if pencere.x > 0.0 and pencere.y > 0.0 and guvenli.size.x > 0.0 and guvenli.size.y > 0.0:
			# Güvenli alan gerçek ekran pikseliyle gelir; arayüzün birimine çevrilir.
			var olcek: Vector2 = get_viewport().get_visible_rect().size / pencere
			sol = maxf(0.0, guvenli.position.x) * olcek.x
			ust = maxf(0.0, guvenli.position.y) * olcek.y
			sag = maxf(0.0, pencere.x - guvenli.end.x) * olcek.x
			alt = maxf(0.0, pencere.y - guvenli.end.y) * olcek.y
	_kenar.add_theme_constant_override("margin_left", KENAR_BOSLUGU + int(ceilf(sol)))
	_kenar.add_theme_constant_override("margin_top", KENAR_BOSLUGU + int(ceilf(ust)))
	_kenar.add_theme_constant_override("margin_right", KENAR_BOSLUGU + int(ceilf(sag)))
	_kenar.add_theme_constant_override("margin_bottom", KENAR_BOSLUGU + int(ceilf(alt)))
