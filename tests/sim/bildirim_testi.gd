extends RefCounted
## Oyun.bildirim_gonder sinyalini sınar: sana savaş ilanı, bölge kaybı/kazancı, üretim
## bitti olaylarında oyuncuya (yalnızca oyuncuyla ilgiliyse) doğru metin ve bölge
## id'siyle yayılır.


func _kurulu_oyun() -> Oyun:
	var dunya: Dunya = Dunya.yukle()
	var oyun: Oyun = Oyun.new(dunya)
	oyun.oyuncuyu_sec("TUR")
	return oyun


## TUR'un kara ya da deniz yoluyla doğrudan komşusu olan bir ülke döner.
func _komsu_ulke(dunya: Dunya) -> String:
	for ulke: Ulke in dunya.ulke_listesi:
		if ulke.id != "TUR" and dunya.ulkeler_komsu_mu("TUR", ulke.id):
			return ulke.id
	return ""


func sina_dusman_savas_ilan_edince_bildirim_gelir() -> String:
	var oyun: Oyun = _kurulu_oyun()
	var komsu: String = _komsu_ulke(oyun.dunya)
	if komsu == "":
		return "Sınama kurulamadı: komşu yok."
	var gelen: Array = []
	oyun.bildirim_gonder.connect(func(metin: String, bolge_id: String) -> void:
		gelen.append([metin, bolge_id]))

	if not oyun.savas_ilan_et(komsu, "TUR", 0):
		return "Sınama kurulamadı: ilan kabul edilmedi."
	if gelen.is_empty():
		return "Düşman oyuncuya savaş ilan edince bildirim gelmeli."
	if gelen[0][1] != oyun.dunya.ulkeler[komsu].baskent_bolgesi:
		return "Bildirimin bölge id'si ilan edenin başkenti olmalı."
	return ""


func sina_oyuncu_savas_ilan_edince_bildirim_gelmez() -> String:
	var oyun: Oyun = _kurulu_oyun()
	var komsu: String = _komsu_ulke(oyun.dunya)
	if komsu == "":
		return "Sınama kurulamadı: komşu yok."
	var gelen: Array = []
	oyun.bildirim_gonder.connect(func(metin: String, bolge_id: String) -> void:
		gelen.append([metin, bolge_id]))

	if not oyun.savas_ilan_et("TUR", komsu, 0):
		return "Sınama kurulamadı: ilan kabul edilmedi."
	if not gelen.is_empty():
		return "Oyuncu kendisi ilan edince kendine bildirim gelmemeli."
	return ""


func sina_oyuncu_bolge_kazaninca_bildirim_gelir() -> String:
	var oyun: Oyun = _kurulu_oyun()
	var bolge: Bolge = oyun.dunya.bolgeler["FRA_1"]
	var gelen: Array = []
	oyun.bildirim_gonder.connect(func(metin: String, bolge_id: String) -> void:
		gelen.append([metin, bolge_id]))

	oyun._bolgeyi_devret(bolge, "TUR", 0)
	if gelen.is_empty():
		return "Oyuncu bölge kazanınca bildirim gelmeli."
	if gelen[0][1] != "FRA_1":
		return "Bildirimin bölge id'si doğru olmalı."
	return ""


func sina_oyuncu_bolge_kaybedince_bildirim_gelir() -> String:
	var oyun: Oyun = _kurulu_oyun()
	var bolge: Bolge = oyun.dunya.bolgeler["TUR_1"]
	var gelen: Array = []
	oyun.bildirim_gonder.connect(func(metin: String, bolge_id: String) -> void:
		gelen.append([metin, bolge_id]))

	oyun._bolgeyi_devret(bolge, "FRA", 0)
	if gelen.is_empty():
		return "Oyuncu bölge kaybedince bildirim gelmeli."
	if gelen[0][1] != "TUR_1":
		return "Bildirimin bölge id'si doğru olmalı."
	return ""


func sina_baskasinin_bolge_degisikliginde_bildirim_gelmez() -> String:
	var oyun: Oyun = _kurulu_oyun()
	var bolge: Bolge = oyun.dunya.bolgeler["FRA_1"]
	var gelen: Array = []
	oyun.bildirim_gonder.connect(func(metin: String, bolge_id: String) -> void:
		gelen.append([metin, bolge_id]))

	oyun._bolgeyi_devret(bolge, "DEU", 0)
	if not gelen.is_empty():
		return "Oyuncuyla ilgisi olmayan bir devirde bildirim gelmemeli."
	return ""


func sina_oyuncu_uretimi_tamamlaninca_bildirim_gelir() -> String:
	var oyun: Oyun = _kurulu_oyun()
	# Savaş ilanı rastgeleliği bu sınamayla alakasız; kapatılmazsa saat_ilerledi
	# döngüsünde bir YZ ülkesi şans eseri TUR'a savaş ilan edip beklenmedik bir
	# bildirim üretebilir (bkz. yapay_zeka_testi.gd'deki aynı sınıf kırılganlık).
	oyun._yz_savas_ilani_olasiligi = 0.0
	oyun.hazineler["TUR"] = 1000.0
	if not oyun.tumen_sirala("TUR", "TUR_1"):
		return "Sınama kurulamadı: tümen sıralanamadı."

	for saat: int in oyun._tumen_suresi_saat - 1:
		oyun.saat_ilerledi(saat)
	var gelen: Array = []
	oyun.bildirim_gonder.connect(func(metin: String, bolge_id: String) -> void:
		gelen.append([metin, bolge_id]))
	oyun.saat_ilerledi(oyun._tumen_suresi_saat)

	if gelen.is_empty():
		return "Oyuncunun üretimi tamamlanınca bildirim gelmeli."
	if gelen[0][1] != "TUR_1":
		return "Bildirimin bölge id'si doğru olmalı."
	return ""
