class_name Ekonomi
extends RefCounted
## Günlük bütçe (bkz. TASARIM.md 9. Ekonomi): gelir ve gider kalemleri, ordu bakımı, borç,
## faiz ve iflas. Tek para birimi hazinedir (`Oyun.hazineler`); eksi hazine borçtur.
##
## Durumu (son günün kalemleri, son 90 günün hazinesi, iflas edenler) tutar ama Oyun'a
## başvuru tutmaz (Oyun bunu tuttuğu için döngü olurdu); her işlev oyunu parametre alır.

const DENGE_DOSYASI: String = "res://data/balance.json"

## Bütçe kalemleri, panelde bu sırayla yazılır.
const GELIR_KALEMLERI: Array[String] = ["sanayi", "ihracat"]
const GIDER_KALEMLERI: Array[String] = ["bakim", "ithalat", "faiz"]
const KALEM_ADLARI: Dictionary[String, String] = {
	"sanayi": "Sanayi", "ihracat": "Kaynak ihracatı", "bakim": "Ordu bakımı",
	"ithalat": "Kaynak ithalatı", "faiz": "Borç faizi",
}

var baslangic_gun_geliri: float = 60.0
## Barıştaki ülkenin kendi toprağındaki tümeni bakımın bu kadarını, yabancı topraktaki
## (barışta ya da savaşta) tümeni bu kadarını öder. Savaştaki ülkenin kendi toprağındaki
## tümeni tam öder.
var bakim_baris_kendi: float = 0.6
var bakim_yabanci: float = 1.3
var aylik_faiz: float = 0.02
var borc_limiti_gun: float = 90.0
var iflas_guc_kaybi: float = 0.04
## İflas, borç limitin bu oranının altına inince biter (sınırda gidip gelmesin diye).
var iflas_cikis_orani: float = 0.8
var gecmis_gun: int = 90

## Ülke -> kalem adı -> son günün değeri (gelirler ve giderler pozitif yazılır).
var kalemler: Dictionary[String, Dictionary] = {}
## Ülke -> son `gecmis_gun` günün gün sonu hazinesi (eskiden yeniye).
var gecmis: Dictionary[String, PackedFloat32Array] = {}
## İflas etmiş ülkeler.
var iflaslar: Dictionary[String, bool] = {}
## Petrol ve maden piyasası (bkz. Piyasa).
var piyasa: Piyasa = Piyasa.new()


func _init() -> void:
	var ayar: Dictionary = VeriOkuyucu.sozluk_oku(DENGE_DOSYASI).get("butce", {})
	baslangic_gun_geliri = float(ayar.get("baslangic_gun_geliri", baslangic_gun_geliri))
	bakim_baris_kendi = float(ayar.get("bakim_baris_kendi_topragi", bakim_baris_kendi))
	bakim_yabanci = float(ayar.get("bakim_yabanci_toprak", bakim_yabanci))
	aylik_faiz = float(ayar.get("aylik_faiz", aylik_faiz))
	borc_limiti_gun = float(ayar.get("borc_limiti_gun", borc_limiti_gun))
	iflas_guc_kaybi = float(ayar.get("iflas_gunluk_guc_kaybi", iflas_guc_kaybi))
	iflas_cikis_orani = float(ayar.get("iflas_cikis_orani", iflas_cikis_orani))
	gecmis_gun = int(ayar.get("gecmis_gun", gecmis_gun))


## Oyun başında her ülkenin hazinesi yaklaşık `baslangic_gun_geliri` (60) günlük gelirdir.
func baslangic_hazinelerini_kur(oyun: Oyun) -> void:
	for ulke: Ulke in oyun.dunya.ulke_listesi:
		oyun.hazineler[ulke.id] = baslangic_gun_geliri * oyun.ulkenin_geliri(ulke.id, 0)


## Bir tümenin bugünkü bakımı: türünün bakımı × bulunduğu yere göre çarpan (bonus hariç).
func birlik_bakimi(oyun: Oyun, birlik: Birlik, ulke_barista: bool = false) -> float:
	return BirlikTurleri.bakim(birlik.tur) * bakim_carpani(oyun, birlik, ulke_barista)


## Yabancı toprakta ×1,3; barıştaki ülkenin kendi toprağında ×0,6; savaştaki ülkenin kendi
## toprağında ×1.
func bakim_carpani(oyun: Oyun, birlik: Birlik, ulke_barista: bool) -> float:
	var bolge: Bolge = oyun.dunya.bolgeler.get(birlik.bolge_id)
	if bolge != null and bolge.sahip != birlik.sahip:
		return bakim_yabanci
	return bakim_baris_kendi if ulke_barista else 1.0


