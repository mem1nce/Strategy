extends RefCounted
## Oyun._savastaki_ulke_dusun() (saldırı eşiği, başkent korunur) ve
## Oyun._savas_ilanini_degerlendir()'i (ayda bir, güç farkı, dokunulmazlık, azami savaş) sınar.


func _kurulu_oyun() -> Oyun:
	var dunya: Dunya = Dunya.yukle()
	var oyun: Oyun = Oyun.new(dunya)
	oyun.oyuncuyu_sec("TUR")
	return oyun


## TUR'un, BAŞKENTİ OLMAYAN bir sınır bölge çiftini (TUR bölgesi, yabancı komşu bölge)
## bulur; başkent saldırmaz, ayrı bir sınamada (sina_baskent_ezici_ustunlukte_bile_saldirmaz)
## kapsanır.
func _sinir_cifti(dunya: Dunya) -> Array:
	var baskent_id: String = dunya.ulkeler["TUR"].baskent_bolgesi
	for bolge: Bolge in dunya.ulkenin_bolgeleri("TUR"):
		if bolge.id == baskent_id:
			continue
		for komsu: Bolge in dunya.bolgenin_komsulari(bolge.id):
			if komsu.sahip != "TUR":
				return [bolge.id, komsu.id, komsu.sahip]
	return ["", "", ""]


func sina_guclu_sinir_bolgesi_saldirir() -> String:
	var oyun: Oyun = _kurulu_oyun()
	var cift: Array = _sinir_cifti(oyun.dunya)
	var kendi_id: String = cift[0]
	var dusman_id: String = cift[1]
	var dusman_sahibi: String = cift[2]
	if kendi_id == "":
		return "TUR'un yabancı bir sınır komşusu yok, sınama kurulamadı."
	oyun.savas_ilan_et("TUR", dusman_sahibi, 0)

	for birlik: Birlik in oyun.bolgedeki_birlikler(kendi_id):
		birlik.guc = 100.0
	for birlik: Birlik in oyun.bolgedeki_birlikler(dusman_id):
		birlik.guc = 10.0  # 100 >= 1.3 * 10, saldırmalı.

	oyun._savastaki_ulke_dusun("TUR", 0)
	for birlik: Birlik in oyun.bolgedeki_birlikler(kendi_id):
		if not birlik.yuruyor_mu() or birlik.hedef_bolge_id != dusman_id:
			return "Güçlü sınır bölgesi düşman bölgesine saldırmalıydı."
	return ""


func sina_zayif_sinir_bolgesi_saldirmaz() -> String:
	var oyun: Oyun = _kurulu_oyun()
	var cift: Array = _sinir_cifti(oyun.dunya)
	var kendi_id: String = cift[0]
	var dusman_id: String = cift[1]
	var dusman_sahibi: String = cift[2]
	if kendi_id == "":
		return "TUR'un yabancı bir sınır komşusu yok, sınama kurulamadı."
	oyun.savas_ilan_et("TUR", dusman_sahibi, 0)

	for birlik: Birlik in oyun.bolgedeki_birlikler(kendi_id):
		birlik.guc = 10.0
	for birlik: Birlik in oyun.bolgedeki_birlikler(dusman_id):
		birlik.guc = 100.0  # 10 < 1.3 * 100, saldırmamalı.

	oyun._savastaki_ulke_dusun("TUR", 0)
	for birlik: Birlik in oyun.bolgedeki_birlikler(kendi_id):
		if birlik.yuruyor_mu():
			return "Zayıf sınır bölgesi saldırmamalıydı."
	return ""


