class_name UstCubuk
extends HBoxContainer
## Üst çubuk (STIL.md): solda oyuncunun ülke kartı (bayrak, ad, simgeli kaynaklar, süren
## inşa), ortada "Ülkeni seç" (seçim yapılana kadar), sağda tarih ve hız denetimi tek bir hapta,
## onun yanında "Ordu YZ", "Sıralama" ve "Teknoloji" araç düğmeleri.
## Zaman yöneticisini (Zaman) okur ve düğmelerle ona emir verir.

## "Ordu YZ" açılıp kapandığında yayılır.
signal yz_yonetimi_degisti(acik: bool)
## "Sıralama" düğmesi açılıp kapandığında yayılır.
signal siralama_degisti(acik: bool)
## "Teknoloji" düğmesi açılıp kapandığında yayılır.
signal teknoloji_degisti(acik: bool)

const ULKE_KARTI_GENISLIGI: float = 470.0
const BAYRAK_YUKSEKLIGI: float = 40.0
const DURDUR_DUGMESI_BOYUTU: Vector2 = Vector2(96.0, 96.0)
const ARAC_DUGMESI_BOYUTU: Vector2 = Vector2(112.0, 104.0)
const HIZ_DUGMESI_BOYUTU: Vector2 = Vector2(96.0, 96.0)
## Tarih değiştikçe hap genişleyip daralmasın.
const TARIH_GENISLIGI: float = 250.0

var _ulke_karti: PanelContainer = null
var _bayrak_yeri: HBoxContainer = null
var _ulke_adi: Label = null
var _hazine: HBoxContainer = null
var _gelir: HBoxContainer = null
var _tumen: HBoxContainer = null
var _bolge: HBoxContainer = null
var _uretim: HBoxContainer = null
var _secim_yazisi: PanelContainer = null
var _tarih: Label = null
var _durdur: Button = null
var _hiz_dugmeleri: Array[Button] = []
var _araclar: HBoxContainer = null
var _yz_yonetimi: Button = null
var _siralama: Button = null
var _teknoloji: Button = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("separation", ArayuzTemasi.BOSLUK_1)
	_ulke_kartini_kur()
	_secim_yazisini_kur()
	_zaman_hapini_kur()
	_araclari_kur()

	Zaman.saat_gecti.connect(_saat_gecti)
	Zaman.durum_degisti.connect(_yenile)
	_yenile()


## Oyuncunun ülkesini üst çubuğa yazar ve "Ülkeni seç" yazısını kaldırır.
func oyuncuyu_goster(ulke: Ulke) -> void:
	for cocuk: Node in _bayrak_yeri.get_children():
		cocuk.queue_free()
	_bayrak_yeri.add_child(Bayraklar.dugum(ulke, BAYRAK_YUKSEKLIGI))
	_ulke_adi.text = ulke.ad
	_ulke_karti.show()
	_secim_yazisi.hide()
	_araclar.show()


## Oyuncunun kaynaklarını yazar: hazine, günlük gelir, tümen ve bölge sayısı.
func kaynaklari_goster(hazine: float, gelir: float, tumen: int, bolge: int) -> void:
	(_hazine.get_child(1) as Label).text = Bicim.kisa(hazine)
	(_gelir.get_child(1) as Label).text = "+%s/gün" % Bicim.kisa(gelir)
	(_tumen.get_child(1) as Label).text = str(tumen)
	(_bolge.get_child(1) as Label).text = str(bolge)


## Oyuncunun inşa kuyruğunun önündeki işi gösterir. `is_` null ise (kuyruk boş) gösterge
## kalkar. `kuyrukta_baska`, öndeki dahil kuyruktaki toplam iş sayısıdır.
func uretimi_goster(is_: InsaIsi, kuyrukta_baska: int) -> void:
	if is_ == null:
		_uretim.hide()
		return
	var tur_adi: String = "Fabrika"
	match is_.tur:
		InsaIsi.Tur.TUMEN:
			tur_adi = BirlikTurleri.ad(is_.birlik_turu)
		InsaIsi.Tur.TAHKIMAT:
			tur_adi = "Tahkimat"
	var metin: String = "%s · %d sa" % [tur_adi, is_.kalan_saat]
	if kuyrukta_baska > 1:
		metin += "  +%d sırada" % (kuyrukta_baska - 1)
	(_uretim.get_child(1) as Label).text = metin
	_uretim.show()