## Ülkenin bütün tümenlerinin bugünkü toplam bakımı (bakım bonusu dahil).
func ulke_bakimi(oyun: Oyun, ulke_id: String) -> float:
	var barista: bool = not oyun._ulkenin_savasta_mi(ulke_id)
	var toplam: float = 0.0
	for birlik: Birlik in oyun.birlikler:
		if birlik.sahip == ulke_id:
			toplam += BirlikTurleri.bakim(birlik.tur) * bakim_carpani(oyun, birlik, barista)
	return toplam * (1.0 - UlkeBonuslari.deger(ulke_id, "bakim_indirimi"))


## Bir tümen kurulursa (kendi toprağında) bakımın ne kadar artacağı.
func yeni_tumen_bakimi(oyun: Oyun, ulke_id: String, tur: String) -> float:
	var carpan: float = 1.0 if oyun._ulkenin_savasta_mi(ulke_id) else bakim_baris_kendi
	return BirlikTurleri.bakim(tur) * carpan * (1.0 - UlkeBonuslari.deger(ulke_id, "bakim_indirimi"))


## Son günün toplam geliri; henüz gün işlenmediyse sanayi geliri.
func gunluk_gelir(oyun: Oyun, ulke_id: String) -> float:
	if not kalemler.has(ulke_id):
		return oyun.ulkenin_geliri(ulke_id, 0)
	var toplam: float = 0.0
	for kalem: String in GELIR_KALEMLERI:
		toplam += float(kalemler[ulke_id].get(kalem, 0.0))
	return toplam


func gunluk_gider(ulke_id: String) -> float:
	var toplam: float = 0.0
	for kalem: String in GIDER_KALEMLERI:
		toplam += float((kalemler.get(ulke_id, {}) as Dictionary).get(kalem, 0.0))
	return toplam


## Son günün neti (gelir − gider); henüz gün işlenmediyse bugünkü tahmin.
func net(oyun: Oyun, ulke_id: String) -> float:
	if not kalemler.has(ulke_id):
		var tahmin: Dictionary = kalem_tahmini(oyun, ulke_id)
		var toplam: float = 0.0
		for kalem: String in GELIR_KALEMLERI:
			toplam += float(tahmin.get(kalem, 0.0))
		for kalem: String in GIDER_KALEMLERI:
			toplam -= float(tahmin.get(kalem, 0.0))
		return toplam
	return gunluk_gelir(oyun, ulke_id) - gunluk_gider(ulke_id)


## Ülkenin kalemleri: son gün işlendiyse onlar, işlenmediyse (oyun başı) bugünkü tahmin.
func kalem_tahmini(oyun: Oyun, ulke_id: String) -> Dictionary:
	if kalemler.has(ulke_id):
		return kalemler[ulke_id]
	return {
		"sanayi": oyun.ulkenin_geliri(ulke_id, 0), "ihracat": 0.0, "ithalat": 0.0,
		"bakim": ulke_bakimi(oyun, ulke_id),
		"faiz": borc(oyun, ulke_id) * aylik_faiz / 30.0,
	}


func borc(oyun: Oyun, ulke_id: String) -> float:
	return maxf(0.0, -float(oyun.hazineler.get(ulke_id, 0.0)))


## Borç limiti: `borc_limiti_gun` (90) günlük gelir.
func borc_limiti(oyun: Oyun, ulke_id: String) -> float:
	return borc_limiti_gun * gunluk_gelir(oyun, ulke_id)


func iflasta_mi(ulke_id: String) -> bool:
	return iflaslar.has(ulke_id)


