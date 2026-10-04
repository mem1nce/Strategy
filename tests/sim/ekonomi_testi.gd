extends RefCounted
## Oyun.bolge_sanayisi(), ulkenin_geliri() ve gun_basladi()'yı sınar.


func _kurulu_oyun() -> Oyun:
	var dunya: Dunya = Dunya.yukle()
	return Oyun.new(dunya)


func sina_bolge_sanayisi_pozitif_ve_cezasiz_baslar() -> String:
	var oyun: Oyun = _kurulu_oyun()
	var bolge: Bolge = oyun.dunya.bolgeler["TUR_1"]
	if bolge.isgal_saati != -1:
		return "Oyun başında hiçbir bölge işgal edilmiş olmamalı, sınama kurulamadı."
	var sanayi: float = oyun.bolge_sanayisi(bolge, 0)
	if sanayi <= 0.0:
		return "TUR_1'in (nüfuslu bir bölge) sanayisi pozitif olmalı, geldi: %.3f" % sanayi
	return ""


func sina_isgal_edilen_bolge_yarim_uretir() -> String:
	var oyun: Oyun = _kurulu_oyun()
	var bolge: Bolge = oyun.dunya.bolgeler["TUR_1"]
	var normal: float = oyun.bolge_sanayisi(bolge, 1000)

	bolge.sahip = "FRA"
	bolge.isgal_saati = 1000
	var isgal_altinda: float = oyun.bolge_sanayisi(bolge, 1000 + 24)  # 1 gün sonra, hâlâ ceza içinde

	if not is_equal_approx(isgal_altinda, normal * 0.5):
		return "İşgal altındaki bölge yarım üretmeli: normal=%.3f, işgal=%.3f" % [normal, isgal_altinda]
	return ""


func sina_isgal_cezasi_suresi_dolunca_kalkar() -> String:
	var oyun: Oyun = _kurulu_oyun()
	var bolge: Bolge = oyun.dunya.bolgeler["TUR_1"]
	var normal: float = oyun.bolge_sanayisi(bolge, 0)

	bolge.sahip = "FRA"
	bolge.isgal_saati = 0
	var cok_sonra: float = oyun.bolge_sanayisi(bolge, 61 * 24)  # 60 günden fazla sonra

	if not is_equal_approx(cok_sonra, normal):
		return "60 günden uzun süre sonra ceza kalkmalı: normal=%.3f, geldi=%.3f" % [normal, cok_sonra]
	return ""


func sina_ev_sahibi_geri_alinca_ceza_olmaz() -> String:
	var oyun: Oyun = _kurulu_oyun()
	var bolge: Bolge = oyun.dunya.bolgeler["TUR_1"]
	var normal: float = oyun.bolge_sanayisi(bolge, 1000)

	# Bölge bir ara el değiştirmiş (isgal_saati yakın zamanda) ama şu an yine ev sahibinde.
	bolge.isgal_saati = 1000
	var geri_alindi: float = oyun.bolge_sanayisi(bolge, 1000 + 1)

	if not is_equal_approx(geri_alindi, normal):
		return "Ev sahibi kendi bölgesini tutarken ceza almamalı."
	return ""


func sina_ulkenin_geliri_bolgelerin_toplamidir() -> String:
	var oyun: Oyun = _kurulu_oyun()
	var toplam: float = 0.0
	for bolge: Bolge in oyun.dunya.ulkenin_bolgeleri("TUR"):
		toplam += oyun.bolge_sanayisi(bolge, 500)
	var gelir: float = oyun.ulkenin_geliri("TUR", 500)
	if not is_equal_approx(gelir, toplam):
		return "Ülke geliri bölgelerin sanayileri toplamına eşit olmalı: %.3f != %.3f" % [gelir, toplam]
	return ""


func sina_gun_basladi_hazineyi_artirir() -> String:
	var oyun: Oyun = _kurulu_oyun()
	var sinyal_sayisi: Array = [0]
	oyun.hazine_degisti.connect(func() -> void: sinyal_sayisi[0] += 1)

	if oyun.hazineler.get("TUR", 0.0) != 0.0:
		return "Oyun başında hazine 0 olmalı, sınama kurulamadı."
	oyun.gun_basladi(0)
	var bir_gun_sonra: float = oyun.hazineler.get("TUR", 0.0)
	if bir_gun_sonra <= 0.0:
		return "Bir gün sonra TUR'un hazinesi artmalı (pozitif gelir), geldi: %.3f" % bir_gun_sonra
	oyun.gun_basladi(24)
	var iki_gun_sonra: float = oyun.hazineler.get("TUR", 0.0)
	if iki_gun_sonra <= bir_gun_sonra:
		return "İki gün sonra hazine daha da artmalı."
	if sinyal_sayisi[0] != 2:
		return "hazine_degisti iki kez yayılmalı, geldi: %d" % sinyal_sayisi[0]
	return ""
