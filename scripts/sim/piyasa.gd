class_name Piyasa
extends RefCounted
## İki stratejik kaynağın (petrol ve maden) üretimi, tüketimi ve dünya piyasası (bkz.
## TASARIM.md 9a. Kaynaklar ve dünya piyasası). Sayılar data/balance.json → "piyasa",
## bölge üretimleri data/resources.json (tools/kaynak_uret.py).
##
## Her oyun günü: her ülkenin üretimi (elindeki bölgelerin; muharebe ve yeni işgal üretimi
## düşürür) ve tüketimi (petrol: sanayi ve zırhlılar; maden: süren inşaat) hesaplanır. Fazla
## dünya fiyatından kendiliğinden satılır, açık kendiliğinden alınır; piyasaya erişimi yoksa
## ya da iflastaysa açık kalır. Kalan açık oranı ertesi güne etki eder: petrol açığı sanayi
## gelirini ve zırhlı gücünü, maden açığı inşaat hızını düşürür. Dünya fiyatı arz ve talebin
## oranına göre her gün yumuşakça değişir.

const KAYNAK_DOSYASI: String = "res://data/resources.json"
const DENGE_DOSYASI: String = "res://data/balance.json"
const KAYNAKLAR: Array[String] = ["petrol", "maden"]
const KAYNAK_ADLARI: Dictionary[String, String] = {"petrol": "Petrol", "maden": "Maden"}
## İnşa işi türü -> maden tüketimindeki adı.
const IS_ADLARI: Dictionary[int, String] = {
	InsaIsi.Tur.TUMEN: "tumen", InsaIsi.Tur.FABRIKA: "fabrika", InsaIsi.Tur.TAHKIMAT: "tahkimat",
	InsaIsi.Tur.LIMAN: "liman",
}

var taban_fiyat: Dictionary[String, float] = {"petrol": 1.0, "maden": 1.0}
var sanayi_basina_petrol: float = 0.09
var zirhli_basina_petrol: float = 0.05
var insaat_basina_maden: Dictionary = {"tumen": 1.0, "fabrika": 3.0, "tahkimat": 2.0, "liman": 2.0}
var baslangic_arz_orani: float = 1.05
var maden_beklenen_insaat_orani: float = 0.8
var fiyat_esnekligi: float = 4.0
var fiyat_yumusatma: float = 0.06
## Uzun vadede arz talebe uyar: fiyatın tepki verdiği referans talep/arz oranı her gün
## gerçek orana bu kadar yaklaşır. Savaş gibi ani şoklar fiyatı yine oynatır ama talep yavaşça
## büyüdü diye fiyat hep tırmanmaz.
var arz_uyum_hizi: float = 0.005
var fiyat_alt_kati: float = 0.5
var fiyat_ust_kati: float = 3.0
var muharebe_uretim_carpani: float = 0.2
var isgal_uretim_carpani: float = 0.4
var petrol_acigi_sanayi_etkisi: float = 0.5
var petrol_acigi_zirhli_etkisi: float = 0.5
var maden_acigi_insaat_etkisi: float = 1.0
var asgari_insaat_hizi: float = 0.25
var yz_petrol_acigi_zirhli_esigi: float = 0.2
var yz_petrol_acigi_zirhli_carpani: float = 0.3

## Kaynak -> bölge id'si -> günlük üretim (ölçeklenmiş). Bölge el değiştirince üretimi yeni
## sahibinindir.
var bolge_uretimi: Dictionary[String, Dictionary] = {}
## Kaynak -> dünya fiyatı ve bir önceki günün fiyatı (eğilim oku için).
var fiyatlar: Dictionary[String, float] = {}
var onceki_fiyatlar: Dictionary[String, float] = {}
## Kaynak -> başlangıçtaki talep / arz oranı; fiyat bu orandan sapmaya tepki verir.
var _referans_oran: Dictionary[String, float] = {}
## Ülke -> kaynak -> {"uretim", "talep", "ithal", "ihrac", "acik"} (son gün; açık = karşılanamayan
## miktar, `acik_orani` = açık / talep).
var durum: Dictionary[String, Dictionary] = {}
## Kaynak -> son günün dünya arzı ve talebi.
var dunya_arzi: Dictionary[String, float] = {}
var dunya_talebi: Dictionary[String, float] = {}


