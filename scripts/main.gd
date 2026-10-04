extends Node2D
## Ana sahne: dünya verisini yükler, harita görünümünü, kamerayı ve arayüzü kurup
## birbirine bağlar. Sahne ağacı burada script'ten kurulur.

## Haritanın üst ve alt kenarının, arayüzün altından çıkarılabilmesi için ekranın
## içine çekilebileceği pay (piksel). Üst çubuğun ve alt panelin yüksekliğine göre seçildi.
const UST_BOSLUK: float = 180.0
const ALT_BOSLUK: float = 340.0
## Dokunulan noktada bölge yoksa bu yarıçap içindeki en yakın bölge seçilir (ekran pikseli).
const YAKIN_DOKUNMA_YARICAPI: float = 30.0

## "--ekran-goruntusu <dosya>" komut satırı argümanı; harita yerleşsin diye biraz beklenir,
## sonra ekran PNG olarak kaydedilip oyun kapanır. Çağırmak için (proje klasöründen):
##   Godot --path . -- --ekran-goruntusu /tam/yol/goruntu.png
const EKRAN_GORUNTUSU_BAYRAGI: String = "--ekran-goruntusu"
const EKRAN_GORUNTUSU_BEKLEME_SANIYE: float = 2.0

var _oyun: Oyun = null
var _harita: HaritaGorunumu = null
var _kamera: HaritaKamerasi = null
var _arayuz: Arayuz = null
## Birlik kartı açıkken, kartta gösterilen (ve bir sonraki hedef seçiminde yürütülecek)
## tümenler; seçim yoksa boştur. "Yarısını ayır" bu listeyi küçültebilir.
var _secili_birlikler: Array[Birlik] = []


func _ready() -> void:
	var dunya: Dunya = Dunya.yukle()
	if dunya == null:
		push_error("Dünya verisi yüklenemedi; oyun başlatılamıyor.")
		return
	_oyun = Oyun.new(dunya)
	_oyun.oyuncu_secildi.connect(_oyuncu_secildi)
	_oyun.birlikler_degisti.connect(_birlikler_degisti)
	Zaman.saat_gecti.connect(_oyun.saat_ilerledi)

	_harita = HaritaGorunumu.new()
	_harita.name = "Harita"
	add_child(_harita)
	_harita.kur(dunya, _oyun)
	_oyun.bolge_sahipligi_degisti.connect(_harita.yenile)

	_kamera = HaritaKamerasi.new()
	_kamera.name = "Kamera"
	add_child(_kamera)
	_kamera.gorunum_degisti.connect(_gorunum_degisti)
	_kamera.dokunuldu.connect(_haritaya_dokunuldu)
	_kamera.kur(Rect2(Vector2.ZERO, dunya.boyut), UST_BOSLUK, ALT_BOSLUK)

	_arayuz = Arayuz.new()
	_arayuz.name = "Arayuz"
	add_child(_arayuz)
	_arayuz.kur(dunya)
	_arayuz.oyna_istendi.connect(_oyun.oyuncuyu_sec)
	_arayuz.komsular_degisti.connect(_harita.komsulari_goster)
	_arayuz.yarisini_ayir_istendi.connect(_yarisini_ayir_istendi)
	_arayuz.savas_istendi.connect(_savas_istendi)

	print("Dünya yüklendi: %d ülke, %d bölge, %d çokgen, üçgenlenemeyen %d." % [
		dunya.ulke_listesi.size(), dunya.bolge_listesi.size(), dunya.cokgenler.size(),
		_harita.ucgenlenemeyenler.size()])

	_ekran_goruntusu_istendiyse_kaydet()


## Kamera her kaydığında ya da yakınlaştığında haritaya yeni görünümü bildirir.
func _gorunum_degisti() -> void:
	_harita.gorunumu_ayarla(_kamera.position, _kamera.zoom.x, get_viewport_rect().size)


## Dokunulan bölgeyi seçer. Tam o noktada bölge yoksa yakındaki en yakın bölgeye bakılır
## (küçük bölgeler ve adalar için). O da yoksa seçim kalkar.
func _haritaya_dokunuldu(dunya_konumu: Vector2) -> void:
	var cokgen: Cokgen = _oyun.dunya.noktadaki_cokgen(dunya_konumu)
	if cokgen == null:
		cokgen = _oyun.dunya.en_yakin_cokgen(dunya_konumu, YAKIN_DOKUNMA_YARICAPI / _kamera.zoom.x)
	_bolgeyi_sec(cokgen.bolge_id if cokgen != null else "")


