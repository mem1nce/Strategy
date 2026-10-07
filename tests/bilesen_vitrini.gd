extends SceneTree
## Ortak bileşenlerin (STIL.md) hepsini tek ekranda gösterip görüntüsünü alır.
##
## Çalıştırmak için (proje klasöründen, headless OLMADAN):
##   Godot --path . --resolution 1600x900 --script res://tests/bilesen_vitrini.gd -- docs/gorsel/stil_vitrini.jpg


func _initialize() -> void:
	_calistir.call_deferred()


func _calistir() -> void:
	var argumanlar: PackedStringArray = OS.get_cmdline_user_args()
	var yol: String = argumanlar[0] if argumanlar.size() > 0 else "docs/gorsel/stil_vitrini.jpg"
	if not yol.is_absolute_path():
		yol = ProjectSettings.globalize_path("res://").path_join(yol)
	RenderingServer.set_default_clear_color(ArayuzTemasi.ZEMIN)

	var kok: Control = Control.new()
	kok.theme = ArayuzTemasi.olustur()
	kok.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(kok)
	var kenar: MarginContainer = MarginContainer.new()
	kenar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for taraf: String in ["left", "top", "right", "bottom"]:
		kenar.add_theme_constant_override("margin_" + taraf, ArayuzTemasi.BOSLUK_4)
	kok.add_child(kenar)
	var sutunlar: HBoxContainer = Bilesenler.sira(ArayuzTemasi.BOSLUK_4)
	kenar.add_child(sutunlar)

	var sol: VBoxContainer = Bilesenler.yigin(ArayuzTemasi.BOSLUK_3)
	sol.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sutunlar.add_child(sol)
	sol.add_child(Bilesenler.baslik("Yerküre", ArayuzTemasi.YAZI_DEV))
	var dugmeler: HBoxContainer = Bilesenler.sira()
	sol.add_child(dugmeler)
	dugmeler.add_child(Bilesenler.birincil_dugme("Bu ülkeyle oyna", "oynat", Vector2(360, 104)))
	dugmeler.add_child(Bilesenler.ikincil_dugme("Komşular", "diplomasi", Vector2(280, 104)))
	var kapali: Button = Bilesenler.ikincil_dugme("Kapalı", "", Vector2(200, 104))
	kapali.disabled = true
	dugmeler.add_child(kapali)
	var sekmeler: SekmeGrubu = SekmeGrubu.new()
	sekmeler.ekle("", "siyasi")
	sekmeler.ekle("", "diplomasi")
	sekmeler.ekle("", "ekonomi")
	sekmeler.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	sol.add_child(sekmeler)
	var rozetler: HBoxContainer = Bilesenler.sira(ArayuzTemasi.BOSLUK_1)
	sol.add_child(rozetler)
	rozetler.add_child(Bilesenler.rozet("Başkent", ArayuzTemasi.VURGU, ArayuzTemasi.VURGU_USTU))
	rozetler.add_child(Bilesenler.rozet("Savaşta", ArayuzTemasi.TEHLIKE))
	rozetler.add_child(Bilesenler.rozet("Barış", ArayuzTemasi.BASARI))
	rozetler.add_child(Bilesenler.rozet("Tarafsız"))
	var cubuk: ProgressBar = Bilesenler.ilerleme_cubugu()
	cubuk.value = 0.62
	sol.add_child(cubuk)
	var kart: PanelContainer = Bilesenler.kart()
	sol.add_child(kart)
	var kart_ici: VBoxContainer = Bilesenler.yigin()
	kart.add_child(kart_ici)
	var yazi: Label = Label.new()
	yazi.text = "Kart: panel içindeki ikinci katman. Türkçe: ğüşıöç ĞÜŞİÖÇ"
	kart_ici.add_child(yazi)
	kart_ici.add_child(Bilesenler.ikincil_yazi("İkincil yazı: 83,4 Mn · 761 Mr $ · 1,25 B"))
	var simgeler: HFlowContainer = HFlowContainer.new()
	simgeler.add_theme_constant_override("h_separation", ArayuzTemasi.BOSLUK_2)
	simgeler.add_theme_constant_override("v_separation", ArayuzTemasi.BOSLUK_2)
	sol.add_child(simgeler)
	for dosya: String in DirAccess.get_files_at("res://art/icons"):
		if dosya.ends_with(".svg"):
			simgeler.add_child(Simgeler.dugum(dosya.get_basename(), 40.0, ArayuzTemasi.YAZI))

	var sag: VBoxContainer = Bilesenler.yigin(ArayuzTemasi.BOSLUK_3)
	sag.custom_minimum_size = Vector2(560, 0)
	sutunlar.add_child(sag)
	var oyun_dunyasi: Dunya = Dunya.yukle()
	var panel: BaslikliPanel = BaslikliPanel.new("Türkiye")
	panel.isaret_ayarla(Bayraklar.dugum(oyun_dunyasi.ulkeler["TUR"], 48.0))
	panel.sag_alan.add_child(Bilesenler.rozet("Oyuncu", ArayuzTemasi.VURGU, ArayuzTemasi.VURGU_USTU))
	sag.add_child(panel)
	for satir: Array in [["nufus", "Nüfus", "83,4 Mn"], ["sanayi", "Sanayi", "12,3 / gün"],
			["ordu", "Ordu", "14 tümen"], ["para", "Hazine", "1,25 B"]]:
		var istatistik: IstatistikSatiri = IstatistikSatiri.new(satir[0], satir[1])
		istatistik.deger_ayarla(satir[2])
		panel.govde.add_child(istatistik)
	var bayraklar: HBoxContainer = Bilesenler.sira(ArayuzTemasi.BOSLUK_1)
	panel.govde.add_child(bayraklar)
	for ulke_id: String in ["FRA", "DEU", "JPN", "BRA", "CYN", "TWN"]:
		bayraklar.add_child(Bayraklar.dugum(oyun_dunyasi.ulkeler[ulke_id], 40.0))

	for i: int in 30:
		await process_frame
	root.get_texture().get_image().save_jpg(yol, 0.9)
	print("goruntu: ", yol)
	quit(0)