func _init() -> void:
	var ayar: Dictionary = VeriOkuyucu.sozluk_oku(DENGE_DOSYASI).get("piyasa", {})
	var fiyat: Dictionary = ayar.get("taban_fiyat", {})
	for kaynak: String in KAYNAKLAR:
		taban_fiyat[kaynak] = float(fiyat.get(kaynak, 1.0))
	sanayi_basina_petrol = float(ayar.get("sanayi_basina_petrol", sanayi_basina_petrol))
	zirhli_basina_petrol = float(ayar.get("zirhli_basina_petrol", zirhli_basina_petrol))
	insaat_basina_maden = ayar.get("insaat_basina_maden", insaat_basina_maden)
	baslangic_arz_orani = float(ayar.get("baslangic_arz_orani", baslangic_arz_orani))
	maden_beklenen_insaat_orani = float(ayar.get("maden_beklenen_insaat_orani", maden_beklenen_insaat_orani))
	fiyat_esnekligi = float(ayar.get("fiyat_esnekligi", fiyat_esnekligi))
	fiyat_yumusatma = float(ayar.get("fiyat_yumusatma", fiyat_yumusatma))
	arz_uyum_hizi = float(ayar.get("arz_uyum_hizi", arz_uyum_hizi))
	fiyat_alt_kati = float(ayar.get("fiyat_alt_kati", fiyat_alt_kati))
	fiyat_ust_kati = float(ayar.get("fiyat_ust_kati", fiyat_ust_kati))
	muharebe_uretim_carpani = float(ayar.get("muharebe_uretim_carpani", muharebe_uretim_carpani))
	isgal_uretim_carpani = float(ayar.get("isgal_uretim_carpani", isgal_uretim_carpani))
	petrol_acigi_sanayi_etkisi = float(ayar.get("petrol_acigi_sanayi_etkisi", petrol_acigi_sanayi_etkisi))
	petrol_acigi_zirhli_etkisi = float(ayar.get("petrol_acigi_zirhli_etkisi", petrol_acigi_zirhli_etkisi))
	maden_acigi_insaat_etkisi = float(ayar.get("maden_acigi_insaat_etkisi", maden_acigi_insaat_etkisi))
	asgari_insaat_hizi = float(ayar.get("asgari_insaat_hizi", asgari_insaat_hizi))
	yz_petrol_acigi_zirhli_esigi = float(ayar.get("yz_petrol_acigi_zirhli_esigi", yz_petrol_acigi_zirhli_esigi))
	yz_petrol_acigi_zirhli_carpani = float(ayar.get("yz_petrol_acigi_zirhli_carpani", yz_petrol_acigi_zirhli_carpani))


## Bölge üretimlerini okur ve dünya üretimini başlangıç talebinin `baslangic_arz_orani`
## (×1,05) katına ölçekler. Maden talebi oyun başında henüz yoktur (kuyruklar boş); her
## ülkenin `maden_beklenen_insaat_orani` olasılıkla bir tümen kurduğu varsayılır.
func kur(oyun: Oyun) -> void:
	var veri: Dictionary = VeriOkuyucu.sozluk_oku(KAYNAK_DOSYASI)
	var sanayiler: Dictionary[String, float] = _ham_sanayiler(oyun, 0)
	for kaynak: String in KAYNAKLAR:
		var ham: Dictionary = veri.get(kaynak, {})
		var ham_toplam: float = 0.0
		for bolge_id: String in ham:
			if oyun.dunya.bolgeler.has(bolge_id):
				ham_toplam += float(ham[bolge_id])
		var talep: float = 0.0
		if kaynak == "petrol":
			for ulke_id: String in sanayiler:
				talep += sanayiler[ulke_id] * sanayi_basina_petrol
			for birlik: Birlik in oyun.birlikler:
				if birlik.tur == "zirhli":
					talep += zirhli_basina_petrol
		else:
			talep = oyun.dunya.ulke_listesi.size() * maden_beklenen_insaat_orani * float(insaat_basina_maden.get("tumen", 1.0))
		var olcek: float = baslangic_arz_orani * talep / maxf(ham_toplam, 0.001)
		var uretim: Dictionary = {}
		for bolge_id: String in ham:
			if oyun.dunya.bolgeler.has(bolge_id):
				uretim[bolge_id] = float(ham[bolge_id]) * olcek
		bolge_uretimi[kaynak] = uretim
		fiyatlar[kaynak] = taban_fiyat[kaynak]
		onceki_fiyatlar[kaynak] = taban_fiyat[kaynak]
		_referans_oran[kaynak] = 1.0 / baslangic_arz_orani


