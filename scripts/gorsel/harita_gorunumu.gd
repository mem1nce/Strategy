class_name HaritaGorunumu
extends Node2D
## Dünya haritasını çizer. Dunya verisini yalnızca okur; hiçbir şeyi değiştirmez.
##
## Harita "çokgen -> bölge -> sahip ülke" mantığıyla çizilir: her çokgen, bölgesinin o anki
## sahibinin rengini alır; sınır çizgisinin türü iki yanındaki bölgelerin sahibine göre
## belirlenir. Bir bölge el değiştirince yenile() çağrılır ve harita kendini günceller.
##
## Yüzlerce bölge tek tek düğüm yapılmaz; her şey birkaç toplu çizimle çıkar:
## - Bu düğüm bütün dolguları tek bir ağ (mesh) olarak çizer.
## - Üç çizgi katmanı (kıyı, ülke sınırı, bölge sınırı) birer ağdır. Kalınlıkları
##   gölgelendiricide ayarlandığı için yakınlık değişince baştan kurulmazlar.
## - Üst katman seçim çerçevelerini, komşu vurgularını ve adları çizer; yalnızca
##   ekranda görünen adlar çizilir.

const SINIR_GOLGELENDIRICISI: Shader = preload("res://scripts/gorsel/sinir_cizgisi.gdshader")

const DENIZ_RENGI: Color = Color("#1e2a36")
## Ülkelerin renk indeksine (1-9) karşılık gelen dokuz sakin renk.
const PALET: Array[Color] = [
	Color("#c97b6b"), Color("#d9a066"), Color("#d8c878"),
	Color("#9dbb6f"), Color("#6fae8f"), Color("#6fa8b8"),
	Color("#7f8fc4"), Color("#a584bd"), Color("#c487a6"),
]

# Çizgi renkleri ve kalınlıkları (kalınlıklar ekran pikseli cinsindendir).
const KIYI_RENGI: Color = Color(0.07, 0.09, 0.11, 0.9)
const KIYI_KALINLIGI: float = 1.5
const ULKE_SINIRI_RENGI: Color = Color(0.05, 0.06, 0.08, 0.95)
const ULKE_SINIRI_KALINLIGI: float = 3.0
## Uzaktan bakınca küçük ülkeler kalın çizgilerin altında kaybolmasın diye ülke sınırı incelir.
const UZAK_ULKE_SINIRI_KALINLIGI: float = 1.8
const BOLGE_SINIRI_RENGI: Color = Color(0.05, 0.06, 0.08, 0.4)
const BOLGE_SINIRI_KALINLIGI: float = 1.2
## Çizgi köşelerindeki gönye payının üst sınırı (sivri köşelerde çizgi uzayıp gitmesin).
const AZAMI_GONYE: float = 2.5

# Çerçeveler.
const SECIM_RENGI: Color = Color("#fff36b")
const SECIM_KALINLIGI: float = 5.0
## Seçili bölgenin ülkesi daha hafif bir çerçeveyle gösterilir.
const SECILI_ULKE_RENGI: Color = Color(1.0, 0.95, 0.42, 0.6)
const SECILI_ULKE_KALINLIGI: float = 2.5
const OYUNCU_RENGI: Color = Color.WHITE
const OYUNCU_KALINLIGI: float = 5.0
const CERCEVE_ALT_RENGI: Color = Color(0.0, 0.0, 0.0, 0.7)
## Çerçevelerin altındaki koyu şeridin, çerçeveden ne kadar taştığı.
const CERCEVE_ALT_PAYI: float = 4.0

# Komşu vurguları.
const KARA_KOMSUSU_RENGI: Color = Color("#2fe0b5")
const DENIZ_GECISI_RENGI: Color = Color("#ff8a2b")
const VURGU_OPAKLIGI: float = 0.62

