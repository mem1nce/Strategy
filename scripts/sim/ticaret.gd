class_name Ticaret
extends RefCounted
## Limanlar, ticaret anlaşmaları, ticaret yolları, geçitler ve ambargolar (bkz. TASARIM.md
## 9b. Limanlar ve ticaret, 9c. Ticaret yolları ve geçitler). Sayılar data/balance.json →
## "ticaret"; deniz ağı, geçitler ve başlangıç limanları data/trade.json.
##
## Bir anlaşma iki ülke arasında bir ticaret yolu açar; iki taraf da her gün anlaşmanın
## değeri kadar gelir alır (geçtiği geçitlerin ücretleri düşülerek). Rota, iki ülkenin en iyi
## limanları (limanı yoksa başkentleri) arasında deniz ağı üzerinden bulunur (bkz. RotaAgi);
## yalnızca savaş, barış, anlaşma, ambargo ya da geçit/liman/başkent sahipliği değişince
## yeniden hesaplanır (o gün başında, bkz. gunu_isle). Oyun'a başvuru tutmaz (Oyun bunu
## tuttuğu için döngü olurdu); işlevler oyunu parametre alır.

const VERI_DOSYASI: String = "res://data/trade.json"
const DENGE_DOSYASI: String = "res://data/balance.json"

var deger_katsayisi: float = 0.1
var liman_bonusu: float = 0.1
var mesafe_olcegi: float = 2500.0
var kara_carpani: float = 3.0
var buz_carpani: float = 8.0
var gecis_ucreti: float = 0.05
var ortak_indirimi: float = 0.2
var taban_kapasite: int = 2
var azami_kapasite: int = 8
var baslangic_doluluk: float = 0.5
var komsu_onceligi: float = 1.5
var liman_taban_maliyeti: float = 150.0
var liman_suresi_saat: int = 480
var teklif_suresi_gun: int = 30
var yz_anlasma_olasiligi: float = 0.07
var yz_degisim_esigi: float = 1.2
## Yapay zekâ ortak ararken en büyük bu kadar ekonomiye ve kendi kara komşularına bakar.
var yz_aday_sayisi: int = 40
var yz_liman_olasiligi: float = 0.03
## Oyuncuya aynı anda en çok bu kadar teklif bekler; oyuncunun reddettiği (ya da yanıtsız bıraktığı)
## ülke bu kadar gün yeniden teklif etmez.
var yz_oyuncuya_azami_teklif: int = 2
var yz_ret_bekleme_gun: int = 90

var ag: RotaAgi = null
## Geçitler: {"id", "ad", "havzalar", "kontrol": Array[String] (bölgeler), "merkez": Vector2}.
var gecitler: Array[Dictionary] = []
var gecit_sozlugu: Dictionary[String, Dictionary] = {}
## Bölge id'si -> kontrol ettiği geçitler.
var gecit_bolgeleri: Dictionary[String, Array] = {}
## Geçit id'si -> geçitten geçen iki farklı bölge arasındaki deniz kenarları ([x, y]); askeri deniz
## hareketinde düşmanın tuttuğu geçidi kapatmak için (bkz. Oyun.birlikleri_yurut).
var gecit_kenarlari: Dictionary[String, Array] = {}
## Kıyı bölgeleri (deniz ağında düğümü olanlar) ve değdikleri deniz havzaları.
var kiyi_bolgeleri: Dictionary[String, bool] = {}
var bolge_havzalari: Dictionary[String, Array] = {}
## Liman adları (büyük limanlar; arayüzde gösterilir).
var liman_adlari: Dictionary[String, String] = {}
## Anlaşmalar: {"a", "b" (a < b), "deger": float, "rota": Dictionary (bkz. RotaAgi.rota_bul,
## boşsa yol kesik), "kirli": bool (rota yeniden hesaplanacak)}.
var anlasmalar: Array[Dictionary] = []
## "A>B": A, B'ye ambargo uyguluyor.
var ambargolar: Dictionary[String, bool] = {}
## Oyuncuya gelen ticaret teklifleri: {"kimden", "kime", "bitis_saati"}.
var teklifler: Array[Dictionary] = []
## Oyuncunun reddettiği ülke -> yeniden teklif edebileceği saat.
var reddedilenler: Dictionary[String, int] = {}
## Olayla kapanan geçitler: geçit id'si -> açılacağı saat.
var kapali_gecitler: Dictionary[String, int] = {}
## Ülke -> {"ticaret": anlaşmalardan net gelir, "gecis": aldığı geçiş ücretleri} (son gün).
var gunluk: Dictionary[String, Dictionary] = {}
## Geçit id'si -> son günkü toplam ücret (kontrol edenlere dağıtılan) ve geçen rota sayısı.
var gecit_geliri: Dictionary[String, float] = {}
var gecit_rota_sayisi: Dictionary[String, int] = {}
## Hızlandırma: anlaşmalar "a|b" anahtarıyla ve ülke başına sayıları; günlük ham sanayiler ve en
## iyi limanlar (gün başında ve sahiplik/liman değişince temizlenir).
var _dizin: Dictionary[String, Dictionary] = {}
## Ülke -> ortaklarının id'leri.
var _ortaklar: Dictionary[String, Array] = {}
var _sanayi_onbellegi: Dictionary = {}
var _liman_onbellegi: Dictionary[String, String] = {}
## Gün başında: ekonomisi en büyük `yz_aday_sayisi` ülke (yapay zekânın ortak adayları).
var _buyuk_ekonomiler: Array[String] = []
## Ülke -> kapasite (gün başında ve sahiplik/liman değişince temizlenir).
var _kapasite_onbellegi: Dictionary[String, int] = {}