## Ülke -> elindeki bölgelerin (bonussuz, teknolojisiz) sanayi toplamı.
static func _ham_sanayiler(oyun: Oyun, su_anki_saat: int) -> Dictionary[String, float]:
	var sonuc: Dictionary[String, float] = {}
	for bolge: Bolge in oyun.dunya.bolge_listesi:
		sonuc[bolge.sahip] = sonuc.get(bolge.sahip, 0.0) + oyun.bolge_sanayisi(bolge, su_anki_saat)
	return sonuc


## Bir bölgenin bugünkü üretimi: muharebe süren bölgede ×0,2, yeni işgal edilmişte ×0,4.
func bolgenin_uretimi(oyun: Oyun, bolge: Bolge, kaynak: String, su_anki_saat: int) -> float:
	var miktar: float = float((bolge_uretimi.get(kaynak, {}) as Dictionary).get(bolge.id, 0.0))
	if miktar <= 0.0:
		return 0.0
	if oyun._onceki_cekismeliler.has(bolge.id):
		miktar *= muharebe_uretim_carpani
	elif oyun.bolge_isgal_altinda_mi(bolge, su_anki_saat):
		miktar *= isgal_uretim_carpani
	return miktar


## Kıyılı ülkeler ve ülkelerin kara komşuları; yalnızca bölge sahiplikleri değişince yeniden
## hesaplanır (bkz. Bolge.sahiplik_surumu).
var _kiyili: Dictionary[String, bool] = {}
var _komsular: Dictionary[String, Dictionary] = {}
var _komsu_surumu: int = -1
## Kara komşusu bölge çiftleri (her çift bir kez, düz dizi: a0, b0, a1, b1, …) ve kıyı bölgeleri;
## komşuluk değişmediği için bir kez kurulur.
var _sinir_ciftleri: Array[Bolge] = []
var _kiyi_bolgeleri: Array[Bolge] = []


## Ülkelerin piyasaya erişimi: kıyısı olan ya da barışta (ambargosuz) olduğu kara komşusunun
## kıyısı olan ülke. Ülke id'si -> true.
func erisimler(oyun: Oyun) -> Dictionary[String, bool]:
	if _komsu_surumu != Bolge.sahiplik_surumu:
		_komsu_surumu = Bolge.sahiplik_surumu
		if _sinir_ciftleri.is_empty():
			for bolge: Bolge in oyun.dunya.bolge_listesi:
				if bolge.kiyi:
					_kiyi_bolgeleri.append(bolge)
				for komsu_id: String in bolge.kara_komsulari:
					if bolge.id < komsu_id:
						_sinir_ciftleri.append(bolge)
						_sinir_ciftleri.append(oyun.dunya.bolgeler[komsu_id])
		_kiyili = {}
		_komsular = {}
		for bolge: Bolge in _kiyi_bolgeleri:
			_kiyili[bolge.sahip] = true
		for i: int in range(0, _sinir_ciftleri.size(), 2):
			var a: String = _sinir_ciftleri[i].sahip
			var b: String = _sinir_ciftleri[i + 1].sahip
			if a != b:
				(_komsular.get_or_add(a, {}) as Dictionary)[b] = true
				(_komsular.get_or_add(b, {}) as Dictionary)[a] = true
	var kiyili: Dictionary[String, bool] = _kiyili
	var komsular: Dictionary[String, Dictionary] = _komsular
	var sonuc: Dictionary[String, bool] = kiyili.duplicate()
	for ulke_id: String in komsular:
		if sonuc.has(ulke_id):
			continue
		for komsu: String in komsular[ulke_id]:
			if kiyili.has(komsu) and not oyun.ambargoda_mi(ulke_id, komsu):
				sonuc[ulke_id] = true
				break
	return sonuc


func piyasaya_erisebilir_mi(oyun: Oyun, ulke_id: String) -> bool:
	return erisimler(oyun).has(ulke_id)


