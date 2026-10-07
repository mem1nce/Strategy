extends RefCounted
## Görsel yenilemeyle gelen saf yardımcıların sınamaları: büyük sayı kısaltma, Türkçe büyük
## harf ve ekonomi modunun renk merdiveni (ekransız çalışır).


func sina_buyuk_sayilar_kisaltilir() -> String:
	var beklenen: Dictionary = {
		0.0: "0", 950.0: "950", 1250.0: "1,25 B", 83429615.0: "83,4 Mn",
		2720000000.0: "2,72 Mr", 761425e6: "761 Mr", 2.7e12: "2,7 Tn", -1500.0: "-1,5 B",
	}
	for sayi: float in beklenen:
		if Bicim.kisa(sayi) != beklenen[sayi]:
			return "Bicim.kisa(%s) = %s, beklenen %s" % [sayi, Bicim.kisa(sayi), beklenen[sayi]]
	if Bicim.para(761425) != "761 Mr $":
		return "Bicim.para(761425) = %s" % Bicim.para(761425)
	return ""


func sina_turkce_buyuk_harf() -> String:
	var beklenen: Dictionary = {
		"Türkiye": "TÜRKİYE", "Birleşik Krallık": "BİRLEŞİK KRALLIK", "Çin": "ÇİN",
		"Irak": "IRAK", "ığdır": "IĞDIR",
	}
	for metin: String in beklenen:
		if Bicim.buyuk_harf(metin) != beklenen[metin]:
			return "buyuk_harf(%s) = %s, beklenen %s" % [metin, Bicim.buyuk_harf(metin), beklenen[metin]]
	return ""


func sina_ekonomi_merdiveni_uclari() -> String:
	var merdiven: Array[Color] = HaritaPaleti.EKONOMI_MERDIVENI
	if not HaritaPaleti.ekonomi_rengi(0.0).is_equal_approx(merdiven[0]):
		return "0 oranı merdivenin ilk rengi olmalı"
	if not HaritaPaleti.ekonomi_rengi(1.0).is_equal_approx(merdiven[merdiven.size() - 1]):
		return "1 oranı merdivenin son rengi olmalı"
	if not HaritaPaleti.ekonomi_rengi(7.0).is_equal_approx(merdiven[merdiven.size() - 1]):
		return "1'den büyük oran son renkte kalmalı"
	return ""