func _init() -> void:
	var ayar: Dictionary = VeriOkuyucu.sozluk_oku(DENGE_DOSYASI).get("ticaret", {})
	deger_katsayisi = float(ayar.get("deger_katsayisi", deger_katsayisi))
	liman_bonusu = float(ayar.get("liman_bonusu", liman_bonusu))
	mesafe_olcegi = float(ayar.get("mesafe_olcegi", mesafe_olcegi))
	kara_carpani = float(ayar.get("kara_carpani", kara_carpani))
	buz_carpani = float(ayar.get("buzlu_deniz_carpani", buz_carpani))
	gecis_ucreti = float(ayar.get("gecis_ucreti", gecis_ucreti))
	ortak_indirimi = float(ayar.get("ortak_indirimi", ortak_indirimi))
	taban_kapasite = int(ayar.get("taban_kapasite", taban_kapasite))
	azami_kapasite = int(ayar.get("azami_kapasite", azami_kapasite))
	baslangic_doluluk = float(ayar.get("baslangic_doluluk", baslangic_doluluk))
	komsu_onceligi = float(ayar.get("komsu_onceligi", komsu_onceligi))
	liman_taban_maliyeti = float(ayar.get("liman_taban_maliyeti", liman_taban_maliyeti))
	liman_suresi_saat = int(ayar.get("liman_suresi_saat", liman_suresi_saat))
	teklif_suresi_gun = int(ayar.get("teklif_suresi_gun", teklif_suresi_gun))
	yz_anlasma_olasiligi = float(ayar.get("yz_anlasma_olasiligi", yz_anlasma_olasiligi))
	yz_degisim_esigi = float(ayar.get("yz_degisim_esigi", yz_degisim_esigi))
	yz_aday_sayisi = int(ayar.get("yz_aday_sayisi", yz_aday_sayisi))
	yz_liman_olasiligi = float(ayar.get("yz_liman_olasiligi", yz_liman_olasiligi))
	yz_oyuncuya_azami_teklif = int(ayar.get("yz_oyuncuya_azami_teklif", yz_oyuncuya_azami_teklif))
	yz_ret_bekleme_gun = int(ayar.get("yz_ret_bekleme_gun", yz_ret_bekleme_gun))


## Deniz ağını ve geçitleri kurar, başlangıç limanlarını bölgelere yazar ve başlangıç
## anlaşmalarını yapar.
func kur(oyun: Oyun) -> void:
	var veri: Dictionary = VeriOkuyucu.sozluk_oku(VERI_DOSYASI)
	ag = RotaAgi.kur(oyun.dunya, veri, kara_carpani, buz_carpani)
	for bolge_id: String in (veri.get("bolge_havzalari", {}) as Dictionary):
		kiyi_bolgeleri[bolge_id] = true
		bolge_havzalari[bolge_id] = veri["bolge_havzalari"][bolge_id]
	for g: Dictionary in (veri.get("gecitler", []) as Array):
		var kontrol: Array[String] = []
		for bolge_id: Variant in (g.get("kontrol", []) as Array):
			if oyun.dunya.bolgeler.has(str(bolge_id)):
				kontrol.append(str(bolge_id))
		var merkez: Array = g.get("merkez", [0.0, 0.0])
		var gecit: Dictionary = {"id": str(g["id"]), "ad": str(g["ad"]), "havzalar": g.get("havzalar", []),
			"kontrol": kontrol, "merkez": Vector2(float(merkez[0]), float(merkez[1]))}
		gecitler.append(gecit)
		gecit_sozlugu[gecit["id"]] = gecit
		for bolge_id: String in kontrol:
			if not gecit_bolgeleri.has(bolge_id):
				gecit_bolgeleri[bolge_id] = []
			gecit_bolgeleri[bolge_id].append(gecit["id"])
	for kenar: Array in (veri.get("deniz_kenarlari", []) as Array):
		var gecit_id: String = str(kenar[4])
		if gecit_id != "" and str(kenar[0]) != str(kenar[2]):
			if not gecit_kenarlari.has(gecit_id):
				gecit_kenarlari[gecit_id] = []
			gecit_kenarlari[gecit_id].append([str(kenar[0]), str(kenar[2])])
	var limanlar: Dictionary = veri.get("limanlar", {})
	for bolge_id: String in limanlar:
		var bolge: Bolge = oyun.dunya.bolgeler.get(bolge_id)
		if bolge != null:
			bolge.liman = clampi(int(limanlar[bolge_id]), 0, 3)
	for bolge_id: String in (veri.get("liman_adlari", {}) as Dictionary):
		liman_adlari[bolge_id] = str(veri["liman_adlari"][bolge_id])
	_baslangic_anlasmalari(oyun)


# --- Sorgular -------------------------------------------------------------------

## Ticaret kapasitesi: taban + elindeki limanların seviyeleri toplamının yarısı (en çok 8).
func kapasite(oyun: Oyun, ulke_id: String) -> int:
	if _kapasite_onbellegi.has(ulke_id):
		return _kapasite_onbellegi[ulke_id]
	var toplam: int = 0
	for bolge: Bolge in oyun.dunya.ulkenin_bolgeleri(ulke_id):
		toplam += bolge.liman
	@warning_ignore("integer_division")
	var sonuc: int = mini(azami_kapasite, taban_kapasite + toplam / 2)
	_kapasite_onbellegi[ulke_id] = sonuc
	return sonuc


func anlasma_sayisi(ulke_id: String) -> int:
	return (_ortaklar.get(ulke_id, []) as Array).size()


## Anlaşma listesine ekler / çıkarır ve dizinleri günceller (anlaşmalar yalnızca bunlarla değişir).
func _ekle(anlasma_: Dictionary) -> void:
	anlasmalar.append(anlasma_)
	_dizin["%s|%s" % [anlasma_["a"], anlasma_["b"]]] = anlasma_
	var a: String = anlasma_["a"]
	var b: String = anlasma_["b"]
	if not _ortaklar.has(a):
		_ortaklar[a] = []
	if not _ortaklar.has(b):
		_ortaklar[b] = []
	_ortaklar[a].append(b)
	_ortaklar[b].append(a)


func _cikar(anlasma_: Dictionary) -> void:
	if not _dizin.erase("%s|%s" % [anlasma_["a"], anlasma_["b"]]):
		return
	anlasmalar.erase(anlasma_)
	(_ortaklar.get(str(anlasma_["a"]), []) as Array).erase(str(anlasma_["b"]))
	(_ortaklar.get(str(anlasma_["b"]), []) as Array).erase(str(anlasma_["a"]))


## Günlük ham sanayiler (bkz. Piyasa._ham_sanayiler); gün başında yenilenir.
func gunluk_sanayiler(oyun: Oyun) -> Dictionary:
	if _sanayi_onbellegi.is_empty():
		_sanayi_onbellegi = Piyasa._ham_sanayiler(oyun, 0)
	return _sanayi_onbellegi


func ortaklar(ulke_id: String) -> Array[String]:
	var sonuc: Array[String] = []
	sonuc.assign(_ortaklar.get(ulke_id, []))
	return sonuc


