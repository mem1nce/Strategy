class_name InsaDugmeleri
extends RefCounted
## Bölge ve birlik panellerindeki "Tümen kur" / "Fabrika kur" / "Tahkimat kur" düğmelerini kurar.
##
## Düğmeler panel açılırken (maliyetler henüz bilinmeden) kurulur; main.gd oyun kurulunca
## fabrika maliyetini, bölge seçildikçe de o bölgenin tahkimat durumunu bildirir. Tümen
## düğmesinde fiyat yazmaz; fiyatlar tür seçim panelinde (TumenSecimPaneli) görünür.

static var _dugmeler: Array[Button] = []
static var _fabrika_maliyeti: float = -1.0
## Seçili bölgenin tahkimat seviyesi ve bir sonraki seviyenin maliyeti (en yüksek
## seviyedeyse 0). Düğme ikisini de yazar: "Tahkimat 1/3" ve "Kur (160)".
static var _tahkimat_seviyesi: int = 0
static var _tahkimat_maliyeti: float = -1.0
## Tahkimatın en yüksek seviyesi (panellerde "Tahkimat: 1/3" yazmak için).
static var tahkimat_azami: int = 0


## `tur` "tumen", "fabrika" ya da "tahkimat"tır. Düğmeye basılınca `sinyal` bu türle yayılır.
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


## Fabrika maliyetini (Oyun.fabrika_maliyeti) düğmelere yazar ve tahkimatın en yüksek
## seviyesini (Oyun.tahkimat_azami_seviye) saklar.
static func maliyetleri_ayarla(fabrika: float, azami_tahkimat: int) -> void:
	_fabrika_maliyeti = fabrika
	tahkimat_azami = azami_tahkimat
	_hepsini_yenile()


## Seçili bölgenin tahkimat seviyesini ve bir sonraki seviyenin maliyetini yazar; `maliyet`
## 0 ise bölge (kuyruktakilerle birlikte) en yüksek seviyededir ve düğme kapanır.
static func tahkimat_durumunu_ayarla(seviye: int, maliyet: float) -> void:
	_tahkimat_seviyesi = seviye
	_tahkimat_maliyeti = maliyet
	_hepsini_yenile()


static func _hepsini_yenile() -> void:
	for dugme: Button in _dugmeler:
		if is_instance_valid(dugme):
			_yaziyi_yenile(dugme)


static func _yaziyi_yenile(dugme: Button) -> void:
	match str(dugme.get_meta("tur")):
		"tumen":
			dugme.text = "Tümen kur"
		"fabrika":
			dugme.text = "Fabrika kur" if _fabrika_maliyeti < 0.0 else "Fabrika kur\n(%d)" % roundi(_fabrika_maliyeti)
		"tahkimat":
			dugme.disabled = _tahkimat_maliyeti == 0.0
			var ust: String = "Tahkimat %d/%d" % [_tahkimat_seviyesi, tahkimat_azami]
			if _tahkimat_maliyeti == 0.0:
				dugme.text = ust + "\nTam"
			elif _tahkimat_maliyeti < 0.0:
				dugme.text = "Tahkimat kur"
			else:
				dugme.text = ust + "\nKur (%d)" % roundi(_tahkimat_maliyeti)
