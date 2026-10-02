@tool
extends EditorScript
## Haritayı Godot düzenleyicisinin içinden yeniden üretir.
##
## Kullanım: bu dosyayı betik düzenleyicisinde aç, Dosya > Çalıştır (Ctrl+Shift+X).
## Sonuç Çıktı panelinde görünür.

const HaritaUretici: GDScript = preload("res://tools/harita_uretici.gd")


func _run() -> void:
	var uretici: RefCounted = HaritaUretici.new()
	uretici.call("calistir")
