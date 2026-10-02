class_name Ulke
extends RefCounted
## Bir ülkenin verisi.

var id: String = ""
var ad: String = ""
## Ülkenin bloğu ("kuzey" ya da "guney").
var blok: String = ""
var renk: Color = Color.WHITE
## Başkent bölgesinin id'si.
var baskent: String = ""


static func sozlukten(veri: Dictionary) -> Ulke:
	var ulke: Ulke = Ulke.new()
	ulke.id = str(veri.get("id", ""))
	ulke.ad = str(veri.get("ad", ulke.id))
	ulke.blok = str(veri.get("blok", ""))
	ulke.renk = Color.from_string(str(veri.get("renk", "")), Color.MAGENTA)
	ulke.baskent = str(veri.get("baskent", ""))
	return ulke
