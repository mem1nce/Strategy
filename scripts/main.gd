extends Node2D
## Ana sahne: dünya verisini yükler, harita görünümünü, kamerayı ve arayüzü kurup
## birbirine bağlar. Sahne ağacı burada script'ten kurulur.

## Haritanın üst ve alt kenarının, arayüzün altından çıkarılabilmesi için ekranın
## içine çekilebileceği pay (piksel). Üst çubuğun ve alt panelin yüksekliğine göre seçildi.
const UST_BOSLUK: float = 180.0
const ALT_BOSLUK: float = 340.0
## Dokunulan noktada ülke yoksa bu yarıçap içindeki en yakın ülke seçilir (ekran pikseli).
const YAKIN_DOKUNMA_YARICAPI: float = 30.0

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
	_harita.kur(dunya)

	_kamera = HaritaKamerasi.new()
	_kamera.name = "Kamera"
	add_child(_kamera)
	_kamera.yakinlik_degisti.connect(_harita.yakinligi_ayarla)
	_kamera.dokunuldu.connect(_haritaya_dokunuldu)
	_kamera.kur(Rect2(Vector2.ZERO, dunya.boyut), UST_BOSLUK, ALT_BOSLUK)

	_arayuz = Arayuz.new()
	_arayuz.name = "Arayuz"
	add_child(_arayuz)
	_arayuz.kur(dunya)
	_arayuz.oyna_istendi.connect(_oyun.oyuncuyu_sec)

	print("Dünya yüklendi: %d ülke, %d çokgen, üçgenlenemeyen %d." % [
		dunya.ulke_listesi.size(), dunya.cokgenler.size(), _harita.ucgenlenemeyenler.size()])


## Dokunulan ülkeyi seçer. Tam o noktada ülke yoksa yakındaki en yakın ülkeye bakılır
## (küçük ülkeler için). O da yoksa seçim kalkar.
func _haritaya_dokunuldu(dunya_konumu: Vector2) -> void:
	var cokgen: Cokgen = _oyun.dunya.noktadaki_cokgen(dunya_konumu)
	if cokgen == null:
		cokgen = _oyun.dunya.en_yakin_cokgen(dunya_konumu, YAKIN_DOKUNMA_YARICAPI / _kamera.zoom.x)
	_ulkeyi_sec(cokgen.sahip if cokgen != null else "")


## Ülkeyi haritada vurgular ve alt panelde gösterir. Boş id seçimi kaldırır.
func _ulkeyi_sec(ulke_id: String) -> void:
	var ulke: Ulke = _oyun.dunya.ulkeler.get(ulke_id)
	_harita.secimi_ayarla(ulke_id)
	_arayuz.ulkeyi_goster(ulke, not _oyun.oyuncu_secildi_mi())


## Oyuncu ülkesini seçti: ülke işaretlenir, kamera oraya kayar, zaman düğmeleri açılır.
func _oyuncu_secildi(ulke_id: String) -> void:
	_ulkeyi_sec("")
	_harita.oyuncuyu_ayarla(ulke_id)
	_arayuz.oyuncuyu_goster(_oyun.dunya.ulkeler[ulke_id])
	var anakara: Cokgen = _oyun.dunya.ulkenin_anakarasi(ulke_id)
	if anakara != null:
		_kamera.odaklan(anakara.sinir_kutusu)
	Zaman.kilidi_ac()
