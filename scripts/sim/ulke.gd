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
## Ülkenin en büyük kara parçasını saran dikdörtgen; kamera ülkeye buna göre odaklanır.
var anakara_kutusu: Rect2 = Rect2()
## Komşu ülkelerin id'leri.
var komsular: PackedStringArray = PackedStringArray()
## Başkentin bulunduğu bölgenin id'si.
var baskent_bolgesi: String = ""
## Ülkenin oyun başındaki bölgelerinin id'leri. O anki bölgeleri için
## Dunya.ulkenin_bolgeleri() kullanılır.
var baslangic_bolgeleri: PackedStringArray = PackedStringArray()


static func sozlukten(veri: Dictionary) -> Ulke:
	var ulke: Ulke = Ulke.new()
	ulke.id = str(veri.get("id", ""))
	ulke.ad = str(veri.get("ad", ulke.id))
	ulke.kita = str(veri.get("kita", ""))
	ulke.nufus = int(veri.get("nufus", 0))
	ulke.gsyh_milyon_dolar = int(veri.get("gsyh_milyon_dolar", 0))
	ulke.renk_indeksi = int(veri.get("renk", 1))
	ulke.etiket = Cokgen.noktaya_cevir(veri.get("etiket", []))
	ulke.baskent_bolgesi = str(veri.get("baskent_bolgesi", ""))

	var kutu: Array = veri.get("anakara_kutusu", [])
	if kutu.size() >= 4:
		ulke.anakara_kutusu = Rect2(float(kutu[0]), float(kutu[1]), float(kutu[2]), float(kutu[3]))
	var komsu_listesi: Array = veri.get("komsular", [])
	for komsu: Variant in komsu_listesi:
		ulke.komsular.append(str(komsu))
	var bolge_listesi: Array = veri.get("bolgeler", [])
	for bolge_id: Variant in bolge_listesi:
		ulke.baslangic_bolgeleri.append(str(bolge_id))
	return ulke
