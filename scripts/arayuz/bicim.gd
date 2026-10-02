class_name Bicim
extends RefCounted
## Sayıları ekranda okunur biçimde yazar ("85,3 milyon", "761 milyar $").


## Örnek: 83429615 -> "83,4 milyon"
static func nufus(sayi: int) -> String:
	if sayi >= 1_000_000_000:
		return "%s milyar" % _kisalt(sayi / 1_000_000_000.0)
	if sayi >= 1_000_000:
		return "%s milyon" % _kisalt(sayi / 1_000_000.0)
	if sayi >= 1_000:
		return "%s bin" % _kisalt(sayi / 1_000.0)
	return str(sayi)


## Milyon dolar cinsinden verilen tutarı yazar. Örnek: 761425 -> "761 milyar $"
static func para(milyon_dolar: int) -> String:
	if milyon_dolar <= 0:
		return "bilinmiyor"
	if milyon_dolar >= 1_000_000:
		return "%s trilyon $" % _kisalt(milyon_dolar / 1_000_000.0)
	if milyon_dolar >= 1_000:
		return "%s milyar $" % _kisalt(milyon_dolar / 1_000.0)
	return "%d milyon $" % milyon_dolar


## Sayıyı üç anlamlı basamağa indirir ve Türkçe ondalık virgülüyle yazar:
## 761.4 -> "761", 85.34 -> "85,3", 1.409 -> "1,41", 5.0 -> "5".
static func _kisalt(deger: float) -> String:
	var metin: String = ""
	if deger >= 100.0:
		metin = "%d" % roundi(deger)
	elif deger >= 10.0:
		metin = "%.1f" % deger
	else:
		metin = "%.2f" % deger
	if metin.contains("."):
		metin = metin.rstrip("0").rstrip(".")
	return metin.replace(".", ",")
