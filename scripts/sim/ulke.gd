class_name Ulke
extends RefCounted
## Bir ülkenin verisi.

## Üç harfli ülke kodu (ör. "TUR").
var id: String = ""
var ad: String = ""
var kita: String = ""
var nufus: int = 0
## Gayrisafi yurt içi hasıla, milyon dolar cinsinden.
var gsyh_milyon_dolar: int = 0
## Haritadaki rengi belirleyen sıra (1-9). Komşu ülkelerin indeksi farklıdır.
var renk_indeksi: int = 1
## Ülke adının haritada yazılacağı nokta.
var etiket: Vector2 = Vector2.ZERO
## Komşu ülkelerin id'leri.
var komsular: PackedStringArray = PackedStringArray()


static func sozlukten(veri: Dictionary) -> Ulke:
	var ulke: Ulke = Ulke.new()
	ulke.id = str(veri.get("id", ""))
	ulke.ad = str(veri.get("ad", ulke.id))
	ulke.kita = str(veri.get("kita", ""))
	ulke.nufus = int(veri.get("nufus", 0))
	ulke.gsyh_milyon_dolar = int(veri.get("gsyh_milyon_dolar", 0))
	ulke.renk_indeksi = int(veri.get("renk", 1))
	ulke.etiket = Cokgen.noktaya_cevir(veri.get("etiket", []))
	var komsu_listesi: Array = veri.get("komsular", [])
	for komsu: Variant in komsu_listesi:
		ulke.komsular.append(str(komsu))
	return ulke