# Yazılar.
const YAZI_RENGI: Color = Color.WHITE
const YAZI_KENAR_RENGI: Color = Color(0.0, 0.0, 0.0, 0.8)
const ASGARI_ULKE_ADI_BOYUTU: int = 24
const AZAMI_ULKE_ADI_BOYUTU: int = 52
## Ülke adının boyutu, ülkenin ekrandaki büyüklüğünün bu oranı kadardır.
const ULKE_ADI_ORANI: float = 0.16
## Ülke adı, ülkenin ekrandaki büyüklüğünün bu katından genişse gizlenir.
const ULKE_ADI_SIGMA_ORANI: float = 1.5
## Ülke ekranda bundan büyükse adı sığmasa da gösterilir (piksel).
const HER_ZAMAN_YAZ_ESIGI: float = 100.0
## Bölge adları belirince ülke adları bu opaklığa kadar solar...
const SOLUK_ULKE_ADI_OPAKLIGI: float = 0.3
## ...ve bu iki yakınlık arasında tümüyle kaybolur.
const ULKE_ADI_KAYBOLMA_BASI: float = 3.5
const ULKE_ADI_KAYBOLMA_SONU: float = 6.0
const BOLGE_ADI_BOYUTU: int = 24
## Bölge adı, bölgenin ekrandaki büyüklüğünün bu katından genişse gizlenir.
const BOLGE_ADI_SIGMA_ORANI: float = 1.1
## Bu yakınlıktan sonra bölge adı, bölgeye sığmasa da gösterilir (başka ada çarpmıyorsa).
const BOLGE_ADI_SIGMA_SINIRI: float = 10.0
## İki ad arasında bırakılan en az boşluk (piksel).
const YAZI_ARALIGI: float = 6.0
const YILDIZ_YARICAPI: float = 13.0
## Aynı bölgedeki bütün tümenler tek kutuda, toplam güçleriyle gösterilir. Bölge adları gibi
## yakınlıktan bağımsız sabit ekran boyutundadır.
const BIRLIK_KUTU_BOYUTU: Vector2 = Vector2(64.0, 40.0)
const BIRLIK_KUTU_KENAR_RENGI: Color = Color(0.0, 0.0, 0.0, 0.85)
const BIRLIK_KUTU_KENAR_KALINLIGI: float = 3.0
const BIRLIK_YAZI_BOYUTU: int = 26
## Kutu, bölge adıyla çakışmasın diye etiket noktasının üstüne çizilir.
const BIRLIK_KONUM_PAYI: Vector2 = Vector2(0.0, -46.0)
## Yürüyen tümenlerin kaynaktan hedefe çizilen yolu. Yakınlıktan bağımsız her zaman görünür.
const YOL_CIZGISI_RENGI: Color = Color(1.0, 0.95, 0.42, 0.85)
const YOL_CIZGISI_KALINLIGI: float = 4.0
## Birden çok ülkenin tümeni bulunan (savaşan) bölgeyi işaretleyen daire.
const MUHAREBE_ISARETI_YARICAPI: float = 16.0
const MUHAREBE_ISARETI_RENGI: Color = Color("#e03b3b")
## Ekranın biraz dışındaki adlar da çizilir ki kaydırırken kenarda birden belirmesinler (piksel).
const GORUNUM_PAYI: float = 260.0

## Bölge ayrıntıları (bölge sınırları, bölge adları, başkent yıldızları) bu iki
## yakınlık arasında yavaşça belirir. Daha uzaktan harita sade kalır.
const BOLGE_BELIRME_BASI: float = 1.7
const BOLGE_BELIRME_SONU: float = 2.6

enum SinirTuru { KIYI, ULKE, BOLGE }

## Dolgusu çizilemeyen çokgenlerin bölge ve ülke adları.
var ucgenlenemeyenler: PackedStringArray = PackedStringArray()

var _dunya: Dunya = null
var _oyun: Oyun = null
var _merkez: Vector2 = Vector2.ZERO
var _yakinlik: float = 1.0
var _ekran: Vector2 = Vector2(1920.0, 1080.0)
## Seçili bölgenin id'si; seçim yoksa boş.
var _secili_bolge: String = ""
## Oyuncunun ülkesinin id'si; seçilmediyse boş.
var _oyuncu: String = ""
var _komsular_gorunur: bool = false

var _yazi_tipi: Font = null
var _ag: ArrayMesh = null
var _vurgu_agi: ArrayMesh = null
var _ust_katman: Node2D = null
## Sınır türü -> o türün çizgi katmanı.
var _cizgi_katmanlari: Dictionary[SinirTuru, MeshInstance2D] = {}
## Her çokgenin üçgen indisleri (Dunya.cokgenler ile aynı sırada). Üçgenlenemeyenlerde boştur.
var _ucgenler: Array[PackedInt32Array] = []
## Bölge id'si -> o bölgenin çokgenlerinin Dunya.cokgenler içindeki sıraları.
var _bolge_cokgenleri: Dictionary[String, PackedInt32Array] = {}
## Ülke id'si -> elindeki toprağın yaklaşık genişliği (harita birimi). Ad yazarken kullanılır.
var _ulke_buyuklugu: Dictionary[String, float] = {}
## Ülkeler, toprağı büyük olandan küçüğe. Adlar bu sırayla yazılır.
var _ulke_adi_sirasi: Array[Ulke] = []
## Her bölgenin adının görünmeye başladığı yakınlık (Dunya.bolge_listesi ile aynı sırada).
var _bolge_adi_esigi: PackedFloat32Array = PackedFloat32Array()
var _bolge_adi_genisligi: PackedFloat32Array = PackedFloat32Array()
# Çerçevesi çizilecek sınırların Dunya.sinirlar içindeki sıraları.
var _secili_bolge_sinirlari: PackedInt32Array = PackedInt32Array()
var _secili_ulke_sinirlari: PackedInt32Array = PackedInt32Array()
var _oyuncu_sinirlari: PackedInt32Array = PackedInt32Array()


## Ülkenin haritadaki rengi.
static func ulke_rengi(ulke: Ulke) -> Color:
	return PALET[posmod(ulke.renk_indeksi - 1, PALET.size())]


