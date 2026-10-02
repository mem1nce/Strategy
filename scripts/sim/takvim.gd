class_name Takvim
extends RefCounted
## Oyun saatini tarihe çevirir.
##
## Takvim sadeleştirilmiştir: her ay 30 gün, her yıl 12 ay (360 gün).

const GUNDEKI_SAAT: int = 24
const AYDAKI_GUN: int = 30
const YILDAKI_AY: int = 12
const YILDAKI_GUN: int = AYDAKI_GUN * YILDAKI_AY

const AY_ADLARI: PackedStringArray = [
	"Ocak", "Şubat", "Mart", "Nisan", "Mayıs", "Haziran",
	"Temmuz", "Ağustos", "Eylül", "Ekim", "Kasım", "Aralık",
]


## Oyunun başından beri geçen tam gün sayısı.
static func gun_sayisi(toplam_saat: int) -> int:
	@warning_ignore("integer_division")
	return toplam_saat / GUNDEKI_SAAT


## Günün saati (0-23).
static func saat(toplam_saat: int) -> int:
	return toplam_saat % GUNDEKI_SAAT


## Ayın günü (1-30).
static func ayin_gunu(toplam_saat: int) -> int:
	return gun_sayisi(toplam_saat) % AYDAKI_GUN + 1


## Ay sırası (0 = Ocak).
static func ay(toplam_saat: int) -> int:
	@warning_ignore("integer_division")
	return (gun_sayisi(toplam_saat) % YILDAKI_GUN) / AYDAKI_GUN


static func yil(toplam_saat: int, baslangic_yili: int) -> int:
	@warning_ignore("integer_division")
	return baslangic_yili + gun_sayisi(toplam_saat) / YILDAKI_GUN


## Verilen yılın 1 Ocak 00:00'ına kadar geçen toplam saat.
static func yil_basi_saati(hedef_yil: int, baslangic_yili: int) -> int:
	return (hedef_yil - baslangic_yili) * YILDAKI_GUN * GUNDEKI_SAAT


## Örnek: "1 Ocak 1931, 00:00"
static func metin(toplam_saat: int, baslangic_yili: int) -> String:
	return "%d %s %d, %02d:00" % [
		ayin_gunu(toplam_saat),
		AY_ADLARI[ay(toplam_saat)],
		yil(toplam_saat, baslangic_yili),
		saat(toplam_saat),
	]
