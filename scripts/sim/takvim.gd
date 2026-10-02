class_name Takvim
extends RefCounted
## Oyun saatini gerçek takvim tarihine çevirir (ay uzunlukları ve artık yıllar dahil).

const GUNDEKI_SAAT: int = 24
const SAATTEKI_SANIYE: int = 3600

const AY_ADLARI: PackedStringArray = [
	"Ocak", "Şubat", "Mart", "Nisan", "Mayıs", "Haziran",
	"Temmuz", "Ağustos", "Eylül", "Ekim", "Kasım", "Aralık",
]


## "2026-01-01" biçimindeki tarihin gece yarısını Unix zamanına çevirir.
static func tarihten_unix(tarih: String) -> int:
	return Time.get_unix_time_from_datetime_string(tarih + "T00:00:00")


## Oyunun başından beri geçen tam gün sayısı.
static func gun_sayisi(toplam_saat: int) -> int:
	@warning_ignore("integer_division")
	return toplam_saat / GUNDEKI_SAAT


## Günün saati (0-23). Oyun gece yarısında başladığı için kalan, saati verir.
static func saat(toplam_saat: int) -> int:
	return toplam_saat % GUNDEKI_SAAT


## Örnek: "1 Ocak 2026, 00:00"
static func metin(baslangic_unix: int, toplam_saat: int) -> String:
	var tarih: Dictionary = Time.get_datetime_dict_from_unix_time(baslangic_unix + toplam_saat * SAATTEKI_SANIYE)
	var ay: int = tarih["month"]
	return "%d %s %d, %02d:00" % [tarih["day"], AY_ADLARI[ay - 1], tarih["year"], tarih["hour"]]
