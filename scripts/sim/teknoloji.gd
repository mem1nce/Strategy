class_name Teknoloji
extends RefCounted
## Teknoloji dalları ve seviyelerinin etkileri.
##
## Dört dal (Sanayi, Silah, Savunma, Lojistik), her biri `azami_seviye` (3) seviye. Her ülke
## aynı anda tek bir araştırma yürütür; maliyet hazineden peşin ödenir, maliyet ve süre
## seviyeyle doğrusal artar. Sayılar data/balance.json -> "teknoloji" bölümündedir. Ülkelerin
## seviyeleri ve süren araştırmaları Oyun'da tutulur (bkz. Oyun.teknoloji_seviyesi).

const DENGE_DOSYASI: String = "res://data/balance.json"
const DALLAR: Array[String] = ["sanayi", "silah", "savunma", "lojistik"]

static var _ayarlar: Dictionary = {}


static func _ayar(anahtar: String, varsayilan: float) -> float:
	if _ayarlar.is_empty():
		_ayarlar = VeriOkuyucu.sozluk_oku(DENGE_DOSYASI).get("teknoloji", {})
	return float(_ayarlar.get(anahtar, varsayilan))


static func azami_seviye() -> int:
	return int(_ayar("azami_seviye", 3))


static func ad(dal: String) -> String:
	match dal:
		"sanayi":
			return "Sanayi"
		"silah":
			return "Silah"
		"savunma":
			return "Savunma"
		"lojistik":
			return "Lojistik"
	return dal


## `seviye`ye (1'den başlar) yükselmenin maliyeti.
static func maliyet(seviye: int) -> float:
	return _ayar("taban_maliyet", 150.0) * seviye


## `seviye`ye yükselmenin süresi (saat).
static func sure_saat(seviye: int) -> int:
	return roundi(_ayar("taban_sure_gun", 30.0) * 24.0 * seviye)


## Sanayi: gelir çarpanı (seviye başına +%10).
static func gelir_carpani(seviye: int) -> float:
	return 1.0 + _ayar("sanayi_artisi", 0.10) * seviye


## Silah: verilen hasarın çarpanı (seviye başına +%10).
static func saldiri_carpani(seviye: int) -> float:
	return 1.0 + _ayar("silah_artisi", 0.10) * seviye


## Savunma: alınan hasar bu değere bölünür (seviye başına +%10 dayanıklılık).
static func savunma_carpani(seviye: int) -> float:
	return 1.0 + _ayar("savunma_artisi", 0.10) * seviye


## Lojistik: hareket hızı çarpanı (seviye başına +%15); yürüyüş süresi buna bölünür.
static func hiz_carpani(seviye: int) -> float:
	return 1.0 + _ayar("lojistik_hiz_artisi", 0.15) * seviye


## Lojistik: denizden saldırı cezasının her seviyede ne kadar hafiflediği (çarpana eklenir).
static func deniz_cezasi_azalisi(seviye: int) -> float:
	return _ayar("lojistik_deniz_cezasi_azalisi", 0.10) * seviye


## Teknoloji panelindeki kutu yazısı, ör. "Gelir +%20".
static func seviye_aciklamasi(dal: String, seviye: int) -> String:
	match dal:
		"sanayi":
			return "Gelir +%%%d" % roundi((gelir_carpani(seviye) - 1.0) * 100.0)
		"silah":
			return "Saldırı +%%%d" % roundi((saldiri_carpani(seviye) - 1.0) * 100.0)
		"savunma":
			return "Savunma +%%%d" % roundi((savunma_carpani(seviye) - 1.0) * 100.0)
		"lojistik":
			return "Hız +%%%d, deniz cezası −%%%d" % [roundi((hiz_carpani(seviye) - 1.0) * 100.0),
					roundi(deniz_cezasi_azalisi(seviye) * 100.0)]
	return ""
