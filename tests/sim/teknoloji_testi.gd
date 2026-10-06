extends RefCounted
## Teknoloji araştırmasını ve dört dalın etkisini sınar.


func _kurulu_oyun() -> Oyun:
	var oyun: Oyun = Oyun.new(Dunya.yukle())
	oyun.oyuncuyu_sec("TUR")
	return oyun


func _seviye_ver(oyun: Oyun, ulke_id: String, dal: String, seviye: int) -> void:
	var seviyeler: Dictionary = oyun.teknolojiler.get(ulke_id, {})
	seviyeler[dal] = seviye
	oyun.teknolojiler[ulke_id] = seviyeler


func _birlik(sahip: String, tur: String, guc: float) -> Birlik:
	var birlik: Birlik = Birlik.new()
	birlik.sahip = sahip
	birlik.tur = tur
	birlik.guc = guc
	birlik.bolge_id = "TUR_1"
	return birlik


func sina_arastirma_ucreti_peşin_odenir_ve_suresi_dolunca_biter() -> String:
	var oyun: Oyun = _kurulu_oyun()
	oyun.hazineler["TUR"] = 1000.0
	if not oyun.arastirma_baslat("TUR", "sanayi"):
		return "Hazine yeterliyken araştırma başlamalı."
	if oyun.hazineler["TUR"] != 1000.0 - Teknoloji.maliyet(1):
		return "Araştırma maliyeti hemen düşülmeli."
	if oyun.arastirma_baslat("TUR", "silah"):
		return "Aynı anda ikinci araştırma başlamamalı."
	for saat: int in Teknoloji.sure_saat(1) - 1:
		oyun._arastirmalari_isle()
	if oyun.teknoloji_seviyesi("TUR", "sanayi") != 0:
		return "Süre dolmadan seviye artmamalı."
	oyun._arastirmalari_isle()
	if oyun.teknoloji_seviyesi("TUR", "sanayi") != 1 or not oyun.suren_arastirma("TUR").is_empty():
		return "Süre dolunca seviye 1 olmalı ve araştırma bitmeli."
	return ""


func sina_maliyet_ve_sure_seviyeyle_artar() -> String:
	if not (Teknoloji.maliyet(2) > Teknoloji.maliyet(1) and Teknoloji.maliyet(3) > Teknoloji.maliyet(2)):
		return "Maliyet seviyeyle artmalı."
	if not (Teknoloji.sure_saat(2) > Teknoloji.sure_saat(1) and Teknoloji.sure_saat(3) > Teknoloji.sure_saat(2)):
		return "Süre seviyeyle artmalı."
	return ""


func sina_en_yuksek_seviyeden_sonra_arastirilamaz() -> String:
	var oyun: Oyun = _kurulu_oyun()
	_seviye_ver(oyun, "TUR", "silah", Teknoloji.azami_seviye())
	oyun.hazineler["TUR"] = 100000.0
	if oyun.arastirma_baslat("TUR", "silah"):
		return "En yüksek seviyedeki dal yeniden araştırılmamalı."
	return ""


func sina_arastirma_bitince_oyuncuya_bildirim_gelir() -> String:
	var oyun: Oyun = _kurulu_oyun()
	oyun.hazineler["TUR"] = 1000.0
	oyun.arastirma_baslat("TUR", "lojistik")
	var gelen: Array[String] = []
	oyun.bildirim_gonder.connect(func(metin: String, _b: String) -> void: gelen.append(metin))
	for saat: int in Teknoloji.sure_saat(1):
		oyun._arastirmalari_isle()
	if gelen.is_empty() or not gelen[0].contains("Lojistik"):
		return "Araştırma bitince bildirim gelmeli: %s" % [gelen]
	return ""


func sina_sanayi_geliri_artirir() -> String:
	var oyun: Oyun = _kurulu_oyun()
	var once: float = oyun.ulkenin_geliri("TUR", 0)
	_seviye_ver(oyun, "TUR", "sanayi", 2)
	var sonra: float = oyun.ulkenin_geliri("TUR", 0)
	if not is_equal_approx(sonra, once * Teknoloji.gelir_carpani(2)):
		return "Sanayi 2 geliri %%20 artırmalı (%.2f -> %.2f)." % [once, sonra]
	return ""


