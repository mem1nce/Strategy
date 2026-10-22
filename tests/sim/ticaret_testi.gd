extends RefCounted
## Ticaret (bkz. Ticaret, RotaAgi): başlangıç anlaşmaları ve kapasite, rotalar ve geçitler
## (İstanbul Boğazı, Süveyş, geçidi atlayan bağlantı yok), geçiş ücreti, ortaktan indirimli
## ithalat, ambargo, teklifler, liman, askeri hareketin geçit kuralı ve kayıt.


func _oyun() -> Oyun:
	return Oyun.new(Dunya.yukle())


## İki ülkeyi doğrudan savaşa sokar (komşu olmasalar da; sınama için).
func _savas(oyun: Oyun, a: String, b: String) -> void:
	oyun._savaslar[oyun._savas_anahtari(a, b)] = 0
	oyun._savas_dizinini_kur()
	oyun.ticaret.savas_basladi(oyun, a, b)


## Anlaşmayı kapasiteye bakmadan kurar (gerekirse tarafların en zayıf anlaşmalarını bırakır).
func _anlasma_kur(oyun: Oyun, a: String, b: String) -> Dictionary:
	var t: Ticaret = oyun.ticaret
	for taraf: String in [a, b]:
		while t.anlasma_sayisi(taraf) >= t.kapasite(oyun, taraf):
			t._cikar(t.en_zayif_anlasma(taraf))
	t.anlasma_yap(oyun, a, b)
	return t.anlasma(a, b)


func _ulke_bolgeleri(oyun: Oyun, ulkeler: Array[String]) -> Array[String]:
	var sonuc: Array[String] = []
	for ulke_id: String in ulkeler:
		for bolge: Bolge in oyun.dunya.ulkenin_bolgeleri(ulke_id):
			sonuc.append(bolge.id)
	return sonuc


## Ülkenin verilen havzaya değen bir kıyı bölgesi.
func _havza_bolgesi(oyun: Oyun, ulke_id: String, havza: String) -> String:
	for bolge: Bolge in oyun.dunya.ulkenin_bolgeleri(ulke_id):
		if (oyun.ticaret.bolge_havzalari.get(bolge.id, []) as Array).has(havza):
			return bolge.id
	return ""


func sina_baslangicta_kapasitenin_yarisi_kadar_anlasma() -> String:
	var oyun: Oyun = _oyun()
	var t: Ticaret = oyun.ticaret
	for ulke: Ulke in oyun.dunya.ulke_listesi:
		var kap: int = t.kapasite(oyun, ulke.id)
		if kap < 2 or kap > 8:
			return "Kapasite 2-8 olmalı (%s: %d)." % [ulke.id, kap]
		if t.anlasma_sayisi(ulke.id) > kap:
			return "Anlaşma sayısı kapasiteyi geçmemeli (%s)." % ulke.id
	if t.anlasmalar.size() < oyun.dunya.ulke_listesi.size() / 2:
		return "Oyun başında her ülkenin aşağı yukarı bir anlaşması olmalı (%d)." % t.anlasmalar.size()
	if t.kapasite(oyun, "TUR") != 2 + _liman_toplami(oyun, "TUR") / 2:
		return "Kapasite 2 + liman seviyeleri toplamının yarısı olmalı."
	return ""


func _liman_toplami(oyun: Oyun, ulke_id: String) -> int:
	var toplam: int = 0
	for bolge: Bolge in oyun.dunya.ulkenin_bolgeleri(ulke_id):
		toplam += bolge.liman
	return toplam


func sina_turkiye_rusya_savasinda_rus_rotalari_bogazdan_gecmez() -> String:
	var oyun: Oyun = _oyun()
	var t: Ticaret = oyun.ticaret
	var karadeniz: String = _havza_bolgesi(oyun, "RUS", "Karadeniz")
	var italya: String = t.en_iyi_liman(oyun, "ITA")
	var acik: Array[String] = _ulke_bolgeleri(oyun, ["RUS", "ITA"] as Array[String])
	var once: Dictionary = t.ag.rota_bul(karadeniz, italya, acik, t.rotaya_kapali_gecitler(oyun, "RUS", "ITA"))
	if not (once.get("gecitler", []) as Array).has("istanbul"):
		return "Barışta Rusya'nın Karadeniz'den Akdeniz'e rotası İstanbul Boğazı'ndan geçmeli (%s)." % [once.get("gecitler")]
	_anlasma_kur(oyun, "RUS", "ITA")
	_savas(oyun, "TUR", "RUS")
	oyun.gun_basladi(24)
	for a: Dictionary in t.ulkenin_anlasmalari("RUS"):
		if ((a["rota"] as Dictionary).get("gecitler", []) as Array).has("istanbul"):
			return "Türkiye ile savaşan Rusya'nın %s-%s rotası boğazdan geçmemeli." % [a["a"], a["b"]]
	var sonra: Dictionary = t.ag.rota_bul(karadeniz, italya, acik, t.rotaya_kapali_gecitler(oyun, "RUS", "ITA"))
	if (sonra.get("gecitler", []) as Array).has("istanbul"):
		return "Savaşta boğaz Rusya'ya kapalı olmalı."
	return ""


