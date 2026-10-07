extends RefCounted
## Ülke bonuslarını sınar: veri dosyasının kurallara uyması ve her bonus türünün etkisi.
## Etki sınamaları Türkiye'ye geçici olarak istenen bonusu verir, bonussuz durumla karşılaştırır
## ve sonunda gerçek bonusu geri koyar.

const ULKE: String = "TUR"
const DEGER: float = 0.15


func _bonus_ver(tur: String) -> Dictionary:
	UlkeBonuslari.bonus(ULKE)  # Veri yüklensin.
	var eski: Dictionary = UlkeBonuslari._ulkeler.get(ULKE, {})
	if tur == "":
		UlkeBonuslari._ulkeler[ULKE] = {}
	else:
		UlkeBonuslari._ulkeler[ULKE] = {"ad": "Sınama", "tur": tur, "deger": DEGER}
	return eski


func _geri_koy(eski: Dictionary) -> void:
	UlkeBonuslari._ulkeler[ULKE] = eski


func _kurulu_oyun() -> Oyun:
	var oyun: Oyun = Oyun.new(Dunya.yukle())
	oyun.oyuncuyu_sec(ULKE)
	return oyun


func _birlik(sahip: String, guc: float, bolge_id: String) -> Birlik:
	var birlik: Birlik = Birlik.new()
	birlik.sahip = sahip
	birlik.guc = guc
	birlik.bolge_id = bolge_id
	return birlik


func sina_her_ulkenin_tek_kucuk_bonusu_var() -> String:
	var dunya: Dunya = Dunya.yukle()
	for ulke: Ulke in dunya.ulke_listesi:
		var b: Dictionary = UlkeBonuslari.bonus(ulke.id)
		if b.is_empty():
			return "%s ülkesinin bonusu yok." % ulke.id
		if not UlkeBonuslari.TURLER.has(str(b["tur"])):
			return "%s ülkesinin bonus türü bilinmiyor: %s" % [ulke.id, b["tur"]]
		if float(b["deger"]) <= 0.0 or float(b["deger"]) > 0.15:
			return "%s ülkesinin bonusu %%15'i geçmemeli (%.2f)." % [ulke.id, b["deger"]]
		if UlkeBonuslari.metin(ulke.id) == "":
			return "%s ülkesinin bonus satırı boş." % ulke.id
	return ""


func sina_en_buyuk_yirmi_ulkenin_ozel_bonusu_var() -> String:
	var dunya: Dunya = Dunya.yukle()
	var ulkeler: Array[Ulke] = dunya.ulke_listesi.duplicate()
	ulkeler.sort_custom(func(a: Ulke, b: Ulke) -> bool: return a.gsyh_milyon_dolar > b.gsyh_milyon_dolar)
	var genel: Array[String] = ["Kıyı ülkesi", "Güçlü ekonomi", "Geniş topraklar", "Kalabalık nüfus"]
	for i: int in 20:
		var ad: String = str(UlkeBonuslari.bonus(ulkeler[i].id).get("ad", ""))
		if genel.has(ad):
			return "En büyük 20 ülkeden %s genel değil özel bir bonus almalı (%s)." % [ulkeler[i].id, ad]
	return ""


func sina_gelir_bonusu() -> String:
	var eski: Dictionary = _bonus_ver("")
	var oyun: Oyun = _kurulu_oyun()
	var taban: float = oyun.ulkenin_geliri(ULKE, 0)
	_bonus_ver("gelir")
	var bonuslu: float = oyun.ulkenin_geliri(ULKE, 0)
	_geri_koy(eski)
	if not is_equal_approx(bonuslu, taban * (1.0 + DEGER)):
		return "Gelir bonusu geliri %%15 artırmalı (%.2f -> %.2f)." % [taban, bonuslu]
	return ""


func sina_fabrika_indirimi() -> String:
	var eski: Dictionary = _bonus_ver("fabrika_indirimi")
	var oyun: Oyun = _kurulu_oyun()
	oyun.hazineler[ULKE] = 1000.0
	var beklenen: float = oyun.fabrika_maliyeti() * (1.0 - DEGER)
	var kabul: bool = oyun.fabrika_sirala(ULKE, "TUR_1")
	var harcanan: float = 1000.0 - oyun.hazineler[ULKE]
	_geri_koy(eski)
	if not kabul or not is_equal_approx(harcanan, beklenen):
		return "Fabrika indirimi maliyeti %%15 düşürmeli (harcanan %.1f, beklenen %.1f)." % [harcanan, beklenen]
	return ""


func sina_piyade_indirimi() -> String:
	var eski: Dictionary = _bonus_ver("piyade_indirimi")
	var oyun: Oyun = _kurulu_oyun()
	var piyade: float = oyun.tumen_maliyeti("piyade", ULKE)
	var zirhli: float = oyun.tumen_maliyeti("zirhli", ULKE)
	_geri_koy(eski)
	if not is_equal_approx(piyade, BirlikTurleri.maliyet("piyade") * (1.0 - DEGER)):
		return "Piyade indirimi piyadeyi %%15 ucuzlatmalı (%.1f)." % piyade
	if not is_equal_approx(zirhli, BirlikTurleri.maliyet("zirhli")):
		return "Piyade indirimi zırhlının fiyatını değiştirmemeli."
	return ""


