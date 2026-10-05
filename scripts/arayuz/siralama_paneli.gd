class_name SiralamaPaneli
extends PanelContainer
## Üst çubuktaki "Sıralama" düğmesiyle açılıp kapanan, güç sıralamasını gösteren panel:
## ilk 10 ülke, oyuncunun ülkesi ilk 10'da değilse ayrıca bir ayraçla.

const GENISLIK: float = 560.0
const BASLIK_YAZI_BOYUTU: int = 40
const SATIR_YAZI_BOYUTU: int = 32
const RENK_KUTUSU_BOYUTU: float = 28.0

var _dikey: VBoxContainer = null


func _ready() -> void:
	custom_minimum_size = Vector2(GENISLIK, 0.0)
	_dikey = VBoxContainer.new()
	_dikey.add_theme_constant_override("separation", 6)
	add_child(_dikey)
	hide()


## `siralama`, Oyun.guc_siralamasi()'nin döndürdüğü listedir (büyükten küçüğe sıralı).
func goster(siralama: Array[Dictionary], dunya: Dunya, oyuncu_ulkesi: String) -> void:
	for cocuk: Node in _dikey.get_children():
		_dikey.remove_child(cocuk)
		cocuk.queue_free()

	var baslik: Label = Label.new()
	baslik.text = "Güç sıralaması"
	baslik.add_theme_font_size_override("font_size", BASLIK_YAZI_BOYUTU)
	_dikey.add_child(baslik)

	var oyuncu_sirasi: int = -1
	var sinir: int = mini(10, siralama.size())
	for i: int in sinir:
		if siralama[i]["ulke_id"] == oyuncu_ulkesi:
			oyuncu_sirasi = i
		_satir_ekle(i + 1, siralama[i], dunya, siralama[i]["ulke_id"] == oyuncu_ulkesi)

	if oyuncu_ulkesi != "" and oyuncu_sirasi == -1:
		for i: int in range(sinir, siralama.size()):
			if siralama[i]["ulke_id"] == oyuncu_ulkesi:
				_dikey.add_child(HSeparator.new())
				_satir_ekle(i + 1, siralama[i], dunya, true)
				break

	show()


func _satir_ekle(sira: int, oge: Dictionary, dunya: Dunya, vurgulu: bool) -> void:
	var ulke: Ulke = dunya.ulkeler.get(oge["ulke_id"])
	if ulke == null:
		return
	var satir: HBoxContainer = HBoxContainer.new()
	satir.add_theme_constant_override("separation", 12)
	_dikey.add_child(satir)

	var sira_etiketi: Label = Label.new()
	sira_etiketi.text = "%d." % sira
	sira_etiketi.custom_minimum_size = Vector2(50.0, 0.0)
	satir.add_child(sira_etiketi)

	var renk_kutusu: ColorRect = ColorRect.new()
	renk_kutusu.color = HaritaGorunumu.ulke_rengi(ulke)
	renk_kutusu.custom_minimum_size = Vector2(RENK_KUTUSU_BOYUTU, RENK_KUTUSU_BOYUTU)
	renk_kutusu.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	renk_kutusu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	satir.add_child(renk_kutusu)

	var ad: Label = Label.new()
	ad.text = ulke.ad
	ad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ad.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	satir.add_child(ad)

	var guc: Label = Label.new()
	guc.text = str(roundi(oge["guc"]))
	satir.add_child(guc)

	if vurgulu:
		for etiket: Label in [sira_etiketi, ad, guc]:
			etiket.add_theme_color_override("font_color", ArayuzTemasi.ETKIN_RENK)
	for etiket: Label in [sira_etiketi, ad, guc]:
		etiket.add_theme_font_size_override("font_size", SATIR_YAZI_BOYUTU)