func anlasma(ulke_a: String, ulke_b: String) -> Dictionary:
	return _dizin.get("%s|%s" % [mini_metin(ulke_a, ulke_b), maxi_metin(ulke_a, ulke_b)], {})


func ulkenin_anlasmalari(ulke_id: String) -> Array[Dictionary]:
	var sonuc: Array[Dictionary] = []
	for ortak: Variant in (_ortaklar.get(ulke_id, []) as Array):
		sonuc.append(anlasma(ulke_id, str(ortak)))
	return sonuc


## Ülkenin en iyi limanı (en yüksek seviyeli, eşitse en kalabalık kıyı bölgesi); limanı yoksa
## başkenti (elindeyse), o da yoksa ilk bölgesi.
func en_iyi_liman(oyun: Oyun, ulke_id: String) -> String:
	if _liman_onbellegi.has(ulke_id):
		return _liman_onbellegi[ulke_id]
	var sonuc: String = _en_iyi_limani_bul(oyun, ulke_id)
	_liman_onbellegi[ulke_id] = sonuc
	return sonuc


func _en_iyi_limani_bul(oyun: Oyun, ulke_id: String) -> String:
	var secilen: Bolge = null
	for bolge: Bolge in oyun.dunya.ulkenin_bolgeleri(ulke_id):
		if bolge.liman <= 0:
			continue
		if secilen == null or bolge.liman > secilen.liman or (bolge.liman == secilen.liman and bolge.nufus > secilen.nufus):
			secilen = bolge
	if secilen != null:
		return secilen.id
	var ulke: Ulke = oyun.dunya.ulkeler.get(ulke_id)
	if ulke != null and oyun.dunya.bolgeler.has(ulke.baskent_bolgesi) and oyun.dunya.bolgeler[ulke.baskent_bolgesi].sahip == ulke_id:
		return ulke.baskent_bolgesi
	var bolgeler: Array[Bolge] = oyun.dunya.ulkenin_bolgeleri(ulke_id)
	return bolgeler[0].id if not bolgeler.is_empty() else ""


func ambargo_uyguluyor_mu(uygulayan: String, hedef: String) -> bool:
	return ambargolar.has("%s>%s" % [uygulayan, hedef])


## İki ülke arasında ticaret yok mu? Savaş otomatik olarak ambargo sayılır.
func ambargoda_mi(oyun: Oyun, ulke_a: String, ulke_b: String) -> bool:
	return oyun.savasta_mi(ulke_a, ulke_b) or ambargo_uyguluyor_mu(ulke_a, ulke_b) or ambargo_uyguluyor_mu(ulke_b, ulke_a)


## Geçidi kontrol eden ülkeler (kontrol bölgelerinin o anki sahipleri, tekrarsız).
func gecit_sahipleri(oyun: Oyun, gecit_id: String) -> Array[String]:
	var sonuc: Array[String] = []
	for bolge_id: String in (gecit_sozlugu.get(gecit_id, {}) as Dictionary).get("kontrol", []):
		var sahip: String = oyun.dunya.bolgeler[bolge_id].sahip
		if not sonuc.has(sahip):
			sonuc.append(sahip)
	return sonuc


## İki taraf arasındaki bir rotaya kapalı geçitler: olayla kapanmış olanlar ve kontrol eden
## ülkelerden biri taraflardan biriyle savaşta ya da ambargodaysa.
func rotaya_kapali_gecitler(oyun: Oyun, ulke_a: String, ulke_b: String, su_anki_saat: int = -1) -> Array[String]:
	var sonuc: Array[String] = []
	for gecit: Dictionary in gecitler:
		var gecit_id: String = gecit["id"]
		if su_anki_saat >= 0 and int(kapali_gecitler.get(gecit_id, -1)) > su_anki_saat:
			sonuc.append(gecit_id)
			continue
		for sahip: String in gecit_sahipleri(oyun, gecit_id):
			if sahip == ulke_a or sahip == ulke_b:
				continue
			if ambargoda_mi(oyun, sahip, ulke_a) or ambargoda_mi(oyun, sahip, ulke_b):
				sonuc.append(gecit_id)
				break
	return sonuc


## Rotada kara yoluyla geçilebilecek bölgeler: tarafların bölgeleri; limanı (kıyısı) olmayan
## taraf için ayrıca barışta ve ambargosuz olduğu kara komşularının bölgeleri (oradan kıyıya ulaşır).
func _acik_bolgeler(oyun: Oyun, ulke_a: String, ulke_b: String) -> Array[String]:
	var sonuc: Array[String] = []
	for taraf: String in [ulke_a, ulke_b]:
		var kiyili: bool = false
		for bolge: Bolge in oyun.dunya.ulkenin_bolgeleri(taraf):
			sonuc.append(bolge.id)
			if kiyi_bolgeleri.has(bolge.id):
				kiyili = true
		if kiyili:
			continue
		for komsu: String in _kara_komsulari(oyun, taraf):
			if komsu == ulke_a or komsu == ulke_b or ambargoda_mi(oyun, komsu, ulke_a) or ambargoda_mi(oyun, komsu, ulke_b):
				continue
			for bolge: Bolge in oyun.dunya.ulkenin_bolgeleri(komsu):
				sonuc.append(bolge.id)
	return sonuc


func _kara_komsulari(oyun: Oyun, ulke_id: String) -> Array[String]:
	var sonuc: Array[String] = []
	for bolge: Bolge in oyun.dunya.ulkenin_bolgeleri(ulke_id):
		for komsu_id: String in bolge.kara_komsulari:
			var sahip: String = oyun.dunya.bolgeler[komsu_id].sahip
			if sahip != ulke_id and not sonuc.has(sahip):
				sonuc.append(sahip)
	return sonuc


## Anlaşmanın değeri: iki ekonominin (günlük ham sanayi) harmonik ortalaması × katsayı ×
## (1 + uçlardaki limanların seviyeleri × liman bonusu) / (1 + rota uzunluğu / mesafe ölçeği).
func deger_hesapla(oyun: Oyun, ulke_a: String, ulke_b: String, uzunluk: float, sanayiler: Dictionary) -> float:
	var ea: float = float(sanayiler.get(ulke_a, 0.0))
	var eb: float = float(sanayiler.get(ulke_b, 0.0))
	if ea <= 0.0 or eb <= 0.0:
		return 0.0
	var liman_a: int = _liman_seviyesi(oyun, en_iyi_liman(oyun, ulke_a))
	var liman_b: int = _liman_seviyesi(oyun, en_iyi_liman(oyun, ulke_b))
	return deger_katsayisi * 2.0 * ea * eb / (ea + eb) * (1.0 + liman_bonusu * (liman_a + liman_b)) \
			/ (1.0 + uzunluk / mesafe_olcegi)


