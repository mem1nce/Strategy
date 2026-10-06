extends SceneTree
## Uzun koşu (denge ölçümü): bütün ülkeleri yapay zekânın yönettiği bir oyunu 5 oyun yılı
## ilerletir ve denge hedeflerini raporlar. Sınama takımından (calistirici.gd) ayrıdır,
## çünkü bir dakikadan uzun sürer.
##
## Çalıştırmak için (proje klasöründen):
##   Godot --headless --path . --script res://tests/uzun_kosu.gd -- --tohum 1
##
## Hedefler (TASARIM.md, H) DENGE): 5 yılda 5-30 ülke teslim olur, hiçbir ülke dünyadaki
## bölgelerin %40'ını geçmez, üç tümen türünün her biri üretimin en az %15'i olur, koşu
## 120 saniyeden kısa sürer. Hedef tutmazsa çıkış kodu 1'dir.

const YIL: int = 5
const ASGARI_TESLIM: int = 5
const AZAMI_TESLIM: int = 30
const AZAMI_PAY: float = 0.40
const ASGARI_TUR_PAYI: float = 0.15
const AZAMI_SURE_SN: float = 120.0


func _init() -> void:
	var tohum: int = 1
	var argumanlar: PackedStringArray = OS.get_cmdline_user_args()
	var sira: int = argumanlar.find("--tohum")
	if sira != -1 and sira + 1 < argumanlar.size():
		tohum = int(argumanlar[sira + 1])

	var baslangic: int = Time.get_ticks_msec()
	var dunya: Dunya = Dunya.yukle()
	var oyun: Oyun = Oyun.new(dunya)
	oyun._rng.seed = tohum
	var teslimler: Array[String] = []
	oyun.ulke_teslim_oldu.connect(func(ulke_id: String, _galip: String) -> void: teslimler.append(ulke_id))

	var uretim: Dictionary[String, int] = {}
	for tur: String in BirlikTurleri.SIRA:
		uretim[tur] = 0
	var en_buyuk_pay: float = 0.0
	var en_buyuk_ulke: String = ""
	var toplam_bolge: float = float(dunya.bolge_listesi.size())

	var son_saat: int = YIL * 365 * 24
	for saat: int in range(1, son_saat + 1):
		# Bu saat bitecek tümen işleri, türüne göre sayılır.
		for kuyruk: Array in oyun.insa_kuyruklari.values():
			if not kuyruk.is_empty():
				var on: InsaIsi = kuyruk[0]
				if on.tur == InsaIsi.Tur.TUMEN and on.kalan_saat == 1:
					uretim[on.birlik_turu] += 1
		oyun.saat_ilerledi(saat)
		if saat % 24 == 0:
			oyun.gun_basladi(saat)
			var sayilar: Dictionary[String, int] = {}
			for bolge: Bolge in dunya.bolge_listesi:
				sayilar[bolge.sahip] = sayilar.get(bolge.sahip, 0) + 1
			for ulke_id: String in sayilar:
				var pay: float = sayilar[ulke_id] / toplam_bolge
				if pay > en_buyuk_pay:
					en_buyuk_pay = pay
					en_buyuk_ulke = ulke_id

	var sure: float = (Time.get_ticks_msec() - baslangic) / 1000.0
	var toplam_uretim: int = 0
	for tur: String in uretim:
		toplam_uretim += uretim[tur]

	var basarili: bool = true
	print("Uzun koşu (tohum %d, %d yıl, %.1f sn):" % [tohum, YIL, sure])
	var teslim_tamam: bool = teslimler.size() >= ASGARI_TESLIM and teslimler.size() <= AZAMI_TESLIM
	basarili = basarili and teslim_tamam
	print("  %s Teslim olan ülke: %d (hedef %d-%d) %s" % [_isaret(teslim_tamam), teslimler.size(),
			ASGARI_TESLIM, AZAMI_TESLIM, ", ".join(teslimler)])
	var pay_tamam: bool = en_buyuk_pay <= AZAMI_PAY
	basarili = basarili and pay_tamam
	print("  %s En büyük ülke: %s, bölgelerin %%%.1f'i (hedef en çok %%%d)" % [_isaret(pay_tamam),
			en_buyuk_ulke, en_buyuk_pay * 100.0, roundi(AZAMI_PAY * 100.0)])
	for tur: String in BirlikTurleri.SIRA:
		var pay: float = uretim[tur] / maxf(1.0, float(toplam_uretim))
		var tur_tamam: bool = pay >= ASGARI_TUR_PAYI
		basarili = basarili and tur_tamam
		print("  %s %s üretimi: %d (%%%.1f, hedef en az %%%d)" % [_isaret(tur_tamam), BirlikTurleri.ad(tur),
				uretim[tur], pay * 100.0, roundi(ASGARI_TUR_PAYI * 100.0)])
	var arastirilan: int = 0
	for ulke_id: String in oyun.teknolojiler:
		for dal: String in oyun.teknolojiler[ulke_id]:
			arastirilan += int(oyun.teknolojiler[ulke_id][dal])
	var tahkimatli: int = 0
	for bolge: Bolge in dunya.bolge_listesi:
		if bolge.tahkimat > 0:
			tahkimatli += 1
	print("  Bilgi: araştırılan toplam seviye %d, tahkimatlı bölge %d" % [arastirilan, tahkimatli])
	var sure_tamam: bool = sure < AZAMI_SURE_SN
	basarili = basarili and sure_tamam
	print("  %s Süre: %.1f sn (hedef %d sn altı)" % [_isaret(sure_tamam), sure, roundi(AZAMI_SURE_SN)])
	quit(0 if basarili else 1)


static func _isaret(tamam: bool) -> String:
	return "[tamam]" if tamam else "[TUTMADI]"