func sina_baskent_ezici_ustunlukte_bile_saldirmaz() -> String:
	var oyun: Oyun = _kurulu_oyun()
	var ulke: Ulke = oyun.dunya.ulkeler["TUR"]
	var baskent: Bolge = oyun.dunya.bolgeler[ulke.baskent_bolgesi]
	var dusman_id: String = ""
	var dusman_sahibi: String = ""
	for komsu: Bolge in oyun.dunya.bolgenin_komsulari(baskent.id):
		if komsu.sahip != "TUR":
			dusman_id = komsu.id
			dusman_sahibi = komsu.sahip
			break
	if dusman_id == "":
		return "Başkentin yabancı bir komşusu yok, sınama kurulamadı."
	oyun.savas_ilan_et("TUR", dusman_sahibi, 0)

	for birlik: Birlik in oyun.bolgedeki_birlikler(baskent.id):
		birlik.guc = 100000.0
	for birlik: Birlik in oyun.bolgedeki_birlikler(dusman_id):
		birlik.guc = 1.0

	oyun._savastaki_ulke_dusun("TUR", 0)
	for birlik: Birlik in oyun.bolgedeki_birlikler(baskent.id):
		if birlik.yuruyor_mu():
			return "Başkentteki tümenler, ezici üstünlükte olsa bile saldırıya katılmamalı."
	return ""


func sina_gun_uyumsuzsa_ilan_degerlendirilmez() -> String:
	var oyun: Oyun = _kurulu_oyun()
	oyun._yz_savas_ilani_olasiligi = 1.0
	# 24 saat = 1. gün; gün_araligi (30) ile bölünmüyor, değerlendirilmemeli.
	oyun._savas_ilanini_degerlendir("TUR", 24)
	if oyun._ulkenin_savas_sayisi("TUR") != 0:
		return "Ayın uygun günü değilken savaş ilanı değerlendirilmemeli."
	return ""


func sina_zar_tutmazsa_ilan_edilmez() -> String:
	var oyun: Oyun = _kurulu_oyun()
	oyun._yz_savas_ilani_olasiligi = 0.0
	oyun._savas_ilanini_degerlendir("TUR", 0)
	if oyun._ulkenin_savas_sayisi("TUR") != 0:
		return "Olasılık 0 iken ilan edilmemeli."
	return ""


func sina_komsu_olmayana_ilan_edilmez() -> String:
	var oyun: Oyun = _kurulu_oyun()
	oyun._yz_savas_ilani_olasiligi = 1.0
	var uzak: String = ""
	for ulke: Ulke in oyun.dunya.ulke_listesi:
		if ulke.id != "TUR" and not oyun.dunya.ulkeler_komsu_mu("TUR", ulke.id):
			uzak = ulke.id
			break
	if uzak == "":
		return "Komşu olmayan bir ülke bulunamadı, sınama kurulamadı."
	oyun._savas_ilanini_degerlendir("TUR", 0)
	if oyun.savasta_mi("TUR", uzak):
		return "Komşu olmayan bir ülkeye ilan edilmemeliydi."
	return ""


func sina_yetersiz_guc_farkinda_ilan_edilmez() -> String:
	var oyun: Oyun = _kurulu_oyun()
	oyun._yz_savas_ilani_olasiligi = 1.0
	var komsu: String = ""
	for ulke: Ulke in oyun.dunya.ulke_listesi:
		if ulke.id != "TUR" and oyun.dunya.ulkeler_komsu_mu("TUR", ulke.id):
			komsu = ulke.id
			break
	if komsu == "":
		return "TUR'un komşusu bulunamadı, sınama kurulamadı."
	# Güçleri (yaklaşık) eşitle: komşu, 2 kat eşiğinin altında kalsın.
	var komsu_guc: float = 0.0
	for birlik: Birlik in oyun.birlikler:
		if birlik.sahip == komsu:
			komsu_guc += birlik.guc
	for birlik: Birlik in oyun.birlikler:
		if birlik.sahip == "TUR":
			birlik.guc = 0.0
	var ilk_tur_birligi: Birlik = oyun.bolgedeki_birlikler(oyun.dunya.ulkeler["TUR"].baskent_bolgesi)[0]
	ilk_tur_birligi.guc = komsu_guc * 1.5  # 2 katından az.

	oyun._savas_ilanini_degerlendir("TUR", 0)
	if oyun.savasta_mi("TUR", komsu):
		return "Hedef 2 kat güçsüz değilken ilan edilmemeliydi."
	return ""


