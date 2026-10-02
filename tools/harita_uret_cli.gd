extends SceneTree
## Haritayı komut satırından yeniden üretir.
##
## Kullanım: godot --headless --path . --script res://tools/harita_uret_cli.gd

const HaritaUretici: GDScript = preload("res://tools/harita_uretici.gd")


func _init() -> void:
	var uretici: RefCounted = HaritaUretici.new()
	var tamam: bool = uretici.call("calistir")
	quit(0 if tamam else 1)
