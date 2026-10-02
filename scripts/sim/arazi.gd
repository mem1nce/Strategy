class_name Arazi
extends RefCounted
## Bir arazi türü (ova, orman, dağ, şehir) ve çarpanları.

var id: String = ""
var ad: String = ""
## Bu araziye girmenin süresini çarpan değer.
var hareket: float = 1.0
## Bu arazide savunanın gücünü çarpan değer.
var savunma: float = 1.0


static func sozlukten(arazi_id: String, veri: Dictionary) -> Arazi:
	var arazi: Arazi = Arazi.new()
	arazi.id = arazi_id
	arazi.ad = str(veri.get("ad", arazi_id))
	arazi.hareket = float(veri.get("hareket", 1.0))
	arazi.savunma = float(veri.get("savunma", 1.0))
	return arazi
