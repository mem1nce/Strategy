extends RefCounted
## KayitYoneticisi.kaydet()/yukle() ve Oyun.kaydet_icin_veri()/kayittan_yukle()'yi sınar.
##
## Gerçek user:// kayıt yuvasını kullanır (tek yuva tasarımı, ayrı bir sınama yolu yok);
## her sınama kendi başında ve sonunda dosyayı siler ki ne sınamalar birbirini etkilesin
## ne de gerçek bir oyun oturumunun kaydını ezsin.


func _kayit_dosyasini_sil() -> void:
	if FileAccess.file_exists(KayitYoneticisi.kayit_dosyasi):
		DirAccess.remove_absolute(KayitYoneticisi.kayit_dosyasi)


func _kurulu_oyun() -> Oyun:
	var dunya: Dunya = Dunya.yukle()
	return Oyun.new(dunya)


func sina_kayit_yoksa_yukle_bos_sozluk_doner() -> String:
	_kayit_dosyasini_sil()
	if not KayitYoneticisi.yukle().is_empty():
		return "Kayıt yokken yukle() boş sözlük döndürmeli."
	return ""


func sina_kaydedip_yuklemek_oyuncu_ulkesini_korur() -> String:
	_kayit_dosyasini_sil()
	var oyun: Oyun = _kurulu_oyun()
	oyun.oyuncuyu_sec("TUR")
	KayitYoneticisi.kaydet(oyun, {"toplam_saat": 500, "durdu": false, "hiz": 2, "kilitli": false})

	var kayit: Dictionary = KayitYoneticisi.yukle()
	_kayit_dosyasini_sil()
	if kayit.is_empty():
		return "Kaydedilen dosya yüklenemedi."
	if kayit["zaman_durumu"].get("toplam_saat") != 500:
		return "Zaman durumu doğru kaydedilip okunmalı."

	var yeni_oyun: Oyun = _kurulu_oyun()
	yeni_oyun.kayittan_yukle(kayit["oyun_verisi"])
	if yeni_oyun.oyuncu_ulkesi != "TUR":
		return "Yüklenen oyunun oyuncu ülkesi TUR olmalı, geldi: %s" % yeni_oyun.oyuncu_ulkesi
	return ""


func sina_kaydedip_yuklemek_birlik_gucunu_korur() -> String:
	_kayit_dosyasini_sil()
	var oyun: Oyun = _kurulu_oyun()
	var birlik: Birlik = oyun.bolgedeki_birlikler("TUR_1")[0]
	birlik.guc = 42.5
	KayitYoneticisi.kaydet(oyun, {})

	var kayit: Dictionary = KayitYoneticisi.yukle()
	_kayit_dosyasini_sil()
	var yeni_oyun: Oyun = _kurulu_oyun()
	yeni_oyun.kayittan_yukle(kayit["oyun_verisi"])

	var toplam_birlik: int = 0
	var bulundu: bool = false
	for b: Birlik in yeni_oyun.bolgedeki_birlikler("TUR_1"):
		toplam_birlik += 1
		if is_equal_approx(b.guc, 42.5):
			bulundu = true
	if not bulundu:
		return "Güç 42,5 olan tümen yüklenen oyunda bulunamadı."
	if toplam_birlik != oyun.bolgedeki_birlikler("TUR_1").size():
		return "Yüklenen tümen sayısı kaydedilenle aynı olmalı."
	return ""


func sina_kaydedip_yuklemek_bolge_sahipligini_korur() -> String:
	_kayit_dosyasini_sil()
	var oyun: Oyun = _kurulu_oyun()
	var bolge: Bolge = oyun.dunya.bolgeler["TUR_2"]
	bolge.sahip = "FRA"
	bolge.isgal_saati = 777
	bolge.fabrika_sanayisi = 3.5
	KayitYoneticisi.kaydet(oyun, {})

	var kayit: Dictionary = KayitYoneticisi.yukle()
	_kayit_dosyasini_sil()
	var yeni_oyun: Oyun = _kurulu_oyun()
	yeni_oyun.kayittan_yukle(kayit["oyun_verisi"])

	var yeni_bolge: Bolge = yeni_oyun.dunya.bolgeler["TUR_2"]
	if yeni_bolge.sahip != "FRA" or yeni_bolge.isgal_saati != 777 or not is_equal_approx(yeni_bolge.fabrika_sanayisi, 3.5):
		return "Bölge sahipliği/işgal saati/fabrika sanayisi korunmalı (geldi: %s, %d, %.1f)." % [
			yeni_bolge.sahip, yeni_bolge.isgal_saati, yeni_bolge.fabrika_sanayisi]
	return ""