func kur(dunya: Dunya, oyun: Oyun) -> void:
	_dunya = dunya
	_oyun = oyun
	_yazi_tipi = ThemeDB.fallback_font
	RenderingServer.set_default_clear_color(DENIZ_RENGI)

	_cokgenleri_hazirla()
	_bolge_adi_esiklerini_hesapla()

	_cizgi_katmani_ekle(SinirTuru.BOLGE, BOLGE_SINIRI_RENGI, BOLGE_SINIRI_KALINLIGI)
	_cizgi_katmani_ekle(SinirTuru.KIYI, KIYI_RENGI, KIYI_KALINLIGI)
	_cizgi_katmani_ekle(SinirTuru.ULKE, ULKE_SINIRI_RENGI, ULKE_SINIRI_KALINLIGI)

	_ust_katman = Node2D.new()
	_ust_katman.name = "UstKatman"
	add_child(_ust_katman)
	_ust_katman.draw.connect(_ust_katmani_ciz)

	yenile()


## Kamera kaydığında ya da yakınlığı değiştiğinde çağrılır.
func gorunumu_ayarla(merkez: Vector2, yakinlik: float, ekran: Vector2) -> void:
	_merkez = merkez
	_ekran = ekran
	var yeni_yakinlik: float = maxf(yakinlik, 0.01)
	if not is_equal_approx(yeni_yakinlik, _yakinlik):
		_yakinlik = yeni_yakinlik
		_cizgi_katmanlarini_guncelle()
	_ust_katmani_yenile()


## Seçili bölgeyi değiştirir. Seçimi kaldırmak için boş metin verilir.
func secimi_ayarla(bolge_id: String) -> void:
	_secili_bolge = bolge_id
	_cerceveleri_guncelle()
	_vurgu_agini_kur()
	_ust_katmani_yenile()


## Oyuncunun ülkesini belirgin bir çerçeveyle işaretler.
func oyuncuyu_ayarla(ulke_id: String) -> void:
	_oyuncu = ulke_id
	_cerceveleri_guncelle()
	_ust_katmani_yenile()


## Seçili bölgenin kara komşularını ve deniz geçişlerini renkle vurgular ya da vurguyu kaldırır.
func komsulari_goster(acik: bool) -> void:
	_komsular_gorunur = acik
	_vurgu_agini_kur()
	_ust_katmani_yenile()


## Tümenler hareket edince ya da güçleri değişince çağrılır.
func birlikleri_yenile() -> void:
	_ust_katmani_yenile()


## Bölgelerin sahipliği değiştiğinde haritayı baştan boyar ve sınırları yeniden sınıflandırır.
func yenile() -> void:
	_dolgu_agini_kur()
	for tur: SinirTuru in _cizgi_katmanlari:
		_cizgi_katmanlari[tur].mesh = _cizgi_agini_kur(tur)
	_cizgi_katmanlarini_guncelle()
	_ulke_olculerini_hesapla()
	_cerceveleri_guncelle()
	_vurgu_agini_kur()
	queue_redraw()
	_ust_katmani_yenile()


func _ust_katmani_yenile() -> void:
	if _ust_katman != null:
		_ust_katman.queue_redraw()


func _draw() -> void:
	if _ag != null:
		draw_mesh(_ag, null)


# --- Dolgular --------------------------------------------------------------

## Her çokgeni üçgenlere böler. Üçgenlenemeyen çokgen oyunu durdurmaz: uyarı yazılır,
## dolgusu atlanır, sınırı yine çizilir.
func _cokgenleri_hazirla() -> void:
	_ucgenler = []
	_bolge_cokgenleri = {}
	ucgenlenemeyenler = PackedStringArray()

	for i: int in _dunya.cokgenler.size():
		var cokgen: Cokgen = _dunya.cokgenler[i]
		var ucgenler: PackedInt32Array = Geometry2D.triangulate_polygon(cokgen.noktalar)
		if ucgenler.is_empty():
			var bolge: Bolge = _dunya.bolgeler[cokgen.bolge_id]
			var ad: String = "%s (%s)" % [bolge.ad, _dunya.ulkeler[bolge.sahip].ad]
			ucgenlenemeyenler.append(ad)
			push_warning("Harita: %s bölgesinin bir çokgeni üçgenlenemedi (%d nokta); dolgusu çizilmeyecek."
					% [ad, cokgen.noktalar.size()])
		_ucgenler.append(ucgenler)

		var siralar: PackedInt32Array = _bolge_cokgenleri.get(cokgen.bolge_id, PackedInt32Array())
		siralar.append(i)
		_bolge_cokgenleri[cokgen.bolge_id] = siralar


## Bütün dolguları tek bir ağda toplar. Üçgenler çokgen sırasıyla (büyükten küçüğe)
## eklendiği için küçük parçalar büyüklerin üstünde kalır.
func _dolgu_agini_kur() -> void:
	var siralar: PackedInt32Array = PackedInt32Array()
	var renkler: PackedColorArray = PackedColorArray()
	for i: int in _dunya.cokgenler.size():
		siralar.append(i)
		renkler.append(ulke_rengi(_dunya.bolgenin_sahibi(_dunya.cokgenler[i].bolge_id)))
	_ag = _ucgen_agi(siralar, renkler)


