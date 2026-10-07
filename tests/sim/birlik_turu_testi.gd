extends RefCounted
## Birlik türlerini sınar: üstünlük üçgeni, karışık yığın, hareket hızı, başlangıç ordusu,
## türe göre üretim ve yapay zekânın tür seçimi.


func _kurulu_oyun() -> Oyun:
	return Oyun.new(Dunya.yukle())


func _birlik(sahip: String, tur: String, guc: float, bolge_id: String = "TUR_1") -> Birlik:
	var birlik: Birlik = Birlik.new()
	birlik.sahip = sahip
	birlik.tur = tur
	birlik.guc = guc
	birlik.bolge_id = bolge_id
	return birlik


## `tur` türündeki 100 güçlü bir saldırganın, `hedef_tur` türündeki 100 güçlü savunana
## verdiği hasar (savunan avantajı saldırganın hasarına uygulanmaz).
func _hasar(oyun: Oyun, tur: String, hedef_tur: String) -> float:
	var veren: Array[Birlik] = [_birlik("FRA", tur, 100.0)]
	var alan: Array[Birlik] = [_birlik("TUR", hedef_tur, 100.0)]
	return oyun._verilen_hasar(veren, alan, true, oyun.dunya.bolgeler["TUR_1"])


func sina_ustunluk_ucgeni_yuzde_elli_fazla_hasar_verir() -> String:
	var oyun: Oyun = _kurulu_oyun()
	var bonus: float = BirlikTurleri.ustunluk_bonusu()
	for tur: String in BirlikTurleri.SIRA:
		var yenilen: String = BirlikTurleri.yener(tur)
		var ustun: float = _hasar(oyun, tur, yenilen)
		var duz: float = _hasar(oyun, tur, tur)
		if not is_equal_approx(ustun, duz * (1.0 + bonus)):
			return "%s, %s karşısında %%%d fazla hasar vermeli (%.1f / %.1f)." % [
				tur, yenilen, roundi(bonus * 100.0), ustun, duz]
	return ""


func sina_ucgen_kapali_dongudur() -> String:
	# zırhlı > piyade > topçu > zırhlı
	if BirlikTurleri.yener("zirhli") != "piyade" or BirlikTurleri.yener("piyade") != "topcu" \
			or BirlikTurleri.yener("topcu") != "zirhli":
		return "Üstünlük üçgeni zırhlı>piyade>topçu>zırhlı olmalı."
	if BirlikTurleri.yenildigi("piyade") != "zirhli":
		return "yenildigi('piyade') zırhlı olmalı."
	return ""


func sina_karisik_yiginda_bonus_tur_payi_kadardir() -> String:
	var oyun: Oyun = _kurulu_oyun()
	var bolge: Bolge = oyun.dunya.bolgeler["TUR_1"]
	var veren: Array[Birlik] = [_birlik("FRA", "zirhli", 100.0)]
	# Karşı taraf yarı piyade yarı topçu: zırhlının bonusu yalnızca piyade payı (%50) kadar.
	var alan: Array[Birlik] = [_birlik("TUR", "piyade", 50.0), _birlik("TUR", "topcu", 50.0)]
	var hasar: float = oyun._verilen_hasar(veren, alan, true, bolge)
	var beklenen: float = 100.0 * BirlikTurleri.saldiri("zirhli") * (1.0 + BirlikTurleri.ustunluk_bonusu() * 0.5)
	if not is_equal_approx(hasar, beklenen):
		return "Karışık yığında bonus tür payıyla orantılı olmalı (%.2f / beklenen %.2f)." % [hasar, beklenen]
	return ""


func sina_karisik_yigin_tek_muharebede_cozulur() -> String:
	var oyun: Oyun = _kurulu_oyun()
	var bolge_id: String = "TUR_1"
	oyun.savas_ilan_et("TUR", "FRA", 0)
	for birlik: Birlik in oyun.bolgedeki_birlikler(bolge_id):
		birlik.guc = 30.0
	var saldiranlar: Array[Birlik] = [_birlik("FRA", "zirhli", 60.0), _birlik("FRA", "topcu", 60.0),
			_birlik("FRA", "piyade", 60.0)]
	oyun.birlikler.append_array(saldiranlar)
	var onceki: Array[float] = []
	for birlik: Birlik in saldiranlar:
		onceki.append(birlik.guc)
	oyun._muharebeleri_isle(0)
	for i: int in saldiranlar.size():
		if not saldiranlar[i].guc < onceki[i]:
			return "Karışık yığındaki her tümen aynı muharebede kayıp almalı (%s)." % saldiranlar[i].tur
	return ""


func sina_zirhli_hizli_piyade_ve_topcu_yavas_yurur() -> String:
	var oyun: Oyun = _kurulu_oyun()
	var hedef: String = oyun.dunya.bolgeler["TUR_1"].kara_komsulari[0]
	var piyade: Birlik = _birlik("TUR", "piyade", 100.0)
	var zirhli: Birlik = _birlik("TUR", "zirhli", 100.0)
	var karisik: Array[Birlik] = [_birlik("TUR", "zirhli", 100.0), _birlik("TUR", "topcu", 100.0)]
	oyun.birlikler.append_array([piyade, zirhli] + karisik)
	oyun.birlikleri_yurut([piyade], hedef, 0)
	oyun.birlikleri_yurut([zirhli], hedef, 0)
	oyun.birlikleri_yurut(karisik, hedef, 0)
	if not zirhli.varis_saati < piyade.varis_saati:
		return "Zırhlı piyadeden önce varmalı (%d / %d)." % [zirhli.varis_saati, piyade.varis_saati]
	if karisik[0].varis_saati < piyade.varis_saati:
		return "Karışık yığın en yavaş türünün (topçu) hızıyla yürümeli."
	return ""


