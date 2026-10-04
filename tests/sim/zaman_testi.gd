extends RefCounted
## Zaman yöneticisinin kilit/hız mantığını ve uzun süre hatasız ilerleyebildiğini sınar.
##
## Autoload'a (Zaman) bağlı olmamak için betik doğrudan örneklenir; sahneye eklenmez.

const ZAMAN_BETIGI: Script = preload("res://scripts/sim/zaman.gd")


func _yeni_zaman() -> Node:
	var zaman: Node = ZAMAN_BETIGI.new()
	zaman._ayarlari_yukle()
	return zaman


func sina_kilitliyken_baslamaz() -> String:
	var zaman: Node = _yeni_zaman()
	zaman.devam_et()
	var hata: String = "" if zaman.durdu else "Kilitliyken devam_et() zamanı başlatmamalı."
	zaman.free()
	return hata


func sina_kilit_acilinca_baslar_ve_durur() -> String:
	var zaman: Node = _yeni_zaman()
	zaman.kilidi_ac()
	zaman.devam_et()
	if zaman.durdu:
		zaman.free()
		return "Kilit açıkken devam_et() zamanı başlatmalı."
	zaman.durdur()
	var hata: String = "" if zaman.durdu else "durdur() zamanı durdurmalı."
	zaman.free()
	return hata


## Uzun koşu sınaması: 5 oyun yılı (43800 saat) hatasız, sonsuz döngüye girmeden ilerler mi?
## Birlik, savaş, ekonomi ve yapay zekâ henüz yok; onlar eklendikçe bu sınama onları da
## kapsayacak şekilde büyütülmeli (bkz. DEVAM.md).
func sina_bes_yil_hatasiz_ilerler() -> String:
	var zaman: Node = _yeni_zaman()
	zaman.kilidi_ac()
	var saat_sayisi: int = 5 * 365 * 24
	for i: int in saat_sayisi:
		zaman.bir_saat_ilerle()
	var hata: String = ""
	if zaman.toplam_saat != saat_sayisi:
		hata = "5 yıl sonra toplam_saat %d olmalıydı, %d geldi." % [saat_sayisi, zaman.toplam_saat]
	print("Uzun koşu özeti: %d saat ilerletildi, son tarih: %s" % [zaman.toplam_saat, zaman.tarih_metni()])
	zaman.free()
	return hata