## Verilen çokgenleri (Dunya.cokgenler sıralarıyla) verilen renklerle tek bir ağ yapar.
func _ucgen_agi(siralar: PackedInt32Array, cokgen_renkleri: PackedColorArray) -> ArrayMesh:
	var koseler: PackedVector2Array = PackedVector2Array()
	var renkler: PackedColorArray = PackedColorArray()
	var indisler: PackedInt32Array = PackedInt32Array()

	for s: int in siralar.size():
		var sira: int = siralar[s]
		if _ucgenler[sira].is_empty():
			continue
		var noktalar: PackedVector2Array = _dunya.cokgenler[sira].noktalar
		var taban: int = koseler.size()
		koseler.append_array(noktalar)
		for n: int in noktalar.size():
			renkler.append(cokgen_renkleri[s])
		for indis: int in _ucgenler[sira]:
			indisler.append(taban + indis)

	if indisler.is_empty():
		return null
	var diziler: Array = []
	diziler.resize(Mesh.ARRAY_MAX)
	diziler[Mesh.ARRAY_VERTEX] = koseler
	diziler[Mesh.ARRAY_COLOR] = renkler
	diziler[Mesh.ARRAY_INDEX] = indisler
	var ag: ArrayMesh = ArrayMesh.new()
	ag.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, diziler)
	return ag


## Seçili bölgenin komşularını renkli, yarı saydam bir ağ olarak hazırlar.
func _vurgu_agini_kur() -> void:
	_vurgu_agi = null
	if not _komsular_gorunur or not _dunya.bolgeler.has(_secili_bolge):
		return
	var siralar: PackedInt32Array = PackedInt32Array()
	var renkler: PackedColorArray = PackedColorArray()
	_vurguya_ekle(_dunya.bolgeler[_secili_bolge].kara_komsulari, KARA_KOMSUSU_RENGI, siralar, renkler)
	_vurguya_ekle(_dunya.bolgeler[_secili_bolge].deniz_gecisleri, DENIZ_GECISI_RENGI, siralar, renkler)
	_vurgu_agi = _ucgen_agi(siralar, renkler)


func _vurguya_ekle(bolge_idleri: PackedStringArray, renk: Color, siralar: PackedInt32Array, renkler: PackedColorArray) -> void:
	var saydam: Color = Color(renk, VURGU_OPAKLIGI)
	for bolge_id: String in bolge_idleri:
		if not _bolge_cokgenleri.has(bolge_id):
			continue
		for sira: int in _bolge_cokgenleri[bolge_id]:
			siralar.append(sira)
			renkler.append(saydam)


# --- Sınır çizgileri -------------------------------------------------------

func _cizgi_katmani_ekle(tur: SinirTuru, renk: Color, kalinlik: float) -> void:
	var malzeme: ShaderMaterial = ShaderMaterial.new()
	malzeme.shader = SINIR_GOLGELENDIRICISI
	malzeme.set_shader_parameter("renk", renk)
	malzeme.set_shader_parameter("kalinlik", kalinlik)
	var katman: MeshInstance2D = MeshInstance2D.new()
	katman.name = "Cizgiler%d" % tur
	katman.material = malzeme
	add_child(katman)
	_cizgi_katmanlari[tur] = katman


## Sınırın türü iki yanındaki bölgelerin o anki sahibine göre belirlenir.
func _sinir_turu(sinir: Sinir) -> SinirTuru:
	if sinir.kiyi_mi():
		return SinirTuru.KIYI
	if _dunya.bolgeler[sinir.a].sahip == _dunya.bolgeler[sinir.b].sahip:
		return SinirTuru.BOLGE
	return SinirTuru.ULKE


## Verilen türdeki bütün sınırları tek bir ağda toplar. Her nokta, çizginin iki yanı için
## iki köşe olur; köşelerin ne yöne açılacağı UV'ye, hangi yanda olduğu renge yazılır.
## Asıl kalınlığı gölgelendirici verir.
func _cizgi_agini_kur(tur: SinirTuru) -> ArrayMesh:
	var koseler: PackedVector2Array = PackedVector2Array()
	var yonler: PackedVector2Array = PackedVector2Array()
	var yanlar: PackedColorArray = PackedColorArray()
	var indisler: PackedInt32Array = PackedInt32Array()

	for sinir: Sinir in _dunya.sinirlar:
		if _sinir_turu(sinir) != tur:
			continue
		var noktalar: PackedVector2Array = sinir.noktalar
		var adet: int = noktalar.size()
		if adet < 2:
			continue
		# Başı ve sonu aynı olan çizgi kapalıdır (ör. bir adanın kıyısı).
		var kapali: bool = adet > 3 and noktalar[0].is_equal_approx(noktalar[adet - 1])
		var taban: int = koseler.size()
		for i: int in adet:
			var onceki: Vector2 = noktalar[i]
			var sonraki: Vector2 = noktalar[i]
			if i > 0:
				onceki = noktalar[i - 1]
			elif kapali:
				onceki = noktalar[adet - 2]
			if i < adet - 1:
				sonraki = noktalar[i + 1]
			elif kapali:
				sonraki = noktalar[1]
			var gelen: Vector2 = (noktalar[i] - onceki).normalized()
			var giden: Vector2 = (sonraki - noktalar[i]).normalized()
			if gelen == Vector2.ZERO:
				gelen = giden
			if giden == Vector2.ZERO:
				giden = gelen
			# Köşede iki kenarın dik yönlerinin ortası alınır ve çizgi incelmesin diye uzatılır.
			var dik: Vector2 = giden.orthogonal()
			var gonye: Vector2 = (gelen.orthogonal() + dik).normalized()
			if gonye == Vector2.ZERO:
				gonye = dik
			gonye *= 1.0 / maxf(gonye.dot(dik), 1.0 / AZAMI_GONYE)

			koseler.append(noktalar[i])
			koseler.append(noktalar[i])
			yonler.append(gonye)
			yonler.append(-gonye)
			yanlar.append(Color(1.0, 1.0, 1.0))
			yanlar.append(Color(0.0, 1.0, 1.0))
		for i: int in adet - 1:
			var k: int = taban + i * 2
			indisler.append(k)
			indisler.append(k + 1)
			indisler.append(k + 2)
			indisler.append(k + 1)
			indisler.append(k + 3)
			indisler.append(k + 2)

	if indisler.is_empty():
		return null
	var diziler: Array = []
	diziler.resize(Mesh.ARRAY_MAX)
	diziler[Mesh.ARRAY_VERTEX] = koseler
	diziler[Mesh.ARRAY_TEX_UV] = yonler
	diziler[Mesh.ARRAY_COLOR] = yanlar
	diziler[Mesh.ARRAY_INDEX] = indisler
	var ag: ArrayMesh = ArrayMesh.new()
	ag.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, diziler)
	return ag