func sina_misirla_savasan_fransa_dogu_asyaya_afrikayi_dolasir() -> String:
	var oyun: Oyun = _oyun()
	var t: Ticaret = oyun.ticaret
	var a: Dictionary = _anlasma_kur(oyun, "FRA", "JPN")
	oyun.gun_basladi(24)
	var once_rota: Dictionary = a["rota"]
	var once_deger: float = a["deger"]
	if not (once_rota.get("gecitler", []) as Array).has("suveys"):
		return "Barışta Fransa-Japonya rotası Süveyş'ten geçmeli (%s)." % [once_rota.get("gecitler")]
	_savas(oyun, "FRA", "EGY")
	oyun.gun_basladi(48)
	var sonra_rota: Dictionary = a["rota"]
	if sonra_rota.is_empty() or (sonra_rota.get("gecitler", []) as Array).has("suveys"):
		return "Mısır'la savaşta rota Süveyş'ten geçmemeli ama kesilmemeli."
	# Afrika'yı dolaşan rota Ümit Burnu'nun enleminden güneye iner.
	var umit_y: float = oyun.dunya.bolgeler[oyun.dunya.ulkeler["ZAF"].baskent_bolgesi].etiket.y
	var en_guney: float = -INF
	for nokta: Vector2 in (sonra_rota["yol"] as Array):
		en_guney = maxf(en_guney, nokta.y)
	if en_guney < umit_y:
		return "Rota Afrika'yı dolaşmalı (en güney %.0f, Güney Afrika %.0f)." % [en_guney, umit_y]
	if not float(a["deger"]) < once_deger:
		return "Uzayan rotanın değeri düşmeli (%.2f -> %.2f)." % [once_deger, float(a["deger"])]
	return ""


func sina_hicbir_gecit_atlanamaz() -> String:
	var oyun: Oyun = _oyun()
	var t: Ticaret = oyun.ticaret
	# [geçit(ler), iç havzadaki ülke, iç havza, dıştaki ülke]: geçit kapalıyken (ve kara yolu yalnızca
	# iki tarafın topraklarındayken) iç havzadan dışarı deniz yolu kalmamalı.
	var durumlar: Array = [
		[["istanbul"], "UKR", "Karadeniz", "ITA"],
		[["danimarka"], "FIN", "Baltık", "GBR"],
		[["hurmuz"], "KWT", "Basra", "IND"],
		[["suveys", "babulmendep"], "SDN", "Kızıldeniz", "ITA"],
	]
	for durum: Array in durumlar:
		var ic: String = _havza_bolgesi(oyun, durum[1], durum[2])
		if ic == "":
			return "%s'nın %s kıyısı bulunamadı." % [durum[1], durum[2]]
		var acik: Array[String] = _ulke_bolgeleri(oyun, [durum[1], durum[3]] as Array[String])
		var kapali: Array[String] = []
		kapali.assign(durum[0])
		var rota: Dictionary = t.ag.rota_bul(ic, t.en_iyi_liman(oyun, durum[3]), acik, kapali)
		if not rota.is_empty():
			return "%s kapalıyken %s'dan %s'ya geçidi atlayan bir yol var: %s" % [durum[0], durum[1], durum[3], rota["bolgeler"]]
		var acik_rota: Dictionary = t.ag.rota_bul(ic, t.en_iyi_liman(oyun, durum[3]), acik, [] as Array[String])
		if acik_rota.is_empty():
			return "%s açıkken %s'dan %s'ya rota olmalı." % [durum[0], durum[1], durum[3]]
	return ""


