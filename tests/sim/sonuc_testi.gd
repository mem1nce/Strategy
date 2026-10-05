extends RefCounted
## Oyun.oyun_kazanildi/oyun_kaybedildi sinyallerini (zafer: kıtanın %60'ı, kaybetme:
## oyuncunun teslim olması) sınar.


func _kurulu_oyun() -> Oyun:
	var dunya: Dunya = Dunya.yukle()
	var oyun: Oyun = Oyun.new(dunya)
	oyun.oyuncuyu_sec("TUR")
	return oyun


func sina_oyuncu_teslim_olunca_kaybedildi_yayilir() -> String:
	var oyun: Oyun = _kurulu_oyun()
	var ulke: Ulke = oyun.dunya.ulkeler["TUR"]
	var galip: String = "FRA" if ulke.id != "FRA" else "DEU"
	var sinyal: Array = [false]
	oyun.oyun_kaybedildi.connect(func() -> void: sinyal[0] = true)

	var baskent: Bolge = oyun.dunya.bolgeler[ulke.baskent_bolgesi]
	var digerleri: Array[Bolge] = oyun.dunya.ulkenin_bolgeleri("TUR").filter(
			func(b: Bolge) -> bool: return b.id != baskent.id)
	@warning_ignore("integer_division")
	var kaybedilecek: int = ulke.baslangic_bolgeleri.size() - ulke.baslangic_bolgeleri.size() / 2
	for i: int in mini(kaybedilecek, digerleri.size()):
		oyun._bolgeyi_devret(digerleri[i], galip, 0)
	oyun._bolgeyi_devret(baskent, galip, 0)

	if not sinyal[0]:
		return "Oyuncu teslim olunca oyun_kaybedildi yayılmalıydı."
	return ""


func sina_baskasi_teslim_olunca_kaybedildi_yayilmaz() -> String:
	var oyun: Oyun = _kurulu_oyun()
	# TUR'a doğrudan komşu VE en az 2 başlangıç bölgesi olan (yoksa teslim koşulu
	# "0 bölge kalınca" gibi dejenere bir hâl alır) bir ülke aranır.
	var komsu: String = ""
	var ulke: Ulke = null
	for aday: Ulke in oyun.dunya.ulke_listesi:
		if aday.id != "TUR" and oyun.dunya.ulkeler_komsu_mu("TUR", aday.id) and aday.baslangic_bolgeleri.size() >= 2:
			komsu = aday.id
			ulke = aday
			break
	if komsu == "":
		return "TUR'un en az 2 bölgeli bir komşusu bulunamadı, sınama kurulamadı."
	var sinyal: Array = [false]
	oyun.oyun_kaybedildi.connect(func() -> void: sinyal[0] = true)

	var baskent: Bolge = oyun.dunya.bolgeler[ulke.baskent_bolgesi]
	var digerleri: Array[Bolge] = oyun.dunya.ulkenin_bolgeleri(komsu).filter(
			func(b: Bolge) -> bool: return b.id != baskent.id)
	@warning_ignore("integer_division")
	var kaybedilecek: int = ulke.baslangic_bolgeleri.size() - ulke.baslangic_bolgeleri.size() / 2
	for i: int in mini(kaybedilecek, digerleri.size()):
		oyun._bolgeyi_devret(digerleri[i], "TUR", 0)
	oyun._bolgeyi_devret(baskent, "TUR", 0)

	if sinyal[0]:
		return "Başka bir ülke teslim olunca oyuncu için oyun_kaybedildi yayılmamalıydı."
	return ""


func sina_kitanin_yuzde_60i_olunca_kazanildi_yayilir() -> String:
	var oyun: Oyun = _kurulu_oyun()
	var kita: String = oyun.dunya.ulkeler["TUR"].kita
	var sinyal: Array = [false]
	oyun.oyun_kazanildi.connect(func() -> void: sinyal[0] = true)

	var kita_bolgeleri: Array[Bolge] = []
	for bolge: Bolge in oyun.dunya.bolge_listesi:
		var ev_ulke: Ulke = oyun.dunya.ulkeler.get(bolge.id.split("_")[0])
		if ev_ulke != null and ev_ulke.kita == kita:
			kita_bolgeleri.append(bolge)
	if kita_bolgeleri.size() < 2:
		return "TUR'un kıtasında yeterli bölge yok, sınama kurulamadı."

	for bolge: Bolge in kita_bolgeleri:
		if sinyal[0]:
			break
		if bolge.sahip != "TUR":
			oyun._bolgeyi_devret(bolge, "TUR", 0)

	if not sinyal[0]:
		return "Kıtanın en az %%60'ı TUR'a geçince oyun_kazanildi yayılmalıydı."
	var sahip_olunan: int = 0
	for bolge: Bolge in kita_bolgeleri:
		if bolge.sahip == "TUR":
			sahip_olunan += 1
	var oran: float = float(sahip_olunan) / float(kita_bolgeleri.size())
	if oran < Oyun.ZAFER_ORANI:
		return "Sinyal geldiğinde oran zaten %%60 olmalıydı, geldi: %.3f" % oran
	return ""


func sina_zafer_bir_kez_yayilir() -> String:
	var oyun: Oyun = _kurulu_oyun()
	var kita: String = oyun.dunya.ulkeler["TUR"].kita
	var sayi: Array = [0]
	oyun.oyun_kazanildi.connect(func() -> void: sayi[0] += 1)

	var kita_bolgeleri: Array[Bolge] = []
	for bolge: Bolge in oyun.dunya.bolge_listesi:
		var ev_ulke: Ulke = oyun.dunya.ulkeler.get(bolge.id.split("_")[0])
		if ev_ulke != null and ev_ulke.kita == kita:
			kita_bolgeleri.append(bolge)
	for bolge: Bolge in kita_bolgeleri:
		if bolge.sahip != "TUR":
			oyun._bolgeyi_devret(bolge, "TUR", 0)

	if sayi[0] != 1:
		return "oyun_kazanildi tam olarak bir kez yayılmalı, geldi: %d" % sayi[0]
	return ""


func sina_oyuncu_secilmemisse_zafer_kontrolu_patlamaz() -> String:
	var dunya: Dunya = Dunya.yukle()
	var oyun: Oyun = Oyun.new(dunya)
	oyun._zaferi_kontrol_et()  # Hata fırlatmamalı.
	return ""
