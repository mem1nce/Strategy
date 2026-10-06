extends RefCounted
## Tahkimatı sınar: savunma avantajı, kuruluş, en yüksek seviye ve el değiştirince düşüş.


func _kurulu_oyun() -> Oyun:
	var oyun: Oyun = Oyun.new(Dunya.yukle())
	oyun.oyuncuyu_sec("TUR")
	return oyun


func _birlik(sahip: String, guc: float) -> Birlik:
	var birlik: Birlik = Birlik.new()
	birlik.sahip = sahip
	birlik.guc = guc
	birlik.bolge_id = "TUR_1"
	return birlik


func sina_her_seviye_savunana_yuzde_on_bes_avantaj_verir() -> String:
	var oyun: Oyun = _kurulu_oyun()
	var bolge: Bolge = oyun.dunya.bolgeler["TUR_1"]
	var savunan: Array[Birlik] = [_birlik("TUR", 100.0)]
	var saldiran: Array[Birlik] = [_birlik("FRA", 100.0)]
	var tahkimatsiz: float = oyun._verilen_hasar(savunan, saldiran, false, bolge)
	bolge.tahkimat = 2
	var tahkimatli: float = oyun._verilen_hasar(savunan, saldiran, false, bolge)
	if not is_equal_approx(tahkimatli, tahkimatsiz * 1.30):
		return "Tahkimat 2 savunanın hasarını %%30 artırmalı (%.2f -> %.2f)." % [tahkimatsiz, tahkimatli]
	# Saldırganın hasarı tahkimattan etkilenmez.
	var saldiri: float = oyun._verilen_hasar(saldiran, savunan, true, bolge)
	bolge.tahkimat = 0
	if not is_equal_approx(saldiri, oyun._verilen_hasar(saldiran, savunan, true, bolge)):
		return "Tahkimat yalnızca savunanı güçlendirmeli."
	return ""


func sina_tahkimat_kurulur_ve_en_cok_uc_seviye_olur() -> String:
	var oyun: Oyun = _kurulu_oyun()
	oyun.hazineler["TUR"] = 10000.0
	for i: int in 3:
		if not oyun.tahkimat_sirala("TUR", "TUR_1"):
			return "%d. seviye sıralanabilmeli." % (i + 1)
	if oyun.tahkimat_sirala("TUR", "TUR_1"):
		return "Kuyruktakilerle birlikte 3'ü aşan tahkimat sıralanmamalı."
	if oyun.tahkimat_sirala("TUR", "FRA_1"):
		return "Başkasının bölgesine tahkimat kurulmamalı."
	for saat: int in 3 * oyun._tahkimat_suresi_saat:
		oyun._insa_islerini_isle()
	if oyun.dunya.bolgeler["TUR_1"].tahkimat != 3:
		return "Üç iş bitince tahkimat 3 olmalı (%d)." % oyun.dunya.bolgeler["TUR_1"].tahkimat
	return ""


func sina_el_degistirince_bir_seviye_duser() -> String:
	var oyun: Oyun = _kurulu_oyun()
	var bolge: Bolge = oyun.dunya.bolgeler["GRC_2"]
	bolge.tahkimat = 2
	oyun._bolgeyi_devret(bolge, "TUR", 0)
	if bolge.tahkimat != 1:
		return "El değiştiren bölgenin tahkimatı 1 seviye düşmeli (%d)." % bolge.tahkimat
	return ""


func sina_tahkimatli_bolge_esit_saldiriya_dayanir() -> String:
	# Tahkimatsız eşit güçte saldırı savunanı yıpratır; tahkimatlı bölgede savunan daha az kaybeder.
	var sonuclar: Array[float] = []
	for tahkimat: int in [0, 3]:
		var oyun: Oyun = _kurulu_oyun()
		oyun.savas_ilan_et("TUR", "GRC", 0)
		var bolge: Bolge = oyun.dunya.bolgeler["TUR_2"]
		bolge.tahkimat = tahkimat
		for birlik: Birlik in oyun.bolgedeki_birlikler(bolge.id):
			birlik.guc = 0.0
		oyun._olenleri_temizle(oyun.bolgedeki_birlikler(bolge.id))
		var savunan: Birlik = _birlik("TUR", 100.0)
		savunan.bolge_id = bolge.id
		var saldiran: Birlik = _birlik("GRC", 100.0)
		saldiran.bolge_id = bolge.id
		oyun.birlikler.append_array([savunan, saldiran])
		for saat: int in 5:
			oyun._muharebeleri_isle(saat)
		sonuclar.append(saldiran.guc)
	if not sonuclar[1] < sonuclar[0]:
		return "Tahkimatlı bölgede saldırgan daha çok kayıp vermeli: %s" % [sonuclar]
	return ""


func sina_yz_baskentini_tahkim_eder() -> String:
	var oyun: Oyun = _kurulu_oyun()
	oyun.hazineler["DEU"] = 10000.0
	oyun._yz_tahkimat_olasiligi = 1.0
	oyun._yz_tahkimat_dusun("DEU")
	for is_: InsaIsi in (oyun.insa_kuyruklari.get("DEU", []) as Array):
		if is_.tur == InsaIsi.Tur.TAHKIMAT and is_.bolge_id == oyun.dunya.ulkeler["DEU"].baskent_bolgesi:
			return ""
	return "Barıştaki yapay zekâ başkentini tahkim etmeli."
