class_name OrduKurucu
extends RefCounted
## Ülkelerin başlangıç ordusunu (tümen sayısı ve yerleşimi) üretir.
##
## Tümen sayısı nüfus ve GSYH'den basit bir formülle çıkar (data/balance.json → "ordu").
## Kişi başına GSYH'si yüksek (zengin) ülkelerde zırhlı ve topçu payı daha yüksektir.
## Dengesi ileride uzun koşu sınamasıyla ayarlanacak (bkz. TASARIM.md 10. Yol haritası, H).

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
		var turler: Array[String] = _tur_dagilimi(ulke, sayi, ayarlar)
		var yerlesim: Array[String] = yerlesim_bolgeleri(dunya, ulke)
		for i: int in sayi:
			var birlik: Birlik = Birlik.new()
			birlik.sahip = ulke.id
			birlik.tur = turler[i]
			birlik.bolge_id = yerlesim[i % yerlesim.size()]
			birlik.guc = baslangic_gucu
			birlikler.append(birlik)
	return birlikler


## Ülkenin `sayi` tümeninin türleri. Ağır tümen (zırhlı + topçu) payı, kişi başına GSYH
## `kisi_basi_gsyh_alt` ile `kisi_basi_gsyh_ust` arasında `agir_pay_asgari`'den
## `agir_pay_azami`'ye doğrusal yükselir; ağır pay zırhlı ve topçu arasında eşit bölünür.
## Türler sırayla karışık dizilir (piyade, zırhlı, topçu, piyade...) ki yerleşimde dağılsınlar.
static func _tur_dagilimi(ulke: Ulke, sayi: int, ayarlar: Dictionary) -> Array[String]:
	var kisi_basi: float = float(ulke.gsyh_milyon_dolar) * 1000000.0 / maxf(float(ulke.nufus), 1.0)
	var alt: float = float(ayarlar.get("kisi_basi_gsyh_alt", 2000.0))
	var ust: float = float(ayarlar.get("kisi_basi_gsyh_ust", 50000.0))
	var t: float = clampf((kisi_basi - alt) / maxf(ust - alt, 1.0), 0.0, 1.0)
	var agir_pay: float = lerpf(float(ayarlar.get("agir_pay_asgari", 0.1)), float(ayarlar.get("agir_pay_azami", 0.5)), t)
	var kalan: Dictionary[String, int] = {
		"zirhli": roundi(sayi * agir_pay * 0.5),
		"topcu": roundi(sayi * agir_pay * 0.5),
	}
	kalan["piyade"] = maxi(0, sayi - kalan["zirhli"] - kalan["topcu"])
	var sonuc: Array[String] = []
	while sonuc.size() < sayi:
		for tur: String in BirlikTurleri.SIRA:
			if kalan.get(tur, 0) > 0 and sonuc.size() < sayi:
				sonuc.append(tur)
				kalan[tur] -= 1
	return sonuc


static func _tumen_sayisi(ulke: Ulke, nufus_bolen: float, gsyh_bolen: float, asgari: int, azami: int) -> int:
	var nufus_puani: float = sqrt(float(ulke.nufus) / nufus_bolen)
	var gsyh_puani: float = sqrt(float(ulke.gsyh_milyon_dolar) / gsyh_bolen)
	var puan: float = (nufus_puani + gsyh_puani) * 0.5
	return clampi(roundi(puan), asgari, azami)


## Başkent ve kara sınırı olan (başka ülkeye komşu) bölgeler. Sınır bölgesi yoksa
## (ör. ada ülkesi) yalnızca başkent döner. Başlangıç ordusu dağıtımı dışında, yapay
## zekânın yeni kurduğu tümenleri de nereye yerleştireceğine karar vermek için kullanılır.
static func yerlesim_bolgeleri(dunya: Dunya, ulke: Ulke) -> Array[String]:
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
