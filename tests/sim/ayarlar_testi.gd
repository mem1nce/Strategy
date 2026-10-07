extends RefCounted
## Ayarların (animasyonlar, ses düzeyi, sessiz) kaydedilip geri yüklenmesini ve animasyon/ses
## için yayılan simülasyon olaylarını sınar.


func _dosyayi_sil() -> void:
	if FileAccess.file_exists(Ayarlar.ayar_dosyasi):
		DirAccess.remove_absolute(Ayarlar.ayar_dosyasi)


func sina_ayarlar_kaydedilip_geri_yuklenir() -> String:
	_dosyayi_sil()
	Ayarlar.animasyonlar_azaltilmis = true
	Ayarlar.ses_duzeyi = 0.3
	Ayarlar.sessiz = true
	Ayarlar.grafik_dusuk = true
	Ayarlar.kaydet()
	# Bellekteki değerleri boz, dosyadan geri gelsin.
	Ayarlar.animasyonlar_azaltilmis = false
	Ayarlar.ses_duzeyi = 1.0
	Ayarlar.sessiz = false
	Ayarlar.grafik_dusuk = false
	Ayarlar.yukle()
	var tamam: bool = Ayarlar.animasyonlar_azaltilmis and is_equal_approx(Ayarlar.ses_duzeyi, 0.3) and Ayarlar.sessiz \
			and Ayarlar.grafik_dusuk
	_dosyayi_sil()
	Ayarlar.yukle()
	if not tamam:
		return "Kaydedilen ayarlar yüklenince aynen geri gelmeli."
	return ""


func sina_ayar_dosyasi_yoksa_varsayilanlar() -> String:
	_dosyayi_sil()
	Ayarlar.sessiz = true
	Ayarlar.grafik_dusuk = true
	Ayarlar.yukle()
	if Ayarlar.grafik_dusuk:
		return "Dosya yokken grafik Yüksek olmalı."
	if Ayarlar.animasyonlar_azaltilmis or Ayarlar.sessiz or not is_equal_approx(Ayarlar.ses_duzeyi, 0.8):
		return "Dosya yokken varsayılanlar (animasyon açık, ses %80, sessiz değil) kullanılmalı."
	return ""


func sina_bozuk_ayar_dosyasi_cokertmez() -> String:
	_dosyayi_sil()
	var dosya: FileAccess = FileAccess.open(Ayarlar.ayar_dosyasi, FileAccess.WRITE)
	dosya.store_string("{bozuk")
	dosya.close()
	Ayarlar.yukle()
	_dosyayi_sil()
	if Ayarlar.sessiz or not is_equal_approx(Ayarlar.ses_duzeyi, 0.8):
		return "Bozuk ayar dosyasında varsayılanlar kullanılmalı."
	return ""


func sina_ses_duzeyi_sinirlanir() -> String:
	_dosyayi_sil()
	var dosya: FileAccess = FileAccess.open(Ayarlar.ayar_dosyasi, FileAccess.WRITE)
	dosya.store_string(JSON.stringify({"ses_duzeyi": 7.0}))
	dosya.close()
	Ayarlar.yukle()
	_dosyayi_sil()
	var duzey: float = Ayarlar.ses_duzeyi
	Ayarlar.yukle()
	if not is_equal_approx(duzey, 1.0):
		return "Ses düzeyi 0-1 arasına sınırlanmalı (%.1f)." % duzey
	return ""


func sina_yuruyen_tumen_cikis_saatini_tutar() -> String:
	var oyun: Oyun = Oyun.new(Dunya.yukle())
	var birlik: Birlik = oyun.bolgedeki_birlikler("TUR_1")[0]
	var hedef: String = oyun.dunya.bolgeler["TUR_1"].kara_komsulari[0]
	if not oyun.birlikleri_yurut([birlik], hedef, 17):
		return "Sınama kurulamadı: yürüyüş emri kabul edilmedi."
	if birlik.cikis_saati != 17:
		return "Yürüyen tümenin çıkış saati (kaydırma animasyonu için) tutulmalı."
	var yeni: Oyun = Oyun.new(Dunya.yukle())
	yeni.kayittan_yukle(oyun.kaydet_icin_veri())
	for b: Birlik in yeni.birlikler:
		if b.yuruyor_mu() and b.cikis_saati == 17:
			return ""
	return "Çıkış saati kayıtta saklanmalı."


func sina_el_degistirme_ve_muharebe_olaylari_yayilir() -> String:
	var oyun: Oyun = Oyun.new(Dunya.yukle())
	var olaylar: Array[String] = []
	oyun.bolge_el_degistirdi.connect(func(bolge_id: String, eski: String, yeni: String) -> void:
		olaylar.append("el:%s:%s:%s" % [bolge_id, eski, yeni]))
	oyun.muharebe_basladi.connect(func(bolge_id: String) -> void: olaylar.append("muharebe:" + bolge_id))
	oyun._bolgeyi_devret(oyun.dunya.bolgeler["GRC_2"], "TUR", 0)
	if not olaylar.has("el:GRC_2:GRC:TUR"):
		return "Bölge el değiştirince bolge_el_degistirdi yayılmalı: %s" % [olaylar]
	oyun.savas_ilan_et("TUR", "FRA", 0)
	var saldiran: Birlik = Birlik.new()
	saldiran.sahip = "FRA"
	saldiran.guc = 1.0
	saldiran.bolge_id = "TUR_1"
	oyun.birlikler.append(saldiran)
	oyun._muharebeleri_isle(1)
	oyun._muharebeleri_isle(2)
	if olaylar.count("muharebe:TUR_1") != 1:
		return "Muharebe başlarken muharebe_basladi bir kez yayılmalı (sürerken yeniden değil): %s" % [olaylar]
	return ""