func sina_zengin_ulkenin_agir_tumen_payi_yuksektir() -> String:
	var oyun: Oyun = _kurulu_oyun()
	var paylar: Dictionary[String, float] = {}
	for ulke_id: String in ["USA", "IND"]:
		var toplam: int = 0
		var agir: int = 0
		for birlik: Birlik in oyun.birlikler:
			if birlik.sahip == ulke_id:
				toplam += 1
				if birlik.tur != "piyade":
					agir += 1
		paylar[ulke_id] = float(agir) / maxf(float(toplam), 1.0)
	if not paylar["USA"] > paylar["IND"]:
		return "Zengin ülkenin (ABD) ağır tümen payı yoksul ülkeninkinden (Hindistan) yüksek olmalı: %s" % paylar
	return ""


func sina_tumen_turu_secilerek_uretilir() -> String:
	var oyun: Oyun = _kurulu_oyun()
	oyun.oyuncuyu_sec("TUR")
	oyun.hazineler["TUR"] = 1000.0
	if not oyun.tumen_sirala("TUR", "TUR_1", "zirhli"):
		return "Zırhlı tümen sıralanmalı."
	if oyun.hazineler["TUR"] != 1000.0 - BirlikTurleri.maliyet("zirhli"):
		return "Zırhlının maliyeti düşülmeli."
	if oyun.tumen_sirala("TUR", "TUR_1", "ucak"):
		return "Bilinmeyen tür sıralanmamalı."
	var once: int = oyun.birlikler.size()
	for saat: int in range(1, BirlikTurleri.sure_saat("zirhli") + 1):
		oyun._insa_islerini_isle()
	if oyun.birlikler.size() != once + 1 or oyun.birlikler[-1].tur != "zirhli":
		return "Süre dolunca zırhlı tümen doğmalı."
	return ""


func sina_zirhlinin_bakimi_piyadeden_yuksektir() -> String:
	if not BirlikTurleri.bakim("zirhli") > BirlikTurleri.bakim("piyade"):
		return "Zırhlının bakımı piyadeninkinden yüksek olmalı."
	if not BirlikTurleri.maliyet("zirhli") > BirlikTurleri.maliyet("topcu") \
			or not BirlikTurleri.maliyet("topcu") > BirlikTurleri.maliyet("piyade"):
		return "Fiyat sırası piyade < topçu < zırhlı olmalı."
	return ""


func sina_yz_pahali_tur_icin_para_biriktirir() -> String:
	var oyun: Oyun = _kurulu_oyun()
	var ulke_id: String = "DEU"
	oyun._yz_fabrika_olasiligi = 0.0
	oyun._yz_bekleyen_tur[ulke_id] = "zirhli"
	# Piyadeye yeter ama zırhlıya yetmez: hiçbir şey kurmamalı, kararını korumalı.
	oyun.hazineler[ulke_id] = BirlikTurleri.maliyet("piyade") + 1.0
	oyun._baristaki_ulke_dusun(ulke_id, 0)
	if oyun.kuyruktaki_is_sayisi(ulke_id) != 0 or oyun._yz_bekleyen_tur.get(ulke_id, "") != "zirhli":
		return "Parası yetmeyen yapay zekâ ucuz türe geçmemeli, zırhlı için beklemeli."
	oyun.hazineler[ulke_id] = BirlikTurleri.maliyet("zirhli") + 1.0
	oyun._baristaki_ulke_dusun(ulke_id, 0)
	var kuyruk: Array = oyun.insa_kuyruklari.get(ulke_id, [])
	if kuyruk.size() != 1 or (kuyruk[0] as InsaIsi).birlik_turu != "zirhli" or oyun._yz_bekleyen_tur.has(ulke_id):
		return "Para birikince bekleyen zırhlı sıralanmalı."
	return ""


func sina_yz_komsunun_cok_kullandigi_ture_karsi_tur_secer() -> String:
	var oyun: Oyun = _kurulu_oyun()
	var komsu: String = oyun.dunya.ulkeler["TUR"].komsular[0]
	# Komşunun bütün ordusu piyade: TUR, piyadeye üstün gelen zırhlıyı daha sık seçmeli.
	for birlik: Birlik in oyun.birlikler:
		if birlik.sahip == komsu:
			birlik.tur = "piyade"
	for ulke_id: String in oyun.dunya.ulkeler["TUR"].komsular:
		if ulke_id != komsu:
			for birlik: Birlik in oyun.birlikler:
				if birlik.sahip == ulke_id:
					birlik.tur = "piyade"
	oyun._ulke_birlik_bolgelerini_hesapla()
	var sayac: Dictionary[String, int] = {"piyade": 0, "zirhli": 0, "topcu": 0}
	for i: int in 3000:
		sayac[oyun._yz_tur_sec("TUR")] += 1
	var taban: float = float(oyun._yz_tur_agirliklari["zirhli"])
	var taban_toplam: float = 0.0
	for tur: String in oyun._yz_tur_agirliklari:
		taban_toplam += float(oyun._yz_tur_agirliklari[tur])
	if not float(sayac["zirhli"]) / 3000.0 > taban / taban_toplam + 0.05:
		return "Komşular piyadeyken zırhlı payı taban payının belirgin üstünde olmalı: %s" % sayac
	if sayac["piyade"] == 0 or sayac["topcu"] == 0:
		return "Yapay zekâ yine de karışık ordu kurmalı: %s" % sayac
	return ""