## Her oyun günü başında: önce petrol ve maden piyasası işlenir (bkz. Piyasa), sonra her ülkenin
## kalemleri hesaplanır, net hazineye işlenir, borcun faizi düşülür, iflas durumu güncellenir ve
## iflastaki ülkelerin tümenleri güç kaybeder.
func gunu_isle(oyun: Oyun, su_anki_saat: int) -> void:
	var dunya: Dunya = oyun.dunya
	var sanayiler: Dictionary[String, float] = Piyasa._ham_sanayiler(oyun, su_anki_saat)
	var kaynak_ticareti: Dictionary[String, Dictionary] = piyasa.gunu_isle(oyun, su_anki_saat, sanayiler)
	var bakimlar: Dictionary[String, float] = {}
	var barista: Dictionary[String, bool] = {}
	for birlik: Birlik in oyun.birlikler:
		if not barista.has(birlik.sahip):
			barista[birlik.sahip] = not oyun._ulkenin_savasta_mi(birlik.sahip)
		bakimlar[birlik.sahip] = bakimlar.get(birlik.sahip, 0.0) \
				+ BirlikTurleri.bakim(birlik.tur) * bakim_carpani(oyun, birlik, barista[birlik.sahip])

	for ulke: Ulke in dunya.ulke_listesi:
		var ulke_id: String = ulke.id
		if not sanayiler.has(ulke_id) and not bakimlar.has(ulke_id):
			continue  # Teslim olmuş.
		var hazine: float = oyun.hazineler.get(ulke_id, 0.0)
		var ticaret: Dictionary = kaynak_ticareti.get(ulke_id, {})
		var kalem: Dictionary = {
			"sanayi": sanayiler.get(ulke_id, 0.0) * oyun._gelir_carpani(ulke_id) * piyasa.sanayi_carpani(ulke_id),
			"ihracat": float(ticaret.get("ihracat", 0.0)),
			"ithalat": float(ticaret.get("ithalat", 0.0)),
			"bakim": bakimlar.get(ulke_id, 0.0) * (1.0 - UlkeBonuslari.deger(ulke_id, "bakim_indirimi")),
			"faiz": maxf(0.0, -hazine) * aylik_faiz / 30.0,
		}
		kalemler[ulke_id] = kalem
		hazine += net(oyun, ulke_id)
		oyun.hazineler[ulke_id] = hazine
		_iflasi_guncelle(oyun, ulke_id)
		var liste: PackedFloat32Array = gecmis.get(ulke_id, PackedFloat32Array())
		liste.append(hazine)
		if liste.size() > gecmis_gun:
			liste = liste.slice(liste.size() - gecmis_gun)
		gecmis[ulke_id] = liste
	if not iflaslar.is_empty():
		_iflas_kayiplari(oyun)


func _iflasi_guncelle(oyun: Oyun, ulke_id: String) -> void:
	var b: float = borc(oyun, ulke_id)
	var limit: float = borc_limiti(oyun, ulke_id)
	if not iflaslar.has(ulke_id) and b > limit:
		iflaslar[ulke_id] = true
		if ulke_id == oyun.oyuncu_ulkesi:
			oyun.bildirim_gonder.emit("İflas ettin: borç limiti aşıldı. İnşaat durdu, tümenler güç kaybediyor.",
					oyun.dunya.ulkeler[ulke_id].baskent_bolgesi)
	elif iflaslar.has(ulke_id) and b <= limit * iflas_cikis_orani:
		iflaslar.erase(ulke_id)
		if ulke_id == oyun.oyuncu_ulkesi:
			oyun.bildirim_gonder.emit("İflastan çıktın: inşaat yeniden başladı.", "")


## İflastaki ülkelerin bütün tümenleri her gün `iflas_guc_kaybi` (%4) güç kaybeder.
func _iflas_kayiplari(oyun: Oyun) -> void:
	var kalanlar: Array[Birlik] = []
	var degisti: bool = false
	for birlik: Birlik in oyun.birlikler:
		if iflaslar.has(birlik.sahip):
			birlik.guc *= 1.0 - iflas_guc_kaybi
			degisti = true
			if birlik.guc < Oyun.ASGARI_GUC:
				continue
		kalanlar.append(birlik)
	if degisti:
		oyun.birlikler = kalanlar
		oyun._dizini_gecersiz_kil()


## Kayda yazılacak durum. Geçmiş yalnızca oyuncu için saklanır (panelde yalnızca o çizilir).
func kayit_verisi(oyuncu_ulkesi: String) -> Dictionary:
	var kalem_verisi: Dictionary = {}
	for ulke_id: String in kalemler:
		kalem_verisi[ulke_id] = kalemler[ulke_id]
	return {
		"kalemler": kalem_verisi,
		"iflaslar": iflaslar.keys(),
		"oyuncu_gecmisi": Array(gecmis.get(oyuncu_ulkesi, PackedFloat32Array())),
		"piyasa": piyasa.kayit_verisi(),
	}


func kayittan_yukle(veri: Dictionary, oyuncu_ulkesi: String) -> void:
	kalemler = {}
	var kalem_verisi: Dictionary = veri.get("kalemler", {})
	for ulke_id: String in kalem_verisi:
		var k: Dictionary = {}
		for ad: String in (kalem_verisi[ulke_id] as Dictionary):
			k[ad] = float(kalem_verisi[ulke_id][ad])
		kalemler[ulke_id] = k
	iflaslar = {}
	for ulke_id: Variant in (veri.get("iflaslar", []) as Array):
		iflaslar[str(ulke_id)] = true
	piyasa.kayittan_yukle(veri.get("piyasa", {}))
	gecmis = {}
	var oyuncu_gecmisi: Array = veri.get("oyuncu_gecmisi", [])
	if oyuncu_ulkesi != "" and not oyuncu_gecmisi.is_empty():
		gecmis[oyuncu_ulkesi] = PackedFloat32Array(oyuncu_gecmisi)
