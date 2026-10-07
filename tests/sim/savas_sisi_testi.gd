extends RefCounted
## Savaş sisini sınar: oyuncunun ve yapay zekânın neyi gördüğü, sis kapalıyken her şeyin
## görünmesi, görünürlüğün yalnızca değişince yeniden hesaplanması ve kayıt.


func _kurulu_oyun() -> Oyun:
	var oyun: Oyun = Oyun.new(Dunya.yukle())
	oyun.oyuncuyu_sec("TUR")
	return oyun


## Ülkenin, gördüğü bölgelerin dışında kalan bir bölgesi (yoksa boş).
func _gorulmeyen_bolge(oyun: Oyun, ulke_id: String) -> String:
	for bolge: Bolge in oyun.dunya.ulkenin_bolgeleri(ulke_id):
		if not oyun.oyuncu_bolgeyi_goruyor_mu(bolge.id):
			return bolge.id
	return ""


func sina_kendi_bolgeleri_ve_komsulari_gorunur() -> String:
	var oyun: Oyun = _kurulu_oyun()
	for bolge: Bolge in oyun.dunya.ulkenin_bolgeleri("TUR"):
		if not oyun.oyuncu_bolgeyi_goruyor_mu(bolge.id):
			return "Kendi bölgesi %s görünmeli." % bolge.id
		for komsu: Bolge in oyun.dunya.bolgenin_komsulari(bolge.id):
			if not oyun.oyuncu_bolgeyi_goruyor_mu(komsu.id):
				return "Kendi bölgesinin komşusu %s (kara ya da deniz) görünmeli." % komsu.id
	return ""


func sina_uzak_bolge_gorunmez() -> String:
	var oyun: Oyun = _kurulu_oyun()
	if oyun.oyuncu_bolgeyi_goruyor_mu("AUS_1"):
		return "Türkiye'den Avustralya'nın başkenti görünmemeli."
	if _gorulmeyen_bolge(oyun, "IRN") == "":
		return "İran'ın sınırdan uzak bir bölgesi görünmemeli."
	return ""


func sina_tumenin_bulundugu_bolge_ve_komsulari_gorunur() -> String:
	var oyun: Oyun = _kurulu_oyun()
	var uzak: String = _gorulmeyen_bolge(oyun, "IRN")
	var birlik: Birlik = Birlik.new()
	birlik.sahip = "TUR"
	birlik.bolge_id = uzak
	oyun.birlikler.append(birlik)
	oyun.birlikler_degisti.emit()
	if not oyun.oyuncu_bolgeyi_goruyor_mu(uzak):
		return "Tümenin bulunduğu bölge görünmeli."
	for komsu: Bolge in oyun.dunya.bolgenin_komsulari(uzak):
		if not oyun.oyuncu_bolgeyi_goruyor_mu(komsu.id):
			return "Tümenin bulunduğu bölgenin komşusu %s görünmeli." % komsu.id
	return ""


func sina_sis_kapaliyken_her_yer_gorunur() -> String:
	var oyun: Oyun = _kurulu_oyun()
	oyun.savas_sisi = false
	for bolge: Bolge in oyun.dunya.bolge_listesi:
		if not oyun.oyuncu_bolgeyi_goruyor_mu(bolge.id):
			return "Sis kapalıyken %s görünmeli." % bolge.id
	oyun.savas_sisi = true
	if oyun.oyuncu_bolgeyi_goruyor_mu("AUS_1"):
		return "Sis yeniden açılınca uzak bölge yine görünmemeli."
	return ""


func sina_oyuncu_secilmeden_her_yer_gorunur() -> String:
	var oyun: Oyun = Oyun.new(Dunya.yukle())
	if not oyun.oyuncu_bolgeyi_goruyor_mu("AUS_1"):
		return "Ülke seçilmeden önce (ülke seçim ekranı) her yer görünmeli."
	return ""


func sina_gorunurluk_yalnizca_degisince_bildirilir() -> String:
	var oyun: Oyun = _kurulu_oyun()
	var sayac: Array[int] = [0]
	oyun.gorunurluk_degisti.connect(func() -> void: sayac[0] += 1)
	# Görünen bölgeleri değiştirmeyen bir tümen değişikliği bildirim üretmemeli.
	oyun.bolgedeki_birlikler("TUR_1")[0].guc = 50.0
	oyun.birlikler_degisti.emit()
	if sayac[0] != 0:
		return "Görünen bölgeler değişmediyse gorunurluk_degisti yayılmamalı."
	var birlik: Birlik = Birlik.new()
	birlik.sahip = "TUR"
	birlik.bolge_id = _gorulmeyen_bolge(oyun, "IRN")
	oyun.birlikler.append(birlik)
	oyun.birlikler_degisti.emit()
	if sayac[0] != 1:
		return "Yeni bölgeler görününce gorunurluk_degisti bir kez yayılmalı (%d)." % sayac[0]
	return ""


func sina_el_degisen_bolge_gorunurlugu_gunceller() -> String:
	var oyun: Oyun = _kurulu_oyun()
	var uzak: String = _gorulmeyen_bolge(oyun, "IRN")
	oyun.dunya.bolgeler[uzak].sahip = "TUR"
	oyun.bolge_sahipligi_degisti.emit()
	if not oyun.oyuncu_bolgeyi_goruyor_mu(uzak):
		return "Ele geçirilen bölge görünür olmalı."
	return ""


func sina_yz_uzaktaki_tumenleri_bilmez() -> String:
	var oyun: Oyun = Oyun.new(Dunya.yukle())
	var gorunenler: Dictionary[String, bool] = oyun._yz_gorunur_bolgeler("TUR")
	var uzak: String = ""
	for bolge: Bolge in oyun.dunya.ulkenin_bolgeleri("IRN"):
		if not gorunenler.has(bolge.id):
			uzak = bolge.id
			break
	if uzak == "":
		return "Sınama kurulamadı: Türkiye'nin görmediği bir İran bölgesi yok."
	var once: float = oyun._gorunen_guc("IRN", gorunenler)
	var dev: Birlik = Birlik.new()
	dev.sahip = "IRN"
	dev.guc = 1000.0
	dev.bolge_id = uzak
	oyun.birlikler.append(dev)
	oyun._saat_dizini_saati = -1
	if not is_equal_approx(oyun._gorunen_guc("IRN", gorunenler), once):
		return "Yapay zekâ, görmediği bölgedeki tümeni hesaba katmamalı."
	return ""


func sina_savas_sisi_kayitta_saklanir() -> String:
	var oyun: Oyun = _kurulu_oyun()
	oyun.savas_sisi = false
	var veri: Dictionary = oyun.kaydet_icin_veri()
	var yeni: Oyun = Oyun.new(Dunya.yukle())
	yeni.kayittan_yukle(veri)
	if yeni.savas_sisi:
		return "Kapalı savaş sisi kayıttan kapalı gelmeli."
	veri.erase("savas_sisi")  # 3. sürüm kayıt.
	var eski: Oyun = Oyun.new(Dunya.yukle())
	eski.kayittan_yukle(veri)
	if not eski.savas_sisi:
		return "Alanı olmayan (3. sürüm) kayıtta savaş sisi açık sayılmalı."
	return ""
