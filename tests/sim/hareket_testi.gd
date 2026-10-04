extends RefCounted
## Oyun.birlikleri_yurut() ve saat_ilerledi()'nin hareket mantığını sınar.


func sina_kendi_topragina_yurur_ve_varir() -> String:
	var dunya: Dunya = Dunya.yukle()
	var oyun: Oyun = Oyun.new(dunya)
	var baskent: Bolge = dunya.bolgeler["TUR_1"]
	var hedef_id: String = ""
	for komsu_id: String in baskent.kara_komsulari:
		if dunya.bolgeler[komsu_id].sahip == "TUR":
			hedef_id = komsu_id
			break
	if hedef_id == "":
		return "TUR_1'in TUR'a ait bir kara komşusu yok, sınama kurulamadı."

	# Hedef bölge kendi garnizonuyla başlıyor olabilir; taşınan tümenler nesne
	# kimliğiyle izlenir, "hedef boş muydu" gibi bir varsayım yapılmaz.
	var tasinanlar: Array[Birlik] = oyun.bolgedeki_birlikler("TUR_1").duplicate()
	if tasinanlar.is_empty():
		return "TUR_1'de tümen yok, sınama kurulamadı."
	if not oyun.birlikleri_yurut("TUR_1", hedef_id, 0):
		return "Kendi toprağına yürütme kabul edilmeliydi."
	for birlik: Birlik in tasinanlar:
		if not birlik.yuruyor_mu() or birlik.hedef_bolge_id != hedef_id:
			return "TUR_1'den taşınan tümenler yürüyor olmalı, hedefi %s." % hedef_id

	var sure: float = dunya.yol_bulucu.en_kisa_sure("TUR_1", hedef_id)
	oyun.saat_ilerledi(int(sure) - 1)
	for birlik: Birlik in tasinanlar:
		if birlik.bolge_id != "TUR_1" or not birlik.yuruyor_mu():
			return "Süre dolmadan taşınan tümenler hâlâ TUR_1'de ve yürüyor olmalı."

	oyun.saat_ilerledi(int(sure) + 2)
	for birlik: Birlik in tasinanlar:
		if birlik.bolge_id != hedef_id or birlik.yuruyor_mu():
			return "Süre dolunca taşınan tümenler hedefe varmış ve durağan olmalı."
	return ""


## Sınırda (yabancı kara komşusu olan ve tümeni bulunan) herhangi bir bölge bulur.
func _sinirda_tumenli_bolge(dunya: Dunya, oyun: Oyun) -> Array:
	for bolge: Bolge in dunya.bolge_listesi:
		if oyun.bolgedeki_birlikler(bolge.id).is_empty():
			continue
		for komsu_id: String in bolge.kara_komsulari:
			if dunya.bolgeler[komsu_id].sahip != bolge.sahip:
				return [bolge.id, komsu_id]
	return ["", ""]


func sina_dusman_topragina_yurutme_reddedilir() -> String:
	var dunya: Dunya = Dunya.yukle()
	var oyun: Oyun = Oyun.new(dunya)
	var bulunan: Array = _sinirda_tumenli_bolge(dunya, oyun)
	var kaynak_id: String = bulunan[0]
	var hedef_id: String = bulunan[1]
	if kaynak_id == "":
		return "Sınırda, tümeni olan bir bölge bulunamadı, sınama kurulamadı."

	if oyun.birlikleri_yurut(kaynak_id, hedef_id, 0):
		return "Düşman (savaşta olunmayan) toprağına yürütme kabul edilmemeliydi."
	for birlik: Birlik in oyun.bolgedeki_birlikler(kaynak_id):
		if birlik.yuruyor_mu():
			return "Reddedilen emirden sonra tümenler hâlâ yürüyor görünmemeli."
	return ""


func sina_var_olmayan_bolgeden_yurutme_false_doner() -> String:
	var dunya: Dunya = Dunya.yukle()
	var oyun: Oyun = Oyun.new(dunya)
	if oyun.birlikleri_yurut("YOK_1", "TUR_1", 0):
		return "Var olmayan kaynak bölgeden yürütme false dönmeli."
	return ""
