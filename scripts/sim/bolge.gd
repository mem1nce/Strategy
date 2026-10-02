class_name Bolge
extends RefCounted
## Bir bölgenin verisi. Bölge, bir şehrin çevresidir ve o şehrin adını taşır.

## Örnek: "TUR_1"
var id: String = ""
var ad: String = ""
## Bölgenin şu anki sahibi olan ülkenin id'si. Oyun içinde değişebilir.
var sahip: String = ""
## Bu bölge, başlangıçtaki sahibinin başkenti mi?
var baskent: bool = false
var nufus: int = 0
## Bölge adının ve işaretlerinin çizileceği nokta (en büyük çokgenin içinde).
var etiket: Vector2 = Vector2.ZERO
## Ortak sınır paylaşan bölgelerin id'leri (başka ülkelerinkiler dahil).
var kara_komsulari: PackedStringArray = PackedStringArray()
## Arada dar bir su bulunan, kara komşusu olmayan bölgelerin id'leri.
var deniz_gecisleri: PackedStringArray = PackedStringArray()
## Bölgeyi oluşturan toprak parçaları (anakara ve adalar), büyükten küçüğe.
var cokgenler: Array[Cokgen] = []
## Çokgenlerin toplam alanı (harita birimi kare).
var alan: float = 0.0


static func sozlukten(veri: Dictionary) -> Bolge:
	var bolge: Bolge = Bolge.new()
	bolge.id = str(veri.get("id", ""))
	bolge.ad = str(veri.get("ad", bolge.id))
	bolge.sahip = str(veri.get("sahip", ""))
	bolge.baskent = bool(veri.get("baskent", false))
	bolge.nufus = int(veri.get("nufus", 0))
	bolge.etiket = Cokgen.noktaya_cevir(veri.get("etiket", []))
	bolge.kara_komsulari = _metin_listesi(veri.get("kara_komsulari", []))
	bolge.deniz_gecisleri = _metin_listesi(veri.get("deniz_gecisleri", []))

	var cokgen_listesi: Array = veri.get("cokgenler", [])
	for nokta_listesi: Array in cokgen_listesi:
		var cokgen: Cokgen = Cokgen.listeden(nokta_listesi, bolge.id)
		if cokgen.noktalar.size() >= 3:
			bolge.cokgenler.append(cokgen)
			bolge.alan += cokgen.alan
	return bolge


static func _metin_listesi(deger: Variant) -> PackedStringArray:
	var sonuc: PackedStringArray = PackedStringArray()
	if deger is Array:
		var liste: Array = deger
		for oge: Variant in liste:
			sonuc.append(str(oge))
	return sonuc
