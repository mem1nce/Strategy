class_name Bayraklar
extends RefCounted
## Ülke bayrakları: lipis/flag-icons (MIT) SVG'lerinden üretilmiş tek bir doku atlası
## (assets/flags/, bkz. tools/bayrak_indir.py ve tools/bayrak_atlasi.gd). Bayrağı olmayan
## ülkeye (Natural Earth'te ISO_A2 kodu eşleşmeyen) ülke renginde sade bir yedek bayrak
## çizilir. Dokular bir kez kurulup önbellekte tutulur.

const ATLAS: String = "res://assets/flags/flags.png"
const DIZIN: String = "res://assets/flags/flags.json"
## Yedek bayrağın boyutu (atlastaki hücreyle aynı oran, 4:3).
const YEDEK_BOYUT: Vector2i = Vector2i(96, 72)

static var _atlas: Texture2D = null
static var _hucre: Vector2i = Vector2i(96, 72)
static var _sutun: int = 16
static var _sira: Dictionary = {}
static var _dokular: Dictionary[String, Texture2D] = {}


static func _yukle() -> void:
	if _atlas != null:
		return
	_atlas = load(ATLAS)
	var veri: Dictionary = VeriOkuyucu.sozluk_oku(DIZIN)
	var hucre: Array = veri.get("hucre", [96, 72])
	_hucre = Vector2i(int(hucre[0]), int(hucre[1]))
	_sutun = int(veri.get("sutun", 16))
	_sira = veri.get("ulkeler", {})


## Ülkenin bayrağı (4:3). Atlasta yoksa ülke renginde yedek bayrak.
static func doku(ulke: Ulke) -> Texture2D:
	if ulke == null:
		return null
	if _dokular.has(ulke.id):
		return _dokular[ulke.id]
	_yukle()
	var sonuc: Texture2D = null
	if _atlas != null and _sira.has(ulke.id):
		var sira: int = int(_sira[ulke.id])
		var parca: AtlasTexture = AtlasTexture.new()
		parca.atlas = _atlas
		@warning_ignore("integer_division")
		parca.region = Rect2((sira % _sutun) * _hucre.x, (sira / _sutun) * _hucre.y, _hucre.x, _hucre.y)
		sonuc = parca
	else:
		sonuc = _yedek(HaritaPaleti.ulke_rengi(ulke))
	_dokular[ulke.id] = sonuc
	return sonuc


## Atlasta bu ülkenin gerçek bayrağı var mı (yoksa yedek çizilir)?
static func gercek_mi(ulke_id: String) -> bool:
	_yukle()
	return _sira.has(ulke_id)


## Ülke renginde sade yedek bayrak: düz zemin, ortada açık bir yatay şerit.
static func _yedek(renk: Color) -> Texture2D:
	var resim: Image = Image.create_empty(YEDEK_BOYUT.x, YEDEK_BOYUT.y, false, Image.FORMAT_RGBA8)
	resim.fill(renk)
	@warning_ignore("integer_division")
	resim.fill_rect(Rect2i(0, YEDEK_BOYUT.y / 3, YEDEK_BOYUT.x, YEDEK_BOYUT.y / 3), renk.lightened(0.35))
	return ImageTexture.create_from_image(resim)


## Bayrak düğümü: verilen yükseklikte, 4:3.
static func dugum(ulke: Ulke, yukseklik: float) -> TextureRect:
	var bayrak: TextureRect = TextureRect.new()
	bayrak.texture = doku(ulke)
	bayrak.custom_minimum_size = Vector2(yukseklik * 4.0 / 3.0, yukseklik)
	bayrak.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bayrak.stretch_mode = TextureRect.STRETCH_SCALE
	bayrak.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bayrak.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return bayrak