func _liman_seviyesi(oyun: Oyun, bolge_id: String) -> int:
	var bolge: Bolge = oyun.dunya.bolgeler.get(bolge_id)
	return bolge.liman if bolge != null else 0


## Rota hesaplamadan değer tahmini (yapay zekânın aday seçimi için): uzunluk, en iyi limanlar
## arası düz uzaklığın 1,3 katı sayılır.
func deger_tahmini(oyun: Oyun, ulke_a: String, ulke_b: String, sanayiler: Dictionary) -> float:
	var a: Bolge = oyun.dunya.bolgeler.get(en_iyi_liman(oyun, ulke_a))
	var b: Bolge = oyun.dunya.bolgeler.get(en_iyi_liman(oyun, ulke_b))
	if a == null or b == null:
		return 0.0
	var ea: float = float(sanayiler.get(ulke_a, 0.0))
	var eb: float = float(sanayiler.get(ulke_b, 0.0))
	if ea <= 0.0 or eb <= 0.0:
		return 0.0
	return deger_katsayisi * 2.0 * ea * eb / (ea + eb) * (1.0 + liman_bonusu * (a.liman + b.liman)) \
			/ (1.0 + a.etiket.distance_to(b.etiket) * 1.3 / mesafe_olcegi)


## Anlaşmanın rotasını (yeniden) bulur.
func rota_hesapla(oyun: Oyun, anlasma_: Dictionary, su_anki_saat: int = -1) -> void:
	var a: String = anlasma_["a"]
	var b: String = anlasma_["b"]
	anlasma_["rota"] = ag.rota_bul(en_iyi_liman(oyun, a), en_iyi_liman(oyun, b), _acik_bolgeler(oyun, a, b),
			rotaya_kapali_gecitler(oyun, a, b, su_anki_saat))
	anlasma_["kirli"] = false


# --- Anlaşmalar -------------------------------------------------------------------

## Anlaşma yapılabilir mi: iki farklı, var olan ülke; ambargo ya da savaş yok; anlaşmaları yok;
## ikisinin de boş kapasitesi var.
func anlasma_yapilabilir_mi(oyun: Oyun, ulke_a: String, ulke_b: String) -> bool:
	if ulke_a == ulke_b or oyun.dunya.ulkenin_bolge_sayisi(ulke_a) == 0 or oyun.dunya.ulkenin_bolge_sayisi(ulke_b) == 0:
		return false
	if ambargoda_mi(oyun, ulke_a, ulke_b) or not anlasma(ulke_a, ulke_b).is_empty():
		return false
	return anlasma_sayisi(ulke_a) < kapasite(oyun, ulke_a) and anlasma_sayisi(ulke_b) < kapasite(oyun, ulke_b)


## Anlaşmayı yapar (koşulları denetler) ve rotasını hesaplar.
func anlasma_yap(oyun: Oyun, ulke_a: String, ulke_b: String, sanayiler: Dictionary = {}) -> bool:
	if not anlasma_yapilabilir_mi(oyun, ulke_a, ulke_b):
		return false
	var yeni: Dictionary = {"a": mini_metin(ulke_a, ulke_b), "b": maxi_metin(ulke_a, ulke_b), "deger": 0.0,
		"rota": {}, "kirli": true}
	rota_hesapla(oyun, yeni)
	if sanayiler.is_empty():
		sanayiler = gunluk_sanayiler(oyun)
	yeni["deger"] = _anlasma_degeri(oyun, yeni, sanayiler)
	_ekle(yeni)
	oyun.ticaret_degisti.emit()
	return true


static func mini_metin(a: String, b: String) -> String:
	return a if a < b else b


static func maxi_metin(a: String, b: String) -> String:
	return b if a < b else a


func _anlasma_degeri(oyun: Oyun, anlasma_: Dictionary, sanayiler: Dictionary) -> float:
	var rota: Dictionary = anlasma_["rota"]
	if rota.is_empty():
		return 0.0
	return deger_hesapla(oyun, anlasma_["a"], anlasma_["b"], float(rota.get("uzunluk", 0.0)), sanayiler)


func anlasmayi_bitir(oyun: Oyun, ulke_a: String, ulke_b: String) -> bool:
	var a: Dictionary = anlasma(ulke_a, ulke_b)
	if a.is_empty():
		return false
	_cikar(a)
	oyun.ticaret_degisti.emit()
	return true


## Ülkenin en zayıf (değeri en düşük) anlaşması; yoksa boş.
func en_zayif_anlasma(ulke_id: String) -> Dictionary:
	var secilen: Dictionary = {}
	for a: Dictionary in ulkenin_anlasmalari(ulke_id):
		if secilen.is_empty() or float(a["deger"]) < float(secilen["deger"]):
			secilen = a
	return secilen


## Yapay zekânın teklife yanıtı: teklif edenle savaşta ya da ambargodaysa reddeder; boş kapasitesi
## varsa ya da teklif en zayıf anlaşmasından değerliyse kabul eder (o zaman zayıfı bırakır).
## Kabul ederse anlaşmayı yapar ve true döner.
func teklifi_degerlendir(oyun: Oyun, kimden: String, kime: String, sanayiler: Dictionary = {}) -> bool:
	if kimden == kime or ambargoda_mi(oyun, kimden, kime) or not anlasma(kimden, kime).is_empty():
		return false
	if sanayiler.is_empty():
		sanayiler = gunluk_sanayiler(oyun)
	if anlasma_sayisi(kime) >= kapasite(oyun, kime):
		var zayif: Dictionary = en_zayif_anlasma(kime)
		if zayif.is_empty() or deger_tahmini(oyun, kimden, kime, sanayiler) <= float(zayif["deger"]):
			return false
		_cikar(zayif)
	if anlasma_sayisi(kimden) >= kapasite(oyun, kimden):
		var kendi_zayifi: Dictionary = en_zayif_anlasma(kimden)
		if kendi_zayifi.is_empty():
			return false
		_cikar(kendi_zayifi)
	return anlasma_yap(oyun, kimden, kime, sanayiler)