func sina_azami_savas_sayisina_ulasinca_ilan_etmez() -> String:
	var oyun: Oyun = _kurulu_oyun()
	oyun._yz_savas_ilani_olasiligi = 1.0
	var komsular: Array[String] = []
	for ulke: Ulke in oyun.dunya.ulke_listesi:
		if ulke.id != "TUR" and oyun.dunya.ulkeler_komsu_mu("TUR", ulke.id):
			komsular.append(ulke.id)
		if komsular.size() >= oyun._yz_azami_eszamanli_savas:
			break
	if komsular.size() < oyun._yz_azami_eszamanli_savas:
		return "TUR'un yeterli komşusu yok, sınama kurulamadı."
	for komsu_id: String in komsular:
		oyun.savas_ilan_et("TUR", komsu_id, 0)

	var savas_sayisi_once: int = oyun._ulkenin_savas_sayisi("TUR")
	oyun._savas_ilanini_degerlendir("TUR", 0)
	if oyun._ulkenin_savas_sayisi("TUR") != savas_sayisi_once:
		return "Azami eşzamanlı savaş sayısına ulaşmışken yeni ilan edilmemeliydi."
	return ""


func sina_ilk_90_gun_oyuncuya_ilan_edilmez() -> String:
	var dunya: Dunya = Dunya.yukle()
	var oyun: Oyun = Oyun.new(dunya)
	oyun.oyuncuyu_sec("TUR")
	oyun._yz_savas_ilani_olasiligi = 1.0
	var komsu: String = ""
	for ulke: Ulke in dunya.ulke_listesi:
		if ulke.id != "TUR" and dunya.ulkeler_komsu_mu("TUR", ulke.id):
			komsu = ulke.id
			break
	if komsu == "":
		return "TUR'un komşusu bulunamadı, sınama kurulamadı."
	# "İlan eden" (komsu) güçlü, hedef (TUR) zayıf olmalı ki tek engel dokunulmazlık olsun.
	for birlik: Birlik in oyun.birlikler:
		if birlik.sahip == "TUR":
			birlik.guc = 1.0

	# 60. gün: hem "ayda bir" aralığına (30'un katı) uyar hem dokunulmazlık (90 gün) içinde.
	oyun._savas_ilanini_degerlendir(komsu, 60 * 24)
	if oyun.savasta_mi(komsu, "TUR"):
		return "İlk 90 gün içinde oyuncuya savaş ilan edilmemeliydi."
	return ""


func sina_90_gunden_sonra_oyuncuya_ilan_edilebilir() -> String:
	var dunya: Dunya = Dunya.yukle()
	var oyun: Oyun = Oyun.new(dunya)
	oyun.oyuncuyu_sec("TUR")
	oyun._yz_savas_ilani_olasiligi = 1.0
	var komsu: String = ""
	for ulke: Ulke in dunya.ulke_listesi:
		if ulke.id != "TUR" and dunya.ulkeler_komsu_mu("TUR", ulke.id):
			komsu = ulke.id
			break
	if komsu == "":
		return "TUR'un komşusu bulunamadı, sınama kurulamadı."
	for birlik: Birlik in oyun.birlikler:
		if birlik.sahip == "TUR":
			birlik.guc = 1.0

	# 120. gün: 30'un katı ve dokunulmazlık (90 gün) bitmiş.
	oyun._savas_ilanini_degerlendir(komsu, 120 * 24)
	if not oyun.savasta_mi(komsu, "TUR"):
		return "90 günden sonra, yeterince güçlüyse oyuncuya savaş ilan edebilmeliydi."
	return ""
