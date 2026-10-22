extends RefCounted
## Bütçe (bkz. Ekonomi): başlangıç hazinesi, bakımın yere göre çarpanı, kalemler, borç ve
## faiz, iflas, terhis ve yapay zekânın borçta terhis etmesi.


func _oyun() -> Oyun:
	return Oyun.new(Dunya.yukle())


func _tumen(oyun: Oyun, sahip: String, bolge_id: String, tur: String = "piyade") -> Birlik:
	var birlik: Birlik = Birlik.new()
	birlik.sahip = sahip
	birlik.tur = tur
	birlik.bolge_id = bolge_id
	birlik.guc = 100.0
	oyun.birlikler.append(birlik)
	return birlik


func sina_baslangic_hazinesi_altmis_gunluk_gelir() -> String:
	var oyun: Oyun = _oyun()
	var beklenen: float = 60.0 * oyun.ulkenin_geliri("TUR", 0)
	if not is_equal_approx(oyun.hazineler["TUR"], beklenen):
		return "TUR ~60 günlük gelirle başlamalı: %.1f != %.1f" % [oyun.hazineler["TUR"], beklenen]
	return ""


func sina_bakim_yere_ve_savasa_gore_degisir() -> String:
	var oyun: Oyun = _oyun()
	var birlik: Birlik = _tumen(oyun, "TUR", "TUR_1", "zirhli")
	var tam: float = BirlikTurleri.bakim("zirhli")
	var baris: float = oyun.ekonomi.bakim_carpani(oyun, birlik, true)
	if not is_equal_approx(baris, 0.6):
		return "Barışta kendi toprağında bakım %%60 olmalı (%.2f)." % baris
	if not is_equal_approx(oyun.ekonomi.bakim_carpani(oyun, birlik, false), 1.0):
		return "Savaşta kendi toprağında bakım tam olmalı."
	birlik.bolge_id = "GRC_1"
	if not is_equal_approx(oyun.ekonomi.bakim_carpani(oyun, birlik, true), 1.3):
		return "Yabancı toprakta bakım %130 olmalı."
	if not BirlikTurleri.bakim("zirhli") > BirlikTurleri.bakim("topcu") or not BirlikTurleri.bakim("topcu") > BirlikTurleri.bakim("piyade"):
		return "Bakım: piyade < topçu < zırhlı olmalı (%.2f)." % tam
	return ""


func sina_kalemler_neti_verir_ve_hazineye_islenir() -> String:
	var oyun: Oyun = _oyun()
	var once: float = oyun.hazineler["TUR"]
	oyun.gun_basladi(24)
	var k: Dictionary = oyun.ekonomi.kalemler["TUR"]
	var net: float = 0.0
	for kalem: String in Ekonomi.GELIR_KALEMLERI:
		net += float(k[kalem])
	for kalem: String in Ekonomi.GIDER_KALEMLERI:
		net -= float(k[kalem])
	if not is_equal_approx(oyun.hazineler["TUR"] - once, net):
		return "Hazine, kalemlerin netiyle değişmeli (%.2f != %.2f)." % [oyun.hazineler["TUR"] - once, net]
	if oyun.ekonomi.gecmis["TUR"].size() != 1:
		return "Her gün geçmişe bir değer eklenmeli."
	return ""


func sina_borc_faiz_isletir() -> String:
	var oyun: Oyun = _oyun()
	oyun.hazineler["TUR"] = -1000.0
	oyun.gun_basladi(24)
	var faiz: float = float(oyun.ekonomi.kalemler["TUR"]["faiz"])
	if not is_equal_approx(faiz, 1000.0 * oyun.ekonomi.aylik_faiz / 30.0):
		return "Eksi hazine borçtur; günlük faiz aylık faizin 1/30'u olmalı (%.3f)." % faiz
	return ""


func sina_limit_asilinca_iflas_insaat_durur_tumen_guc_kaybeder() -> String:
	var oyun: Oyun = _oyun()
	oyun.gun_basladi(24)
	var limit: float = oyun.ekonomi.borc_limiti(oyun, "TUR")
	oyun.hazineler["TUR"] = -(limit + 1000.0)
	var birlik: Birlik = oyun.bolgedeki_birlikler("TUR_1")[0]
	oyun.gun_basladi(48)
	if not oyun.ekonomi.iflasta_mi("TUR"):
		return "Borç limiti (90 günlük gelir) aşılınca iflas edilmeli."
	if birlik.guc >= 100.0:
		return "İflasta tümenler her gün güç kaybetmeli."
	oyun.hazineler["TUR"] = 100000.0
	if oyun.tumen_sirala("TUR", "TUR_1"):
		return "İflastayken inşaat sıralanmamalı."
	oyun.gun_basladi(72)
	if oyun.ekonomi.iflasta_mi("TUR"):
		return "Borç kapanınca iflas bitmeli."
	return ""


