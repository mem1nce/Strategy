class_name SiralamaPaneli
extends PanelContainer
## Üst çubuktaki "Sıralama" düğmesiyle açılıp kapanan, güç sıralamasını gösteren başlıklı
## panel: ilk 10 ülke (sıra, bayrak, ad, güç çubuğu ve değeri), oyuncunun ülkesi ilk 10'da
## değilse ayrıca bir ayraçla. Oyuncunun satırı vurgu renginde bir kartla gösterilir.

const GENISLIK: float = 640.0
const BAYRAK_YUKSEKLIGI: float = 30.0
const CUBUK_GENISLIGI: float = 140.0

var _govde: VBoxContainer = null


func _ready() -> void:
	custom_minimum_size = Vector2(GENISLIK, 0.0)
	var panel: BaslikliPanel = BaslikliPanel.new("Güç sıralaması")
	panel.isaret_ayarla(Simgeler.dugum("siralama", 40.0, ArayuzTemasi.VURGU))
	# Başlıklı panel kendi zeminini çizer; bu düğüm yalnızca kap.
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	add_child(panel)
	_govde = panel.govde
	_govde.add_theme_constant_override("separation", 4)
	hide()


## `siralama`, Oyun.guc_siralamasi()'nin döndürdüğü listedir (büyükten küçüğe sıralı).
func goster(siralama: Array[Dictionary], dunya: Dunya, oyuncu_ulkesi: String) -> void:
	for cocuk: Node in _govde.get_children():
		_govde.remove_child(cocuk)
		cocuk.queue_free()
	var en_guc: float = maxf(float(siralama[0]["guc"]) if not siralama.is_empty() else 1.0, 1.0)
	var oyuncu_sirasi: int = -1
	var sinir: int = mini(10, siralama.size())
	for i: int in sinir:
		if siralama[i]["ulke_id"] == oyuncu_ulkesi:
			oyuncu_sirasi = i
		_satir_ekle(i + 1, siralama[i], dunya, siralama[i]["ulke_id"] == oyuncu_ulkesi, en_guc)
	if oyuncu_ulkesi != "" and oyuncu_sirasi == -1:
		for i: int in range(sinir, siralama.size()):
			if siralama[i]["ulke_id"] == oyuncu_ulkesi:
				_govde.add_child(HSeparator.new())
				_satir_ekle(i + 1, siralama[i], dunya, true, en_guc)
				break
	show()


func _satir_ekle(sira: int, oge: Dictionary, dunya: Dunya, vurgulu: bool, en_guc: float) -> void:
	var ulke: Ulke = dunya.ulkeler.get(oge["ulke_id"])
	if ulke == null:
		return
	var kap: PanelContainer = PanelContainer.new()
	var zemin: StyleBoxFlat = ArayuzTemasi.kutu(ArayuzTemasi.BASILI_YUZEY if vurgulu else Color(0, 0, 0, 0),
			ArayuzTemasi.KOSE, ArayuzTemasi.BOSLUK_1)
	if vurgulu:
		zemin.border_color = ArayuzTemasi.VURGU
		zemin.set_border_width_all(2)
	kap.add_theme_stylebox_override("panel", zemin)
	_govde.add_child(kap)
	var satir: HBoxContainer = Bilesenler.sira(ArayuzTemasi.BOSLUK_2)
	kap.add_child(satir)

	var sira_etiketi: Label = Label.new()
	sira_etiketi.text = "%d" % sira
	sira_etiketi.custom_minimum_size = Vector2(44.0, 0.0)
	sira_etiketi.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	sira_etiketi.add_theme_font_override("font", ArayuzTemasi.arayuz_fontu(600))
	sira_etiketi.add_theme_color_override("font_color", ArayuzTemasi.VURGU if sira <= 3 else ArayuzTemasi.IKINCIL_YAZI)
	satir.add_child(sira_etiketi)
	satir.add_child(Bayraklar.dugum(ulke, BAYRAK_YUKSEKLIGI))

	var ad: Label = Label.new()
	ad.text = ulke.ad
	ad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ad.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	if vurgulu:
		ad.add_theme_color_override("font_color", ArayuzTemasi.VURGU)
	satir.add_child(ad)

	var cubuk: ProgressBar = Bilesenler.ilerleme_cubugu(ArayuzTemasi.VURGU if vurgulu else ArayuzTemasi.IKINCIL_YAZI, 10.0)
	cubuk.custom_minimum_size.x = CUBUK_GENISLIGI
	cubuk.value = float(oge["guc"]) / en_guc
	satir.add_child(cubuk)

	var guc: Label = Label.new()
	guc.text = Bicim.kisa(float(oge["guc"]))
	guc.custom_minimum_size = Vector2(90.0, 0.0)
	guc.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	guc.add_theme_font_override("font", ArayuzTemasi.arayuz_fontu(600))
	satir.add_child(guc)