## Bir ülke başkasına teklif götürür. Hedef oyuncuysa teklif bekleyen tekliflere eklenir ve
## "teklif" döner; değilse yapay zekâ hemen yanıtlar ("kabul" ya da "red").
func teklif_et(oyun: Oyun, kimden: String, kime: String, su_anki_saat: int) -> String:
	if kime == oyun.oyuncu_ulkesi and not oyun.yz_oyuncuyu_yonetsin:
		for t: Dictionary in teklifler:
			if t["kimden"] == kimden and t["kime"] == kime:
				return "teklif"
		if ambargoda_mi(oyun, kimden, kime) or not anlasma(kimden, kime).is_empty():
			return "red"
		teklifler.append({"kimden": kimden, "kime": kime, "bitis_saati": su_anki_saat + teklif_suresi_gun * 24})
		oyun.ticaret_teklifi_geldi.emit(kimden)
		return "teklif"
	return "kabul" if teklifi_degerlendir(oyun, kimden, kime) else "red"


## Oyuncu bekleyen bir teklife yanıt verir. Kabul edip anlaşma yapılırsa true döner (oyuncunun
## kapasitesi doluysa en zayıf anlaşması bırakılır).
func teklifi_yanitla(oyun: Oyun, kimden: String, kabul: bool) -> bool:
	var bulunan: Dictionary = {}
	for t: Dictionary in teklifler:
		if t["kimden"] == kimden and t["kime"] == oyun.oyuncu_ulkesi:
			bulunan = t
			break
	if bulunan.is_empty():
		return false
	teklifler.erase(bulunan)
	if not kabul:
		reddedilenler[kimden] = int(bulunan["bitis_saati"]) + yz_ret_bekleme_gun * 24
		return false
	var oyuncu: String = oyun.oyuncu_ulkesi
	if ambargoda_mi(oyun, kimden, oyuncu):
		return false
	for taraf: String in [oyuncu, kimden]:
		if anlasma_sayisi(taraf) >= kapasite(oyun, taraf):
			var zayif: Dictionary = en_zayif_anlasma(taraf)
			if zayif.is_empty():
				return false
			_cikar(zayif)
	return anlasma_yap(oyun, kimden, oyuncu)


## Geçidi verilen saate kadar kapatır (olay: geçit kazası); bütün rotalar gün başında yeniden
## hesaplanır.
func gecidi_kapat(gecit_id: String, bitis_saati: int) -> void:
	kapali_gecitler[gecit_id] = bitis_saati
	for a: Dictionary in anlasmalar:
		a["kirli"] = true


## Ambargo uygular: o ülkeyle anlaşmalar biter, elindeki geçitler ona kapanır (rotalar yeniden
## hesaplanır).
func ambargo_uygula(oyun: Oyun, uygulayan: String, hedef: String) -> bool:
	if uygulayan == hedef or ambargo_uyguluyor_mu(uygulayan, hedef):
		return false
	ambargolar["%s>%s" % [uygulayan, hedef]] = true
	anlasmayi_bitir(oyun, uygulayan, hedef)
	iliskiler_degisti(uygulayan, hedef)
	oyun.ticaret_degisti.emit()
	return true


func ambargo_kaldir(oyun: Oyun, uygulayan: String, hedef: String) -> bool:
	if not ambargolar.erase("%s>%s" % [uygulayan, hedef]):
		return false
	iliskiler_degisti(uygulayan, hedef)
	oyun.ticaret_degisti.emit()
	return true


# --- Olaylar --------------------------------------------------------------------

## Savaş, barış ya da ambargo: iki ülkeyi ilgilendiren anlaşmaların rotaları (taraf, kara
## geçişi ya da geçidin sahibi olarak) ve kesik rotalar yeniden hesaplanacak.
func iliskiler_degisti(ulke_a: String, ulke_b: String) -> void:
	for a: Dictionary in anlasmalar:
		if _ilgili_mi(a, ulke_a) or _ilgili_mi(a, ulke_b) or (a["rota"] as Dictionary).is_empty():
			a["kirli"] = true


## Savaş çıkınca iki ülke arasındaki anlaşma biter (savaş ambargo sayılır).
func savas_basladi(oyun: Oyun, ulke_a: String, ulke_b: String) -> void:
	anlasmayi_bitir(oyun, ulke_a, ulke_b)
	teklifleri_temizle(ulke_a, ulke_b)
	iliskiler_degisti(ulke_a, ulke_b)


func teklifleri_temizle(ulke_a: String, ulke_b: String) -> void:
	for t: Dictionary in teklifler.duplicate():
		if (t["kimden"] == ulke_a and t["kime"] == ulke_b) or (t["kimden"] == ulke_b and t["kime"] == ulke_a):
			teklifler.erase(t)


## Bir bölgenin sahibi değişti: eski ve yeni sahibin anlaşmaları (en iyi limanı ya da başkenti
## değişmiş olabilir), bölgeden kara yoluyla geçen ve bölgenin kontrol ettiği geçitten geçen
## rotalar yeniden hesaplanacak.
##
## Bir ülkenin rotalarının ucu ancak bu bölge onun en iyi limanıysa ya da (yeni sahip için) şimdiki en
## iyi limanından daha iyi bir limansa değişir; o zaman o ülkenin bütün rotaları yeniden hesaplanır.
func bolge_degisti(oyun: Oyun, bolge_id: String, eski_sahip: String, yeni_sahip: String) -> void:
	var bolge: Bolge = oyun.dunya.bolgeler[bolge_id]
	var etkilenen: Array[String] = []
	if _liman_onbellegi.get(eski_sahip, "") == bolge_id or eski_sahip == yeni_sahip:
		etkilenen.append(eski_sahip)
	var yeninin_limani: Bolge = oyun.dunya.bolgeler.get(_liman_onbellegi.get(yeni_sahip, ""))
	if bolge.liman > 0 and (yeninin_limani == null or bolge.liman >= yeninin_limani.liman):
		etkilenen.append(yeni_sahip)
	var ulke: Ulke = oyun.dunya.ulkeler.get(eski_sahip)
	if ulke != null and ulke.baskent_bolgesi == bolge_id:
		etkilenen.append(eski_sahip)
		etkilenen.append(yeni_sahip)
	for taraf: String in etkilenen:
		_liman_onbellegi.erase(taraf)
	if bolge.liman > 0:
		_kapasite_onbellegi.erase(eski_sahip)
		_kapasite_onbellegi.erase(yeni_sahip)
	var gecitleri: Array = gecit_bolgeleri.get(bolge_id, [])
	for a: Dictionary in anlasmalar:
		if etkilenen.has(a["a"]) or etkilenen.has(a["b"]):
			a["kirli"] = true
			continue
		var rota: Dictionary = a["rota"]
		if (rota.get("kara_bolgeleri", []) as Array).has(bolge_id):
			a["kirli"] = true
			continue
		for gecit_id: String in gecitleri:
			if (rota.get("gecitler", []) as Array).has(gecit_id):
				a["kirli"] = true
				break


