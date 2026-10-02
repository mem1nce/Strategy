extends Node2D
## Ana sahne: simülasyon verisini yükler, harita görünümünü, kamerayı ve arayüzü kurup
## birbirine bağlar. Sahne ağacı burada script'ten kurulur.

var _dunya: Dunya = null
var _harita: HaritaGorunumu = null
var _kamera: HaritaKamerasi = null
var _arayuz: Arayuz = null


func _ready() -> void:
	_dunya = Dunya.yukle()
	if _dunya == null:
		push_error("Harita verisi yüklenemedi; oyun başlatılamıyor.")
		return

	_harita = HaritaGorunumu.new()
	_harita.name = "Harita"
	add_child(_harita)
	_harita.kur(_dunya)

	_kamera = HaritaKamerasi.new()
	_kamera.name = "Kamera"
	add_child(_kamera)
	_kamera.yakinlik_degisti.connect(_harita.yakinligi_ayarla)
	_kamera.dokunuldu.connect(_haritaya_dokunuldu)
	_kamera.kur(Rect2(Vector2.ZERO, _dunya.boyut))

	_arayuz = Arayuz.new()
	_arayuz.name = "Arayuz"
	add_child(_arayuz)
	_arayuz.kur(_dunya)


## Dokunulan bölgeyi seçer. Denize dokunulduysa bölge null gelir ve seçim kalkar.
func _haritaya_dokunuldu(dunya_konumu: Vector2) -> void:
	var bolge: Bolge = _dunya.noktadaki_bolge(dunya_konumu)
	_harita.secimi_ayarla(bolge)
	_arayuz.bolgeyi_goster(bolge)
