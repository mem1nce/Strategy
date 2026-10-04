extends RefCounted
## Takvim'in saat/gün hesabını ve artık yıl dahil tarih metnini sınar.


func sina_gun_ve_saat_hesabi() -> String:
	if Takvim.gun_sayisi(0) != 0 or Takvim.saat(0) != 0:
		return "Saat 0, gün 0 saat 0 olmalı."
	if Takvim.saat(23) != 23 or Takvim.gun_sayisi(23) != 0:
		return "23. saat hâlâ 0. günde, saat 23 olmalı."
	if Takvim.gun_sayisi(25) != 1 or Takvim.saat(25) != 1:
		return "25. saat 1. günün 1. saati olmalı."
	return ""


func sina_artik_yil_olmayan_subat() -> String:
	# 2026 artık yıl değil: Ocak 31 gündür, 31*24 saat sonra 1 Şubat olmalı.
	var baslangic: int = Takvim.tarihten_unix("2026-01-01")
	var metin: String = Takvim.metin(baslangic, 31 * 24)
	if not metin.begins_with("1 Şubat 2026"):
		return "31 gün sonrası 1 Şubat 2026 olmalı, geldi: %s" % metin
	return ""


func sina_artik_yil_subat_29() -> String:
	# 2028 artık yıldır: Ocak (31) + Şubat'ın 28. günü = 59 gün sonra 29 Şubat olmalı.
	var baslangic: int = Takvim.tarihten_unix("2028-01-01")
	var metin: String = Takvim.metin(baslangic, 59 * 24)
	if not metin.begins_with("29 Şubat 2028"):
		return "Artık yılda 59 gün sonrası 29 Şubat 2028 olmalı, geldi: %s" % metin
	return ""
