class_name EkonomikOlaylar
extends RefCounted
## Dünya ekonomisi olayları (TASARIM.md 9e): petrol krizi, küresel durgunluk, ticaret patlaması,
## maden bolluğu, geçit kazası. Hepsi data/events.json'dadır. Her gün yillik_olay_sayisi / 365
## olasılıkla (oyunun tohumlu rastgele sayı üretecinden) bir olay başlar; aynı anda tek olay
## sürer. Olay çarpanları piyasa üretimine ve ticaret değerine uygulanır (bkz. Ekonomi.gunu_isle);
## geçit kazası rastgele bir geçidi kapatır (bkz. Ticaret.gecidi_kapat).
##
## Oyun'a başvuru tutmaz; işlevler oyunu parametre alır.

const VERI_DOSYASI: String = "res://data/events.json"

var yillik_olay_sayisi: float = 1.0
## Olay tanımları (events.json → "olaylar").
var tanimlar: Array[Dictionary] = []
## Süren olay: {"id", "bitis_saati", "gecit": kapanan geçit (geçit kazasında)}; yoksa boş.
var suren: Dictionary = {}


func _init() -> void:
	var veri: Dictionary = VeriOkuyucu.sozluk_oku(VERI_DOSYASI)
	yillik_olay_sayisi = float(veri.get("yillik_olay_sayisi", yillik_olay_sayisi))
	for tanim: Dictionary in (veri.get("olaylar", []) as Array):
		tanimlar.append(tanim)


func tanim(olay_id: String) -> Dictionary:
	for t: Dictionary in tanimlar:
		if t.get("id", "") == olay_id:
			return t
	return {}


## Süren olayın verilen çarpanı (ör. "ticaret", "petrol_uretimi"); olay yoksa 1.
func carpan(ad: String) -> float:
	if suren.is_empty():
		return 1.0
	return float((tanim(suren["id"]).get("carpanlar", {}) as Dictionary).get(ad, 1.0))


## Gün başında: süren olay bittiyse kaldırır, yoksa olasılıkla yeni bir olay başlatır.
func gunu_isle(oyun: Oyun, su_anki_saat: int) -> void:
	if not suren.is_empty() and int(suren["bitis_saati"]) <= su_anki_saat:
		suren = {}
	if not suren.is_empty() or tanimlar.is_empty():
		return
	if oyun._rng.randf() >= yillik_olay_sayisi / 365.0:
		return
	baslat(oyun, str(tanimlar[oyun._rng.randi_range(0, tanimlar.size() - 1)]["id"]), su_anki_saat)


## Olayı başlatır ve oyuncuya bildirim kartı gönderir. Geçit kazasında rastgele bir (açık) geçit
## kapanır. Başlatılamazsa (bilinmeyen olay, kapatılacak geçit yok) false döner.
func baslat(oyun: Oyun, olay_id: String, su_anki_saat: int) -> bool:
	var t: Dictionary = tanim(olay_id)
	if t.is_empty():
		return false
	var bitis: int = su_anki_saat + int(t.get("sure_gun", 30)) * 24
	var metin: String = str(t.get("metin", t.get("ad", olay_id)))
	var gecit_id: String = ""
	if bool(t.get("gecit_kapat", false)):
		var adaylar: Array[String] = []
		for gecit: Dictionary in oyun.ticaret.gecitler:
			if not oyun.ticaret.kapali_gecitler.has(gecit["id"]):
				adaylar.append(gecit["id"])
		if adaylar.is_empty():
			return false
		gecit_id = adaylar[oyun._rng.randi_range(0, adaylar.size() - 1)]
		oyun.ticaret.gecidi_kapat(gecit_id, bitis)
		metin = metin % str(oyun.ticaret.gecit_sozlugu[gecit_id]["ad"])
	suren = {"id": olay_id, "bitis_saati": bitis, "gecit": gecit_id}
	if oyun.oyuncu_ulkesi != "":
		oyun.bildirim_gonder.emit(metin, "")
	return true


func kayit_verisi() -> Dictionary:
	return suren.duplicate()


func kayittan_yukle(veri: Dictionary) -> void:
	suren = {}
	if veri.has("id") and not tanim(str(veri["id"])).is_empty():
		suren = {"id": str(veri["id"]), "bitis_saati": int(veri.get("bitis_saati", 0)), "gecit": str(veri.get("gecit", ""))}