func sina_kaydedip_yuklemek_savasi_korur() -> String:
	_kayit_dosyasini_sil()
	var oyun: Oyun = _kurulu_oyun()
	var komsu: String = ""
	for ulke: Ulke in oyun.dunya.ulke_listesi:
		if ulke.id != "TUR" and oyun.dunya.ulkeler_komsu_mu("TUR", ulke.id):
			komsu = ulke.id
			break
	if komsu == "" or not oyun.savas_ilan_et("TUR", komsu, 123):
		return "Sınama kurulamadı (komşu yok ya da ilan başarısız)."
	KayitYoneticisi.kaydet(oyun, {})

	var kayit: Dictionary = KayitYoneticisi.yukle()
	_kayit_dosyasini_sil()
	var yeni_oyun: Oyun = _kurulu_oyun()
	yeni_oyun.kayittan_yukle(kayit["oyun_verisi"])
	if not yeni_oyun.savasta_mi("TUR", komsu):
		return "Savaş durumu yüklendikten sonra korunmalı."
	return ""


func sina_kaydedip_yuklemek_hazineyi_korur() -> String:
	_kayit_dosyasini_sil()
	var oyun: Oyun = _kurulu_oyun()
	oyun.hazineler["TUR"] = 987.5
	KayitYoneticisi.kaydet(oyun, {})

	var kayit: Dictionary = KayitYoneticisi.yukle()
	_kayit_dosyasini_sil()
	var yeni_oyun: Oyun = _kurulu_oyun()
	yeni_oyun.kayittan_yukle(kayit["oyun_verisi"])
	if not is_equal_approx(yeni_oyun.hazineler.get("TUR", 0.0), 987.5):
		return "Hazine yüklendikten sonra korunmalı, geldi: %.1f" % yeni_oyun.hazineler.get("TUR", 0.0)
	return ""


func sina_kaydedip_yuklemek_insa_kuyrugunu_korur() -> String:
	_kayit_dosyasini_sil()
	var oyun: Oyun = _kurulu_oyun()
	oyun.oyuncuyu_sec("TUR")
	oyun.hazineler["TUR"] = 1000.0
	if not oyun.tumen_sirala("TUR", "TUR_1"):
		return "Sınama kurulamadı: tümen sıralanamadı."
	KayitYoneticisi.kaydet(oyun, {})

	var kayit: Dictionary = KayitYoneticisi.yukle()
	_kayit_dosyasini_sil()
	var yeni_oyun: Oyun = _kurulu_oyun()
	yeni_oyun.kayittan_yukle(kayit["oyun_verisi"])

	var kuyruk: Array = yeni_oyun.insa_kuyruklari.get("TUR", [])
	if kuyruk.size() != 1:
		return "Yüklenen kuyrukta 1 iş olmalı, geldi: %d" % kuyruk.size()
	var is_: InsaIsi = kuyruk[0]
	if is_.tur != InsaIsi.Tur.TUMEN or is_.bolge_id != "TUR_1" or is_.kalan_saat != oyun._tumen_suresi_saat:
		return "Yüklenen işin tür/bölge/kalan süresi kaydedilenle aynı olmalı."
	return ""


func sina_kaydedip_yuklemek_yz_yonetimini_korur() -> String:
	_kayit_dosyasini_sil()
	var oyun: Oyun = _kurulu_oyun()
	oyun.yz_oyuncuyu_yonetsin = true
	KayitYoneticisi.kaydet(oyun, {})

	var kayit: Dictionary = KayitYoneticisi.yukle()
	_kayit_dosyasini_sil()
	var yeni_oyun: Oyun = _kurulu_oyun()
	yeni_oyun.kayittan_yukle(kayit["oyun_verisi"])
	if not yeni_oyun.yz_oyuncuyu_yonetsin:
		return "'Ordumu yapay zekâ yönetsin' tercihi yüklendikten sonra korunmalı."
	return ""


func sina_surum_uyusmazsa_yukle_bos_sozluk_doner() -> String:
	_kayit_dosyasini_sil()
	var dosya: FileAccess = FileAccess.open(KayitYoneticisi.kayit_dosyasi, FileAccess.WRITE)
	dosya.store_string(JSON.stringify({"surum": 999, "oyuncu_ulkesi": "TUR"}))
	dosya = null

	var sonuc: bool = KayitYoneticisi.yukle().is_empty()
	_kayit_dosyasini_sil()
	if not sonuc:
		return "Sürümü uyuşmayan kayıt yok sayılmalı (boş sözlük dönmeli)."
	return ""


