extends SceneTree
## tools/kaynak/bayraklar/*.svg dosyalarını Godot'nun SVG çiziciyle tek bir doku atlasına çevirir.
##
## Çalıştırmak için (proje klasöründen; önce python tools/bayrak_indir.py):
##   Godot --headless --path . --script <tam yol>/tools/bayrak_atlasi.gd
## (tools/ klasörü Godot'dan gizli olduğu için betik tam yoluyla verilir.)
##
## Çıktı: assets/flags/flags.png (her bayrak HUCRE boyutunda, SUTUN sütunlu ızgara) ve
## assets/flags/flags.json (ülke id'si -> atlas sırası). Bayrağı olmayan ülke atlasta yoktur;
## oyun ona yedek bayrak çizer (bkz. scripts/arayuz/bayraklar.gd).

const HUCRE: Vector2i = Vector2i(96, 72)
const SUTUN: int = 16


func _init() -> void:
	var kok: String = ProjectSettings.globalize_path("res://")
	var kaynak: String = kok.path_join("tools/kaynak/bayraklar")
	var eslesme: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(kaynak.path_join("eslesme.json")))
	var idler: Array = eslesme.keys()
	idler.sort()
	var satir: int = ceili(float(idler.size()) / SUTUN)
	var atlas: Image = Image.create_empty(SUTUN * HUCRE.x, satir * HUCRE.y, false, Image.FORMAT_RGBA8)
	var dizin: Dictionary = {}
	for i: int in idler.size():
		var ulke_id: String = idler[i]
		var svg: String = FileAccess.get_file_as_string(kaynak.path_join("%s.svg" % ulke_id))
		var resim: Image = Image.new()
		# flag-icons 4x3 dosyaları 640 x 480 birimdir.
		if resim.load_svg_from_string(svg, float(HUCRE.x) / 640.0) != OK:
			push_warning("Çizilemedi: %s" % ulke_id)
			continue
		resim.convert(Image.FORMAT_RGBA8)
		resim.resize(HUCRE.x, HUCRE.y, Image.INTERPOLATE_LANCZOS)
		var konum: Vector2i = Vector2i((i % SUTUN) * HUCRE.x, (i / SUTUN) * HUCRE.y)
		atlas.blit_rect(resim, Rect2i(Vector2i.ZERO, HUCRE), konum)
		dizin[ulke_id] = i
	DirAccess.make_dir_recursive_absolute(kok.path_join("assets/flags"))
	atlas.save_png(kok.path_join("assets/flags/flags.png"))
	var dosya: FileAccess = FileAccess.open(kok.path_join("assets/flags/flags.json"), FileAccess.WRITE)
	dosya.store_string(JSON.stringify({"hucre": [HUCRE.x, HUCRE.y], "sutun": SUTUN, "ulkeler": dizin}, "\t", true))
	dosya.close()
	print("Bayrak atlası: %d bayrak, %d x %d" % [dizin.size(), atlas.get_width(), atlas.get_height()])
	quit(0)
