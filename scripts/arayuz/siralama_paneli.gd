class_name SiralamaPaneli
extends PanelContainer
## Üst çubuktaki "Sıralama" düğmesiyle açılıp kapanan başlıklı panel; iki sekmesi vardır:
## - Güç: ilk 10 ülke (sıra, bayrak, ad, güç çubuğu ve değeri).
## - Ekonomi: günlük gelirine göre ilk 10 ülke (gelir çubuğu ve değeri, yanında günlük ticaret geliri).
## Oyuncunun ülkesi ilk 10'da değilse ayrıca bir ayraçla gösterilir; oyuncunun satırı vurgu
## renginde bir kartla çizilir.

const GENISLIK: float = 900.0
const BAYRAK_YUKSEKLIGI: float = 30.0
const CUBUK_GENISLIGI: float = 140.0
const SEKMELER: Array[String] = ["Güç", "Ekonomi"]

var _govde: VBoxContainer = null
var _liste: VBoxContainer = null
var _panel: BaslikliPanel = null
var _sekme: int = 0
var _guc: Array[Dictionary] = []
var _ekonomi: Array[Dictionary] = []
var _dunya: Dunya = null
var _oyuncu: String = ""


func _ready() -> void:
	custom_minimum_size = Vector2(GENISLIK, 0.0)
	_panel = BaslikliPanel.new("Sıralama")
	_panel.isaret_ayarla(Simgeler.dugum("siralama", 40.0, ArayuzTemasi.VURGU))
	# Başlıklı panel kendi zeminini çizer; bu düğüm yalnızca kap.
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	add_child(_panel)
	_govde = _panel.govde
	var sekmeler: SekmeGrubu = SekmeGrubu.new()
	sekmeler.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	for ad: String in SEKMELER:
		sekmeler.ekle(ad, "", Vector2(150.0, 96.0))
	sekmeler.secildi.connect(func(sira: int) -> void:
		_sekme = sira
		_listeyi_kur())
	# Sekmeler başlığın sağında durur (panel kısa kalsın, ekrana sığsın).
	_panel.sag_alan.add_child(sekmeler)
	_liste = Bilesenler.yigin(4)
	_govde.add_child(_liste)
	hide()


## `siralama`, Oyun.guc_siralamasi()'nin; `ekonomi`, Ekonomi.ekonomi_siralamasi()'nın
## döndürdüğü listedir (büyükten küçüğe sıralı).
func goster(siralama: Array[Dictionary], dunya: Dunya, oyuncu_ulkesi: String,
		ekonomi: Array[Dictionary] = []) -> void:
	_guc = siralama
	_ekonomi = ekonomi
	_dunya = dunya
	_oyuncu = oyuncu_ulkesi
	_listeyi_kur()
	show()


func _listeyi_kur() -> void:
	for cocuk: Node in _liste.get_children():
		_liste.remove_child(cocuk)
		cocuk.queue_free()
	var ekonomi: bool = _sekme == 1
	var liste: Array[Dictionary] = _ekonomi if ekonomi else _guc
	var alan: String = "gelir" if ekonomi else "guc"
	var en_buyuk: float = maxf(float(liste[0][alan]) if not liste.is_empty() else 1.0, 0.001)
	var oyuncu_sirasi: int = -1
	var sinir: int = mini(10, liste.size())
	for i: int in sinir:
		if liste[i]["ulke_id"] == _oyuncu:
			oyuncu_sirasi = i
		_satir_ekle(i + 1, liste[i], liste[i]["ulke_id"] == _oyuncu, en_buyuk, ekonomi)
	if _oyuncu != "" and oyuncu_sirasi == -1:
		for i: int in range(sinir, liste.size()):
			if liste[i]["ulke_id"] == _oyuncu:
				_liste.add_child(HSeparator.new())
				_satir_ekle(i + 1, liste[i], true, en_buyuk, ekonomi)
				break


func _satir_ekle(sira: int, oge: Dictionary, vurgulu: bool, en_buyuk: float, ekonomi: bool) -> void:
	var ulke: Ulke = _dunya.ulkeler.get(oge["ulke_id"])
	if ulke == null:
		return
	var kap: PanelContainer = PanelContainer.new()
	var zemin: StyleBoxFlat = ArayuzTemasi.kutu(ArayuzTemasi.BASILI_YUZEY if vurgulu else Color(0, 0, 0, 0),
			ArayuzTemasi.KOSE, ArayuzTemasi.BOSLUK_1)
	if vurgulu:
		zemin.border_color = ArayuzTemasi.VURGU
		zemin.set_border_width_all(2)
	kap.add_theme_stylebox_override("panel", zemin)
	_liste.add_child(kap)
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

	var deger: float = float(oge["gelir" if ekonomi else "guc"])
	var cubuk: ProgressBar = Bilesenler.ilerleme_cubugu(ArayuzTemasi.VURGU if vurgulu else ArayuzTemasi.IKINCIL_YAZI, 10.0)
	cubuk.custom_minimum_size.x = CUBUK_GENISLIGI
	cubuk.value = deger / en_buyuk
	satir.add_child(cubuk)

	var deger_yazisi: Label = Label.new()
	deger_yazisi.text = "+%s" % Bicim.tutar(deger) if ekonomi else Bicim.kisa(deger)
	deger_yazisi.custom_minimum_size = Vector2(90.0, 0.0)
	deger_yazisi.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	deger_yazisi.add_theme_font_override("font", ArayuzTemasi.arayuz_fontu(600))
	satir.add_child(deger_yazisi)
	if ekonomi:
		# Günlük ticaret geliri, simgesiyle.
		var ticaret: HBoxContainer = Bilesenler.simgeli_deger("ticaret", ArayuzTemasi.IKINCIL_YAZI)
		ticaret.custom_minimum_size.x = 110.0
		(ticaret.get_child(1) as Label).text = Bicim.tutar(float(oge.get("ticaret", 0.0)))
		satir.add_child(ticaret)
