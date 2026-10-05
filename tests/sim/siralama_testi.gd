extends RefCounted
## Oyun.guc_siralamasi()'nı sınar: büyükten küçüğe sıralı, teslim olmuş ülke yok, her
## yaşayan ülke tam bir kez var.


func _kurulu_oyun() -> Oyun:
	var dunya: Dunya = Dunya.yukle()
	return Oyun.new(dunya)


func sina_siralama_buyukten_kucuge_siralidir() -> String:
	var oyun: Oyun = _kurulu_oyun()
	var siralama: Array[Dictionary] = oyun.guc_siralamasi()
	if siralama.size() < 2:
		return "Sınama için en az 2 ülke gerekli, sınama kurulamadı."
	for i: int in siralama.size() - 1:
		if siralama[i]["guc"] < siralama[i + 1]["guc"]:
			return "Sıralama büyükten küçüğe olmalı: %d. sıra (%.1f) < %d. sıra (%.1f)" % [
				i, siralama[i]["guc"], i + 1, siralama[i + 1]["guc"]]
	return ""


func sina_siralamada_her_yasayan_ulke_bir_kez_var() -> String:
	var oyun: Oyun = _kurulu_oyun()
	var siralama: Array[Dictionary] = oyun.guc_siralamasi()
	var gorulen: Dictionary[String, bool] = {}
	for oge: Dictionary in siralama:
		var ulke_id: String = oge["ulke_id"]
		if gorulen.has(ulke_id):
			return "%s sıralamada birden fazla kez var." % ulke_id
		gorulen[ulke_id] = true
	if siralama.size() != oyun.dunya.ulke_listesi.size():
		return "Henüz hiç ülke teslim olmadı; sıralama bütün ülkeleri içermeli (%d != %d)." % [
			siralama.size(), oyun.dunya.ulke_listesi.size()]
	return ""


func sina_teslim_olmus_ulke_siralamada_yok() -> String:
	var oyun: Oyun = _kurulu_oyun()
	var ulke: Ulke = oyun.dunya.ulke_listesi[0]
	if ulke.id == "TUR":
		ulke = oyun.dunya.ulke_listesi[1]
	for bolge: Bolge in oyun.dunya.ulkenin_bolgeleri(ulke.id):
		bolge.sahip = "TUR"

	var siralama: Array[Dictionary] = oyun.guc_siralamasi()
	for oge: Dictionary in siralama:
		if oge["ulke_id"] == ulke.id:
			return "%s'in artık hiç bölgesi yok, sıralamada görünmemeli." % ulke.id
	return ""