## Bölge ayrıntılarının o anki görünürlüğü: uzaktan 0, yakından 1.
func _bolge_gorunurlugu() -> float:
	return smoothstep(BOLGE_BELIRME_BASI, BOLGE_BELIRME_SONU, _yakinlik)


## Çizgi katmanlarına yeni yakınlığı bildirir; bölge sınırlarını uzaktan gizler.
func _cizgi_katmanlarini_guncelle() -> void:
	for tur: SinirTuru in _cizgi_katmanlari:
		var malzeme: ShaderMaterial = _cizgi_katmanlari[tur].material as ShaderMaterial
		malzeme.set_shader_parameter("yakinlik", _yakinlik)
	var gorunurluk: float = _bolge_gorunurlugu()
	(_cizgi_katmanlari[SinirTuru.ULKE].material as ShaderMaterial).set_shader_parameter(
			"kalinlik", lerpf(UZAK_ULKE_SINIRI_KALINLIGI, ULKE_SINIRI_KALINLIGI, gorunurluk))
	var bolge_katmani: MeshInstance2D = _cizgi_katmanlari[SinirTuru.BOLGE]
	bolge_katmani.visible = gorunurluk > 0.0
	(bolge_katmani.material as ShaderMaterial).set_shader_parameter(
			"renk", Color(BOLGE_SINIRI_RENGI, BOLGE_SINIRI_RENGI.a * gorunurluk))


# --- Çerçeveler ------------------------------------------------------------

## Seçili bölgenin, onun ülkesinin ve oyuncunun ülkesinin çevresindeki sınırları bulur.
func _cerceveleri_guncelle() -> void:
	_secili_bolge_sinirlari = PackedInt32Array()
	_secili_ulke_sinirlari = PackedInt32Array()
	_oyuncu_sinirlari = PackedInt32Array()
	var secili_ulke: String = ""
	if _dunya.bolgeler.has(_secili_bolge):
		secili_ulke = _dunya.bolgeler[_secili_bolge].sahip

	for i: int in _dunya.sinirlar.size():
		var sinir: Sinir = _dunya.sinirlar[i]
		var sahip_a: String = _dunya.bolgeler[sinir.a].sahip
		var sahip_b: String = "" if sinir.kiyi_mi() else _dunya.bolgeler[sinir.b].sahip
		if _secili_bolge != "" and sinir.bolgeye_degiyor_mu(_secili_bolge):
			_secili_bolge_sinirlari.append(i)
		# Bir ülkenin dış sınırı: yalnızca bir yanı o ülkeye ait olan çizgiler.
		if secili_ulke != "" and (sahip_a == secili_ulke) != (sahip_b == secili_ulke):
			_secili_ulke_sinirlari.append(i)
		if _oyuncu != "" and (sahip_a == _oyuncu) != (sahip_b == _oyuncu):
			_oyuncu_sinirlari.append(i)


func _cerceve_ciz(sinir_siralari: PackedInt32Array, renk: Color, kalinlik: float, olcek: float) -> void:
	for i: int in sinir_siralari:
		_ust_katman.draw_polyline(_dunya.sinirlar[i].noktalar, CERCEVE_ALT_RENGI,
				(kalinlik + CERCEVE_ALT_PAYI) * olcek, true)
	for i: int in sinir_siralari:
		_ust_katman.draw_polyline(_dunya.sinirlar[i].noktalar, renk, kalinlik * olcek, true)


# --- Üst katman ------------------------------------------------------------

