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
]


func _init() -> void:
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
	print("%d / %d sınama geçti." % [toplam - basarisiz, toplam])
	quit(1 if basarisiz > 0 else 0)
