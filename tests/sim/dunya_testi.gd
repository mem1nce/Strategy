extends RefCounted
## Dunya.yukle() ve sorgularının data/ dosyalarıyla tutarlı çalıştığını sınar.
##
## tools/dunya_donustur.py kendi doğrulamasını yapar; burada sınanan, GDScript tarafının
## (Bolge/Ulke/Dunya) aynı veriyi doğru okuyup sorgulayabildiğidir.


func sina_dunya_yuklenir() -> String:
	var dunya: Dunya = Dunya.yukle()
	if dunya == null:
		return "Dunya.yukle() null döndürdü."
	if dunya.ulke_listesi.is_empty() or dunya.bolge_listesi.is_empty():
		return "Ülke ya da bölge listesi boş."
	return ""


func sina_bolgenin_sahibi() -> String:
	var dunya: Dunya = Dunya.yukle()
	var ulke: Ulke = dunya.ulkeler.get("TUR")
	if ulke == null:
		return "TUR bulunamadı."
	var sahip: Ulke = dunya.bolgenin_sahibi(ulke.baskent_bolgesi)
	if sahip == null or sahip.id != "TUR":
		return "Türkiye'nin başkent bölgesinin sahibi yanlış: %s" % (sahip.id if sahip != null else "null")
	return ""


func sina_kara_komsulugu_simetrik() -> String:
	var dunya: Dunya = Dunya.yukle()
	for bolge: Bolge in dunya.bolge_listesi:
		for komsu_id: String in bolge.kara_komsulari:
			var komsu: Bolge = dunya.bolgeler.get(komsu_id)
			if komsu == null:
				return "%s: bilinmeyen kara komşusu %s" % [bolge.id, komsu_id]
			if not komsu.kara_komsulari.has(bolge.id):
				return "%s -> %s kara komşuluğu tek yönlü" % [bolge.id, komsu_id]
	return ""


func sina_deniz_yolu_simetrik_ve_karadan_ayrik() -> String:
	var dunya: Dunya = Dunya.yukle()
	for bolge: Bolge in dunya.bolge_listesi:
		for komsu_id: String in bolge.deniz_gecisleri:
			var komsu: Bolge = dunya.bolgeler.get(komsu_id)
			if komsu == null or not komsu.deniz_gecisleri.has(bolge.id):
				return "%s -> %s deniz yolu tek yönlü ya da hedef yok" % [bolge.id, komsu_id]
			if bolge.kara_komsulari.has(komsu_id):
				return "%s ile %s hem kara komşusu hem deniz yolu" % [bolge.id, komsu_id]
	return ""


func sina_kiyi_olmayan_bolgenin_deniz_yolu_yok() -> String:
	var dunya: Dunya = Dunya.yukle()
	for bolge: Bolge in dunya.bolge_listesi:
		if not bolge.kiyi and not bolge.deniz_gecisleri.is_empty():
			return "%s kıyı değil ama deniz yolu var" % bolge.id
	return ""


func sina_noktadaki_cokgen_bolgeyi_bulur() -> String:
	var dunya: Dunya = Dunya.yukle()
	var ankara: Bolge = dunya.bolgeler.get("TUR_1")
	if ankara == null:
		return "TUR_1 bulunamadı."
	var cokgen: Cokgen = dunya.noktadaki_cokgen(ankara.etiket)
	if cokgen == null or cokgen.bolge_id != "TUR_1":
		return "Ankara'nın etiket noktasında TUR_1 bulunamadı (geldi: %s)." % (cokgen.bolge_id if cokgen != null else "null")
	return ""


func sina_dunya_baglantisi_tek_parca() -> String:
	# Kara komşuluğu ve deniz yollarının birleşimiyle her bölgeye her bölgeden ulaşılabilmeli
	# (tools/dunya_donustur.py bunu üretimde garanti eder; burada GDScript tarafında doğrulanır).
	var dunya: Dunya = Dunya.yukle()
	if dunya.bolge_listesi.is_empty():
		return "Bölge listesi boş."
	var gorulen: Dictionary[String, bool] = {}
	var kuyruk: Array[String] = [dunya.bolge_listesi[0].id]
	gorulen[kuyruk[0]] = true
	while not kuyruk.is_empty():
		var su_an: String = kuyruk.pop_back()
		for komsu: Bolge in dunya.bolgenin_komsulari(su_an):
			if not gorulen.has(komsu.id):
				gorulen[komsu.id] = true
				kuyruk.append(komsu.id)
	if gorulen.size() != dunya.bolge_listesi.size():
		return "Ulaşılamayan bölge sayısı: %d" % (dunya.bolge_listesi.size() - gorulen.size())
	return ""
