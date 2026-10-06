class_name InsaDugmeleri
extends RefCounted
## Bölge ve birlik panellerindeki "Tümen kur" / "Fabrika kur" düğmelerini kurar.
##
## Düğmeler panel açılırken (maliyetler henüz bilinmeden) kurulur; main.gd oyun kurulunca
## maliyetleri_ayarla() ile maliyetleri bildirir ve bütün düğmelerin yazısı güncellenir.

static var _dugmeler: Array[Button] = []
static var _maliyetler: Dictionary[String, float] = {}


## `tur` "tumen" ya da "fabrika"dır. Düğmeye basılınca `sinyal` bu türle yayılır.
static func dugme_olustur(tur: String, boyut: Vector2, sinyal: Signal) -> Button:
	var dugme: Button = Button.new()
	dugme.custom_minimum_size = boyut
	dugme.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	dugme.focus_mode = Control.FOCUS_NONE
	dugme.set_meta("tur", tur)
	dugme.pressed.connect(func() -> void: sinyal.emit(tur))
	_dugmeler.append(dugme)
	_yaziyi_yenile(dugme)
	return dugme


## Tümen ve fabrika maliyetlerini (Oyun.tumen_maliyeti/fabrika_maliyeti) düğmelere yazar.
static func maliyetleri_ayarla(tumen: float, fabrika: float) -> void:
	_maliyetler = {"tumen": tumen, "fabrika": fabrika}
	for dugme: Button in _dugmeler:
		if is_instance_valid(dugme):
			_yaziyi_yenile(dugme)


static func _yaziyi_yenile(dugme: Button) -> void:
	var tur: String = dugme.get_meta("tur")
	var ad: String = "Tümen kur" if tur == "tumen" else "Fabrika kur"
	if _maliyetler.has(tur):
		dugme.text = "%s (%d)" % [ad, roundi(_maliyetler[tur])]
	else:
		dugme.text = ad
