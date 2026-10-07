extends SceneTree
## Görsel karşılaştırma için ekran görüntüleri alır (docs/gorsel/).
##
## Çalıştırmak için (proje klasöründen, headless OLMADAN):
##   Godot --path . --resolution 1600x900 --script res://tests/gorsel_cek.gd -- <klasör> <önek>
## Örnek: ... -- docs/gorsel/sonra 16x9_
## Oyuncunun gerçek kaydına ve ayarlarına dokunmaz (sınama dosyalarını kullanır).

var _klasor: String = ""
var _onek: String = ""
var _ana: Node = null


func _initialize() -> void:
	var argumanlar: PackedStringArray = OS.get_cmdline_user_args()
	_klasor = argumanlar[0] if argumanlar.size() > 0 else "docs/gorsel"
	_onek = argumanlar[1] if argumanlar.size() > 1 else ""
	if not _klasor.is_absolute_path():
		_klasor = ProjectSettings.globalize_path("res://").path_join(_klasor)
	DirAccess.make_dir_recursive_absolute(_klasor)
	KayitYoneticisi.kayit_dosyasi = "user://sinama_kayit.json"
	Ayarlar.ayar_dosyasi = "user://sinama_ayarlar.json"
	_calistir.call_deferred()


func _bekle(kare: int) -> void:
	for i: int in kare:
		await process_frame


func _cek(ad: String, bekleme: int = 40) -> void:
	await _bekle(bekleme)
	# JPG (yüksek kalite): PNG'ye göre depoda ~5 kat az yer tutar.
	var yol: String = _klasor.path_join(_onek + ad + ".jpg")
	root.get_texture().get_image().save_jpg(yol, 0.88)
	print("goruntu: ", yol)


func _odaklan(bolge_id: String, boyut: Vector2) -> void:
	var oyun: Oyun = _ana.get("_oyun")
	var merkez: Vector2 = oyun.dunya.bolgeler[bolge_id].etiket
	_ana.get("_kamera").odaklan(Rect2(merkez - boyut * 0.5, boyut))
	await _bekle(70)


func _calistir() -> void:
	_ana = load("res://scenes/main.tscn").instantiate()
	root.add_child(_ana)
	var menu: Node = _ana.get("_ana_menu")
	var arayuz: Node = _ana.get("_arayuz")
	await _cek("05_ana_menu", 60)
	menu.call("_alt_paneli_ac", menu.get("_ayarlar_paneli"))
	await _cek("12_ayarlar")
	menu.call("_alt_paneli_kapat", menu.get("_ayarlar_paneli"))
	menu.call("_alt_paneli_ac", menu.get("_nasil_oynanir_paneli"))
	await _cek("13_nasil_oynanir")
	menu.call("_alt_paneli_kapat", menu.get("_nasil_oynanir_paneli"))
	menu.call("_yeni_oyun_onaylandi")
	var oyun: Oyun = _ana.get("_oyun")
	var zaman: Node = root.get_node("Zaman")
	await _cek("01_dunya")
	_ana.call("_bolgeyi_sec", "FRA_1")
	await _cek("06_ulke_secimi")
	_ana.call("_bolgeyi_sec", "")
	oyun.oyuncuyu_sec("TUR")
	zaman.durdur()
	oyun.hazineler["TUR"] = 2500.0
	oyun.hazine_degisti.emit()
	await _odaklan("DEU_1", Vector2(420, 210))
	await _cek("02_avrupa")
	await _odaklan("IRQ_1", Vector2(320, 160))
	await _cek("03_ortadogu")
	await _odaklan("KOR_1", Vector2(360, 180))
	await _cek("04_dogu_asya")

	# Türkiye ile Yunanistan savaşta: yürüyüş yolu, muharebe ve bildirim.
	await _odaklan("TUR_2", Vector2(200, 100))
	_ana.call("_bolgeyi_sec", "TUR_1")
	await _cek("08_birlik_paneli")
	_ana.call("_bolgeyi_sec", "")
	var bos: String = ""
	for bolge: Bolge in oyun.dunya.ulkenin_bolgeleri("TUR"):
		if oyun.bolgedeki_birlikler(bolge.id).is_empty():
			bos = bolge.id
			break
	# Harita simgeleri görünsün diye bu bölgede tahkimat ve fabrika varmış gibi gösterilir.
	oyun.dunya.bolgeler[bos].tahkimat = 2
	oyun.dunya.bolgeler[bos].fabrika_sanayisi = 2.0
	_ana.call("_bolgeyi_sec", bos)
	await _cek("07_bolge_paneli")
	arayuz.call("_insa_basildi", "tumen")
	await _cek("09_tumen_secimi")
	arayuz.get("_tumen_secim_paneli").hide()
	_ana.call("_bolgeyi_sec", "")
	oyun.teknolojiler["TUR"] = {"sanayi": 2, "silah": 1}
	oyun.arastirma_baslat("TUR", "lojistik")
	arayuz.call("_teknoloji_degisti", true)
	await _cek("10_teknoloji")
	arayuz.call("_siralama_degisti", true)
	await _cek("11_siralama")
	arayuz.call("_siralama_degisti", false)

	oyun.savas_ilan_et("TUR", "GRC", zaman.toplam_saat)
	var kaynak: String = ""
	var hedef: String = ""
	for bolge: Bolge in oyun.dunya.ulkenin_bolgeleri("TUR"):
		for komsu: Bolge in oyun.dunya.bolgenin_kara_komsulari(bolge.id):
			if komsu.sahip == "GRC" and not oyun.bolgedeki_birlikler(bolge.id).is_empty():
				kaynak = bolge.id
				hedef = komsu.id
	var merkez: Vector2 = oyun.dunya.bolgeler[kaynak].etiket.lerp(oyun.dunya.bolgeler[hedef].etiket, 0.5)
	_ana.get("_kamera").odaklan(Rect2(merkez - Vector2(60, 30), Vector2(120, 60)))
	await _bekle(70)
	oyun.birlikleri_yurut(oyun.bolgedeki_birlikler(kaynak), hedef, zaman.toplam_saat)
	var varis: int = oyun.bolgedeki_birlikler(kaynak)[0].varis_saati
	var orta: int = zaman.toplam_saat + (varis - zaman.toplam_saat) / 2
	while zaman.toplam_saat < orta:
		zaman.bir_saat_ilerle()
	await _cek("14_yuruyus")
	while zaman.toplam_saat < varis + 1:
		zaman.bir_saat_ilerle()
	oyun.bildirim_gonder.emit("Yunanistan'la muharebe başladı.", hedef)
	await _cek("15_muharebe_bildirim")

	# Harita modları (görsel yenilemeyle geldi; "önce" görüntülerinde yoktur).
	await _odaklan("DEU_1", Vector2(700, 350))
	var secici: SekmeGrubu = arayuz.get("_mod_secici").get("_sekmeler")
	(secici.get_child(0).get_child(1) as Button).button_pressed = true
	await _cek("16_diplomasi")
	(secici.get_child(0).get_child(2) as Button).button_pressed = true
	await _cek("17_ekonomi")
	(secici.get_child(0).get_child(0) as Button).button_pressed = true
	quit(0)
