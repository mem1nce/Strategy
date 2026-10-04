extends RefCounted
## OrduKurucu.baslangic_birliklerini_olustur()'ın ürettiği orduyu sınar.


func sina_her_ulkenin_tumeni_var() -> String:
	var dunya: Dunya = Dunya.yukle()
	var oyun: Oyun = Oyun.new(dunya)
	var sayilar: Dictionary[String, int] = {}
	for birlik: Birlik in oyun.birlikler:
		sayilar[birlik.sahip] = sayilar.get(birlik.sahip, 0) + 1
	for ulke: Ulke in dunya.ulke_listesi:
		var sayi: int = sayilar.get(ulke.id, 0)
		if sayi < 1 or sayi > 24:
			return "%s: tümen sayısı 1-24 arasında olmalı, %d geldi" % [ulke.id, sayi]
	return ""


func sina_baskentte_tumen_var() -> String:
	var dunya: Dunya = Dunya.yukle()
	var oyun: Oyun = Oyun.new(dunya)
	for ulke: Ulke in dunya.ulke_listesi:
		if oyun.bolgedeki_birlikler(ulke.baskent_bolgesi).is_empty():
			return "%s: başkent bölgesinde (%s) hiç tümen yok" % [ulke.id, ulke.baskent_bolgesi]
	return ""


func sina_tumenler_sahibinin_bolgesinde() -> String:
	var dunya: Dunya = Dunya.yukle()
	var oyun: Oyun = Oyun.new(dunya)
	for birlik: Birlik in oyun.birlikler:
		if birlik.guc <= 0.0:
			return "Bir tümenin gücü 0 ya da altında."
		var bolge: Bolge = dunya.bolgeler.get(birlik.bolge_id)
		if bolge == null or bolge.sahip != birlik.sahip:
			return "%s sahipli tümen, sahibi olmayan %s bölgesinde." % [birlik.sahip, birlik.bolge_id]
	return ""
