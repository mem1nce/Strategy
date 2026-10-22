extends RefCounted
## Ekonomik olaylar (bkz. EkonomikOlaylar), savaş tazminatı ve teslim olanın hazinesinin
## başkentini alana geçmesi.


func _oyun() -> Oyun:
	return Oyun.new(Dunya.yukle())


## Verilen günler boyunca yalnızca olay zarını atar; başlayan olayları "gün:id" olarak döndürür.
func _olay_gecmisi(tohum: int, gun_sayisi: int) -> PackedStringArray:
	var oyun: Oyun = _oyun()
	oyun._rng.seed = tohum
	var sonuc: PackedStringArray = PackedStringArray()
	for gun: int in range(1, gun_sayisi + 1):
		var onceki: Dictionary = oyun.ekonomi.olaylar.suren
		oyun.ekonomi.olaylar.gunu_isle(oyun, gun * 24)
		var suren: Dictionary = oyun.ekonomi.olaylar.suren
		if not suren.is_empty() and suren != onceki:
			sonuc.append("%d:%s" % [gun, suren["id"]])
	return sonuc


func sina_olaylar_tohuma_bagli_ve_yilda_bir_kadar() -> String:
	var a: PackedStringArray = _olay_gecmisi(7, 3650)
	var b: PackedStringArray = _olay_gecmisi(7, 3650)
	if a != b:
		return "Aynı tohum aynı olayları üretmeli."
	if a.size() < 4 or a.size() > 16:
		return "10 yılda yaklaşık 10 olay beklenir: %d (%s)" % [a.size(), ", ".join(a)]
	if _olay_gecmisi(8, 3650) == a:
		return "Başka tohum başka olaylar üretmeli."
	return ""


## Petrol krizi dünya petrol üretimini düşürür: 30 günde fiyat krizsiz oyundakinden yüksek olur.
func sina_petrol_krizi_fiyati_yukseltir() -> String:
	var krizli: Oyun = _oyun()
	var krizsiz: Oyun = _oyun()
	for oyun: Oyun in [krizli, krizsiz]:
		oyun.ekonomi.olaylar.yillik_olay_sayisi = 0.0
	krizli.ekonomi.olaylar.baslat(krizli, "petrol_krizi", 0)
	for gun: int in range(1, 31):
		krizli.gun_basladi(gun * 24)
		krizsiz.gun_basladi(gun * 24)
	var p1: float = krizli.ekonomi.piyasa.fiyatlar["petrol"]
	var p0: float = krizsiz.ekonomi.piyasa.fiyatlar["petrol"]
	if p1 < p0 * 1.2:
		return "Petrol krizinde fiyat belirgin yükselmeli: %.2f / %.2f" % [p1, p0]
	return ""


## Küresel durgunluk ticaret gelirini düşürür, ticaret patlaması artırır.
func sina_durgunluk_ve_patlama_ticareti_degistirir() -> String:
	var degerler: Dictionary = {}
	for olay: String in ["", "kuresel_durgunluk", "ticaret_patlamasi"]:
		var oyun: Oyun = _oyun()
		oyun.ekonomi.olaylar.yillik_olay_sayisi = 0.0
		if olay != "":
			oyun.ekonomi.olaylar.baslat(oyun, olay, 0)
		oyun.gun_basladi(24)
		degerler[olay] = float(oyun.ekonomi.kalemler["TUR"]["ticaret"])
	if not (degerler["kuresel_durgunluk"] < degerler[""] * 0.8 and degerler["ticaret_patlamasi"] > degerler[""] * 1.2):
		return "Durgunluk ticareti düşürmeli, patlama artırmalı: %s" % str(degerler)
	return ""


## Geçit kazası bir geçidi 30 gün kapatır: rotalar o geçitten geçmez; süre bitince açılır.
func sina_gecit_kazasi_gecidi_kapatir() -> String:
	var oyun: Oyun = _oyun()
	var olaylar: EkonomikOlaylar = oyun.ekonomi.olaylar
	olaylar.yillik_olay_sayisi = 0.0
	if not olaylar.baslat(oyun, "gecit_kazasi", 24):
		return "Geçit kazası başlamalı."
	var gecit: String = olaylar.suren["gecit"]
	if not oyun.ticaret.kapali_gecitler.has(gecit):
		return "Kazadaki geçit kapanmalı."
	oyun.gun_basladi(48)
	for a: Dictionary in oyun.ticaret.anlasmalar:
		if ((a["rota"] as Dictionary).get("gecitler", []) as Array).has(gecit):
			return "Kapalı geçitten rota geçmemeli (%s-%s, %s)." % [a["a"], a["b"], gecit]
	oyun.gun_basladi(24 + 31 * 24)
	if oyun.ticaret.kapali_gecitler.has(gecit) or not olaylar.suren.is_empty():
		return "30 gün sonra geçit açılmalı ve olay bitmeli."
	return ""


