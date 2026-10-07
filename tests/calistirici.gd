extends SceneTree
## Headless sınama çalıştırıcısı.
##
## Çalıştırmak için (proje klasöründen):
##   Godot --headless --path . --script res://tests/calistirici.gd
##
## Her sınama sınıfındaki "sina_" ile başlayan işlevler sırayla çağrılır. İşlev boş metin
## döndürürse sınama geçmiştir; aksi hâlde döndürdüğü metin hata açıklamasıdır.

const SINAMA_SINIFLARI: Array[Script] = [
	preload("res://tests/sim/dunya_testi.gd"),
	preload("res://tests/sim/takvim_testi.gd"),
	preload("res://tests/sim/zaman_testi.gd"),
	preload("res://tests/sim/ordu_kurucu_testi.gd"),
	preload("res://tests/sim/yol_bulucu_testi.gd"),
	preload("res://tests/sim/hareket_testi.gd"),
	preload("res://tests/sim/savas_testi.gd"),
	preload("res://tests/sim/muharebe_testi.gd"),
	preload("res://tests/sim/teslim_ve_baris_testi.gd"),
	preload("res://tests/sim/ekonomi_testi.gd"),
	preload("res://tests/sim/insa_testi.gd"),
	preload("res://tests/sim/yapay_zeka_testi.gd"),
	preload("res://tests/sim/yz_savas_testi.gd"),
	preload("res://tests/sim/kayit_testi.gd"),
	preload("res://tests/sim/sonuc_testi.gd"),
	preload("res://tests/sim/siralama_testi.gd"),
	preload("res://tests/sim/bildirim_testi.gd"),
	preload("res://tests/sim/birlik_turu_testi.gd"),
	preload("res://tests/sim/teknoloji_testi.gd"),
	preload("res://tests/sim/tahkimat_testi.gd"),
	preload("res://tests/sim/savas_sisi_testi.gd"),
	preload("res://tests/sim/ayarlar_testi.gd"),
]


## Sınamaların kullandığı kayıt dosyası; oyuncunun gerçek kaydı (user://kayit.json)
## sınamalarda hiçbir zaman okunmaz, yazılmaz ve silinmez.
const SINAMA_KAYIT_DOSYASI: String = "user://sinama_kayit.json"
## Sınamaların kullandığı ayar dosyası; oyuncunun ayarlarına (user://ayarlar.json) dokunulmaz.
const SINAMA_AYAR_DOSYASI: String = "user://sinama_ayarlar.json"


func _init() -> void:
	KayitYoneticisi.kayit_dosyasi = SINAMA_KAYIT_DOSYASI
	Ayarlar.ayar_dosyasi = SINAMA_AYAR_DOSYASI
	var toplam: int = 0
	var basarisiz: int = 0
	for sinif: Script in SINAMA_SINIFLARI:
		var sinama: Object = sinif.new()
		for yontem: Dictionary in sinama.get_method_list():
			var ad: String = yontem.name
			if not ad.begins_with("sina_"):
				continue
			toplam += 1
			var hata: String = sinama.call(ad)
			if hata != "":
				basarisiz += 1
				print("BAŞARISIZ %s.%s: %s" % [sinif.resource_path.get_file(), ad, hata])
	for dosya: String in [SINAMA_KAYIT_DOSYASI, SINAMA_AYAR_DOSYASI]:
		if FileAccess.file_exists(dosya):
			DirAccess.remove_absolute(dosya)
	print("%d / %d sınama geçti." % [toplam - basarisiz, toplam])
	quit(1 if basarisiz > 0 else 0)
