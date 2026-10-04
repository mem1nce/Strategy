extends RefCounted
## YolBulucu'nun kara/deniz süre hesabını ve yol bulmasını sınar.


func sina_kendi_bolgesine_sure_sifir() -> String:
	var dunya: Dunya = Dunya.yukle()
	if dunya.yol_bulucu.en_kisa_sure("TUR_1", "TUR_1") != 0.0:
		return "Aynı bölgeye süre 0 olmalı."
	return ""


func sina_kara_komsusuna_dogrudan_ve_sabit_sure() -> String:
	var dunya: Dunya = Dunya.yukle()
	var baslangic: Bolge = dunya.bolgeler["TUR_1"]
	if baslangic.kara_komsulari.is_empty():
		return "TUR_1'in kara komşusu yok, sınama kurulamadı."
	var komsu_id: String = baslangic.kara_komsulari[0]
	var yol: Array[String] = dunya.yol_bulucu.en_kisa_yol("TUR_1", komsu_id)
	if yol.size() != 2:
		return "Doğrudan kara komşusuna yol 2 bölgeli olmalı, geldi: %s" % str(yol)
	var sure: float = dunya.yol_bulucu.en_kisa_sure("TUR_1", komsu_id)
	if not is_equal_approx(sure, 24.0):
		return "Kara komşuluğu 24 saat olmalı, geldi: %.1f" % sure
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
	var sure: float = dunya.yol_bulucu.en_kisa_sure(kiyi_bolge.id, hedef_id)
	if sure <= 24.0:
		return "%s -> %s deniz yolu kara komşuluğundan (24 saat) belirgin yavaş olmalı, geldi: %.1f" % [
			kiyi_bolge.id, hedef_id, sure]
	return ""


func sina_uzak_bolgeler_arasinda_yol_bulunur() -> String:
	var dunya: Dunya = Dunya.yukle()
	# Türkiye'den Avustralya'ya: çoğunlukla kara, en az bir deniz yolu gerektirir.
	var sure: float = dunya.yol_bulucu.en_kisa_sure("TUR_1", "AUS_1")
	if sure <= 0.0:
		return "TUR_1 -> AUS_1 arasında yol bulunamadı."
	return ""
