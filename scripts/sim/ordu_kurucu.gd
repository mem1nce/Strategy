class_name OrduKurucu
extends RefCounted
## Ülkelerin başlangıç ordusunu (tümen sayısı ve yerleşimi) üretir.
##
## Tümen sayısı nüfus ve GSYH'den basit bir formülle çıkar (data/balance.json → "ordu").
## Dengesi ileride uzun koşu sınamasıyla ayarlanacak (bkz. TASARIM.md 9. Yol haritası, H).

const DENGE_DOSYASI: String = "res://data/balance.json"


static func baslangic_birliklerini_olustur(dunya: Dunya) -> Array[Birlik]:
	var ayarlar: Dictionary = VeriOkuyucu.sozluk_oku(DENGE_DOSYASI).get("ordu", {})
	var baslangic_gucu: float = float(ayarlar.get("baslangic_gucu", 100.0))
	var nufus_bolen: float = float(ayarlar.get("nufus_bolen", 2000000.0))
	var gsyh_bolen: float = float(ayarlar.get("gsyh_bolen", 50000.0))
	var asgari: int = int(ayarlar.get("asgari_tumen", 1))
	var azami: int = int(ayarlar.get("azami_tumen", 24))

	var birlikler: Array[Birlik] = []
	for ulke: Ulke in dunya.ulke_listesi:
		var sayi: int = _tumen_sayisi(ulke, nufus_bolen, gsyh_bolen, asgari, azami)
		var yerlesim: Array[String] = _yerlesim_bolgeleri(dunya, ulke)
		for i: int in sayi:
			var birlik: Birlik = Birlik.new()
			birlik.sahip = ulke.id
			birlik.bolge_id = yerlesim[i % yerlesim.size()]
			birlik.guc = baslangic_gucu
			birlikler.append(birlik)
	return birlikler


static func _tumen_sayisi(ulke: Ulke, nufus_bolen: float, gsyh_bolen: float, asgari: int, azami: int) -> int:
	var nufus_puani: float = sqrt(float(ulke.nufus) / nufus_bolen)
	var gsyh_puani: float = sqrt(float(ulke.gsyh_milyon_dolar) / gsyh_bolen)
	var puan: float = (nufus_puani + gsyh_puani) * 0.5
	return clampi(roundi(puan), asgari, azami)


## Başkent ve kara sınırı olan (başka ülkeye komşu) bölgeler. Sınır bölgesi yoksa
## (ör. ada ülkesi) yalnızca başkent döner.
static func _yerlesim_bolgeleri(dunya: Dunya, ulke: Ulke) -> Array[String]:
	var sonuc: Array[String] = [ulke.baskent_bolgesi]
	for bolge: Bolge in dunya.ulkenin_bolgeleri(ulke.id):
		if bolge.id == ulke.baskent_bolgesi:
			continue
		for komsu_id: String in bolge.kara_komsulari:
			var komsu: Bolge = dunya.bolgeler.get(komsu_id)
			if komsu != null and komsu.sahip != ulke.id:
				sonuc.append(bolge.id)
				break
	return sonuc