func _ust_katmani_ciz() -> void:
	if _dunya == null:
		return
	var olcek: float = 1.0 / _yakinlik
	var gorunen: Rect2 = Rect2(_merkez - _ekran * 0.5 * olcek, _ekran * olcek).grow(GORUNUM_PAYI * olcek)

	if _vurgu_agi != null:
		_ust_katman.draw_mesh(_vurgu_agi, null)
	_cerceve_ciz(_oyuncu_sinirlari, OYUNCU_RENGI, OYUNCU_KALINLIGI, olcek)
	_cerceve_ciz(_secili_ulke_sinirlari, SECILI_ULKE_RENGI, SECILI_ULKE_KALINLIGI, olcek)
	_cerceve_ciz(_secili_bolge_sinirlari, SECIM_RENGI, SECIM_KALINLIGI, olcek)
	_yol_cizgilerini_ciz(olcek)

	_ulke_adlarini_ciz(gorunen, olcek)
	_bolge_adlarini_ciz(gorunen, olcek)
	_birlikleri_ciz(gorunen, olcek)
	_ust_katman.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Her ülkenin elindeki toprağın büyüklüğünü ölçer ve ülkeleri büyükten küçüğe sıralar.
func _ulke_olculerini_hesapla() -> void:
	var alanlar: Dictionary[String, float] = {}
	for bolge: Bolge in _dunya.bolge_listesi:
		alanlar[bolge.sahip] = alanlar.get(bolge.sahip, 0.0) + bolge.alan
	_ulke_buyuklugu = {}
	_ulke_adi_sirasi = []
	for ulke: Ulke in _dunya.ulke_listesi:
		if alanlar.has(ulke.id):
			_ulke_buyuklugu[ulke.id] = sqrt(alanlar[ulke.id])
			_ulke_adi_sirasi.append(ulke)
	_ulke_adi_sirasi.sort_custom(func(a: Ulke, b: Ulke) -> bool:
		return _ulke_buyuklugu[a.id] > _ulke_buyuklugu[b.id])


## Ülke adlarını yazar. Uzaktan yalnızca büyük ülkelerin adı görünür; yakınlaştıkça ülke
## ekranda büyür ve adı sığmaya başlar. Bölge adları belirince ülke adları solar.
## Adlar üst üste binmez: büyük ülkeden küçüğe yazılır, önceki bir ada çarpan ad atlanır.
func _ulke_adlarini_ciz(gorunen: Rect2, olcek: float) -> void:
	var opaklik: float = lerpf(1.0, SOLUK_ULKE_ADI_OPAKLIGI, _bolge_gorunurlugu()) 			* (1.0 - smoothstep(ULKE_ADI_KAYBOLMA_BASI, ULKE_ADI_KAYBOLMA_SONU, _yakinlik))
	if opaklik <= 0.0:
		return
	var dolu_alanlar: Array[Rect2] = []
	for ulke: Ulke in _ulke_adi_sirasi:
		if not gorunen.has_point(ulke.etiket):
			continue
		var zorunlu: bool = ulke.id == _oyuncu
		var ekran_buyuklugu: float = _ulke_buyuklugu[ulke.id] * _yakinlik
		# Yazı tipi her boyut için ayrı hazırlandığından boyut 4'ün katlarına yuvarlanır.
		var boyut: int = clampi(int(snappedf(ekran_buyuklugu * ULKE_ADI_ORANI, 4.0)),
				ASGARI_ULKE_ADI_BOYUTU, AZAMI_ULKE_ADI_BOYUTU)
		var genislik: float = _yazi_tipi.get_string_size(ulke.ad, HORIZONTAL_ALIGNMENT_LEFT, -1.0, boyut).x
		# Adın ekranda kaplayacağı yer (kamera kaymasından bağımsız, yalnızca yakınlığa bağlı).
		var alan: Rect2 = Rect2(ulke.etiket * _yakinlik + Vector2(-genislik * 0.5, -boyut * 0.65),
				Vector2(genislik, boyut)).grow(YAZI_ARALIGI)
		if not zorunlu:
			if genislik > ekran_buyuklugu * ULKE_ADI_SIGMA_ORANI and ekran_buyuklugu < HER_ZAMAN_YAZ_ESIGI:
				continue
			var carpiyor: bool = false
			for dolu: Rect2 in dolu_alanlar:
				if dolu.intersects(alan):
					carpiyor = true
					break
			if carpiyor:
				continue
		dolu_alanlar.append(alan)
		_ust_katman.draw_set_transform(ulke.etiket, 0.0, Vector2(olcek, olcek))
		_yazi_ciz(ulke.ad, Vector2(-genislik * 0.5, boyut * 0.35), boyut, opaklik)