## 1. sürüm kaydında tümen türü, tahkimat ve teknoloji yoktu: açılınca çökmemeli ve
## bütün tümenler piyade olmalı.
func sina_eski_surum_kaydi_piyade_olarak_acilir() -> String:
	_kayit_dosyasini_sil()
	var oyun: Oyun = _kurulu_oyun()
	oyun.oyuncuyu_sec("TUR")
	oyun.hazineler["TUR"] = 1000.0
	oyun.tumen_sirala("TUR", "TUR_1")
	KayitYoneticisi.kaydet(oyun, {"toplam_saat": 10})
	# Yeni anahtarları silip dosyayı 1. sürüm kaydı gibi yeniden yaz.
	var veri: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(KayitYoneticisi.kayit_dosyasi))
	veri["surum"] = 1
	veri.erase("teknolojiler")
	veri.erase("arastirmalar")
	for b: Dictionary in (veri["bolgeler"] as Array):
		b.erase("tahkimat")
	for b: Dictionary in (veri["birlikler"] as Array):
		b.erase("tur")
	for kuyruk: Array in (veri["insa_kuyruklari"] as Dictionary).values():
		for is_verisi: Dictionary in kuyruk:
			is_verisi.erase("birlik_turu")
	var dosya: FileAccess = FileAccess.open(KayitYoneticisi.kayit_dosyasi, FileAccess.WRITE)
	dosya.store_string(JSON.stringify(veri))
	dosya = null

	var kayit: Dictionary = KayitYoneticisi.yukle()
	_kayit_dosyasini_sil()
	if kayit.is_empty():
		return "1. sürüm kayıt açılabilmeli."
	var yeni_oyun: Oyun = _kurulu_oyun()
	yeni_oyun.kayittan_yukle(kayit["oyun_verisi"])
	if yeni_oyun.birlikler.size() != oyun.birlikler.size():
		return "Eski kayıttaki bütün tümenler yüklenmeli."
	for birlik: Birlik in yeni_oyun.birlikler:
		if birlik.tur != "piyade":
			return "Eski kayıttaki tümenler piyade olmalı, geldi: %s" % birlik.tur
	var kuyruk: Array = yeni_oyun.insa_kuyruklari.get("TUR", [])
	if kuyruk.size() != 1 or (kuyruk[0] as InsaIsi).birlik_turu != "piyade":
		return "Eski kayıttaki tümen işi piyade işi olarak yüklenmeli."
	if yeni_oyun.teknoloji_seviyesi("TUR", "silah") != 0 or yeni_oyun.dunya.bolgeler["TUR_1"].tahkimat != 0:
		return "Eski kayıtta teknoloji ve tahkimat sıfırdan başlamalı."
	return ""


func sina_kaydedip_yuklemek_tur_teknoloji_ve_tahkimati_korur() -> String:
	_kayit_dosyasini_sil()
	var oyun: Oyun = _kurulu_oyun()
	oyun.oyuncuyu_sec("TUR")
	oyun.hazineler["TUR"] = 1000.0
	oyun.bolgedeki_birlikler("TUR_1")[0].tur = "topcu"
	oyun.dunya.bolgeler["TUR_1"].tahkimat = 2
	oyun.teknolojiler["TUR"] = {"sanayi": 1}
	oyun.arastirma_baslat("TUR", "silah")
	KayitYoneticisi.kaydet(oyun, {})

	var kayit: Dictionary = KayitYoneticisi.yukle()
	_kayit_dosyasini_sil()
	var yeni_oyun: Oyun = _kurulu_oyun()
	yeni_oyun.kayittan_yukle(kayit["oyun_verisi"])
	if yeni_oyun.bolgedeki_birlikler("TUR_1")[0].tur != "topcu":
		return "Tümen türü korunmalı."
	if yeni_oyun.dunya.bolgeler["TUR_1"].tahkimat != 2:
		return "Tahkimat seviyesi korunmalı."
	if yeni_oyun.teknoloji_seviyesi("TUR", "sanayi") != 1 or yeni_oyun.suren_arastirma("TUR").get("dal", "") != "silah":
		return "Teknoloji seviyeleri ve süren araştırma korunmalı: %s" % yeni_oyun.suren_arastirma("TUR")
	return ""


func sina_sil_kaydi_kaldirir() -> String:
	_kayit_dosyasini_sil()
	var oyun: Oyun = _kurulu_oyun()
	oyun.oyuncuyu_sec("TUR")
	KayitYoneticisi.kaydet(oyun, {})
	if not KayitYoneticisi.kayit_var_mi():
		return "Sınama kurulamadı: kayıt yazılamadı."

	KayitYoneticisi.sil()
	if KayitYoneticisi.kayit_var_mi():
		return "sil()'den sonra kayit_var_mi() false dönmeli."
	return ""


func sina_sil_kayit_yokken_hata_vermez() -> String:
	_kayit_dosyasini_sil()
	KayitYoneticisi.sil()
	return ""
