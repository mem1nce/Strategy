extends RefCounted
## Oyun._yapay_zekayi_isle()/_ulke_dusun()'ü (YZ'nin günlük tümen/fabrika kurması) sınar.


func _kurulu_oyun() -> Oyun:
	var dunya: Dunya = Dunya.yukle()
	return Oyun.new(dunya)


func sina_dusunme_saatleri_0_23_arasinda_ve_tutarli() -> String:
	var oyun: Oyun = _kurulu_oyun()
	for ulke: Ulke in oyun.dunya.ulke_listesi:
		var saat: int = oyun._ulkenin_dusunme_saati(ulke.id)
		if saat < 0 or saat > 23:
			return "%s'in düşünme saati 0-23 arasında olmalı, geldi: %d" % [ulke.id, saat]
		if oyun._ulkenin_dusunme_saati(ulke.id) != saat:
			return "Aynı ülke için düşünme saati her çağrıda aynı olmalı (deterministik)."
	return ""


func sina_oyuncu_dusunmez() -> String:
	var oyun: Oyun = _kurulu_oyun()
	oyun.oyuncuyu_sec("TUR")
	oyun.hazineler["TUR"] = 100000.0
	var dusunme_saati: int = oyun._ulkenin_dusunme_saati("TUR")

	oyun._yapay_zekayi_isle(dusunme_saati)
	if not (oyun.insa_kuyruklari.get("TUR", []) as Array).is_empty():
		return "Oyuncunun ülkesi için YZ karar vermemeli (oyuncu kendi kontrol eder)."
	return ""


func sina_yz_oyuncuyu_yonetsin_aciksa_oyuncu_da_dusunur() -> String:
	var oyun: Oyun = _kurulu_oyun()
	oyun.oyuncuyu_sec("TUR")
	oyun.yz_oyuncuyu_yonetsin = true
	oyun.hazineler["TUR"] = 100000.0
	var dusunme_saati: int = oyun._ulkenin_dusunme_saati("TUR")

	oyun._yapay_zekayi_isle(dusunme_saati)
	if (oyun.insa_kuyruklari.get("TUR", []) as Array).is_empty():
		return "'Ordumu yapay zekâ yönetsin' açıkken oyuncu için de karar verilmeli."
	return ""


func sina_sirasi_gelmeyen_ulke_dusunmez() -> String:
	var oyun: Oyun = _kurulu_oyun()
	var ulke: Ulke = oyun.dunya.ulke_listesi[0]
	if ulke.id == "TUR":
		ulke = oyun.dunya.ulke_listesi[1]
	oyun.hazineler[ulke.id] = 100000.0
	var dusunme_saati: int = oyun._ulkenin_dusunme_saati(ulke.id)
	var baska_saat: int = (dusunme_saati + 12) % 24

	oyun._yapay_zekayi_isle(baska_saat)
	if not (oyun.insa_kuyruklari.get(ulke.id, []) as Array).is_empty():
		return "Sırası gelmeyen saatte %s karar vermemeli." % ulke.id
	return ""


func sina_zengin_ulke_sirasi_gelince_tumen_veya_fabrika_kurar() -> String:
	var oyun: Oyun = _kurulu_oyun()
	var ulke: Ulke = oyun.dunya.ulke_listesi[0]
	if ulke.id == "TUR":
		ulke = oyun.dunya.ulke_listesi[1]
	oyun.hazineler[ulke.id] = 100000.0
	var dusunme_saati: int = oyun._ulkenin_dusunme_saati(ulke.id)

	oyun._yapay_zekayi_isle(dusunme_saati)
	var kuyruk: Array = oyun.insa_kuyruklari.get(ulke.id, [])
	if kuyruk.is_empty():
		return "Zengin bir ülke, sırası gelince kuyruğa bir iş eklemeli."
	var is_: InsaIsi = kuyruk[0]
	if is_.sahip != ulke.id:
		return "Sıralanan işin sahibi doğru ülke olmalı."
	return ""


func sina_fakir_ulke_sirasi_gelince_hicbir_sey_kurmaz() -> String:
	var oyun: Oyun = _kurulu_oyun()
	var ulke: Ulke = oyun.dunya.ulke_listesi[0]
	if ulke.id == "TUR":
		ulke = oyun.dunya.ulke_listesi[1]
	oyun.hazineler[ulke.id] = 0.0
	var dusunme_saati: int = oyun._ulkenin_dusunme_saati(ulke.id)

	oyun._yapay_zekayi_isle(dusunme_saati)
	if not (oyun.insa_kuyruklari.get(ulke.id, []) as Array).is_empty():
		return "Hazinesi olmayan ülke hiçbir şey kurmamalı."
	return ""


func sina_savastaki_ulke_simdilik_hicbir_sey_kurmaz() -> String:
	var oyun: Oyun = _kurulu_oyun()
	var komsu: String = ""
	for ulke: Ulke in oyun.dunya.ulke_listesi:
		if ulke.id != "TUR" and oyun.dunya.ulkeler_komsu_mu("TUR", ulke.id):
			komsu = ulke.id
			break
	if komsu == "" or not oyun.savas_ilan_et("TUR", komsu, 0):
		return "Sınama kurulamadı (komşu yok ya da ilan başarısız)."
	oyun.hazineler[komsu] = 100000.0
	var dusunme_saati: int = oyun._ulkenin_dusunme_saati(komsu)

	oyun._yapay_zekayi_isle(dusunme_saati)
	if not (oyun.insa_kuyruklari.get(komsu, []) as Array).is_empty():
		return "Savaştaki ülke (barış davranışı uygulanmamalı) şimdilik hiçbir şey kurmamalı."
	return ""


func sina_teslim_olmus_ulke_dusunmez() -> String:
	var oyun: Oyun = _kurulu_oyun()
	var ulke: Ulke = oyun.dunya.ulke_listesi[0]
	if ulke.id == "TUR":
		ulke = oyun.dunya.ulke_listesi[1]
	for bolge: Bolge in oyun.dunya.ulkenin_bolgeleri(ulke.id):
		bolge.sahip = "TUR"
	oyun.hazineler[ulke.id] = 100000.0
	var dusunme_saati: int = oyun._ulkenin_dusunme_saati(ulke.id)

	oyun._yapay_zekayi_isle(dusunme_saati)  # Hata fırlatmamalı; kuyruk boş kalmalı.
	if not (oyun.insa_kuyruklari.get(ulke.id, []) as Array).is_empty():
		return "Hiç bölgesi kalmamış (teslim olmuş) ülke karar vermemeli."
	return ""
