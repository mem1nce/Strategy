extends RefCounted
## Oyun.savas_ilan_et() ve boş düşman bölgesi işgalini sınar.


## TUR'un kara komşusu olmayan (başka kıtada, komşu olmadığı bilinen) bir ülke döner.
func _komsu_olmayan_ulke(dunya: Dunya) -> String:
	for ulke: Ulke in dunya.ulke_listesi:
		if ulke.id != "TUR" and not dunya.ulkeler_komsu_mu("TUR", ulke.id):
			return ulke.id
	return ""


## TUR'un kara ya da deniz yoluyla doğrudan komşusu olan bir ülke döner.
func _komsu_ulke(dunya: Dunya) -> String:
	for ulke: Ulke in dunya.ulke_listesi:
		if ulke.id != "TUR" and dunya.ulkeler_komsu_mu("TUR", ulke.id):
			return ulke.id
	return ""


func sina_komsu_olmayan_ulkeye_ilan_edilemez() -> String:
	var dunya: Dunya = Dunya.yukle()
	var oyun: Oyun = Oyun.new(dunya)
	var uzak: String = _komsu_olmayan_ulke(dunya)
	if uzak == "":
		return "Komşu olmayan bir ülke bulunamadı, sınama kurulamadı."
	if oyun.savas_ilan_et("TUR", uzak):
		return "Komşu olmayan ülkeye savaş ilanı kabul edilmemeliydi."
	if oyun.savasta_mi("TUR", uzak):
		return "Reddedilen ilandan sonra savaşta görünmemeli."
	return ""


func sina_komsu_ulkeye_ilan_edilebilir() -> String:
	var dunya: Dunya = Dunya.yukle()
	var oyun: Oyun = Oyun.new(dunya)
	var komsu: String = _komsu_ulke(dunya)
	if komsu == "":
		return "TUR'un komşusu bulunamadı, sınama kurulamadı."
	if not oyun.savas_ilan_et("TUR", komsu):
		return "Komşu ülkeye savaş ilanı kabul edilmeliydi."
	if not oyun.savasta_mi("TUR", komsu) or not oyun.savasta_mi(komsu, "TUR"):
		return "İlandan sonra iki yönde de savaşta olmalı."
	return ""


func sina_ayni_savas_tekrar_ilan_edilemez() -> String:
	var dunya: Dunya = Dunya.yukle()
	var oyun: Oyun = Oyun.new(dunya)
	var komsu: String = _komsu_ulke(dunya)
	if komsu == "" or not oyun.savas_ilan_et("TUR", komsu):
		return "Sınama kurulamadı (komşu yok ya da ilk ilan başarısız)."
	if oyun.savas_ilan_et(komsu, "TUR"):
		return "Zaten savaşta olan iki ülke arasında tekrar ilan kabul edilmemeliydi."
	return ""


func sina_kendine_ilan_edilemez() -> String:
	var dunya: Dunya = Dunya.yukle()
	var oyun: Oyun = Oyun.new(dunya)
	if oyun.savas_ilan_et("TUR", "TUR"):
		return "Bir ülke kendine savaş ilan edemez."
	return ""


func sina_bos_dusman_bolgesi_isgal_edilir() -> String:
	var dunya: Dunya = Dunya.yukle()
	var oyun: Oyun = Oyun.new(dunya)
	var komsu: String = _komsu_ulke(dunya)
	if komsu == "" or not oyun.savas_ilan_et("TUR", komsu):
		return "Sınama kurulamadı (komşu yok ya da ilan başarısız)."

	# Komşu ülkenin TUR'a değen (kara ya da deniz) bir bölgesini bul ve boşalt.
	var hedef_id: String = ""
	for bolge: Bolge in dunya.ulkenin_bolgeleri(komsu):
		for komsusu: Bolge in dunya.bolgenin_komsulari(bolge.id):
			if komsusu.sahip == "TUR":
				hedef_id = bolge.id
				break
		if hedef_id != "":
			break
	if hedef_id == "":
		return "TUR'a değen bir %s bölgesi bulunamadı, sınama kurulamadı." % komsu
	for birlik: Birlik in oyun.bolgedeki_birlikler(hedef_id):
		birlik.bolge_id = "SIMDILIK_BASKA_YERDE"

	var kaynak_id: String = dunya.bolgenin_komsulari(hedef_id).filter(
			func(b: Bolge) -> bool: return b.sahip == "TUR")[0].id
	var tasinacaklar: Array[Birlik] = oyun.bolgedeki_birlikler(kaynak_id)
	if tasinacaklar.is_empty():
		return "%s bölgesinde tümen yok, sınama kurulamadı." % kaynak_id
	if not oyun.birlikleri_yurut(tasinacaklar, hedef_id, 0):
		return "Savaştaki düşman bölgesine yürütme kabul edilmeliydi."
	oyun.saat_ilerledi(1000)

	if dunya.bolgeler[hedef_id].sahip != "TUR":
		return "Boş düşman bölgesi ele geçirilmeliydi, hâlâ sahibi: %s" % dunya.bolgeler[hedef_id].sahip
	return ""


func sina_dolu_dusman_bolgesi_isgal_edilmez() -> String:
	var dunya: Dunya = Dunya.yukle()
	var oyun: Oyun = Oyun.new(dunya)
	var komsu: String = _komsu_ulke(dunya)
	if komsu == "" or not oyun.savas_ilan_et("TUR", komsu):
		return "Sınama kurulamadı (komşu yok ya da ilan başarısız)."

	var hedef: Bolge = null
	var kaynak_id: String = ""
	for bolge: Bolge in dunya.ulkenin_bolgeleri(komsu):
		for komsusu: Bolge in dunya.bolgenin_komsulari(bolge.id):
			if komsusu.sahip == "TUR":
				hedef = bolge
				kaynak_id = komsusu.id
				break
		if hedef != null:
			break
	if hedef == null or oyun.bolgedeki_birlikler(hedef.id).is_empty():
		return "Savunması olan bir %s bölgesi bulunamadı, sınama kurulamadı." % komsu

	var tasinacaklar: Array[Birlik] = oyun.bolgedeki_birlikler(kaynak_id)
	if tasinacaklar.is_empty() or not oyun.birlikleri_yurut(tasinacaklar, hedef.id, 0):
		return "Sınama kurulamadı: kaynakta tümen yok ya da yürütme reddedildi."
	oyun.saat_ilerledi(1000)

	if dunya.bolgeler[hedef.id].sahip != komsu:
		return "Savunması olan bölge, muharebe olmadan ele geçirilmemeliydi."
	return ""
