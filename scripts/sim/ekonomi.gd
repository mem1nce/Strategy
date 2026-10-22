class_name Ekonomi
extends RefCounted
## Günlük bütçe (bkz. TASARIM.md 9. Ekonomi): gelir ve gider kalemleri, ordu bakımı, borç,
## faiz ve iflas. Tek para birimi hazinedir (`Oyun.hazineler`); eksi hazine borçtur.
##
## Durumu (son günün kalemleri, son 90 günün hazinesi, iflas edenler) tutar ama Oyun'a
## başvuru tutmaz (Oyun bunu tuttuğu için döngü olurdu); her işlev oyunu parametre alır.

const DENGE_DOSYASI: String = "res://data/balance.json"

## Bütçe kalemleri, panelde bu sırayla yazılır.
const GELIR_KALEMLERI: Array[String] = ["sanayi", "ticaret", "ihracat", "gecis", "tazminat"]
const GIDER_KALEMLERI: Array[String] = ["bakim", "ithalat", "faiz", "tazminat_odeme"]
const KALEM_ADLARI: Dictionary[String, String] = {
	"sanayi": "Sanayi", "ticaret": "Ticaret", "ihracat": "Kaynak ihracatı", "gecis": "Geçiş ücretleri",
	"tazminat": "Savaş tazminatı", "bakim": "Ordu bakımı",
	"ithalat": "Kaynak ithalatı", "faiz": "Borç faizi", "tazminat_odeme": "Ödenen tazminat",
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
## Barışta daha çok bölge kaybeden taraf, günlük gelirinin bu oranını bu kadar gün öteki tarafa öder.
var tazminat_orani: float = 0.15
var tazminat_gun: int = 180

## Ülke -> kalem adı -> son günün değeri (gelirler ve giderler pozitif yazılır).
var kalemler: Dictionary[String, Dictionary] = {}
## Ülke -> son `gecmis_gun` günün gün sonu hazinesi (eskiden yeniye).
var gecmis: Dictionary[String, PackedFloat32Array] = {}
## İflas etmiş ülkeler.
var iflaslar: Dictionary[String, bool] = {}
## Petrol ve maden piyasası (bkz. Piyasa).
var piyasa: Piyasa = Piyasa.new()
## Dünya ekonomisi olayları (bkz. EkonomikOlaylar).
var olaylar: EkonomikOlaylar = EkonomikOlaylar.new()
## Süren tazminatlar: {"oduyen", "alan", "bitis_saati"}.
var tazminatlar: Array[Dictionary] = []


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
	tazminat_orani = float(ayar.get("tazminat_orani", tazminat_orani))
	tazminat_gun = int(ayar.get("tazminat_gun", tazminat_gun))


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
		"ticaret": float((oyun.ticaret.gunluk.get(ulke_id, {}) as Dictionary).get("ticaret", 0.0)),
		"gecis": float((oyun.ticaret.gunluk.get(ulke_id, {}) as Dictionary).get("gecis", 0.0)),
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
	olaylar.gunu_isle(oyun, su_anki_saat)
	piyasa.olay_carpanlari = {"petrol": olaylar.carpan("petrol_uretimi"), "maden": olaylar.carpan("maden_uretimi")}
	var sanayiler: Dictionary[String, float] = Piyasa._ham_sanayiler(oyun, su_anki_saat)
	var kaynak_ticareti: Dictionary[String, Dictionary] = piyasa.gunu_isle(oyun, su_anki_saat, sanayiler)
	var anlasma_gelirleri: Dictionary[String, Dictionary] = oyun.ticaret.gunu_isle(oyun, su_anki_saat, sanayiler,
			olaylar.carpan("ticaret"))
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
		var anlasma_geliri: Dictionary = anlasma_gelirleri.get(ulke_id, {})
		var hazine: float = oyun.hazineler.get(ulke_id, 0.0)
		var ticaret: Dictionary = kaynak_ticareti.get(ulke_id, {})
		var kalem: Dictionary = {
			"sanayi": sanayiler.get(ulke_id, 0.0) * oyun._gelir_carpani(ulke_id) * piyasa.sanayi_carpani(ulke_id),
			"ticaret": float(anlasma_geliri.get("ticaret", 0.0)),
			"gecis": float(anlasma_geliri.get("gecis", 0.0)),
			"ihracat": float(ticaret.get("ihracat", 0.0)),
			"ithalat": float(ticaret.get("ithalat", 0.0)),
			"bakim": bakimlar.get(ulke_id, 0.0) * (1.0 - UlkeBonuslari.deger(ulke_id, "bakim_indirimi")),
			"faiz": maxf(0.0, -hazine) * aylik_faiz / 30.0,
			"tazminat": 0.0,
			"tazminat_odeme": 0.0,
		}
		kalemler[ulke_id] = kalem
	_tazminatlari_isle(oyun, su_anki_saat)

	for ulke: Ulke in dunya.ulke_listesi:
		var ulke_id: String = ulke.id
		if not kalemler.has(ulke_id) or (not sanayiler.has(ulke_id) and not bakimlar.has(ulke_id)):
			continue
		var hazine: float = oyun.hazineler.get(ulke_id, 0.0)
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


## Süren tazminatlar: ödeyen, bugünkü gelirinin (tazminat hariç) `tazminat_orani`nı alana öder.
## Süresi biten ya da taraflarından biri yok olan tazminat düşer.
func _tazminatlari_isle(oyun: Oyun, su_anki_saat: int) -> void:
	for t: Dictionary in tazminatlar.duplicate():
		var oduyen: String = t["oduyen"]
		var alan: String = t["alan"]
		if int(t["bitis_saati"]) <= su_anki_saat or not kalemler.has(oduyen) or not kalemler.has(alan) \
				or oyun.dunya.ulkenin_bolge_sayisi(oduyen) == 0 or oyun.dunya.ulkenin_bolge_sayisi(alan) == 0:
			tazminatlar.erase(t)
			continue
		var gelir: float = 0.0
		for kalem: String in GELIR_KALEMLERI:
			if kalem != "tazminat":
				gelir += float(kalemler[oduyen].get(kalem, 0.0))
		var tutar: float = maxf(0.0, gelir) * tazminat_orani
		kalemler[oduyen]["tazminat_odeme"] = float(kalemler[oduyen].get("tazminat_odeme", 0.0)) + tutar
		kalemler[alan]["tazminat"] = float(kalemler[alan].get("tazminat", 0.0)) + tutar


## Barış yapıldı: savaşta daha çok bölge kaybeden taraf (eşitse kimse) `tazminat_gun` gün
## tazminat öder. Ödeyenin id'si döner (yoksa boş).
func tazminat_baslat(oyun: Oyun, ulke_a: String, ulke_b: String, a_kaybi: int, b_kaybi: int, su_anki_saat: int) -> String:
	if a_kaybi == b_kaybi:
		return ""
	var oduyen: String = ulke_a if a_kaybi > b_kaybi else ulke_b
	var alan: String = ulke_b if oduyen == ulke_a else ulke_a
	tazminatlar.append({"oduyen": oduyen, "alan": alan, "bitis_saati": su_anki_saat + tazminat_gun * 24})
	if oyun.oyuncu_ulkesi == oduyen or oyun.oyuncu_ulkesi == alan:
		var karsi: Ulke = oyun.dunya.ulkeler[alan if oyun.oyuncu_ulkesi == oduyen else oduyen]
		if oyun.oyuncu_ulkesi == oduyen:
			oyun.bildirim_gonder.emit("Tazminat: %d gün boyunca günlük gelirinin %%%d'ini %s'a ödeyeceksin."
					% [tazminat_gun, roundi(tazminat_orani * 100), karsi.ad], "")
		else:
			oyun.bildirim_gonder.emit("Tazminat: %s %d gün boyunca günlük gelirinin %%%d'ini sana ödeyecek."
					% [karsi.ad, tazminat_gun, roundi(tazminat_orani * 100)], "")
	return oduyen


## Ülkeler gelirine göre büyükten küçüğe: {"ulke_id", "gelir", "ticaret"} (sıralama panelinin
## Ekonomi sekmesi için).
func ekonomi_siralamasi(oyun: Oyun) -> Array[Dictionary]:
	var sonuc: Array[Dictionary] = []
	for ulke: Ulke in oyun.dunya.ulke_listesi:
		if oyun.dunya.ulkenin_bolge_sayisi(ulke.id) == 0:
			continue
		var k: Dictionary = kalem_tahmini(oyun, ulke.id)
		sonuc.append({"ulke_id": ulke.id, "gelir": gunluk_gelir(oyun, ulke.id),
			"ticaret": float(k.get("ticaret", 0.0))})
	sonuc.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["gelir"]) > float(b["gelir"]))
	return sonuc


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
		"olay": olaylar.kayit_verisi(),
		"tazminatlar": tazminatlar,
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
	olaylar.kayittan_yukle(veri.get("olay", {}))
	tazminatlar = []
	for t: Dictionary in (veri.get("tazminatlar", []) as Array):
		tazminatlar.append({"oduyen": str(t.get("oduyen", "")), "alan": str(t.get("alan", "")),
			"bitis_saati": int(t.get("bitis_saati", 0))})
	gecmis = {}
	var oyuncu_gecmisi: Array = veri.get("oyuncu_gecmisi", [])
	if oyuncu_ulkesi != "" and not oyuncu_gecmisi.is_empty():
		gecmis[oyuncu_ulkesi] = PackedFloat32Array(oyuncu_gecmisi)