## Her bölge adının hangi yakınlıktan sonra görüneceğini bir kez hesaplar.
##
## Ad şu iki koşul sağlanınca görünür: bölge ekranda adına yetecek kadar büyüktür ve ad,
## kendinden öncelikli (başkent ya da daha kalabalık) hiçbir bölgenin adına çarpmaz.
## Adların ekrandaki boyutu sabit olduğu için iki adın çarpışmayı bıraktığı yakınlık
## baştan bellidir; çizim sırasında yalnızca bu eşiğe bakılır.
func _bolge_adi_esiklerini_hesapla() -> void:
	var adet: int = _dunya.bolge_listesi.size()
	_bolge_adi_esigi = PackedFloat32Array()
	_bolge_adi_esigi.resize(adet)
	_bolge_adi_genisligi = PackedFloat32Array()
	_bolge_adi_genisligi.resize(adet)
	var yukseklikler: PackedFloat32Array = PackedFloat32Array()
	yukseklikler.resize(adet)

	var sira: Array[int] = []
	for i: int in adet:
		var bolge: Bolge = _dunya.bolge_listesi[i]
		var genislik: float = _yazi_tipi.get_string_size(bolge.ad, HORIZONTAL_ALIGNMENT_LEFT, -1.0, BOLGE_ADI_BOYUTU).x
		_bolge_adi_genisligi[i] = genislik
		# Başkentlerde adın üstünde yıldız da yer kaplar.
		yukseklikler[i] = BOLGE_ADI_BOYUTU * 1.2 + (YILDIZ_YARICAPI * 2.0 if bolge.baskent else 0.0)
		var sigma_esigi: float = genislik / (maxf(sqrt(bolge.alan), 0.01) * BOLGE_ADI_SIGMA_ORANI)
		_bolge_adi_esigi[i] = maxf(BOLGE_BELIRME_BASI, minf(sigma_esigi, BOLGE_ADI_SIGMA_SINIRI))
		sira.append(i)
	sira.sort_custom(func(a: int, b: int) -> bool:
		var bolge_a: Bolge = _dunya.bolge_listesi[a]
		var bolge_b: Bolge = _dunya.bolge_listesi[b]
		if bolge_a.baskent != bolge_b.baskent:
			return bolge_a.baskent
		return bolge_a.nufus > bolge_b.nufus)

	for s: int in adet:
		var i: int = sira[s]
		var konum: Vector2 = _dunya.bolge_listesi[i].etiket
		var esik: float = _bolge_adi_esigi[i]
		for t: int in s:
			var j: int = sira[t]
			var fark: Vector2 = (_dunya.bolge_listesi[j].etiket - konum).abs()
			# İki ad, yatayda ya da dikeyde birbirinden ayrıldığı yakınlıkta çarpışmayı bırakır.
			var yatay: float = ((_bolge_adi_genisligi[i] + _bolge_adi_genisligi[j]) * 0.5 + YAZI_ARALIGI) / maxf(fark.x, 0.001)
			if yatay <= esik:
				continue
			var dikey: float = ((yukseklikler[i] + yukseklikler[j]) * 0.5 + YAZI_ARALIGI) / maxf(fark.y, 0.001)
			if dikey <= esik:
				continue
			esik = minf(yatay, dikey)
		_bolge_adi_esigi[i] = esik


## Bölge adlarını ve başkent yıldızlarını çizer. Uzaktan hiçbiri görünmez; yalnızca
## ekrandaki bölgeler çizilir. Seçili bölgenin adı her yakınlıkta yazılır.
func _bolge_adlarini_ciz(gorunen: Rect2, olcek: float) -> void:
	var opaklik: float = _bolge_gorunurlugu()
	for i: int in _dunya.bolge_listesi.size():
		var bolge: Bolge = _dunya.bolge_listesi[i]
		var secili: bool = bolge.id == _secili_bolge
		if opaklik <= 0.0 and not secili:
			continue
		if not gorunen.has_point(bolge.etiket):
			continue
		var ad_gorunur: bool = secili or _yakinlik >= _bolge_adi_esigi[i]
		if not ad_gorunur and not bolge.baskent:
			continue
		var oge_opakligi: float = 1.0 if secili else opaklik

		_ust_katman.draw_set_transform(bolge.etiket, 0.0, Vector2(olcek, olcek))
		var taban_y: float = BOLGE_ADI_BOYUTU * 0.35
		if bolge.baskent:
			_yildiz_ciz(Vector2(0.0, -YILDIZ_YARICAPI * 0.6), oge_opakligi)
			taban_y = YILDIZ_YARICAPI * 0.6 + BOLGE_ADI_BOYUTU
		if ad_gorunur:
			_yazi_ciz(bolge.ad, Vector2(-_bolge_adi_genisligi[i] * 0.5, taban_y), BOLGE_ADI_BOYUTU, oge_opakligi)


## Yürüyen tümenlerin kaynak-hedef çizgisini çizer. Aynı yolu paylaşan tümenler tek
## çizgide birleşir.
func _yol_cizgilerini_ciz(olcek: float) -> void:
	if _oyun == null:
		return
	var cizilen: Dictionary[String, bool] = {}
	for birlik: Birlik in _oyun.birlikler:
		if not birlik.yuruyor_mu():
			continue
		var anahtar: String = "%s>%s" % [birlik.bolge_id, birlik.hedef_bolge_id]
		if cizilen.has(anahtar):
			continue
		cizilen[anahtar] = true
		var kaynak: Bolge = _dunya.bolgeler.get(birlik.bolge_id)
		var hedef: Bolge = _dunya.bolgeler.get(birlik.hedef_bolge_id)
		if kaynak == null or hedef == null:
			continue
		_ust_katman.draw_line(kaynak.etiket, hedef.etiket, YOL_CIZGISI_RENGI, YOL_CIZGISI_KALINLIGI * olcek, true)