func _ulke_kartini_kur() -> void:
	_ulke_karti = PanelContainer.new()
	_ulke_karti.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_ulke_karti.custom_minimum_size = Vector2(ULKE_KARTI_GENISLIGI, 0.0)
	add_child(_ulke_karti)
	var dikey: VBoxContainer = Bilesenler.yigin(ArayuzTemasi.BOSLUK_1)
	_ulke_karti.add_child(dikey)

	var baslik: HBoxContainer = Bilesenler.sira(ArayuzTemasi.BOSLUK_2)
	dikey.add_child(baslik)
	_bayrak_yeri = Bilesenler.sira(0)
	baslik.add_child(_bayrak_yeri)
	_ulke_adi = Bilesenler.baslik("", ArayuzTemasi.YAZI_ALT_BASLIK)
	_ulke_adi.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# Uzun ülke adları kartı genişletmesin, "…" ile kesilsin.
	_ulke_adi.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	baslik.add_child(_ulke_adi)

	var kaynaklar: HBoxContainer = Bilesenler.sira(ArayuzTemasi.BOSLUK_3)
	dikey.add_child(kaynaklar)
	_hazine = Bilesenler.simgeli_deger("para", ArayuzTemasi.VURGU)
	_gelir = Bilesenler.simgeli_deger("gelir", ArayuzTemasi.BASARI)
	_tumen = Bilesenler.simgeli_deger("ordu")
	_bolge = Bilesenler.simgeli_deger("alan")
	for deger: HBoxContainer in [_hazine, _gelir, _tumen, _bolge]:
		kaynaklar.add_child(deger)

	_uretim = Bilesenler.simgeli_deger("uretim", ArayuzTemasi.IKINCIL_YAZI)
	dikey.add_child(_uretim)
	_uretim.hide()
	_ulke_karti.hide()


## Ortadaki boşluğu doldurur. Dokunuşu haritaya geçirir.
func _secim_yazisini_kur() -> void:
	var ortalayici: CenterContainer = CenterContainer.new()
	ortalayici.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ortalayici.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	ortalayici.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ortalayici)

	_secim_yazisi = PanelContainer.new()
	_secim_yazisi.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_secim_yazisi.add_theme_stylebox_override("panel", _hap_kutusu())
	ortalayici.add_child(_secim_yazisi)
	var yazi: Label = Bilesenler.baslik("Ülkeni seç", ArayuzTemasi.YAZI_BASLIK)
	yazi.add_theme_color_override("font_color", ArayuzTemasi.VURGU)
	yazi.custom_minimum_size = Vector2(380.0, DURDUR_DUGMESI_BOYUTU.y - 16.0)
	yazi.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	yazi.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_secim_yazisi.add_child(yazi)


## Tarih ve hız denetimi tek hapta: [tarih | durdur/devam | 1× 2× 3×].
func _zaman_hapini_kur() -> void:
	var hap: PanelContainer = PanelContainer.new()
	hap.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	hap.add_theme_stylebox_override("panel", _hap_kutusu())
	add_child(hap)
	var sira: HBoxContainer = Bilesenler.sira(4)
	hap.add_child(sira)

	var tarih: HBoxContainer = Bilesenler.sira(ArayuzTemasi.BOSLUK_1)
	tarih.custom_minimum_size = Vector2(TARIH_GENISLIGI, 0.0)
	tarih.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tarih.add_child(Simgeler.dugum("tarih", 30.0))
	_tarih = Label.new()
	_tarih.add_theme_font_override("font", ArayuzTemasi.arayuz_fontu(600))
	_tarih.add_theme_font_size_override("font_size", ArayuzTemasi.YAZI_KUCUK)
	tarih.add_child(_tarih)
	sira.add_child(tarih)

	_durdur = Bilesenler.ikincil_dugme("", "duraklat", DURDUR_DUGMESI_BOYUTU)
	_durdur.toggle_mode = true
	_durdur.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_durdur.pressed.connect(_durdur_basildi)
	sira.add_child(_durdur)

	for i: int in Zaman.hiz_sayisi():
		var dugme: Button = Bilesenler.ikincil_dugme("%d×" % (i + 1), "", HIZ_DUGMESI_BOYUTU)
		dugme.theme_type_variation = ArayuzTemasi.SEKME
		dugme.toggle_mode = true
		dugme.pressed.connect(_hiz_basildi.bind(i + 1))
		sira.add_child(dugme)
		_hiz_dugmeleri.append(dugme)


