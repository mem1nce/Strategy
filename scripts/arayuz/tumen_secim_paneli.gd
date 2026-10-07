class_name TumenSecimPaneli
extends PanelContainer
## "Tümen kur"a basınca ortada açılan tür seçimi: piyade, zırhlı ve topçu için birer büyük
## düğme (fiyat, süre, neye karşı güçlü olduğu) ve "Vazgeç". Sayılar data/balance.json'dan
## (BirlikTurleri) okunur.

## Oyuncu bir türe dokunduğunda yayılır; panel kendini kapatır.
signal tur_secildi(tur: String)

const SECENEK_BOYUTU: Vector2 = Vector2(540.0, 260.0)
const SECENEK_YAZI_BOYUTU: int = 30
const VAZGEC_BOYUTU: Vector2 = Vector2(300.0, 104.0)


func _ready() -> void:
	var dikey: VBoxContainer = VBoxContainer.new()
	dikey.add_theme_constant_override("separation", 20)
	add_child(dikey)

	var baslik: Label = Label.new()
	baslik.text = "Hangi tümeni kuralım?"
	baslik.add_theme_font_size_override("font_size", ArayuzTemasi.BASLIK_BOYUTU)
	baslik.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dikey.add_child(baslik)

	var sira: HBoxContainer = HBoxContainer.new()
	sira.add_theme_constant_override("separation", 24)
	dikey.add_child(sira)
	for tur: String in BirlikTurleri.SIRA:
		var dugme: Button = Button.new()
		dugme.custom_minimum_size = SECENEK_BOYUTU
		dugme.focus_mode = Control.FOCUS_NONE
		dugme.add_theme_font_size_override("font_size", SECENEK_YAZI_BOYUTU)
		dugme.text = "%s\nFiyat: %d\nSüre: %s\n%s" % [BirlikTurleri.ad(tur), roundi(BirlikTurleri.maliyet(tur)),
				_sure_metni(BirlikTurleri.sure_saat(tur)), BirlikTurleri.guclu_oldugu_metin(tur)]
		dugme.pressed.connect(_secildi.bind(tur))
		sira.add_child(dugme)

	var vazgec: Button = Button.new()
	vazgec.text = "Vazgeç"
	vazgec.custom_minimum_size = VAZGEC_BOYUTU
	vazgec.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vazgec.focus_mode = Control.FOCUS_NONE
	vazgec.pressed.connect(func() -> void: Gecis.kapat(self))
	dikey.add_child(vazgec)
	hide()


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
