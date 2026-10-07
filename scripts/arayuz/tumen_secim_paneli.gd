class_name TumenSecimPaneli
extends PanelContainer
## "Tümen kur"a basınca ortada açılan tür seçimi: piyade, zırhlı ve topçu için birer büyük
## düğme (fiyat, süre, neye karşı güçlü olduğu) ve "Vazgeç". Sayılar data/balance.json'dan
## (BirlikTurleri) okunur; oyuncunun ülke bonusuyla değişen fiyatlar fiyatlari_ayarla() ile yazılır.

## Oyuncu bir türe dokunduğunda yayılır; panel kendini kapatır.
signal tur_secildi(tur: String)

const SECENEK_BOYUTU: Vector2 = Vector2(500.0, 300.0)
const SECENEK_YAZI_BOYUTU: int = ArayuzTemasi.YAZI_KUCUK
const VAZGEC_BOYUTU: Vector2 = Vector2(300.0, 104.0)

var _dugmeler: Dictionary[String, Button] = {}


func _ready() -> void:
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	var panel: BaslikliPanel = BaslikliPanel.new("Hangi tümeni kuralım?")
	panel.isaret_ayarla(Simgeler.dugum("ordu", 40.0, ArayuzTemasi.VURGU))
	add_child(panel)
	var dikey: VBoxContainer = panel.govde
	dikey.add_theme_constant_override("separation", ArayuzTemasi.BOSLUK_3)

	var sira: HBoxContainer = Bilesenler.sira(ArayuzTemasi.BOSLUK_3)
	dikey.add_child(sira)
	for tur: String in BirlikTurleri.SIRA:
		var dugme: Button = Bilesenler.ikincil_dugme("", tur, SECENEK_BOYUTU)
		dugme.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		dugme.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		dugme.add_theme_constant_override("icon_max_width", 64)
		dugme.add_theme_font_size_override("font_size", SECENEK_YAZI_BOYUTU)
		dugme.pressed.connect(_secildi.bind(tur))
		sira.add_child(dugme)
		_dugmeler[tur] = dugme
	fiyatlari_ayarla({})

	var vazgec: Button = Bilesenler.ikincil_dugme("Vazgeç", "kapat", VAZGEC_BOYUTU)
	vazgec.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vazgec.pressed.connect(func() -> void: Gecis.kapat(self))
	dikey.add_child(vazgec)
	hide()


## `fiyatlar`: tür -> oyuncunun ödeyeceği fiyat (ör. piyade indirimi olan ülkede ucuz);
## verilmeyen türde data/balance.json'daki fiyat yazar.
func fiyatlari_ayarla(fiyatlar: Dictionary) -> void:
	for tur: String in _dugmeler:
		var fiyat: float = float(fiyatlar.get(tur, BirlikTurleri.maliyet(tur)))
		_dugmeler[tur].text = "%s\nFiyat: %d\nSüre: %s\n%s" % [BirlikTurleri.ad(tur), roundi(fiyat),
				_sure_metni(BirlikTurleri.sure_saat(tur)), BirlikTurleri.guclu_oldugu_metin(tur)]


func _secildi(tur: String) -> void:
	Gecis.kapat(self)
	tur_secildi.emit(tur)


## 96 saat -> "4 gün", 30 saat -> "1 gün 6 saat".
static func _sure_metni(saat: int) -> String:
	var gun: int = saat / 24
	var kalan: int = saat % 24
	if gun == 0:
		return "%d saat" % kalan
	if kalan == 0:
		return "%d gün" % gun
	return "%d gün %d saat" % [gun, kalan]