## Aynı bölgedeki tümenleri tek kutuda, toplam güçleriyle çizer. Bölge sınırları ve adları
## gibi yalnızca yakınlaşınca görünür; uzaktan dünya genelinde yüzlerce kutu dünyayı
## karmaşıklaştırmasın diye.
func _birlikleri_ciz(gorunen: Rect2, olcek: float) -> void:
	if _oyun == null or _bolge_gorunurlugu() <= 0.0:
		return
	var toplam_guc: Dictionary[String, float] = {}
	var sahipler: Dictionary[String, Dictionary] = {}
	for birlik: Birlik in _oyun.birlikler:
		toplam_guc[birlik.bolge_id] = toplam_guc.get(birlik.bolge_id, 0.0) + birlik.guc
		var kume: Dictionary = sahipler.get(birlik.bolge_id, {})
		kume[birlik.sahip] = true
		sahipler[birlik.bolge_id] = kume

	for bolge_id: String in toplam_guc:
		var bolge: Bolge = _dunya.bolgeler.get(bolge_id)
		if bolge == null or not gorunen.has_point(bolge.etiket):
			continue
		var sahip: Ulke = _dunya.bolgenin_sahibi(bolge_id)
		var renk: Color = ulke_rengi(sahip) if sahip != null else Color.GRAY
		_ust_katman.draw_set_transform(bolge.etiket, 0.0, Vector2(olcek, olcek))
		_birlik_kutusu_ciz(renk, toplam_guc[bolge_id])
		if sahipler[bolge_id].size() > 1:
			_muharebe_isareti_ciz()


## `konum` (BIRLIK_KONUM_PAYI) ölçeklenmiş yerel çerçeve içinde uygulanır ki kutu,
## yakınlıktan bağımsız olarak bölge etiketine göre hep aynı ekran uzaklığında kalsın
## (konum dönüşüm köküne eklenseydi, kamera yakınlığıyla birlikte ekranda büyürdü).
func _birlik_kutusu_ciz(renk: Color, guc: float) -> void:
	var merkez: Vector2 = BIRLIK_KONUM_PAYI
	var yarim: Vector2 = BIRLIK_KUTU_BOYUTU * 0.5
	var kose: PackedVector2Array = PackedVector2Array([
		merkez + Vector2(-yarim.x, -yarim.y), merkez + Vector2(yarim.x, -yarim.y),
		merkez + Vector2(yarim.x, yarim.y), merkez + Vector2(-yarim.x, yarim.y),
	])
	_ust_katman.draw_colored_polygon(kose, renk)
	kose.append(kose[0])
	_ust_katman.draw_polyline(kose, BIRLIK_KUTU_KENAR_RENGI, BIRLIK_KUTU_KENAR_KALINLIGI, true)

	var metin: String = str(roundi(guc))
	var genislik: float = _yazi_tipi.get_string_size(metin, HORIZONTAL_ALIGNMENT_LEFT, -1.0, BIRLIK_YAZI_BOYUTU).x
	_yazi_ciz(metin, merkez + Vector2(-genislik * 0.5, BIRLIK_YAZI_BOYUTU * 0.35), BIRLIK_YAZI_BOYUTU, 1.0)


## Tümen kutusunun sağına, birden çok ülkenin tümeni bulunan (savaşan) bölgeyi işaretleyen
## kırmızı bir daire çizer. `_birlik_kutusu_ciz` ile aynı ölçeklenmiş yerel çerçevede çalışır.
func _muharebe_isareti_ciz() -> void:
	var merkez: Vector2 = BIRLIK_KONUM_PAYI + Vector2(BIRLIK_KUTU_BOYUTU.x * 0.5 + MUHAREBE_ISARETI_YARICAPI + 10.0, 0.0)
	_ust_katman.draw_circle(merkez, MUHAREBE_ISARETI_YARICAPI, MUHAREBE_ISARETI_RENGI)
	_ust_katman.draw_arc(merkez, MUHAREBE_ISARETI_YARICAPI, 0.0, TAU, 24, Color.WHITE, 2.0)


## Yazıyı okunaklı olsun diye koyu kenarlıkla çizer. `konum`, yazının sol alt köşesidir.
func _yazi_ciz(metin: String, konum: Vector2, boyut: int, opaklik: float) -> void:
	_ust_katman.draw_string_outline(_yazi_tipi, konum, metin, HORIZONTAL_ALIGNMENT_LEFT, -1.0, boyut,
			maxi(4, roundi(boyut * 0.26)), Color(YAZI_KENAR_RENGI, YAZI_KENAR_RENGI.a * opaklik))
	_ust_katman.draw_string(_yazi_tipi, konum, metin, HORIZONTAL_ALIGNMENT_LEFT, -1.0, boyut,
			Color(YAZI_RENGI, opaklik))


func _yildiz_ciz(konum: Vector2, opaklik: float) -> void:
	var noktalar: PackedVector2Array = PackedVector2Array()
	for k: int in 10:
		var yaricap: float = YILDIZ_YARICAPI if k % 2 == 0 else YILDIZ_YARICAPI * 0.42
		noktalar.append(konum + Vector2.UP.rotated(TAU * float(k) / 10.0) * yaricap)
	_ust_katman.draw_colored_polygon(noktalar, Color(1.0, 0.85, 0.29, opaklik))
	noktalar.append(noktalar[0])
	noktalar.append(noktalar[1])
	_ust_katman.draw_polyline(noktalar, Color(0.12, 0.08, 0.0, opaklik), 2.0, true)
