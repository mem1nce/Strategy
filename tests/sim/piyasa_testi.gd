extends RefCounted
## Petrol ve maden piyasası (bkz. Piyasa): başlangıç arzı, ihracat/ithalat, fiyat sınırları,
## muharebe ve işgalin üretimi düşürmesi, erişimsiz ülkenin açığı, maden açığının inşaatı
## yavaşlatması, savaşın petrol fiyatını yükseltmesi ve kayıt.


func _oyun() -> Oyun:
	return Oyun.new(Dunya.yukle())


func _petrol_talebi(oyun: Oyun) -> float:
	var talep: float = 0.0
	var sanayiler: Dictionary[String, float] = Piyasa._ham_sanayiler(oyun, 0)
	var zirhlilar: Dictionary[String, int] = {}
	for birlik: Birlik in oyun.birlikler:
		if birlik.tur == "zirhli":
			zirhlilar[birlik.sahip] = zirhlilar.get(birlik.sahip, 0) + 1
	for ulke_id: String in sanayiler:
		talep += oyun.ekonomi.piyasa.ulke_talebi(oyun, ulke_id, "petrol", sanayiler[ulke_id], zirhlilar.get(ulke_id, 0))
	return talep


func sina_baslangicta_petrol_arzi_talebin_yuzde_105i() -> String:
	var oyun: Oyun = _oyun()
	var arz: float = 0.0
	for bolge_id: String in oyun.ekonomi.piyasa.bolge_uretimi["petrol"]:
		arz += float(oyun.ekonomi.piyasa.bolge_uretimi["petrol"][bolge_id])
	var oran: float = arz / _petrol_talebi(oyun)
	if absf(oran - 1.05) > 0.01:
		return "Başlangıçta dünya petrol üretimi talebin ~%%105'i olmalı (%%%.1f)." % (oran * 100.0)
	return ""


func sina_fazlasi_olan_satar_acigi_olan_alir() -> String:
	var oyun: Oyun = _oyun()
	oyun.gun_basladi(24)
	var suudi: Dictionary = oyun.ekonomi.kalemler["SAU"]
	var japonya: Dictionary = oyun.ekonomi.kalemler["JPN"]
	if not float(suudi["ihracat"]) > 0.0:
		return "Petrol fazlası olan Suudi Arabistan ihracat geliri almalı."
	if not float(japonya["ithalat"]) > 0.0:
		return "Petrolü olmayan Japonya ithalat gideri ödemeli."
	return ""


func sina_fiyat_sinirlar_icinde_kalir() -> String:
	var oyun: Oyun = _oyun()
	var piyasa: Piyasa = oyun.ekonomi.piyasa
	# Bütün üretimi sil: talep/arz oranı çok büyür, fiyat tavana dayanmalı.
	for bolge_id: String in piyasa.bolge_uretimi["petrol"]:
		piyasa.bolge_uretimi["petrol"][bolge_id] = 0.0001
	for gun: int in range(1, 200):
		oyun.gun_basladi(gun * 24)
	if not is_equal_approx(piyasa.fiyatlar["petrol"], piyasa.taban_fiyat["petrol"] * piyasa.fiyat_ust_kati):
		return "Fiyat taban fiyatın en çok 3 katına çıkmalı (%.2f)." % piyasa.fiyatlar["petrol"]
	return ""


func sina_muharebe_ve_isgal_uretimi_dusurur() -> String:
	var oyun: Oyun = _oyun()
	var piyasa: Piyasa = oyun.ekonomi.piyasa
	var bolge: Bolge = oyun.dunya.bolgeler["IRQ_2"]
	var tam: float = piyasa.bolgenin_uretimi(oyun, bolge, "petrol", 0)
	oyun._onceki_cekismeliler[bolge.id] = true
	var muharebede: float = piyasa.bolgenin_uretimi(oyun, bolge, "petrol", 0)
	oyun._onceki_cekismeliler.erase(bolge.id)
	oyun._bolgeyi_devret(bolge, "IRN", 0)
	var isgalde: float = piyasa.bolgenin_uretimi(oyun, bolge, "petrol", 24)
	if not (tam > 0.0 and muharebede < tam and isgalde < tam):
		return "Muharebe ve yeni işgal üretimi düşürmeli (%.2f / %.2f / %.2f)." % [tam, muharebede, isgalde]
	return ""


