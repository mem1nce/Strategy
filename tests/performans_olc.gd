extends SceneTree
## Haritanın kare süresini ölçer (dikey eşitleme kapalı): dünya, Avrupa ve yakın görünümde,
## oyun 1× hızda akarken, "Grafik: Yüksek" ve "Düşük" için ortalama ve en kötü kare süresi.
##
## Çalıştırmak için (proje klasöründen, headless OLMADAN):
##   Godot --path . --resolution 1920x1080 --script res://tests/performans_olc.gd
## Bilgisayarda ölçülür; telefon bundan birkaç kat yavaştır, sonuç göreli karşılaştırma içindir.

const OLCUM_KARESI: int = 240

var _ana: Node = null


func _initialize() -> void:
	KayitYoneticisi.kayit_dosyasi = "user://sinama_kayit.json"
	Ayarlar.ayar_dosyasi = "user://sinama_ayarlar.json"
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	_calistir.call_deferred()


func _bekle(kare: int) -> void:
	for i: int in kare:
		await process_frame


func _olc(ad: String) -> void:
	await _bekle(30)
	var sureler: PackedFloat64Array = PackedFloat64Array()
	var onceki: int = Time.get_ticks_usec()
	for i: int in OLCUM_KARESI:
		await process_frame
		var simdi: int = Time.get_ticks_usec()
		sureler.append((simdi - onceki) / 1000.0)
		onceki = simdi
	var toplam: float = 0.0
	var en_kotu: float = 0.0
	for sure: float in sureler:
		toplam += sure
		en_kotu = maxf(en_kotu, sure)
	var ortalama: float = toplam / sureler.size()
	print("%-28s ortalama %.2f ms (%.0f FPS), en kötü %.2f ms" % [ad, ortalama, 1000.0 / ortalama, en_kotu])


func _calistir() -> void:
	_ana = load("res://scenes/main.tscn").instantiate()
	root.add_child(_ana)
	await _bekle(5)
	_ana.get("_ana_menu").call("_yeni_oyun_onaylandi")
	var oyun: Oyun = _ana.get("_oyun")
	oyun.oyuncuyu_sec("TUR")
	var zaman: Node = root.get_node("Zaman")
	zaman.hiz_sec(1)
	if zaman.durdu:
		zaman.durdurmayi_degistir()
	var kamera: Node = _ana.get("_kamera")
	var harita: Node = _ana.get("_harita")
	for dusuk: bool in [false, true, false, true]:
		Ayarlar.grafik_dusuk = dusuk
		harita.call("grafigi_uygula")
		var etiket: String = "Düşük" if dusuk else "Yüksek"
		kamera.call("dunyayi_goster")
		await _olc("Dünya / " + etiket)
		kamera.call("odaklan", Rect2(oyun.dunya.bolgeler["DEU_1"].etiket - Vector2(350, 175), Vector2(700, 350)))
		await _olc("Avrupa / " + etiket)
		kamera.call("odaklan", Rect2(oyun.dunya.bolgeler["TUR_1"].etiket - Vector2(100, 50), Vector2(200, 100)))
		await _olc("Yakın (Türkiye) / " + etiket)
	Ayarlar.grafik_dusuk = false
	quit(0)
