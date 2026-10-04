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


func _ready() -> void:
	var dunya: Dunya = Dunya.yukle()
	if dunya == null:
		push_error("Dünya verisi yüklenemedi; oyun başlatılamıyor.")
		return
	_oyun = Oyun.new(dunya)
	_oyun.oyuncu_secildi.connect(_oyuncu_secildi)

	_harita = HaritaGorunumu.new()
	_harita.name = "Harita"
	add_child(_harita)
	_harita.kur(dunya, _oyun)

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
func _bolgeyi_sec(bolge_id: String) -> void:
	var bolge: Bolge = _oyun.dunya.bolgeler.get(bolge_id)
	_harita.secimi_ayarla(bolge_id)
	_arayuz.bolgeyi_goster(bolge, not _oyun.oyuncu_secildi_mi())


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