func sina_silah_verilen_hasari_artirir() -> String:
	var oyun: Oyun = _kurulu_oyun()
	var bolge: Bolge = oyun.dunya.bolgeler["TUR_1"]
	var veren: Array[Birlik] = [_birlik("FRA", "piyade", 100.0)]
	var alan: Array[Birlik] = [_birlik("TUR", "piyade", 100.0)]
	var once: float = oyun._verilen_hasar(veren, alan, true, bolge)
	_seviye_ver(oyun, "FRA", "silah", 3)
	var sonra: float = oyun._verilen_hasar(veren, alan, true, bolge)
	if not is_equal_approx(sonra, once * Teknoloji.saldiri_carpani(3)):
		return "Silah 3 hasarı %%30 artırmalı (%.2f -> %.2f)." % [once, sonra]
	return ""


func sina_savunma_alinan_hasari_azaltir() -> String:
	var oyun: Oyun = _kurulu_oyun()
	var korumasiz: Birlik = _birlik("TUR", "piyade", 100.0)
	var korunan: Birlik = _birlik("FRA", "piyade", 100.0)
	_seviye_ver(oyun, "FRA", "savunma", 2)
	oyun._hasar_uygula([korumasiz], 20.0)
	oyun._hasar_uygula([korunan], 20.0)
	var beklenen: float = 100.0 - 20.0 / Teknoloji.savunma_carpani(2)
	if not is_equal_approx(korunan.guc, beklenen) or not korunan.guc > korumasiz.guc:
		return "Savunma 2 alınan hasarı azaltmalı (korunan %.2f, korumasız %.2f)." % [korunan.guc, korumasiz.guc]
	return ""


func sina_lojistik_yurumeyi_hizlandirir_ve_deniz_cezasini_azaltir() -> String:
	var yavas: Oyun = _kurulu_oyun()
	var hizli: Oyun = _kurulu_oyun()
	_seviye_ver(hizli, "TUR", "lojistik", 3)
	var hedef: String = yavas.dunya.bolgeler["TUR_1"].kara_komsulari[0]
	var a: Birlik = _birlik("TUR", "piyade", 100.0)
	var b: Birlik = _birlik("TUR", "piyade", 100.0)
	yavas.birlikler.append(a)
	hizli.birlikler.append(b)
	yavas.birlikleri_yurut([a], hedef, 0)
	hizli.birlikleri_yurut([b], hedef, 0)
	if not b.varis_saati < a.varis_saati:
		return "Lojistik 3 yürüyüşü kısaltmalı (%d / %d)." % [b.varis_saati, a.varis_saati]

	var bolge: Bolge = yavas.dunya.bolgeler["TUR_1"]
	var deniz: Birlik = _birlik("FRA", "piyade", 100.0)
	deniz.son_adim_deniz_mi = true
	var alan: Array[Birlik] = [_birlik("TUR", "piyade", 100.0)]
	var cezali: float = yavas._verilen_hasar([deniz], alan, true, bolge)
	_seviye_ver(yavas, "FRA", "lojistik", 2)
	var hafif: float = yavas._verilen_hasar([deniz], alan, true, bolge)
	if not hafif > cezali:
		return "Lojistik denizden saldırı cezasını azaltmalı (%.2f -> %.2f)." % [cezali, hafif]
	return ""


func sina_yz_arastirma_yapar() -> String:
	var oyun: Oyun = _kurulu_oyun()
	var ulke_id: String = "DEU"
	oyun.hazineler[ulke_id] = 100000.0
	oyun._yz_arastirma_olasiligi = 1.0
	oyun._yz_arastirma_dusun(ulke_id)
	if oyun.suren_arastirma(ulke_id).is_empty():
		return "Hazinesi olan yapay zekâ araştırma başlatmalı."
	return ""
