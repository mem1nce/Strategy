class_name KayitYoneticisi
extends RefCounted
## Oyunun durumunu user:// altına tek bir JSON dosyası olarak kaydeder ve yükler.
##
## Tek kayıt yuvası vardır; yeni kayıt eskisinin üzerine yazılır. Dosyada bir sürüm
## numarası durur; okurken sürüm uyuşmazsa kayıt yok sayılır (oyun sıfırdan başlar).

const SURUM: int = 1

## Kayıt dosyasının yolu. Sınamalar bunu ayrı bir dosyaya çevirir ki oyuncunun gerçek
## kaydına dokunmasınlar (bkz. tests/calistirici.gd).
static var kayit_dosyasi: String = "user://kayit.json"


static func kayit_var_mi() -> bool:
	return FileAccess.file_exists(kayit_dosyasi)


## Kayıt dosyasını siler (yoksa bir şey yapmaz). Ana menüdeki "Yeni oyun" ve "Ayarlar ->
## Kaydı sil" tarafından kullanılır.
static func sil() -> void:
	if kayit_var_mi():
		DirAccess.remove_absolute(kayit_dosyasi)


## `zaman_durumu`, Zaman.durumu_al()'ın döndürdüğü sözlüktür; KayitYoneticisi Zaman
## autoload'ına bağlı olmasın diye çağıran taraftan parametre olarak alınır.
static func kaydet(oyun: Oyun, zaman_durumu: Dictionary) -> void:
	var veri: Dictionary = oyun.kaydet_icin_veri()
	veri["surum"] = SURUM
	veri["zaman"] = zaman_durumu
	var dosya: FileAccess = FileAccess.open(kayit_dosyasi, FileAccess.WRITE)
	if dosya == null:
		push_error("Kayıt dosyası yazılamadı: %s (hata %d)" % [kayit_dosyasi, FileAccess.get_open_error()])
		return
	dosya.store_string(JSON.stringify(veri))


## Kayıt yoksa, okunamazsa ya da sürümü uyuşmazsa boş sözlük döner. Bulunursa
## `{"oyun_verisi": Dictionary, "zaman_durumu": Dictionary}` döner; `oyun_verisi`
## doğrudan `Oyun.kayittan_yukle()`'ye, `zaman_durumu` `Zaman.durumu_uygula()`'ya verilir.
static func yukle() -> Dictionary:
	if not kayit_var_mi():
		return {}
	var dosya: FileAccess = FileAccess.open(kayit_dosyasi, FileAccess.READ)
	if dosya == null:
		push_error("Kayıt dosyası okunamadı: %s (hata %d)" % [kayit_dosyasi, FileAccess.get_open_error()])
		return {}
	var ayristirici: JSON = JSON.new()
	if ayristirici.parse(dosya.get_as_text()) != OK or not ayristirici.data is Dictionary:
		push_error("Kayıt dosyası bozuk: %s" % ayristirici.get_error_message())
		return {}
	var veri: Dictionary = ayristirici.data
	if int(veri.get("surum", -1)) != SURUM:
		push_error("Kayıt dosyasının sürümü (%s) bu oyunun sürümüyle (%d) uyuşmuyor, yok sayılıyor." % [
			str(veri.get("surum")), SURUM])
		return {}
	return {"oyun_verisi": veri, "zaman_durumu": veri.get("zaman", {})}