## Teslim olan ülkenin anlaşmaları ve ambargoları biter.
func ulke_yok_oldu(oyun: Oyun, ulke_id: String) -> void:
	for a: Dictionary in ulkenin_anlasmalari(ulke_id):
		_cikar(a)
	for anahtar: String in ambargolar.keys():
		if anahtar.begins_with(ulke_id + ">") or anahtar.ends_with(">" + ulke_id):
			ambargolar.erase(anahtar)
	for t: Dictionary in teklifler.duplicate():
		if t["kimden"] == ulke_id:
			teklifler.erase(t)
	oyun.ticaret_degisti.emit()


## Anlaşmanın taraflarından, kara yoluyla geçtiği ülkelerden ya da geçtiği geçitlerin
## sahiplerinden biri mi?
func _ilgili_mi(anlasma_: Dictionary, ulke_id: String) -> bool:
	if anlasma_["a"] == ulke_id or anlasma_["b"] == ulke_id:
		return true
	var rota: Dictionary = anlasma_["rota"]
	for bolge_id: String in (rota.get("kara_ulkeleri", []) as Array):
		if bolge_id == ulke_id:
			return true
	for gecit_id: String in (rota.get("gecitler", []) as Array):
		if (rota.get("gecit_sahipleri", {}) as Dictionary).get(gecit_id, []).has(ulke_id):
			return true
	return false


# --- Günlük -----------------------------------------------------------------------

## Her gün başında: kirli rotalar yeniden hesaplanır, anlaşmaların değeri ekonomilere göre
## güncellenir, ticaret gelirleri ve geçiş ücretleri dağıtılır, süresi dolan teklifler silinir.
## Ülke -> {"ticaret", "gecis"} döndürür. `carpan`, dünya olaylarının ticaret çarpanıdır.
func gunu_isle(oyun: Oyun, su_anki_saat: int, sanayiler: Dictionary, carpan: float = 1.0) -> Dictionary[String, Dictionary]:
	var sonuc: Dictionary[String, Dictionary] = {}
	_sanayi_onbellegi = sanayiler
	_liman_onbellegi = {}
	_kapasite_onbellegi = {}
	_buyuk_ekonomiler = []
	_siralanmis = []
	gecit_geliri = {}
	gecit_rota_sayisi = {}
	for gecit_id: String in kapali_gecitler.keys():
		if int(kapali_gecitler[gecit_id]) <= su_anki_saat:
			kapali_gecitler.erase(gecit_id)
			for a: Dictionary in anlasmalar:
				a["kirli"] = true
	for a: Dictionary in anlasmalar:
		if a["kirli"]:
			rota_hesapla(oyun, a, su_anki_saat)
			_rota_bilgisini_tamamla(oyun, a)
		a["deger"] = _anlasma_degeri(oyun, a, sanayiler)
		var deger: float = float(a["deger"]) * carpan
		var taraflar: Array[String] = [str(a["a"]), str(a["b"])]
		var odenen: float = 0.0
		for gecit_id: String in ((a["rota"] as Dictionary).get("gecitler", []) as Array):
			gecit_rota_sayisi[gecit_id] = gecit_rota_sayisi.get(gecit_id, 0) + 1
			var sahipler: Array[String] = gecit_sahipleri(oyun, gecit_id)
			if sahipler.has(taraflar[0]) or sahipler.has(taraflar[1]) or sahipler.is_empty():
				continue
			var ucret: float = deger * gecis_ucreti
			odenen += ucret
			gecit_geliri[gecit_id] = gecit_geliri.get(gecit_id, 0.0) + ucret
			for sahip: String in sahipler:
				var k: Dictionary = sonuc.get(sahip, {"ticaret": 0.0, "gecis": 0.0})
				k["gecis"] += ucret / sahipler.size()
				sonuc[sahip] = k
		for taraf: String in taraflar:
			var k: Dictionary = sonuc.get(taraf, {"ticaret": 0.0, "gecis": 0.0})
			k["ticaret"] += deger - odenen * 0.5
			sonuc[taraf] = k
	for t: Dictionary in teklifler.duplicate():
		if int(t["bitis_saati"]) <= su_anki_saat:
			teklifler.erase(t)
			reddedilenler[str(t["kimden"])] = su_anki_saat + yz_ret_bekleme_gun * 24
	gunluk = sonuc
	return sonuc


## Rotanın kara yoluyla geçtiği ülkeleri ve geçitlerinin o anki sahiplerini anlaşmaya yazar
## (hangi olayların rotayı etkilediğini bilmek için, bkz. _ilgili_mi).
func _rota_bilgisini_tamamla(oyun: Oyun, anlasma_: Dictionary) -> void:
	var rota: Dictionary = anlasma_["rota"]
	if rota.is_empty():
		return
	var kara_ulkeleri: Array[String] = []
	for bolge_id: String in (rota.get("kara_bolgeleri", []) as Array):
		var sahip: String = oyun.dunya.bolgeler[bolge_id].sahip
		if sahip != anlasma_["a"] and sahip != anlasma_["b"] and not kara_ulkeleri.has(sahip):
			kara_ulkeleri.append(sahip)
	rota["kara_ulkeleri"] = kara_ulkeleri
	var sahipler: Dictionary = {}
	for gecit_id: String in (rota.get("gecitler", []) as Array):
		sahipler[gecit_id] = gecit_sahipleri(oyun, gecit_id)
	rota["gecit_sahipleri"] = sahipler


## Ortaklarının bir kaynaktaki toplam fazlası (indirimli ithalat için; bkz. Piyasa).
func ortak_fazlasi(ulke_id: String, fazlalar: Dictionary) -> float:
	var toplam: float = 0.0
	for ortak: Variant in (_ortaklar.get(ulke_id, []) as Array):
		toplam += maxf(0.0, float(fazlalar.get(ortak, 0.0)))
	return toplam


