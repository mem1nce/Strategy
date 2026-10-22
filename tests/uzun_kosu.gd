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
## Ekonomi ve ticaret paketi hedefleri: 5 yılda iflas eden ülke sayısı ve fiyatların taban
## fiyata göre sınırı (Piyasa zaten 0,5-3 kata sınırlar; burada doğrulanır).
const AZAMI_IFLAS: int = 10
const FIYAT_ALT_KATI: float = 0.5
const FIYAT_UST_KATI: float = 3.0
## Ticaret: ortalama bir ülkenin gelirinde ticaretin payı ve ülke başına anlaşma sayısı (5 yıl
## boyunca ayda bir ölçülen ortalamalar).
const ASGARI_TICARET_PAYI: float = 0.15
const AZAMI_TICARET_PAYI: float = 0.35
const ASGARI_ANLASMA: float = 2.0
const AZAMI_ANLASMA: float = 5.0


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
	# Üretim olaydan sayılır: kuyruk değiştiğinde, önceki öndeki iş süresini doldurduysa
	# tamamlanmıştır (her saat bütün kuyrukları gezmek koşuyu belirgin yavaşlatıyordu).
	var ondeki: Dictionary[String, InsaIsi] = {}
	oyun.insa_kuyrugu_degisti.connect(func(ulke_id: String) -> void:
		var onceki: InsaIsi = ondeki.get(ulke_id)
		if onceki != null and onceki.kalan_saat <= 0 and onceki.tur == InsaIsi.Tur.TUMEN:
			uretim[onceki.birlik_turu] += 1
		var kuyruk: Array = oyun.insa_kuyruklari.get(ulke_id, [])
		ondeki[ulke_id] = kuyruk[0] if not kuyruk.is_empty() else null)
	var en_buyuk_pay: float = 0.0
	var en_buyuk_ulke: String = ""
	var toplam_bolge: float = float(dunya.bolge_listesi.size())

	var iflas_edenler: Dictionary[String, bool] = {}
	var fiyat_alt: Dictionary[String, float] = {}
	var fiyat_ust: Dictionary[String, float] = {}
	var ticaret_paylari: Array[float] = []
	var anlasma_ortalamalari: Array[float] = []
	var son_saat: int = YIL * 365 * 24
	var olculen_surum: int = -1
	for saat: int in range(1, son_saat + 1):
		oyun.saat_ilerledi(saat)
		if saat % 24 == 0:
			oyun.gun_basladi(saat)
			for ulke_id: String in oyun.ekonomi.iflaslar:
				iflas_edenler[ulke_id] = true
			if saat % (30 * 24) == 0:
				_ticareti_olc(oyun, ticaret_paylari, anlasma_ortalamalari)
			for kaynak: String in Piyasa.KAYNAKLAR:
				var fiyat: float = oyun.ekonomi.piyasa.fiyatlar[kaynak] / oyun.ekonomi.piyasa.taban_fiyat[kaynak]
				fiyat_alt[kaynak] = minf(fiyat_alt.get(kaynak, fiyat), fiyat)
				fiyat_ust[kaynak] = maxf(fiyat_ust.get(kaynak, fiyat), fiyat)
			# Bölge payları yalnızca sahiplik değiştiyse yeniden sayılır.
			if Bolge.sahiplik_surumu == olculen_surum:
				continue
			olculen_surum = Bolge.sahiplik_surumu
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
	var iflas_tamam: bool = iflas_edenler.size() <= AZAMI_IFLAS
	basarili = basarili and iflas_tamam
	print("  %s İflas eden ülke: %d (hedef 0-%d) %s" % [_isaret(iflas_tamam), iflas_edenler.size(), AZAMI_IFLAS,
			", ".join(iflas_edenler.keys())])
	for kaynak: String in Piyasa.KAYNAKLAR:
		var fiyat_tamam: bool = fiyat_alt[kaynak] >= FIYAT_ALT_KATI - 0.001 and fiyat_ust[kaynak] <= FIYAT_UST_KATI + 0.001
		basarili = basarili and fiyat_tamam
		print("  %s %s fiyatı: taban fiyatın %.2f-%.2f katı (son %.2f; hedef %.1f-%.1f)" % [_isaret(fiyat_tamam),
				Piyasa.KAYNAK_ADLARI[kaynak], fiyat_alt[kaynak], fiyat_ust[kaynak],
				oyun.ekonomi.piyasa.fiyatlar[kaynak] / oyun.ekonomi.piyasa.taban_fiyat[kaynak], FIYAT_ALT_KATI, FIYAT_UST_KATI])
	var ticaret_payi: float = _ortalama(ticaret_paylari)
	var ticaret_tamam: bool = ticaret_payi >= ASGARI_TICARET_PAYI and ticaret_payi <= AZAMI_TICARET_PAYI
	basarili = basarili and ticaret_tamam
	print("  %s Ticaretin gelirdeki payı (ortalama ülke): %%%.1f (hedef %%%d-%%%d)" % [_isaret(ticaret_tamam),
			ticaret_payi * 100.0, roundi(ASGARI_TICARET_PAYI * 100.0), roundi(AZAMI_TICARET_PAYI * 100.0)])
	var anlasma_ortalamasi: float = _ortalama(anlasma_ortalamalari)
	var anlasma_tamam: bool = anlasma_ortalamasi >= ASGARI_ANLASMA and anlasma_ortalamasi <= AZAMI_ANLASMA
	basarili = basarili and anlasma_tamam
	print("  %s Ülke başına anlaşma: %.2f (hedef %.0f-%.0f; son %d anlaşma)" % [_isaret(anlasma_tamam),
			anlasma_ortalamasi, ASGARI_ANLASMA, AZAMI_ANLASMA, oyun.ticaret.anlasmalar.size()])
	var sure_tamam: bool = sure < AZAMI_SURE_SN
	basarili = basarili and sure_tamam
	print("  %s Süre: %.1f sn (hedef %d sn altı)" % [_isaret(sure_tamam), sure, roundi(AZAMI_SURE_SN)])
	quit(0 if basarili else 1)


## Ayda bir: var olan ülkelerin gelirinde ticaretin (anlaşmalar + geçiş ücretleri) ortalama
## payı ve ülke başına anlaşma sayısı.
static func _ticareti_olc(oyun: Oyun, paylar: Array[float], ortalamalar: Array[float]) -> void:
	var toplam_pay: float = 0.0
	var toplam_anlasma: int = 0
	var sayi: int = 0
	for ulke: Ulke in oyun.dunya.ulke_listesi:
		var kalem: Dictionary = oyun.ekonomi.kalemler.get(ulke.id, {})
		if kalem.is_empty() or oyun.dunya.ulkenin_bolge_sayisi(ulke.id) == 0:
			continue
		var gelir: float = oyun.ekonomi.gunluk_gelir(oyun, ulke.id)
		if gelir <= 0.0:
			continue
		toplam_pay += (float(kalem.get("ticaret", 0.0)) + float(kalem.get("gecis", 0.0))) / gelir
		toplam_anlasma += oyun.ticaret.anlasma_sayisi(ulke.id)
		sayi += 1
	if sayi > 0:
		paylar.append(toplam_pay / sayi)
		ortalamalar.append(float(toplam_anlasma) / sayi)


static func _ortalama(liste: Array[float]) -> float:
	var toplam: float = 0.0
	for deger: float in liste:
		toplam += deger
	return toplam / maxf(1.0, float(liste.size()))


static func _isaret(tamam: bool) -> String:
	return "[tamam]" if tamam else "[TUTMADI]"
