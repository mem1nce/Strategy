class_name HaritaModuSecici
extends VBoxContainer
## Haritanın sol kenarındaki mod düğmeleri (Siyasi / Diplomasi / Ekonomi) ve seçili modun
## küçük açıklama kartı. Modu yalnızca bildirir; haritayı main.gd boyar
## (HaritaGorunumu.modu_ayarla).

signal mod_secildi(mod: HaritaPaleti.Mod)

const DUGME_BOYUTU: Vector2 = Vector2(96.0, 96.0)
const RENK_KUTUSU_BOYUTU: Vector2 = Vector2(22.0, 22.0)
const MERDIVEN_BOYUTU: Vector2 = Vector2(150.0, 16.0)

var _sekmeler: SekmeGrubu = null
var _aciklama: PanelContainer = null
var _aciklama_icerigi: VBoxContainer = null


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("separation", ArayuzTemasi.BOSLUK_1)
	_sekmeler = SekmeGrubu.new(true)
	_sekmeler.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	add_child(_sekmeler)
	for simge: String in ["siyasi", "diplomasi", "ekonomi"]:
		_sekmeler.ekle("", simge, DUGME_BOYUTU)
	_sekmeler.secildi.connect(_secildi)

	_aciklama = Bilesenler.kart()
	_aciklama.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_aciklama.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_aciklama.hide()
	add_child(_aciklama)
	_aciklama_icerigi = Bilesenler.yigin(ArayuzTemasi.BOSLUK_1)
	_aciklama.add_child(_aciklama_icerigi)


func _secildi(sira: int) -> void:
	var mod: HaritaPaleti.Mod = sira as HaritaPaleti.Mod
	_aciklamayi_kur(mod)
	mod_secildi.emit(mod)


## Siyasi modda açıklama gizlidir (renkler ülkelerindir); öbür modlarda renklerin anlamı yazılır.
func _aciklamayi_kur(mod: HaritaPaleti.Mod) -> void:
	for cocuk: Node in _aciklama_icerigi.get_children():
		cocuk.queue_free()
	_aciklama.visible = mod != HaritaPaleti.Mod.SIYASI
	match mod:
		HaritaPaleti.Mod.DIPLOMASI:
			_aciklama_icerigi.add_child(Bilesenler.baslik("Diplomasi", ArayuzTemasi.YAZI_KUCUK))
			_renk_satiri_ekle(HaritaPaleti.BEN_RENGI, "Sen")
			_renk_satiri_ekle(HaritaPaleti.DUSMAN_RENGI, "Savaştığın")
			_renk_satiri_ekle(HaritaPaleti.TARAFSIZ_RENGI, "Tarafsız")
		HaritaPaleti.Mod.EKONOMI:
			_aciklama_icerigi.add_child(Bilesenler.baslik("Sanayi", ArayuzTemasi.YAZI_KUCUK))
			var merdiven: TextureRect = TextureRect.new()
			merdiven.texture = _merdiven_dokusu()
			merdiven.custom_minimum_size = MERDIVEN_BOYUTU
			merdiven.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			merdiven.stretch_mode = TextureRect.STRETCH_SCALE
			_aciklama_icerigi.add_child(merdiven)
			var uclar: HBoxContainer = Bilesenler.sira()
			var az: Label = Bilesenler.ikincil_yazi("Az")
			az.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			uclar.add_child(az)
			uclar.add_child(Bilesenler.ikincil_yazi("Çok"))
			_aciklama_icerigi.add_child(uclar)


func _renk_satiri_ekle(renk: Color, metin: String) -> void:
	var satir: HBoxContainer = Bilesenler.sira(ArayuzTemasi.BOSLUK_1)
	var kutu: PanelContainer = PanelContainer.new()
	kutu.custom_minimum_size = RENK_KUTUSU_BOYUTU
	kutu.add_theme_stylebox_override("panel", ArayuzTemasi.kutu(renk, 6, 0))
	kutu.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	satir.add_child(kutu)
	satir.add_child(Bilesenler.ikincil_yazi(metin))
	_aciklama_icerigi.add_child(satir)


static func _merdiven_dokusu() -> GradientTexture1D:
	var gecis: Gradient = Gradient.new()
	var renkler: PackedColorArray = PackedColorArray(HaritaPaleti.EKONOMI_MERDIVENI)
	var konumlar: PackedFloat32Array = PackedFloat32Array()
	for i: int in renkler.size():
		konumlar.append(float(i) / (renkler.size() - 1))
	gecis.colors = renkler
	gecis.offsets = konumlar
	var doku: GradientTexture1D = GradientTexture1D.new()
	doku.gradient = gecis
	return doku
