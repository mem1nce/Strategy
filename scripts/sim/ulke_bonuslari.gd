class_name UlkeBonuslari
extends RefCounted
## Her ülkenin tek, küçük bonusu (en çok %15). Veri data/bonuses.json'dadır (tools/bonus_uret.py
## üretir) ve ilk kullanımda bir kez okunur. Bonusu yapay zekâ ülkeleri de kullanır; etkiler
## Oyun'un ilgili hesaplarında uygulanır:
##
## | tür                    | etki                                                       |
## |------------------------|------------------------------------------------------------|
## | gelir                  | günlük gelir × (1 + değer)                                 |
## | fabrika_indirimi       | fabrika maliyeti × (1 - değer)                             |
## | piyade_indirimi        | piyade tümen maliyeti × (1 - değer)                        |
## | deniz_saldirisi        | denizden saldırı cezası çarpanına + değer (en çok 1)       |
## | kendi_toprak_savunmasi | ev sahibi olduğu bölgeyi savunurken verilen hasar × (1 + değer) |
## | arastirma_hizi         | araştırma süresi × (1 - değer)                             |
## | hareket_hizi           | yürüyüş süresi ÷ (1 + değer)                               |
## | bakim_indirimi         | tümen bakımı × (1 - değer)                                 |

const BONUS_DOSYASI: String = "res://data/bonuses.json"
const TURLER: Array[String] = ["gelir", "fabrika_indirimi", "piyade_indirimi", "deniz_saldirisi",
		"kendi_toprak_savunmasi", "arastirma_hizi", "hareket_hizi", "bakim_indirimi"]
const AZAMI_DEGER: float = 0.15

static var _ulkeler: Dictionary = {}


static func _yukle() -> void:
	if not _ulkeler.is_empty():
		return
	_ulkeler = VeriOkuyucu.sozluk_oku(BONUS_DOSYASI).get("ulkeler", {})


## Ülkenin bonusu: {"ad", "tur", "deger"}; yoksa boş sözlük.
static func bonus(ulke_id: String) -> Dictionary:
	_yukle()
	return _ulkeler.get(ulke_id, {})


## Ülkenin bonusu bu türdense değeri (en çok AZAMI_DEGER), değilse 0.
static func deger(ulke_id: String, tur: String) -> float:
	var b: Dictionary = bonus(ulke_id)
	if str(b.get("tur", "")) != tur:
		return 0.0
	return clampf(float(b.get("deger", 0.0)), 0.0, AZAMI_DEGER)


## Arayüzdeki tek satır, ör. "Geniş topraklar: kendi toprağında savunma +%15".
static func metin(ulke_id: String) -> String:
	var b: Dictionary = bonus(ulke_id)
	if b.is_empty():
		return ""
	var yuzde: int = roundi(float(b.get("deger", 0.0)) * 100.0)
	var etki: String = ""
	match str(b.get("tur", "")):
		"gelir":
			etki = "gelir +%%%d" % yuzde
		"fabrika_indirimi":
			etki = "fabrika %%%d ucuz" % yuzde
		"piyade_indirimi":
			etki = "piyade %%%d ucuz" % yuzde
		"deniz_saldirisi":
			etki = "denizden saldırı cezası %%%d az" % yuzde
		"kendi_toprak_savunmasi":
			etki = "kendi toprağında savunma +%%%d" % yuzde
		"arastirma_hizi":
			etki = "araştırma %%%d kısa" % yuzde
		"hareket_hizi":
			etki = "tümenler %%%d hızlı" % yuzde
		"bakim_indirimi":
			etki = "bakım %%%d ucuz" % yuzde
	return "%s: %s" % [b.get("ad", ""), etki]
