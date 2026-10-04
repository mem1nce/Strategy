extends RefCounted
## Oyun._teslimi_kontrol_et() (başkent düşünce + yarıdan fazla bölge kaybı) ve
## Oyun.baris_teklif_et()'i sınar.


func _kurulu_oyun() -> Oyun:
	var dunya: Dunya = Dunya.yukle()
	return Oyun.new(dunya)


func _komsu_ulke(dunya: Dunya) -> String:
	for ulke: Ulke in dunya.ulke_listesi:
		if ulke.id != "TUR" and dunya.ulkeler_komsu_mu("TUR", ulke.id):
			return ulke.id
	return ""


func sina_baskenti_dusen_ve_yarisi_kaybedilen_ulke_teslim_olur() -> String:
	var oyun: Oyun = _kurulu_oyun()
	var ulke: Ulke = oyun.dunya.ulkeler["TUR"]
	var baslangic_sayisi: int = ulke.baslangic_bolgeleri.size()
	if baslangic_sayisi < 2:
		return "TUR'un en az 2 başlangıç bölgesi olmalı, sınama kurulamadı."

	var galip: String = "FRA" if ulke.id != "FRA" else "DEU"
	@warning_ignore("integer_division")
	var kaybedilecek: int = baslangic_sayisi - baslangic_sayisi / 2

	# GDScript lambda'ları yerel değişkenleri değer olarak yakalar (atama dışarı yansımaz);
	# değiştirilebilir bir konteyner (Array) kullanılır.
	var sinyal: Array = [false, ""]
	oyun.ulke_teslim_oldu.connect(func(_u: String, g: String) -> void:
		sinyal[0] = true
		sinyal[1] = g)

	var baskent: Bolge = oyun.dunya.bolgeler[ulke.baskent_bolgesi]
	var digerleri: Array[Bolge] = oyun.dunya.ulkenin_bolgeleri("TUR").filter(
			func(b: Bolge) -> bool: return b.id != baskent.id)
	var devredilecek: int = mini(kaybedilecek, digerleri.size())
	for i: int in devredilecek:
		oyun._bolgeyi_devret(digerleri[i], galip, 0)
	if sinyal[0]:
		return "Başkent düşmeden teslim olmamalı (henüz %d/%d bölge kaybedildi)." % [devredilecek, baslangic_sayisi]

	oyun._bolgeyi_devret(baskent, galip, 0)
	if not sinyal[0]:
		return "Başkent düşüp yarıdan fazlası kaybedilince teslim sinyali gelmeliydi."
	if sinyal[1] != galip:
		return "Teslim sinyali galip ülkeyi doğru vermeli (geldi: %s)." % sinyal[1]
	if not oyun.dunya.ulkenin_bolgeleri("TUR").is_empty():
		return "Teslim sonrası TUR'un hiç bölgesi kalmamalı (hepsi galibe geçmeli)."
	for birlik: Birlik in oyun.birlikler:
		if birlik.sahip == "TUR":
			return "Teslim sonrası TUR'un hiç tümeni kalmamalı."
	return ""


func sina_zayif_taraf_baris_teklifini_kabul_eder() -> String:
	var oyun: Oyun = _kurulu_oyun()
	var komsu: String = _komsu_ulke(oyun.dunya)
	if komsu == "" or not oyun.savas_ilan_et("TUR", komsu, 0):
		return "Sınama kurulamadı (komşu yok ya da ilan başarısız)."
	var guclu: Birlik = Birlik.new()
	guclu.sahip = "TUR"
	guclu.bolge_id = "TUR_1"
	guclu.guc = 100000.0
	oyun.birlikler.append(guclu)

	if not oyun.baris_teklif_et("TUR", komsu, 0):
		return "Açıkça kaybeden tarafa yapılan barış teklifi kabul edilmeliydi."
	if oyun.savasta_mi("TUR", komsu):
		return "Barış sonrası artık savaşta olunmamalı."
	return ""


func sina_kazanan_taraf_erken_baris_teklifini_reddeder() -> String:
	var oyun: Oyun = _kurulu_oyun()
	var komsu: String = _komsu_ulke(oyun.dunya)
	if komsu == "" or not oyun.savas_ilan_et("TUR", komsu, 0):
		return "Sınama kurulamadı (komşu yok ya da ilan başarısız)."
	var guclu: Birlik = Birlik.new()
	guclu.sahip = komsu
	guclu.bolge_id = oyun.dunya.ulkeler[komsu].baskent_bolgesi
	guclu.guc = 100000.0
	oyun.birlikler.append(guclu)

	if oyun.baris_teklif_et("TUR", komsu, 100):
		return "Kazanan tarafa, savaş yeni başlamışken yapılan barış teklifi kabul edilmemeliydi."
	if not oyun.savasta_mi("TUR", komsu):
		return "Reddedilen teklifden sonra hâlâ savaşta olunmalı."
	return ""


func sina_uzun_suren_savasta_baris_kabul_edilir() -> String:
	var oyun: Oyun = _kurulu_oyun()
	var komsu: String = _komsu_ulke(oyun.dunya)
	if komsu == "" or not oyun.savas_ilan_et("TUR", komsu, 0):
		return "Sınama kurulamadı (komşu yok ya da ilan başarısız)."
	if not oyun.baris_teklif_et("TUR", komsu, 180 * 24 + 1):
		return "180 günden uzun süren savaşta, kimse açıkça kaybetmese de barış kabul edilmeliydi."
	return ""


func sina_savasta_olmayanlar_arasinda_baris_teklifi_reddedilir() -> String:
	var oyun: Oyun = _kurulu_oyun()
	if oyun.baris_teklif_et("TUR", "FRA", 0):
		return "Savaşta olmayan ülkeler arasında barış teklifi kabul edilmemeliydi."
	return ""