func sina_gecis_ucreti_kontrol_edene_odenir() -> String:
	var oyun: Oyun = _oyun()
	var t: Ticaret = oyun.ticaret
	var a: Dictionary = _anlasma_kur(oyun, "UKR", "ITA")
	oyun.gun_basladi(24)
	var rota: Dictionary = a["rota"]
	if not (rota.get("gecitler", []) as Array).has("istanbul"):
		return "Ukrayna-İtalya rotası İstanbul Boğazı'ndan geçmeli (%s)." % [rota.get("gecitler")]
	var deger: float = a["deger"]
	var ucret: float = deger * t.gecis_ucreti
	if float((t.gunluk.get("TUR", {}) as Dictionary).get("gecis", 0.0)) < ucret * 0.999:
		return "Türkiye geçen rotanın değerinin %%5'ini almalı (%.4f)." % ucret
	if not is_equal_approx(float(t.gecit_geliri.get("istanbul", 0.0)) >= ucret * 0.999, true):
		return "Geçidin ücret geliri sayılmalı."
	return ""


func sina_ortaktan_ithalat_ucuzdur() -> String:
	var bedeller: Array[float] = []
	for ortakli: bool in [false, true]:
		var oyun: Oyun = _oyun()
		var t: Ticaret = oyun.ticaret
		for a: Dictionary in t.ulkenin_anlasmalari("JPN"):
			t._cikar(a)
		if ortakli:
			_anlasma_kur(oyun, "JPN", "SAU")
		oyun.gun_basladi(24)
		bedeller.append(float(oyun.ekonomi.kalemler["JPN"]["ithalat"]))
	if not bedeller[1] < bedeller[0]:
		return "Petrol fazlası olan ortaktan ithalat ucuz olmalı (%.3f -> %.3f)." % bedeller
	return ""


func sina_ambargo_anlasmayi_bitirir_gecidi_kapatir() -> String:
	var oyun: Oyun = _oyun()
	var t: Ticaret = oyun.ticaret
	_anlasma_kur(oyun, "TUR", "UKR")
	t.ambargo_uygula(oyun, "TUR", "UKR")
	if not t.anlasma("TUR", "UKR").is_empty():
		return "Ambargo iki ülke arasındaki anlaşmayı bitirmeli."
	if not t.rotaya_kapali_gecitler(oyun, "UKR", "ITA").has("istanbul"):
		return "Ambargo uygulayan Türkiye boğazı Ukrayna'ya kapatmalı."
	if t.anlasma_yapilabilir_mi(oyun, "UKR", "TUR"):
		return "Ambargodaki iki ülke anlaşma yapamamalı."
	oyun._yz_ambargo_dusun("UKR")
	if not t.ambargo_uyguluyor_mu("UKR", "TUR"):
		return "Yapay zekâ kendisine uygulanan ambargoya karşılık vermeli."
	t.ambargo_kaldir(oyun, "TUR", "UKR")
	oyun._yz_ambargo_dusun("UKR")
	if t.ambargo_uyguluyor_mu("UKR", "TUR"):
		return "Karşı taraf kaldırınca yapay zekâ da ambargoyu kaldırmalı."
	return ""


func sina_yapay_zeka_teklifleri() -> String:
	var oyun: Oyun = _oyun()
	var t: Ticaret = oyun.ticaret
	_savas(oyun, "DEU", "POL")
	if t.teklif_et(oyun, "DEU", "POL", 0) != "red":
		return "Savaştaki ülkenin teklifi reddedilmeli."
	for a: Dictionary in t.ulkenin_anlasmalari("NLD"):
		t._cikar(a)
	for a: Dictionary in t.ulkenin_anlasmalari("BEL"):
		t._cikar(a)
	if t.teklif_et(oyun, "NLD", "BEL", 0) != "kabul" or t.anlasma("NLD", "BEL").is_empty():
		return "Boş kapasitesi olan yapay zekâ teklifi kabul etmeli."
	oyun.oyuncuyu_sec("TUR")
	for a: Dictionary in t.ulkenin_anlasmalari("TUR"):
		t._cikar(a)
	if t.teklif_et(oyun, "GRC", "TUR", 0) != "teklif" or t.teklifler.size() != 1:
		return "Oyuncuya gelen teklif bekleyen tekliflere girmeli."
	if not t.teklifi_yanitla(oyun, "GRC", true) or t.anlasma("GRC", "TUR").is_empty():
		return "Oyuncu kabul edince anlaşma yapılmalı."
	return ""