# --- Başlangıç ve yapay zekâ ---------------------------------------------------------

## Oyun başında her ülke kapasitesinin yarısı (en az 1) kadar anlaşmayla başlar; büyük
## ekonomiler önce seçer, komşular ve değerli ortaklar öncelikli.
func _baslangic_anlasmalari(oyun: Oyun) -> void:
	var sanayiler: Dictionary = gunluk_sanayiler(oyun)
	var hedef: Dictionary[String, int] = {}
	var ulkeler: Array[String] = []
	for ulke: Ulke in oyun.dunya.ulke_listesi:
		if oyun.dunya.ulkenin_bolge_sayisi(ulke.id) == 0:
			continue
		hedef[ulke.id] = maxi(1, roundi(kapasite(oyun, ulke.id) * baslangic_doluluk))
		ulkeler.append(ulke.id)
	ulkeler.sort_custom(func(a: String, b: String) -> bool: return float(sanayiler.get(a, 0.0)) > float(sanayiler.get(b, 0.0)))
	for ulke_id: String in ulkeler:
		while anlasma_sayisi(ulke_id) < hedef[ulke_id]:
			var en_iyi: String = ""
			var en_iyi_puan: float = 0.0
			for diger: String in ulkeler:
				if diger == ulke_id or anlasma_sayisi(diger) >= hedef[diger] or not anlasma(ulke_id, diger).is_empty():
					continue
				var puan: float = deger_tahmini(oyun, ulke_id, diger, sanayiler)
				if oyun.dunya.ulkeler_komsu_mu(ulke_id, diger):
					puan *= komsu_onceligi
				if puan > en_iyi_puan:
					en_iyi_puan = puan
					en_iyi = diger
			if en_iyi == "" or not anlasma_yap(oyun, ulke_id, en_iyi, sanayiler):
				break
	for a: Dictionary in anlasmalar:
		_rota_bilgisini_tamamla(oyun, a)


## Yapay zekânın günlük ticaret kararı (ara sıra): boş kapasitesi varsa en değerli adaya,
## yoksa en zayıf anlaşmasından belirgin değerli bir adaya teklif götürür; kapasitesi doluysa
## ve daha iyi adaylar varsa ara sıra liman geliştirir.
func yz_dusun(oyun: Oyun, ulke_id: String, su_anki_saat: int, zar: float, liman_zari: float) -> void:
	if zar >= yz_anlasma_olasiligi:
		return
	_yz_ara(oyun, ulke_id, su_anki_saat, liman_zari)


func _yz_ara(oyun: Oyun, ulke_id: String, su_anki_saat: int, liman_zari: float) -> void:
	var sanayiler: Dictionary = gunluk_sanayiler(oyun)
	# Kapasitesi dolu ve en zayıf anlaşması bile olası en iyi tekliften (üst sınır) değerliyse
	# aramaya gerek yok; yalnızca liman geliştirmeyi düşünür.
	var dolu: bool = anlasma_sayisi(ulke_id) >= kapasite(oyun, ulke_id)
	if dolu:
		var zayifi: Dictionary = en_zayif_anlasma(ulke_id)
		var tavan: float = deger_katsayisi * 2.0 * float(sanayiler.get(ulke_id, 0.0)) * (1.0 + liman_bonusu * 6.0)
		if not zayifi.is_empty() and float(zayifi["deger"]) * yz_degisim_esigi >= tavan:
			_liman_dusun(oyun, ulke_id, liman_zari)
			return
	if _buyuk_ekonomiler.is_empty():
		_buyuk_ekonomiler = _siralanmis_ekonomiler(sanayiler).slice(0, yz_aday_sayisi)
	# Adaylar: en büyük ekonomiler, kara komşuları ve boş kapasitesi olan her ülke; büyükten
	# küçüğe bakılır. Değeri en iyi adayı geçemeyecek (üst sınırı küçük) aday hesaplanmaz.
	var komsular: Array[String] = _kara_komsulari(oyun, ulke_id)
	var siralanmis: Array[String] = _siralanmis_ekonomiler(sanayiler)
	var kendi: float = float(sanayiler.get(ulke_id, 0.0))
	var kendi_limani: Bolge = oyun.dunya.bolgeler.get(en_iyi_liman(oyun, ulke_id))
	# Harmonik ortalama küçük ekonominin iki katını, liman çarpanı (kendi limanı + 3) sınırını geçemez.
	var liman_tavani: float = 1.0 + liman_bonusu * ((kendi_limani.liman if kendi_limani != null else 0) + 3)
	var ortaklari: Array = _ortaklar.get(ulke_id, [])
	var en_iyi: String = ""
	var en_iyi_deger: float = 0.0
	var degerlendirilen: int = 0
	for sira: int in siralanmis.size():
		var diger: String = siralanmis[sira]
		var diger_sanayi: float = float(sanayiler.get(diger, 0.0))
		var ust_sinir: float = deger_katsayisi * 2.0 * minf(kendi, diger_sanayi) * liman_tavani
		if ust_sinir <= en_iyi_deger:
			# Sıra ilerledikçe ekonomiler küçülür; kendisinden küçüklere gelince üst sınır hep düşer.
			if diger_sanayi <= kendi:
				break
			continue
		var bos: bool = anlasma_sayisi(diger) < kapasite(oyun, diger)
		if sira >= yz_aday_sayisi and not bos and not komsular.has(diger):
			continue
		if diger == ulke_id or ortaklari.has(diger):
			continue
		if diger == oyun.oyuncu_ulkesi and not oyun.yz_oyuncuyu_yonetsin \
				and not _oyuncuya_teklif_edilebilir(ulke_id, su_anki_saat):
			continue
		# Dolu bir ülke, en zayıf anlaşmasından değerli olmayan bir teklifi kabul etmez.
		var onun_zayifi: float = 0.0
		if not bos:
			var zayif_anlasma: Dictionary = en_zayif_anlasma(diger)
			if zayif_anlasma.is_empty():
				continue
			onun_zayifi = float(zayif_anlasma["deger"])
			if ust_sinir <= onun_zayifi:
				continue
		if oyun.dunya.ulkenin_bolge_sayisi(diger) == 0 or oyun.savasta_mi(ulke_id, diger) \
				or (not ambargolar.is_empty() and ambargoda_mi(oyun, ulke_id, diger)):
			continue
		# Uygun adaylardan en çok yz_aday_sayisi kadarı tahmin edilir (büyükten küçüğe sıralı).
		degerlendirilen += 1
		if degerlendirilen > yz_aday_sayisi:
			break
		var deger: float = deger_tahmini(oyun, ulke_id, diger, sanayiler)
		if deger <= en_iyi_deger or (not bos and deger <= onun_zayifi):
			continue
		en_iyi_deger = deger
		en_iyi = diger
	if en_iyi == "":
		return
	if anlasma_sayisi(ulke_id) < kapasite(oyun, ulke_id):
		teklif_et(oyun, ulke_id, en_iyi, su_anki_saat)
		return
	var zayif: Dictionary = en_zayif_anlasma(ulke_id)
	if not zayif.is_empty() and en_iyi_deger > float(zayif["deger"]) * yz_degisim_esigi:
		teklif_et(oyun, ulke_id, en_iyi, su_anki_saat)
	else:
		_liman_dusun(oyun, ulke_id, liman_zari)