func sina_erisimi_olmayan_ulkenin_acigi_kalir() -> String:
	var oyun: Oyun = _oyun()
	var ulke_id: String = "AFG"  # Kıyısı yok.
	for bolge: Bolge in oyun.dunya.ulkenin_bolgeleri(ulke_id):
		for komsu_id: String in bolge.kara_komsulari:
			var komsu: String = oyun.dunya.bolgeler[komsu_id].sahip
			if komsu != ulke_id:
				oyun._savaslar[oyun._savas_anahtari(ulke_id, komsu)] = 0
	oyun._savas_dizinini_kur()
	if oyun.ekonomi.piyasa.piyasaya_erisebilir_mi(oyun, ulke_id):
		return "Bütün kıyılı komşularıyla savaştaki kara ülkesinin piyasaya erişimi olmamalı."
	oyun.gun_basladi(24)
	if not oyun.ekonomi.piyasa.acik_orani(ulke_id, "petrol") > 0.0 or not oyun.ekonomi.piyasa.sanayi_carpani(ulke_id) < 1.0:
		return "Erişimi olmayan ülkenin petrol açığı kalmalı ve sanayi geliri düşmeli."
	if not oyun.ekonomi.piyasa.piyasaya_erisebilir_mi(oyun, "TUR"):
		return "Kıyı ülkesinin piyasaya erişimi olmalı."
	return ""


func sina_maden_acigi_insaati_yavaslatir() -> String:
	var oyun: Oyun = _oyun()
	oyun.ekonomi.piyasa.durum["TUR"] = {"maden": {"acik_orani": 0.5}}
	oyun.hazineler["TUR"] = 10000.0
	oyun.tumen_sirala("TUR", "TUR_1")
	var is_: InsaIsi = oyun.onde_ki_is("TUR")
	var once: int = is_.kalan_saat
	for saat: int in range(1, 11):
		oyun._insa_islerini_isle()
	if once - is_.kalan_saat != 5:
		return "Yarı açıkta inşaat yarı hızda ilerlemeli (10 saatte %d)." % (once - is_.kalan_saat)
	return ""


func sina_iran_suudi_savasi_petrol_fiyatini_yukseltir() -> String:
	var oyun: Oyun = _oyun()
	var piyasa: Piyasa = oyun.ekonomi.piyasa
	oyun._savaslar[oyun._savas_anahtari("IRN", "SAU")] = 0
	oyun._savas_dizinini_kur()
	# Savaşta iki tarafın büyük petrol bölgeleri karşılıklı ele geçirildi (yeni işgal).
	var suudi_petrolu: String = _en_cok_ureten(oyun, "SAU")
	var iran_petrolu: String = _en_cok_ureten(oyun, "IRN")
	oyun._bolgeyi_devret(oyun.dunya.bolgeler[suudi_petrolu], "IRN", 0)
	oyun._bolgeyi_devret(oyun.dunya.bolgeler[iran_petrolu], "SAU", 0)
	var bas: float = piyasa.fiyatlar["petrol"]
	for gun: int in range(1, 31):
		oyun.gun_basladi(gun * 24)
	var son: float = piyasa.fiyatlar["petrol"]
	if son < bas * 1.25:
		return "İran-Suudi savaşında 30 günde petrol fiyatı belirgin yükselmeli (%.2f -> %.2f)." % [bas, son]
	return ""


func _en_cok_ureten(oyun: Oyun, ulke_id: String) -> String:
	var secilen: String = ""
	var en_cok: float = 0.0
	var tablo: Dictionary = oyun.ekonomi.piyasa.bolge_uretimi["petrol"]
	for bolge: Bolge in oyun.dunya.ulkenin_bolgeleri(ulke_id):
		if float(tablo.get(bolge.id, 0.0)) > en_cok:
			en_cok = float(tablo[bolge.id])
			secilen = bolge.id
	return secilen


func sina_fiyatlar_kayitta_korunur() -> String:
	var oyun: Oyun = _oyun()
	oyun.ekonomi.piyasa.fiyatlar["petrol"] = 2.25
	oyun.gun_basladi(24)
	var fiyat: float = oyun.ekonomi.piyasa.fiyatlar["petrol"]
	var yeni: Oyun = _oyun()
	yeni.kayittan_yukle(JSON.parse_string(JSON.stringify(oyun.kaydet_icin_veri())))
	if not is_equal_approx(yeni.ekonomi.piyasa.fiyatlar["petrol"], fiyat) \
			or not is_equal_approx(yeni.ekonomi.piyasa.acik_orani("JPN", "petrol"), oyun.ekonomi.piyasa.acik_orani("JPN", "petrol")):
		return "Dünya fiyatları ve ülkelerin kaynak durumu kayıtta korunmalı."
	return ""