## Barışta daha çok bölge kaybeden, günlük gelirinin %15'ini 180 gün öbür tarafa öder.
func sina_baris_tazminati() -> String:
	var oyun: Oyun = _oyun()
	oyun.ekonomi.olaylar.yillik_olay_sayisi = 0.0
	oyun._savaslar[oyun._savas_anahtari("TUR", "GRC")] = 0
	oyun._savas_dizinini_kur()
	var verilecek: Bolge = null
	for bolge: Bolge in oyun.dunya.ulkenin_bolgeleri("GRC"):
		if not bolge.baskent:
			verilecek = bolge
			break
	oyun._bolgeyi_devret(verilecek, "TUR", 0)
	if int(oyun.savas_kayiplari.get("GRC>TUR", 0)) != 1:
		return "Savaşta kaybedilen bölge sayılmalı."
	if not oyun.baris_teklif_et("TUR", "GRC", Oyun.BARIS_ESIGI_SAAT + 1):
		return "Uzun süren savaşta barış kabul edilmeli."
	if oyun.ekonomi.tazminatlar.size() != 1 or oyun.ekonomi.tazminatlar[0]["oduyen"] != "GRC":
		return "Daha çok kaybeden (GRC) tazminat ödemeli: %s" % str(oyun.ekonomi.tazminatlar)
	oyun.gun_basladi(Oyun.BARIS_ESIGI_SAAT + 24)
	var k_grc: Dictionary = oyun.ekonomi.kalemler["GRC"]
	var gelir: float = 0.0
	for kalem: String in ["sanayi", "ticaret", "ihracat", "gecis"]:
		gelir += float(k_grc.get(kalem, 0.0))
	var beklenen: float = 0.15 * gelir
	if not is_equal_approx(float(k_grc["tazminat_odeme"]), beklenen) \
			or not is_equal_approx(float(oyun.ekonomi.kalemler["TUR"]["tazminat"]), beklenen):
		return "Tazminat gelirin %%15'i olmalı: %.3f / %.3f" % [float(k_grc["tazminat_odeme"]), beklenen]
	oyun.gun_basladi(Oyun.BARIS_ESIGI_SAAT + 182 * 24)
	if not oyun.ekonomi.tazminatlar.is_empty():
		return "180 gün sonra tazminat bitmeli."
	return ""


## Teslim olan ülkenin artı hazinesi başkentini alana geçer.
func sina_teslim_olanin_hazinesi_baskenti_alana_gecer() -> String:
	var oyun: Oyun = _oyun()
	oyun._savaslar[oyun._savas_anahtari("TUR", "ARM")] = 0
	oyun._savas_dizinini_kur()
	oyun.hazineler["ARM"] = 500.0
	var once: float = oyun.hazineler["TUR"]
	var ermenistan: Ulke = oyun.dunya.ulkeler["ARM"]
	oyun._bolgeyi_devret(oyun.dunya.bolgeler[ermenistan.baskent_bolgesi], "TUR", 0)
	for bolge: Bolge in oyun.dunya.ulkenin_bolgeleri("ARM"):
		if oyun.dunya.ulkenin_bolge_sayisi("ARM") == 0:
			break
		oyun._bolgeyi_devret(bolge, "TUR", 0)
	if oyun.dunya.ulkenin_bolge_sayisi("ARM") != 0:
		return "Ermenistan teslim olmalı."
	if not is_equal_approx(oyun.hazineler["TUR"], once + 500.0) or oyun.hazineler["ARM"] != 0.0:
		return "Hazine başkenti alana geçmeli: %.1f -> %.1f" % [once, oyun.hazineler["TUR"]]
	return ""


func sina_olay_ve_tazminat_kayitta_korunur() -> String:
	var oyun: Oyun = _oyun()
	oyun.ekonomi.olaylar.baslat(oyun, "maden_bollugu", 0)
	oyun.ekonomi.tazminatlar.append({"oduyen": "GRC", "alan": "TUR", "bitis_saati": 999})
	oyun.savas_kayiplari["GRC>TUR"] = 3
	var veri: Dictionary = JSON.parse_string(JSON.stringify(oyun.kaydet_icin_veri()))
	var yeni: Oyun = _oyun()
	yeni.kayittan_yukle(veri)
	if yeni.ekonomi.olaylar.suren.get("id", "") != "maden_bollugu" or yeni.ekonomi.tazminatlar.size() != 1 \
			or int(yeni.savas_kayiplari.get("GRC>TUR", 0)) != 3:
		return "Olay, tazminat ve savaş kayıpları kayıtta korunmalı."
	return ""