func sina_deniz_saldirisi_bonusu() -> String:
	var eski: Dictionary = _bonus_ver("")
	var oyun: Oyun = _kurulu_oyun()
	var bolge: Bolge = oyun.dunya.bolgeler["GRC_1"]
	var saldiran: Birlik = _birlik(ULKE, 100.0, "GRC_1")
	saldiran.son_adim_deniz_mi = true
	var savunan: Array[Birlik] = [_birlik("GRC", 100.0, "GRC_1")]
	var taban: float = oyun._verilen_hasar([saldiran], savunan, true, bolge)
	_bonus_ver("deniz_saldirisi")
	var bonuslu: float = oyun._verilen_hasar([saldiran], savunan, true, bolge)
	_geri_koy(eski)
	if not is_equal_approx(bonuslu - taban, 100.0 * DEGER):
		return "Deniz bonusu denizden saldırı cezasını 0,15 hafifletmeli (%.1f -> %.1f)." % [taban, bonuslu]
	return ""


func sina_kendi_toprak_savunmasi() -> String:
	var eski: Dictionary = _bonus_ver("")
	var oyun: Oyun = _kurulu_oyun()
	var kendi: Bolge = oyun.dunya.bolgeler["TUR_1"]
	var savunan: Array[Birlik] = [_birlik(ULKE, 100.0, "TUR_1")]
	var saldiran: Array[Birlik] = [_birlik("GRC", 100.0, "TUR_1")]
	var taban: float = oyun._verilen_hasar(savunan, saldiran, false, kendi)
	_bonus_ver("kendi_toprak_savunmasi")
	var bonuslu: float = oyun._verilen_hasar(savunan, saldiran, false, kendi)
	# Ele geçirilmiş yabancı bölgede bonus yok.
	var yabanci: Bolge = oyun.dunya.bolgeler["GRC_1"]
	yabanci.sahip = ULKE
	var yabanci_taban: float = oyun._verilen_hasar(savunan, saldiran, false, yabanci)
	_bonus_ver("")
	var yabanci_bonussuz: float = oyun._verilen_hasar(savunan, saldiran, false, yabanci)
	_geri_koy(eski)
	if not is_equal_approx(bonuslu, taban * (1.0 + DEGER)):
		return "Kendi toprağında savunma bonusu hasarı %%15 artırmalı (%.1f -> %.1f)." % [taban, bonuslu]
	if not is_equal_approx(yabanci_taban, yabanci_bonussuz):
		return "Bonus ele geçirilmiş yabancı bölgede işlememeli."
	return ""


func sina_arastirma_hizi() -> String:
	var eski: Dictionary = _bonus_ver("arastirma_hizi")
	var oyun: Oyun = _kurulu_oyun()
	oyun.hazineler[ULKE] = 1000.0
	oyun.arastirma_baslat(ULKE, "silah")
	var sure: int = int(oyun.suren_arastirma(ULKE).get("toplam_saat", 0))
	_geri_koy(eski)
	if sure != roundi(Teknoloji.sure_saat(1) * (1.0 - DEGER)):
		return "Araştırma bonusu süreyi %%15 kısaltmalı (%d saat)." % sure
	return ""


func sina_hareket_hizi() -> String:
	var varislar: Array[int] = []
	for tur: String in ["", "hareket_hizi"]:
		var eski: Dictionary = _bonus_ver(tur)
		var oyun: Oyun = _kurulu_oyun()
		var birlik: Birlik = _birlik(ULKE, 100.0, "TUR_1")
		oyun.birlikler.append(birlik)
		oyun.birlikleri_yurut([birlik], oyun.dunya.bolgeler["TUR_1"].kara_komsulari[0], 0)
		varislar.append(birlik.varis_saati)
		_geri_koy(eski)
	if not varislar[1] < varislar[0]:
		return "Hareket bonusu yürüyüşü kısaltmalı (%d / %d saat)." % [varislar[1], varislar[0]]
	return ""


func sina_bakim_indirimi() -> String:
	var harcananlar: Array[float] = []
	for tur: String in ["", "bakim_indirimi"]:
		var eski: Dictionary = _bonus_ver(tur)
		var oyun: Oyun = _kurulu_oyun()
		oyun.hazineler[ULKE] = 1000.0
		oyun._bakimi_uygula()
		harcananlar.append(1000.0 - oyun.hazineler[ULKE])
		_geri_koy(eski)
	if not is_equal_approx(harcananlar[1], harcananlar[0] * (1.0 - DEGER)):
		return "Bakım bonusu bakımı %%15 düşürmeli (%.2f -> %.2f)." % harcananlar
	return ""


func sina_yapay_zeka_bonusundan_yararlanir() -> String:
	# Yapay zekânın fabrika kararı, ülkenin indirimli fiyatına bakar.
	var eski: Dictionary = _bonus_ver("fabrika_indirimi")
	var oyun: Oyun = Oyun.new(Dunya.yukle())
	oyun._yz_fabrika_olasiligi = 1.0
	oyun.hazineler[ULKE] = oyun.fabrika_maliyeti(ULKE) + 1.0
	oyun._baristaki_ulke_dusun(ULKE, 0)
	var kuyruk: Array = oyun.insa_kuyruklari.get(ULKE, [])
	_geri_koy(eski)
	if kuyruk.is_empty() or (kuyruk[0] as InsaIsi).tur != InsaIsi.Tur.FABRIKA:
		return "Yapay zekâ indirimli fabrikayı karşılayabildiğinde kurmalı."
	return ""
