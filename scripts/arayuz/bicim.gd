class_name Bicim
extends RefCounted
## Sayıları ekranda kısa ve okunur biçimde yazar (STIL.md → Yazı): 1 250 -> "1,25 B",
## 83 429 615 -> "83,4 Mn", 2 720 000 000 -> "2,72 Mr". B = bin, Mn = milyon, Mr = milyar,
## Tn = trilyon.


## Herhangi bir büyük sayıyı kısaltır. 1 000'in altındakiler tam sayı olarak yazılır.
static func kisa(sayi: float) -> String:
	var mutlak: float = absf(sayi)
	var isaret: String = "-" if sayi < 0.0 else ""
	if mutlak >= 1e12:
		return "%s%s Tn" % [isaret, _kisalt(mutlak / 1e12)]
	if mutlak >= 1e9:
		return "%s%s Mr" % [isaret, _kisalt(mutlak / 1e9)]
	if mutlak >= 1e6:
		return "%s%s Mn" % [isaret, _kisalt(mutlak / 1e6)]
	if mutlak >= 1e3:
		return "%s%s B" % [isaret, _kisalt(mutlak / 1e3)]
	return "%s%d" % [isaret, roundi(mutlak)]


## Örnek: 83429615 -> "83,4 Mn"
static func nufus(sayi: int) -> String:
	return kisa(float(sayi))


## Milyon dolar cinsinden verilen tutarı yazar. Örnek: 761425 -> "761 Mr $"
static func para(milyon_dolar: int) -> String:
	if milyon_dolar <= 0:
		return "bilinmiyor"
	return "%s $" % kisa(milyon_dolar * 1e6)


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
