class_name VeriOkuyucu
extends RefCounted
## data/ klasöründeki JSON dosyalarını okur.


## Dosyayı okuyup kökteki sözlüğü döndürür. Hata olursa nedenini yazar ve boş sözlük döndürür.
static func sozluk_oku(yol: String) -> Dictionary:
	if not FileAccess.file_exists(yol):
		push_error("Veri dosyası bulunamadı: %s" % yol)
		return {}
	var ayristirici: JSON = JSON.new()
	if ayristirici.parse(FileAccess.get_file_as_string(yol)) != OK:
		push_error("%s bozuk (satır %d): %s" % [yol, ayristirici.get_error_line(), ayristirici.get_error_message()])
		return {}
	if not ayristirici.data is Dictionary:
		push_error("%s bir sözlükle ({ ... }) başlamalı." % yol)
		return {}
	var sonuc: Dictionary = ayristirici.data
	return sonuc
