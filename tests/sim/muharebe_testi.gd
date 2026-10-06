extends RefCounted
## Oyun._muharebeyi_coz() üzerinden saatlik çarpışmayı, savunan avantajını, deniz cezasını
## ve geri çekilme/ele geçirmeyi sınar.


func _kurulu_oyun() -> Oyun:
	var dunya: Dunya = Dunya.yukle()
	return Oyun.new(dunya)


## TUR_1'de kurulu savunanları verilen güce ayarlar ve belirtilen güçte, verilen ülkeye ait
## tek bir saldırgan tümen ekler. Savaşı da ilan eder. Saldıran ülkenin id'sini döndürür.
func _carpismayi_kur(oyun: Oyun, savunan_guc: float, saldiran_guc: float, saldiran_deniz_mi: bool) -> String:
	var bolge_id: String = "TUR_1"
	var savunan_sahibi: String = oyun.dunya.bolgeler[bolge_id].sahip
	var saldiran_sahibi: String = "FRA" if savunan_sahibi != "FRA" else "DEU"
	oyun.savas_ilan_et(savunan_sahibi, saldiran_sahibi, 0)
	# Bölgede tek bir piyade savunan kalsın ki sonuç başlangıç ordusunun dağılımına bağlı olmasın.
	for birlik: Birlik in oyun.bolgedeki_birlikler(bolge_id):
		birlik.guc = 0.0
	oyun._olenleri_temizle(oyun.bolgedeki_birlikler(bolge_id))
	var savunan: Birlik = Birlik.new()
	savunan.sahip = savunan_sahibi
	savunan.bolge_id = bolge_id
	savunan.guc = savunan_guc
	oyun.birlikler.append(savunan)
	var saldiran: Birlik = Birlik.new()
	saldiran.sahip = saldiran_sahibi
	saldiran.bolge_id = bolge_id
	saldiran.guc = saldiran_guc
	saldiran.son_adim_deniz_mi = saldiran_deniz_mi
	oyun.birlikler.append(saldiran)
	return saldiran_sahibi


func sina_ezici_saldirgan_bolgeyi_alir() -> String:
	var oyun: Oyun = _kurulu_oyun()
	var bolge_id: String = "TUR_1"
	var savunan_sahibi: String = oyun.dunya.bolgeler[bolge_id].sahip
	var saldiran_sahibi: String = _carpismayi_kur(oyun, 5.0, 100.0, false)

	var tur: int = 0
	while oyun.dunya.bolgeler[bolge_id].sahip == savunan_sahibi and tur < 100:
		oyun.saat_ilerledi(tur)
		tur += 1
	if oyun.dunya.bolgeler[bolge_id].sahip != saldiran_sahibi:
		return "Ezici saldırgan karşısında bölge saldırgana geçmeliydi (sahip: %s)." % oyun.dunya.bolgeler[bolge_id].sahip
	return ""


func sina_savunan_avantajiyla_esit_guctekiler_arasinda_kazanir() -> String:
	var oyun: Oyun = _kurulu_oyun()
	var bolge_id: String = "TUR_1"
	var savunan_sahibi: String = oyun.dunya.bolgeler[bolge_id].sahip
	_carpismayi_kur(oyun, 100.0, 100.0, false)

	for tur: int in 2000:
		if oyun.dunya.bolgeler[bolge_id].sahip != savunan_sahibi:
			return "Savunan avantajıyla bölge saldırgana geçmemeliydi."
		if oyun.bolgedeki_birlikler(bolge_id).all(func(b: Birlik) -> bool: return b.sahip == savunan_sahibi):
			return ""  # Saldırgan tükendi ya da çekildi; bölgede yalnızca savunan kaldı.
		oyun.saat_ilerledi(tur)
	return "2000 saatte muharebe bir sonuca ulaşmadı (sonsuz döngü ya da aşırı yavaş)."


func sina_deniz_cezasi_saldirgani_zayiflatir() -> String:
	var kara_oyun: Oyun = _kurulu_oyun()
	var deniz_oyun: Oyun = _kurulu_oyun()
	var bolge_id: String = "TUR_1"
	var savunan_sahibi: String = kara_oyun.dunya.bolgeler[bolge_id].sahip

	_carpismayi_kur(kara_oyun, 50.0, 100.0, false)
	_carpismayi_kur(deniz_oyun, 50.0, 100.0, true)
	kara_oyun.saat_ilerledi(0)
	deniz_oyun.saat_ilerledi(0)

	var kara_savunan_guc: float = 0.0
	for birlik: Birlik in kara_oyun.bolgedeki_birlikler(bolge_id):
		if birlik.sahip == savunan_sahibi:
			kara_savunan_guc += birlik.guc
	var deniz_savunan_guc: float = 0.0
	for birlik: Birlik in deniz_oyun.bolgedeki_birlikler(bolge_id):
		if birlik.sahip == savunan_sahibi:
			deniz_savunan_guc += birlik.guc

	if deniz_savunan_guc <= kara_savunan_guc:
		return "Deniz cezalı saldırganın savunana verdiği hasar, karadan gelenden az olmalıydı."
	return ""


## Gerçek başlangıç ordusuyla (savaş yokken) 200 saat ilerletmek hatasız çalışmalı; yeni
## muharebe gruplama mantığının bütün dünyada (176 ülke, yüzlerce tümen) sorunsuz çalıştığını
## doğrular.
func sina_savas_yokken_saat_ilerledi_hatasiz_calisir() -> String:
	var oyun: Oyun = _kurulu_oyun()
	for saat: int in 200:
		oyun.saat_ilerledi(saat)
	return ""
