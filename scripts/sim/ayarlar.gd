class_name Ayarlar
extends RefCounted
## Oyuncunun cihaz ayarları: animasyonlar, ses düzeyi, sessiz. Oyun kaydından ayrıdır (kayıt
## silinse de ayarlar kalır) ve user:// altına tek bir JSON dosyası olarak yazılır.
##
## Ayarlar oyunun kurallarını değil yalnızca sunumunu etkiler; savaş sisi gibi oyuna ait
## seçenekler kayıtta durur (bkz. Oyun.savas_sisi).

## Ayar dosyasının yolu. Sınamalar bunu ayrı bir dosyaya çevirir (bkz. tests/calistirici.gd).
static var ayar_dosyasi: String = "user://ayarlar.json"

## true ise animasyonlar azaltılır: tümenler kaymaz, işaretler atmaz, paneller anında açılır.
static var animasyonlar_azaltilmis: bool = false
## Efekt ses düzeyi (0-1).
static var ses_duzeyi: float = 0.8
static var sessiz: bool = false


static func kaydet() -> void:
	var dosya: FileAccess = FileAccess.open(ayar_dosyasi, FileAccess.WRITE)
	if dosya == null:
		push_error("Ayar dosyası yazılamadı: %s (hata %d)" % [ayar_dosyasi, FileAccess.get_open_error()])
		return
	dosya.store_string(JSON.stringify({
		"animasyonlar_azaltilmis": animasyonlar_azaltilmis,
		"ses_duzeyi": ses_duzeyi,
		"sessiz": sessiz,
	}))
	dosya.close()


## Dosya yoksa ya da bozuksa varsayılanlar kullanılır.
static func yukle() -> void:
	animasyonlar_azaltilmis = false
	ses_duzeyi = 0.8
	sessiz = false
	if not FileAccess.file_exists(ayar_dosyasi):
		return
	var ayristirici: JSON = JSON.new()
	if ayristirici.parse(FileAccess.get_file_as_string(ayar_dosyasi)) != OK or not ayristirici.data is Dictionary:
		push_warning("Ayar dosyası bozuk, varsayılanlar kullanılıyor: %s" % ayar_dosyasi)
		return
	var sozluk: Dictionary = ayristirici.data
	animasyonlar_azaltilmis = bool(sozluk.get("animasyonlar_azaltilmis", false))
	ses_duzeyi = clampf(float(sozluk.get("ses_duzeyi", 0.8)), 0.0, 1.0)
	sessiz = bool(sozluk.get("sessiz", false))