## Günlük piyasa: üretim, tüketim, alım-satım ve fiyat. `sanayiler`, ülkelerin bugünkü ham
## sanayisi. Ülke id'si -> {"ihracat": satış geliri, "ithalat": alım gideri} döndürür.
func gunu_isle(oyun: Oyun, su_anki_saat: int, sanayiler: Dictionary[String, float]) -> Dictionary[String, Dictionary]:
	var uretimler: Dictionary[String, Dictionary] = {}
	for kaynak: String in KAYNAKLAR:
		var tablo: Dictionary = {}
		for bolge_id: String in (bolge_uretimi.get(kaynak, {}) as Dictionary):
			var bolge: Bolge = oyun.dunya.bolgeler[bolge_id]
			tablo[bolge.sahip] = float(tablo.get(bolge.sahip, 0.0)) + bolgenin_uretimi(oyun, bolge, kaynak, su_anki_saat)
		uretimler[kaynak] = tablo
	var zirhlilar: Dictionary[String, int] = {}
	for birlik: Birlik in oyun.birlikler:
		if birlik.tur == "zirhli":
			zirhlilar[birlik.sahip] = zirhlilar.get(birlik.sahip, 0) + 1
	var erisim: Dictionary[String, bool] = erisimler(oyun)

	var sonuc: Dictionary[String, Dictionary] = {}
	var yeni_durum: Dictionary[String, Dictionary] = {}
	for kaynak: String in KAYNAKLAR:
		dunya_arzi[kaynak] = 0.0
		dunya_talebi[kaynak] = 0.0
	# Önce herkesin talebi ve fazlası: ticaret ortaklarının fazlası kadarlık ithalat ucuzdur.
	var talepler: Dictionary[String, Dictionary] = {}
	var fazlalar: Dictionary[String, Dictionary] = {}
	for kaynak: String in KAYNAKLAR:
		fazlalar[kaynak] = {}
	for ulke_id: String in sanayiler:
		var t: Dictionary = {}
		for kaynak: String in KAYNAKLAR:
			t[kaynak] = ulke_talebi(oyun, ulke_id, kaynak, sanayiler.get(ulke_id, 0.0), zirhlilar.get(ulke_id, 0))
			fazlalar[kaynak][ulke_id] = float((uretimler[kaynak] as Dictionary).get(ulke_id, 0.0)) - float(t[kaynak])
		talepler[ulke_id] = t
	var indirim: float = oyun.ticaret.ortak_indirimi
	for ulke: Ulke in oyun.dunya.ulke_listesi:
		var ulke_id: String = ulke.id
		if not sanayiler.has(ulke_id):
			continue  # Bölgesi yok (teslim olmuş).
		var ticaret: Dictionary = {"ihracat": 0.0, "ithalat": 0.0}
		var kaynak_durumu: Dictionary = {}
		for kaynak: String in KAYNAKLAR:
			var uretim: float = float((uretimler[kaynak] as Dictionary).get(ulke_id, 0.0))
			var talep: float = float(talepler[ulke_id][kaynak])
			dunya_arzi[kaynak] += uretim
			dunya_talebi[kaynak] += talep
			var ihrac: float = 0.0
			var ithal: float = 0.0
			var acik: float = 0.0
			var fark: float = uretim - talep
			if fark > 0.0:
				if erisim.has(ulke_id):
					ihrac = fark
					ticaret["ihracat"] += fark * fiyatlar[kaynak]
			elif fark < 0.0:
				if erisim.has(ulke_id) and not oyun.ekonomi.iflasta_mi(ulke_id):
					ithal = -fark
					var ucuz: float = minf(ithal, oyun.ticaret.ortak_fazlasi(ulke_id, fazlalar[kaynak]))
					ticaret["ithalat"] += (ithal - ucuz * indirim) * fiyatlar[kaynak]
				else:
					acik = -fark
			kaynak_durumu[kaynak] = {"uretim": uretim, "talep": talep, "ithal": ithal, "ihrac": ihrac,
					"acik": acik, "acik_orani": acik / talep if talep > 0.0 else 0.0}
		yeni_durum[ulke_id] = kaynak_durumu
		sonuc[ulke_id] = ticaret
	durum = yeni_durum
	_fiyatlari_guncelle()
	return sonuc


## Ülkenin bir kaynaktaki günlük talebi. Petrol: ham sanayi × `sanayi_basina_petrol` +
## zırhlı sayısı × `zirhli_basina_petrol`. Maden: kuyruğunun önündeki (süren) işin türüne
## göre `insaat_basina_maden` (iflasta inşaat durduğu için 0).
func ulke_talebi(oyun: Oyun, ulke_id: String, kaynak: String, ham_sanayi: float, zirhli_sayisi: int) -> float:
	if kaynak == "petrol":
		return ham_sanayi * sanayi_basina_petrol + zirhli_sayisi * zirhli_basina_petrol
	if oyun.ekonomi.iflasta_mi(ulke_id):
		return 0.0
	var on: InsaIsi = oyun.onde_ki_is(ulke_id)
	if on == null:
		return 0.0
	return float(insaat_basina_maden.get(IS_ADLARI.get(on.tur, "tumen"), 1.0))


