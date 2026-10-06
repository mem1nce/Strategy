class_name BirlikTurleri
extends RefCounted
## Birlik türleri (piyade, zırhlı, topçu) ve üstünlük üçgeni.
##
## Bütün sayılar data/balance.json -> "birlik_turleri" bölümündedir ve ilk kullanımda bir kez
## okunur. Üstünlük üçgeni: zırhlı piyadeyi, piyade topçuyu, topçu zırhlıyı yener; üstün olan
## tür o türe karşı `ustunluk_bonusu` (%50) daha fazla hasar verir.

const DENGE_DOSYASI: String = "res://data/balance.json"
## Kayıtta türü olmayan (eski) tümenler ve tür belirtilmeyen üretim bu türü alır.
const VARSAYILAN: String = "piyade"
## Arayüzde ve sınamalarda kullanılan sabit sıra.
const SIRA: Array[String] = ["piyade", "zirhli", "topcu"]

static var _turler: Dictionary = {}
static var _ustunluk_bonusu: float = 0.5


static func _yukle() -> void:
	if not _turler.is_empty():
		return
	var ayarlar: Dictionary = VeriOkuyucu.sozluk_oku(DENGE_DOSYASI).get("birlik_turleri", {})
	_ustunluk_bonusu = float(ayarlar.get("ustunluk_bonusu", _ustunluk_bonusu))
	_turler = ayarlar.get("turler", {})
	if _turler.is_empty():
		push_error("data/balance.json içinde birlik_turleri/turler bulunamadı.")
		_turler = {VARSAYILAN: {"ad": "Piyade", "maliyet": 40, "sure_saat": 96, "bakim": 0.4,
				"saldiri": 1.0, "savunma": 1.0, "hareket_carpani": 1.0, "yener": ""}}


static func gecerli_mi(tur: String) -> bool:
	_yukle()
	return _turler.has(tur)


static func _deger(tur: String, anahtar: String, varsayilan: Variant) -> Variant:
	_yukle()
	var bilgi: Dictionary = _turler.get(tur, _turler.get(VARSAYILAN, {}))
	return bilgi.get(anahtar, varsayilan)


static func ad(tur: String) -> String:
	return str(_deger(tur, "ad", tur))


static func maliyet(tur: String) -> float:
	return float(_deger(tur, "maliyet", 50.0))


static func sure_saat(tur: String) -> int:
	return int(_deger(tur, "sure_saat", 120))


## Tümen başına günlük bakım masrafı.
static func bakim(tur: String) -> float:
	return float(_deger(tur, "bakim", 0.5))


## Saldırırken verdiği hasarın çarpanı.
static func saldiri(tur: String) -> float:
	return float(_deger(tur, "saldiri", 1.0))


## Savunurken verdiği hasarın çarpanı.
static func savunma(tur: String) -> float:
	return float(_deger(tur, "savunma", 1.0))


## Yürüyüş süresinin çarpanı (küçük = hızlı).
static func hareket_carpani(tur: String) -> float:
	return float(_deger(tur, "hareket_carpani", 1.0))


## Bu türün üstün geldiği tür.
static func yener(tur: String) -> String:
	return str(_deger(tur, "yener", ""))


## Bu türe üstün gelen tür.
static func yenildigi(tur: String) -> String:
	_yukle()
	for diger: String in _turler:
		if yener(diger) == tur:
			return diger
	return ""


static func ustunluk_bonusu() -> float:
	_yukle()
	return _ustunluk_bonusu


## Arayüzdeki kısa açıklama, ör. "Piyadeye karşı güçlü".
static func guclu_oldugu_metin(tur: String) -> String:
	var hedef: String = yener(tur)
	if hedef == "":
		return ""
	return "%s birliklerine karşı güçlü" % ad(hedef)