func sina_terhis_tumeni_siler_bakim_duser() -> String:
	var oyun: Oyun = _oyun()
	var once: float = oyun.ekonomi.ulke_bakimi(oyun, "TUR")
	var liste: Array[Birlik] = oyun.bolgedeki_birlikler("TUR_1")
	var sayi: int = oyun.terhis_et(liste)
	if sayi != liste.size() or not oyun.bolgedeki_birlikler("TUR_1").is_empty():
		return "Terhis edilen tümenler silinmeli."
	if not oyun.ekonomi.ulke_bakimi(oyun, "TUR") < once:
		return "Terhisten sonra bakım düşmeli."
	return ""


func sina_yapay_zeka_borcta_terhis_eder() -> String:
	var oyun: Oyun = _oyun()
	oyun.gun_basladi(24)
	var ulke_id: String = "DEU"
	var once: int = 0
	for birlik: Birlik in oyun.birlikler:
		if birlik.sahip == ulke_id:
			once += 1
	oyun.hazineler[ulke_id] = -0.8 * oyun.ekonomi.borc_limiti(oyun, ulke_id)
	oyun._yz_terhis_dusun(ulke_id)
	var sonra: int = 0
	for birlik: Birlik in oyun.birlikler:
		if birlik.sahip == ulke_id:
			sonra += 1
	if sonra >= once:
		return "Borcu limite yaklaşan yapay zekâ tümen terhis etmeli (%d -> %d)." % [once, sonra]
	return ""


func sina_yapay_zeka_butcesini_acige_dusurmez() -> String:
	var oyun: Oyun = _oyun()
	var ulke_id: String = "DEU"
	oyun.gun_basladi(24)
	# Bakımı gelire eşitleyen kadar tümen ekle: net ~0, yeni tümen kurulmamalı.
	var gelir: float = oyun.ekonomi.gunluk_gelir(oyun, ulke_id)
	var baskent: String = oyun.dunya.ulkeler[ulke_id].baskent_bolgesi
	while oyun.ekonomi.ulke_bakimi(oyun, ulke_id) < gelir:
		_tumen(oyun, ulke_id, baskent)
	oyun.gun_basladi(48)
	oyun.hazineler[ulke_id] = 100000.0
	var kuyruk_once: int = oyun.kuyruktaki_is_sayisi(ulke_id)
	for i: int in 10:
		oyun._baristaki_ulke_dusun(ulke_id, 48)
	var tumen_isi: int = 0
	for is_: InsaIsi in (oyun.insa_kuyruklari.get(ulke_id, []) as Array).slice(kuyruk_once):
		if is_.tur == InsaIsi.Tur.TUMEN:
			tumen_isi += 1
	if tumen_isi > 0:
		return "Neti açıktaki yapay zekâ tümen kurmamalı (%d iş sıraladı)." % tumen_isi
	return ""


func sina_kayit_butceyi_korur() -> String:
	var oyun: Oyun = _oyun()
	oyun.oyuncuyu_sec("TUR")
	oyun.gun_basladi(24)
	oyun.ekonomi.iflaslar["TUR"] = true
	var yeni: Oyun = _oyun()
	yeni.kayittan_yukle(JSON.parse_string(JSON.stringify(oyun.kaydet_icin_veri())))
	if not yeni.ekonomi.iflasta_mi("TUR") or not yeni.ekonomi.kalemler.has("TUR") \
			or yeni.ekonomi.gecmis.get("TUR", PackedFloat32Array()).size() != 1:
		return "Kalemler, iflas ve oyuncunun hazine geçmişi kayıtta korunmalı."
	var eski: Dictionary = oyun.kaydet_icin_veri()
	eski.erase("ekonomi")
	var eskiden: Oyun = _oyun()
	eskiden.kayittan_yukle(eski)
	if eskiden.ekonomi.iflasta_mi("TUR") or not eskiden.ekonomi.kalemler.is_empty():
		return "Ekonomisi olmayan eski kayıt varsayılanlarla açılmalı."
	return ""