## Fiyat, talep/arz oranının başlangıçtakine göre sapmasının `fiyat_esnekligi`. kuvveti kadar
## hedefe doğru her gün `fiyat_yumusatma` (%6) yaklaşır; taban fiyatın 0,5-3 katında kalır.
func _fiyatlari_guncelle() -> void:
	for kaynak: String in KAYNAKLAR:
		onceki_fiyatlar[kaynak] = fiyatlar[kaynak]
		var arz: float = maxf(float(dunya_arzi.get(kaynak, 0.0)), 0.001)
		var oran: float = float(dunya_talebi.get(kaynak, 0.0)) / arz
		var hedef: float = taban_fiyat[kaynak] * pow(maxf(oran, 0.01) / _referans_oran[kaynak], fiyat_esnekligi)
		var yeni: float = fiyatlar[kaynak] + (hedef - fiyatlar[kaynak]) * fiyat_yumusatma
		fiyatlar[kaynak] = clampf(yeni, taban_fiyat[kaynak] * fiyat_alt_kati, taban_fiyat[kaynak] * fiyat_ust_kati)
		_referans_oran[kaynak] += (maxf(oran, 0.01) - _referans_oran[kaynak]) * arz_uyum_hizi


func acik_orani(ulke_id: String, kaynak: String) -> float:
	var ulke_durumu: Dictionary = durum.get(ulke_id, {})
	return float((ulke_durumu.get(kaynak, {}) as Dictionary).get("acik_orani", 0.0))


## Petrol açığı sanayi gelirini orantılı düşürür (açık oranı × `petrol_acigi_sanayi_etkisi`).
func sanayi_carpani(ulke_id: String) -> float:
	return 1.0 - acik_orani(ulke_id, "petrol") * petrol_acigi_sanayi_etkisi


## Petrol açığı zırhlıların muharebe gücünü orantılı düşürür.
func zirhli_carpani(ulke_id: String) -> float:
	return 1.0 - acik_orani(ulke_id, "petrol") * petrol_acigi_zirhli_etkisi


## Maden açığı inşaat hızını orantılı düşürür (en az `asgari_insaat_hizi`).
func insaat_hizi(ulke_id: String) -> float:
	return maxf(asgari_insaat_hizi, 1.0 - acik_orani(ulke_id, "maden") * maden_acigi_insaat_etkisi)


## Ülkenin bir kaynaktaki dengesi (üretim − talep; artı fazla, eksi açık).
func denge(ulke_id: String, kaynak: String) -> float:
	var k: Dictionary = (durum.get(ulke_id, {}) as Dictionary).get(kaynak, {})
	return float(k.get("uretim", 0.0)) - float(k.get("talep", 0.0))


func kayit_verisi() -> Dictionary:
	return {"fiyatlar": fiyatlar, "onceki_fiyatlar": onceki_fiyatlar, "durum": durum,
		"referans_oran": _referans_oran}


func kayittan_yukle(veri: Dictionary) -> void:
	for kaynak: String in KAYNAKLAR:
		fiyatlar[kaynak] = float((veri.get("fiyatlar", {}) as Dictionary).get(kaynak, taban_fiyat[kaynak]))
		onceki_fiyatlar[kaynak] = float((veri.get("onceki_fiyatlar", {}) as Dictionary).get(kaynak, fiyatlar[kaynak]))
		_referans_oran[kaynak] = float((veri.get("referans_oran", {}) as Dictionary).get(kaynak, _referans_oran.get(kaynak, 1.0 / baslangic_arz_orani)))
	durum = {}
	var durum_verisi: Dictionary = veri.get("durum", {})
	for ulke_id: String in durum_verisi:
		var kaynaklar: Dictionary = {}
		for kaynak: String in (durum_verisi[ulke_id] as Dictionary):
			var k: Dictionary = {}
			for ad: String in (durum_verisi[ulke_id][kaynak] as Dictionary):
				k[ad] = float(durum_verisi[ulke_id][kaynak][ad])
			kaynaklar[kaynak] = k
		durum[ulke_id] = kaynaklar