## Bölgeyi haritada vurgular ve alt panelde gösterir. Boş id seçimi kaldırır.
##
## Birlik kartı açıkken (bkz. _secili_birlikler) başka bir bölgeye dokunmak, karttaki
## tümenleri dokunulan bölgeye yürütme emri olarak yorumlanır; emir kabul edilmezse
## (ör. düşman toprağı) dokunulan bölge normal şekilde gösterilir. Aksi hâlde, oyuncunun
## kendi tümenlerinin olduğu bir bölgeyse bölge paneli yerine birlik paneli açılır.
func _bolgeyi_sec(bolge_id: String) -> void:
	if not _secili_birlikler.is_empty() and bolge_id != "" and bolge_id != _secili_birlikler[0].bolge_id:
		if _oyun.birlikleri_yurut(_secili_birlikler, bolge_id, Zaman.toplam_saat):
			_secili_birlikler = []
			_harita.secimi_ayarla("")
			_arayuz.bolgeyi_goster(null, false)
			return

	var bolge: Bolge = _oyun.dunya.bolgeler.get(bolge_id)
	_harita.secimi_ayarla(bolge_id)
	if bolge != null and _oyun.oyuncu_secildi_mi() and bolge.sahip == _oyun.oyuncu_ulkesi:
		var birlikler: Array[Birlik] = _oyun.bolgedeki_birlikler(bolge_id)
		if not birlikler.is_empty():
			_arayuz.birligi_goster(bolge, birlikler, _oyun.dunya.ulkeler[_oyun.oyuncu_ulkesi])
			_secili_birlikler = birlikler
			return
	_secili_birlikler = []
	var savas_dugmesi_gorunur: bool = bolge != null and _oyun.oyuncu_secildi_mi() \
			and bolge.sahip != _oyun.oyuncu_ulkesi \
			and not _oyun.savasta_mi(_oyun.oyuncu_ulkesi, bolge.sahip) \
			and _oyun.dunya.ulkeler_komsu_mu(_oyun.oyuncu_ulkesi, bolge.sahip)
	_arayuz.bolgeyi_goster(bolge, not _oyun.oyuncu_secildi_mi(), savas_dugmesi_gorunur)


## Bir tümen yürümeye başlayınca ya da vardığında haritayı (kutular ve yol çizgileri) günceller.
func _birlikler_degisti() -> void:
	_harita.birlikleri_yenile()


## Bölge panelinde "Savaş ilan et" onaylandığında çağrılır. Kabul edilirse seçim kaldırılır.
func _savas_istendi(hedef_ulke_id: String) -> void:
	if _oyun.savas_ilan_et(_oyun.oyuncu_ulkesi, hedef_ulke_id):
		_bolgeyi_sec("")


## Birlik kartındaki "Yarısını ayır" düğmesine basıldığında çağrılır. Ayrılan yarı sonraki
## hedef seçiminde yürütülür; panel yeni (küçülmüş) seçimi gösterir.
func _yarisini_ayir_istendi() -> void:
	if _secili_birlikler.is_empty():
		return
	var bolge_id: String = _secili_birlikler[0].bolge_id
	var ayrilan: Array[Birlik] = _oyun.yariya_ayir(_secili_birlikler)
	if ayrilan.is_empty():
		return
	_secili_birlikler = ayrilan
	var bolge: Bolge = _oyun.dunya.bolgeler[bolge_id]
	_arayuz.birligi_goster(bolge, _secili_birlikler, _oyun.dunya.ulkeler[_oyun.oyuncu_ulkesi])


## Oyuncu ülkesini seçti: ülke işaretlenir, kamera oraya kayar, zaman düğmeleri açılır.
func _oyuncu_secildi(ulke_id: String) -> void:
	var ulke: Ulke = _oyun.dunya.ulkeler[ulke_id]
	_bolgeyi_sec("")
	_harita.oyuncuyu_ayarla(ulke_id)
	_arayuz.oyuncuyu_goster(ulke)
	_kamera.odaklan(ulke.anakara_kutusu)
	Zaman.kilidi_ac()


## Komut satırında "--ekran-goruntusu <dosya>" verildiyse harita yerleştikten sonra
## ekranı PNG olarak kaydeder ve oyunu kapatır. Görsel değişikliklerden sonra sınamak içindir.
func _ekran_goruntusu_istendiyse_kaydet() -> void:
	var argumanlar: PackedStringArray = OS.get_cmdline_user_args()
	var sira: int = argumanlar.find(EKRAN_GORUNTUSU_BAYRAGI)
	if sira == -1:
		return
	var yol: String = argumanlar[sira + 1] if sira + 1 < argumanlar.size() else "user://ekran_goruntusu.png"
	await get_tree().create_timer(EKRAN_GORUNTUSU_BEKLEME_SANIYE).timeout
	var goruntu: Image = get_viewport().get_texture().get_image()
	var hata: Error = goruntu.save_png(yol)
	if hata == OK:
		print("Ekran görüntüsü kaydedildi: %s" % yol)
	else:
		push_error("Ekran görüntüsü kaydedilemedi (hata %d): %s" % [hata, yol])
	get_tree().quit()