## Oyuncuya yeni teklif: bekleyen teklif sayısı sınırın altındaysa, bu ülkenin bekleyen teklifi
## yoksa ve oyuncu onu yakın zamanda reddetmediyse.
func _oyuncuya_teklif_edilebilir(ulke_id: String, su_anki_saat: int) -> bool:
	if int(reddedilenler.get(ulke_id, -1)) > su_anki_saat:
		return false
	var sayi: int = 0
	for t: Dictionary in teklifler:
		if t["kimden"] == ulke_id:
			return false
		sayi += 1
	return sayi < yz_oyuncuya_azami_teklif


## Kapasitesi dolu ülke ara sıra limanını geliştirir (kapasite ve anlaşma değeri artar).
func _liman_dusun(oyun: Oyun, ulke_id: String, liman_zari: float) -> void:
	if liman_zari < yz_liman_olasiligi / yz_anlasma_olasiligi and kapasite(oyun, ulke_id) < azami_kapasite:
		var bolge: String = liman_gelistirilecek_bolge(oyun, ulke_id)
		if bolge != "":
			oyun.liman_sirala(ulke_id, bolge)


## Ülkenin liman geliştirebileceği (kıyı, seviyesi 3'ten az, kuyrukta liman işi olmayan) en iyi
## bölgesi: en yüksek limanlı, eşitse en kalabalık.
func liman_gelistirilecek_bolge(oyun: Oyun, ulke_id: String) -> String:
	var secilen: Bolge = null
	for bolge: Bolge in oyun.dunya.ulkenin_bolgeleri(ulke_id):
		if not kiyi_bolgeleri.has(bolge.id) or oyun.sonraki_liman_seviyesi(ulke_id, bolge.id) == 0:
			continue
		if secilen == null or bolge.liman > secilen.liman or (bolge.liman == secilen.liman and bolge.nufus > secilen.nufus):
			secilen = bolge
	return secilen.id if secilen != null else ""


## Ülkeler, ham sanayisi büyükten küçüğe (gün başında bir kez sıralanır).
var _siralanmis: Array[String] = []


func _siralanmis_ekonomiler(sanayiler: Dictionary) -> Array[String]:
	if _siralanmis.is_empty():
		_siralanmis.assign(sanayiler.keys())
		_siralanmis.sort_custom(func(a: String, b: String) -> bool: return float(sanayiler[a]) > float(sanayiler[b]))
	return _siralanmis


## Liman seviyesine yükseltmenin maliyeti.
func liman_maliyeti(seviye: int) -> float:
	return liman_taban_maliyeti * seviye


# --- Kayıt ---------------------------------------------------------------------------

func kayit_verisi(oyun: Oyun) -> Dictionary:
	var anlasma_verisi: Array = []
	for a: Dictionary in anlasmalar:
		anlasma_verisi.append([a["a"], a["b"]])
	var limanlar: Dictionary = {}
	for bolge: Bolge in oyun.dunya.bolge_listesi:
		if bolge.liman > 0:
			limanlar[bolge.id] = bolge.liman
	return {"anlasmalar": anlasma_verisi, "ambargolar": ambargolar.keys(), "teklifler": teklifler,
		"reddedilenler": reddedilenler, "kapali_gecitler": kapali_gecitler, "limanlar": limanlar}


## Kayıttaki anlaşmaları, ambargoları, teklifleri ve limanları uygular. Eski kayıtta ticaret yoksa
## (veri boş) başlangıç anlaşmaları ve limanları olduğu gibi kalır.
func kayittan_yukle(oyun: Oyun, veri: Dictionary) -> void:
	if veri.is_empty():
		for a: Dictionary in anlasmalar:
			a["kirli"] = true
		return
	var limanlar: Dictionary = veri.get("limanlar", {})
	for bolge: Bolge in oyun.dunya.bolge_listesi:
		bolge.liman = clampi(int(limanlar.get(bolge.id, 0)), 0, 3)
	anlasmalar = []
	_dizin = {}
	_ortaklar = {}
	_liman_onbellegi = {}
	for cift: Array in (veri.get("anlasmalar", []) as Array):
		if cift.size() == 2 and str(cift[0]) != str(cift[1]):
			_ekle({"a": mini_metin(str(cift[0]), str(cift[1])), "b": maxi_metin(str(cift[0]), str(cift[1])),
				"deger": 0.0, "rota": {}, "kirli": true})
	ambargolar = {}
	for anahtar: Variant in (veri.get("ambargolar", []) as Array):
		ambargolar[str(anahtar)] = true
	teklifler = []
	for t: Dictionary in (veri.get("teklifler", []) as Array):
		teklifler.append({"kimden": str(t.get("kimden", "")), "kime": str(t.get("kime", "")),
			"bitis_saati": int(t.get("bitis_saati", 0))})
	reddedilenler = {}
	var retler: Dictionary = veri.get("reddedilenler", {})
	for ulke_id: String in retler:
		reddedilenler[ulke_id] = int(retler[ulke_id])
	kapali_gecitler = {}
	var kapali: Dictionary = veri.get("kapali_gecitler", {})
	for gecit_id: String in kapali:
		kapali_gecitler[gecit_id] = int(kapali[gecit_id])
	_sanayi_onbellegi = {}
	var sanayiler: Dictionary = gunluk_sanayiler(oyun)
	for a: Dictionary in anlasmalar:
		rota_hesapla(oyun, a)
		_rota_bilgisini_tamamla(oyun, a)
		a["deger"] = _anlasma_degeri(oyun, a, sanayiler)