## Yapay zekâ oyuncuya teklif yağdırmaz: en çok yz_oyuncuya_azami_teklif teklif bekler, aynı ülke
## ikinci kez teklif etmez, reddedilen ülke yz_ret_bekleme_gun boyunca yeniden teklif etmez.
func sina_oyuncuya_teklif_sinirli() -> String:
	var oyun: Oyun = _oyun()
	var t: Ticaret = oyun.ticaret
	oyun.oyuncuyu_sec("TUR")
	for a: Dictionary in t.ulkenin_anlasmalari("TUR"):
		t._cikar(a)
	if not t._oyuncuya_teklif_edilebilir("GRC", 0):
		return "Bekleyen teklif yokken teklif edilebilmeli."
	t.teklif_et(oyun, "GRC", "TUR", 0)
	if t._oyuncuya_teklif_edilebilir("GRC", 0):
		return "Aynı ülke ikinci kez teklif etmemeli."
	for i: int in t.yz_oyuncuya_azami_teklif - 1:
		t.teklif_et(oyun, ["BGR", "GEO", "ARM", "IRN"][i], "TUR", 0)
	if t._oyuncuya_teklif_edilebilir("SYR", 0):
		return "Bekleyen teklif sınırdayken yeni teklif gelmemeli."
	t.teklifi_yanitla(oyun, "GRC", false)
	if t._oyuncuya_teklif_edilebilir("GRC", 24):
		return "Reddeden ülke hemen yeniden teklif etmemeli."
	var bitis: int = (t.teklif_suresi_gun + t.yz_ret_bekleme_gun) * 24 + 1
	if not t._oyuncuya_teklif_edilebilir("GRC", bitis):
		return "Bekleme bitince yeniden teklif edebilmeli."
	return ""


func sina_liman_gelisir_kapasite_artar() -> String:
	var oyun: Oyun = _oyun()
	var t: Ticaret = oyun.ticaret
	oyun.hazineler["TUR"] = 100000.0
	var ic_bolge: String = ""
	for bolge: Bolge in oyun.dunya.ulkenin_bolgeleri("TUR"):
		if not t.kiyi_bolgeleri.has(bolge.id):
			ic_bolge = bolge.id
	if ic_bolge != "" and oyun.liman_sirala("TUR", ic_bolge):
		return "Kıyıda olmayan bölgede liman kurulamamalı."
	var hedef: String = t.liman_gelistirilecek_bolge(oyun, "TUR")
	var once: int = oyun.dunya.bolgeler[hedef].liman
	if not oyun.liman_sirala("TUR", hedef):
		return "Kıyı bölgesinde liman sıralanabilmeli."
	for saat: int in range(1, t.liman_suresi_saat + 2):
		oyun._insa_islerini_isle()
	if oyun.dunya.bolgeler[hedef].liman != once + 1:
		return "Liman işi bitince seviye bir artmalı (%d -> %d)." % [once, oyun.dunya.bolgeler[hedef].liman]
	return ""


func sina_dusmanin_tuttugu_gecitten_birlik_gecemez() -> String:
	var oyun: Oyun = _oyun()
	var karadeniz: String = _havza_bolgesi(oyun, "RUS", "Karadeniz")
	var hedef: String = _havza_bolgesi(oyun, "GRC", "Akdeniz")
	_savas(oyun, "RUS", "TUR")
	var yol: Array[String] = oyun._gecitleri_gozeterek_yol("RUS", karadeniz, hedef)
	if yol.has("TUR_2"):
		return "Türkiye ile savaşan Rusya'nın birlikleri İstanbul'dan geçmemeli: %s" % [yol]
	return ""


func sina_ticaret_kayitta_korunur() -> String:
	var oyun: Oyun = _oyun()
	var t: Ticaret = oyun.ticaret
	t.ambargo_uygula(oyun, "TUR", "GRC")
	oyun.dunya.bolgeler["TUR_2"].liman = 1
	var sayi: int = t.anlasmalar.size()
	var yeni: Oyun = _oyun()
	yeni.kayittan_yukle(JSON.parse_string(JSON.stringify(oyun.kaydet_icin_veri())))
	if yeni.ticaret.anlasmalar.size() != sayi or not yeni.ticaret.ambargo_uyguluyor_mu("TUR", "GRC") \
			or yeni.dunya.bolgeler["TUR_2"].liman != 1:
		return "Anlaşmalar, ambargolar ve limanlar kayıtta korunmalı."
	var eski: Dictionary = oyun.kaydet_icin_veri()
	eski.erase("ticaret")
	var eskiden: Oyun = _oyun()
	eskiden.kayittan_yukle(eski)
	if eskiden.ticaret.anlasmalar.is_empty():
		return "Ticareti olmayan eski kayıtta başlangıç anlaşmaları kalmalı."
	return ""