func _araclari_kur() -> void:
	_araclar = Bilesenler.sira(ArayuzTemasi.BOSLUK_1)
	_araclar.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	add_child(_araclar)
	_yz_yonetimi = Bilesenler.arac_dugmesi("Ordu YZ", "ordu", ARAC_DUGMESI_BOYUTU)
	_yz_yonetimi.pressed.connect(func() -> void: yz_yonetimi_degisti.emit(_yz_yonetimi.button_pressed))
	_araclar.add_child(_yz_yonetimi)
	_siralama = Bilesenler.arac_dugmesi("Sıralama", "siralama", ARAC_DUGMESI_BOYUTU)
	_siralama.pressed.connect(func() -> void: siralama_degisti.emit(_siralama.button_pressed))
	_araclar.add_child(_siralama)
	_teknoloji = Bilesenler.arac_dugmesi("Teknoloji", "teknoloji", ARAC_DUGMESI_BOYUTU)
	_teknoloji.pressed.connect(func() -> void: teknoloji_degisti.emit(_teknoloji.button_pressed))
	_araclar.add_child(_teknoloji)
	# Ülke seçilene kadar bu düğmelerin işlevi yok; gizli kalırlar.
	_araclar.hide()


## Hap biçimli üst çubuk zemini (panel rengi, ince kenar, gölge).
static func _hap_kutusu() -> StyleBoxFlat:
	var kutu: StyleBoxFlat = ArayuzTemasi.kutu(ArayuzTemasi.YUZEY, ArayuzTemasi.KOSE_HAP, ArayuzTemasi.BOSLUK_1)
	kutu.content_margin_left = ArayuzTemasi.BOSLUK_3
	kutu.border_color = ArayuzTemasi.KENAR
	kutu.set_border_width_all(1)
	kutu.shadow_color = ArayuzTemasi.GOLGE_RENGI
	kutu.shadow_size = 10
	kutu.shadow_offset = Vector2(0.0, 4.0)
	return kutu


func _durdur_basildi() -> void:
	Zaman.durdurmayi_degistir()
	_yenile()


func _hiz_basildi(hiz: int) -> void:
	Zaman.hiz_sec(hiz)
	_yenile()


## "Ordu YZ" düğmesinin durumunu, sinyal yaymadan ayarlar (kayıttan yüklerken kullanılır).
func yz_yonetimini_goster(acik: bool) -> void:
	_yz_yonetimi.set_pressed_no_signal(acik)


## "Teknoloji" düğmesini, sinyal yaymadan kapatır (panel başka yoldan kapandığında).
func teknoloji_dugmesini_kapat() -> void:
	_teknoloji.set_pressed_no_signal(false)


## "Sıralama" düğmesini, sinyal yaymadan kapatır.
func siralama_dugmesini_kapat() -> void:
	_siralama.set_pressed_no_signal(false)


func _saat_gecti(_toplam_saat: int) -> void:
	_tarih.text = Zaman.tarih_metni()


## Düğmelerin görünümünü zamanın durumuna uydurur: etkin hız vurgulanır; durmuşken
## durdur düğmesi "oynat" simgesine döner ve vurgulanır (oyun dururken dikkat çeksin).
## Zaman kilitliyken (ülke seçilmeden önce) bütün düğmeler kapalıdır.
func _yenile() -> void:
	_tarih.text = Zaman.tarih_metni()
	_durdur.icon = Simgeler.doku("oynat" if Zaman.durdu else "duraklat")
	_durdur.set_pressed_no_signal(Zaman.durdu and not Zaman.kilitli)
	_durdur.disabled = Zaman.kilitli
	for i: int in _hiz_dugmeleri.size():
		_hiz_dugmeleri[i].set_pressed_no_signal(Zaman.hiz == i + 1 and not Zaman.kilitli)
		_hiz_dugmeleri[i].disabled = Zaman.kilitli
	_yz_yonetimi.disabled = Zaman.kilitli
	_siralama.disabled = Zaman.kilitli
	_teknoloji.disabled = Zaman.kilitli
