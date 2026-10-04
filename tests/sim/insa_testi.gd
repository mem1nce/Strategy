extends RefCounted
## Oyun.tumen_sirala()/fabrika_sirala() (inşa kuyruğu) ve _bakimi_uygula()'yı sınar.


func _kurulu_oyun() -> Oyun:
	var dunya: Dunya = Dunya.yukle()
	return Oyun.new(dunya)


func sina_baskasinin_bolgesine_siralanamaz() -> String:
	var oyun: Oyun = _kurulu_oyun()
	oyun.hazineler["TUR"] = 100000.0
	if oyun.tumen_sirala("TUR", "FRA_1"):
		return "TUR, FRA'nın bölgesinde tümen sıralayamamalı."
	return ""


func sina_hazine_yetmezse_siralanamaz() -> String:
	var oyun: Oyun = _kurulu_oyun()
	oyun.hazineler["TUR"] = 0.0
	if oyun.tumen_sirala("TUR", "TUR_1"):
		return "Hazine yetersizken tümen sıralanmamalı."
	return ""


func sina_tumen_siralanir_ve_maliyet_dusulur() -> String:
	var oyun: Oyun = _kurulu_oyun()
	oyun.hazineler["TUR"] = 1000.0
	if not oyun.tumen_sirala("TUR", "TUR_1"):
		return "Hazine yeterliyken tümen sıralanmalı."
	if oyun.hazineler["TUR"] != 1000.0 - 50.0:
		return "Maliyet (50) hemen hazineden düşmeli, kalan: %.1f" % oyun.hazineler["TUR"]
	if (oyun.insa_kuyruklari.get("TUR", []) as Array).size() != 1:
		return "Kuyrukta 1 iş olmalı."
	return ""


func sina_kuyruk_azami_uzunlugu_asilamaz() -> String:
	var oyun: Oyun = _kurulu_oyun()
	oyun.hazineler["TUR"] = 100000.0
	for i: int in oyun.AZAMI_KUYRUK_UZUNLUGU:
		if not oyun.tumen_sirala("TUR", "TUR_1"):
			return "İlk %d iş kabul edilmeliydi." % oyun.AZAMI_KUYRUK_UZUNLUGU
	if oyun.tumen_sirala("TUR", "TUR_1"):
		return "Kuyruk doluyken (%d iş) yeni iş kabul edilmemeliydi." % oyun.AZAMI_KUYRUK_UZUNLUGU
	return ""


func sina_tumen_suresi_dolunca_yeni_tumen_dogar() -> String:
	var oyun: Oyun = _kurulu_oyun()
	oyun.hazineler["TUR"] = 1000.0
	oyun.tumen_sirala("TUR", "TUR_1")
	var once: int = oyun.bolgedeki_birlikler("TUR_1").size()

	for saat: int in oyun._tumen_suresi_saat - 1:
		oyun.saat_ilerledi(saat)
	if oyun.bolgedeki_birlikler("TUR_1").size() != once:
		return "Süre dolmadan yeni tümen doğmuş olmamalı."
	oyun.saat_ilerledi(oyun._tumen_suresi_saat)
	if oyun.bolgedeki_birlikler("TUR_1").size() != once + 1:
		return "Süre dolunca TUR_1'de bir tümen daha olmalı."
	if not (oyun.insa_kuyruklari.get("TUR", []) as Array).is_empty():
		return "İş tamamlanınca kuyruktan çıkmalı."
	return ""


func sina_tek_kuyrukta_ikinci_is_ilerlemez() -> String:
	var oyun: Oyun = _kurulu_oyun()
	oyun.hazineler["TUR"] = 1000.0
	oyun.tumen_sirala("TUR", "TUR_1")
	oyun.tumen_sirala("TUR", "TUR_1")
	var kuyruk: Array = oyun.insa_kuyruklari["TUR"]
	var ikinci_is: InsaIsi = kuyruk[1]
	var ikincinin_baslangic_suresi: int = ikinci_is.kalan_saat

	oyun.saat_ilerledi(0)
	if ikinci_is.kalan_saat != ikincinin_baslangic_suresi:
		return "Kuyruktaki ikinci iş, ilki bitmeden ilerlememeli."
	return ""


func sina_fabrika_tamamlaninca_sanayi_artar() -> String:
	var oyun: Oyun = _kurulu_oyun()
	oyun.hazineler["TUR"] = 10000.0
	var bolge: Bolge = oyun.dunya.bolgeler["TUR_1"]
	var once: float = bolge.fabrika_sanayisi
	if not oyun.fabrika_sirala("TUR", "TUR_1"):
		return "Fabrika sıralanmalıydı."

	for saat: int in oyun._fabrika_suresi_saat:
		oyun.saat_ilerledi(saat)
	if not is_equal_approx(bolge.fabrika_sanayisi, once + oyun._fabrika_sanayi_artisi):
		return "Fabrika tamamlanınca bölgenin fabrika_sanayisi artmalı: %.2f -> %.2f" % [
			once, bolge.fabrika_sanayisi]
	return ""


## _bakimi_uygula() doğrudan çağrılır (gun_basladi() yerine): gun_basladi önce geliri
## ekler, bu da "hazine yetersiz" ön koşulunu bozabilir (TUR'un gerçek geliri bakımdan
## fazla olabilir). Bakım mekaniğini, gelirden bağımsız olarak izole sınar.
func sina_hazine_yetersiz_bakim_tumen_gucunu_azaltir() -> String:
	var oyun: Oyun = _kurulu_oyun()
	oyun.hazineler["TUR"] = 0.0
	var birlik: Birlik = Birlik.new()
	birlik.sahip = "TUR"
	birlik.bolge_id = "TUR_1"
	birlik.guc = 10.0
	oyun.birlikler.append(birlik)
	var once: float = birlik.guc

	oyun._bakimi_uygula()
	if oyun.hazineler.get("TUR", -1.0) != 0.0:
		return "Hazine yetersizken 0'ın altına düşmemeli (eksi değer tutulmamalı)."
	if birlik.guc >= once:
		return "Bakım karşılanamazsa tümen güç kaybetmeli: önce=%.2f, sonra=%.2f" % [once, birlik.guc]
	return ""


func sina_hazine_yeterliyse_bakim_tumeni_etkilemez() -> String:
	var oyun: Oyun = _kurulu_oyun()
	oyun.hazineler["TUR"] = 100000.0
	var birlik: Birlik = Birlik.new()
	birlik.sahip = "TUR"
	birlik.bolge_id = "TUR_1"
	birlik.guc = 10.0
	oyun.birlikler.append(birlik)

	oyun._bakimi_uygula()
	if birlik.guc != 10.0:
		return "Hazine yeterliyken bakım tümenin gücünü değiştirmemeli."
	return ""
