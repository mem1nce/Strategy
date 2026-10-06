extends RefCounted
## YolBulucu'nun kara/deniz süre hesabını ve yol bulmasını sınar.


func sina_kendi_bolgesine_sure_sifir() -> String:
	var dunya: Dunya = Dunya.yukle()
	if dunya.yol_bulucu.en_kisa_sure("TUR_1", "TUR_1") != 0.0:
		return "Aynı bölgeye süre 0 olmalı."
	return ""


func sina_kara_komsusuna_dogrudan_ve_mesafeyle_orantili_sure() -> String:
	var dunya: Dunya = Dunya.yukle()
	var baslangic: Bolge = dunya.bolgeler["TUR_1"]
	if baslangic.kara_komsulari.is_empty():
		return "TUR_1'in kara komşusu yok, sınama kurulamadı."
	var komsu_id: String = baslangic.kara_komsulari[0]
	var yol: Array[String] = dunya.yol_bulucu.en_kisa_yol("TUR_1", komsu_id)
	if yol.size() != 2:
		return "Doğrudan kara komşusuna yol 2 bölgeli olmalı, geldi: %s" % str(yol)
	var sure: float = dunya.yol_bulucu.en_kisa_sure("TUR_1", komsu_id)
	var ayarlar: Dictionary = VeriOkuyucu.sozluk_oku("res://data/balance.json")["hareket"]
	var mesafe: float = baslangic.etiket.distance_to(dunya.bolgeler[komsu_id].etiket)
	var beklenen: float = clampf(mesafe * float(ayarlar["kara_saat_birim_basi"]),
			float(ayarlar["kara_asgari_saat"]), float(ayarlar["kara_azami_saat"]))
	if not is_equal_approx(sure, beklenen):
		return "Kara komşuluğu mesafeyle orantılı olmalı (beklenen %.1f, geldi %.1f)." % [beklenen, sure]
	return ""


func sina_uzak_kara_komsusu_yakindakinden_uzun_surer() -> String:
	var dunya: Dunya = Dunya.yukle()
	var en_kisa: float = INF
	var en_uzun: float = 0.0
	for bolge: Bolge in dunya.ulkenin_bolgeleri("RUS"):
		for komsu_id: String in bolge.kara_komsulari:
			var sure: float = dunya.yol_bulucu.en_kisa_sure(bolge.id, komsu_id)
			en_kisa = minf(en_kisa, sure)
			en_uzun = maxf(en_uzun, sure)
	if not en_uzun > en_kisa:
		return "Rusya'da uzak kara komşuları yakındakilerden uzun sürmeli (%.1f / %.1f)." % [en_kisa, en_uzun]
	return ""


func sina_deniz_yolu_karadan_belirgin_yavas() -> String:
	var dunya: Dunya = Dunya.yukle()
	var kiyi_bolge: Bolge = null
	for bolge: Bolge in dunya.bolge_listesi:
		if not bolge.deniz_gecisleri.is_empty():
			kiyi_bolge = bolge
			break
	if kiyi_bolge == null:
		return "Hiç deniz yolu olan bölge bulunamadı, sınama kurulamadı."
	var hedef_id: String = kiyi_bolge.deniz_gecisleri[0]
	# Doğrudan deniz geçişinin süresi (en kısa yol karadan dolaşabilir).
	var yb: YolBulucu = dunya.yol_bulucu
	var sure: float = yb._compute_cost(yb._bolge_id[kiyi_bolge.id], yb._bolge_id[hedef_id])
	if sure <= 48.0:
		return "%s -> %s deniz yolu belirgin yavaş olmalı (en az 48 saatlik taban), geldi: %.1f" % [
			kiyi_bolge.id, hedef_id, sure]
	return ""


func sina_uzak_bolgeler_arasinda_yol_bulunur() -> String:
	var dunya: Dunya = Dunya.yukle()
	# Türkiye'den Avustralya'ya: çoğunlukla kara, en az bir deniz yolu gerektirir.
	var sure: float = dunya.yol_bulucu.en_kisa_sure("TUR_1", "AUS_1")
	if sure <= 0.0:
		return "TUR_1 -> AUS_1 arasında yol bulunamadı."
	return ""
