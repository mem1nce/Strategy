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
## Oyuncuyla savaştaki ülkeleri işaretler (muharebe işaretiyle aynı kırmızı).
const SAVAS_RENGI: Color = Color("#e03b3b")
const SAVAS_KALINLIGI: float = 4.0
## Son "işgal cezası" günü içinde ele geçirilmiş, hâlâ ev sahibine dönmemiş bölgeleri
## işaretler (bkz. Oyun.bolge_isgal_altinda_mi).
const ISGAL_RENGI: Color = Color("#e0943b")
const ISGAL_KALINLIGI: float = 3.0
const CERCEVE_ALT_RENGI: Color = Color(0.0, 0.0, 0.0, 0.7)
## Çerçevelerin altındaki koyu şeridin, çerçeveden ne kadar taştığı.
const CERCEVE_ALT_PAYI: float = 4.0

# Komşu vurguları.
const KARA_KOMSUSU_RENGI: Color = Color("#2fe0b5")
const DENIZ_GECISI_RENGI: Color = Color("#ff8a2b")
const VURGU_OPAKLIGI: float = 0.62
## Savaş sisi: oyuncunun görmediği bölgelerin dolgusu bu oranda koyulaşır (harita okunaklı
## kalsın diye hafif). Sahiplik rengi yine anlaşılır.
const SIS_KARARTMASI: float = 0.32
## Animasyonlar (Ayarlar.animasyonlar_azaltilmis değilse ve en yüksek hızda değilken):
## muharebe işaretinin atışı, altındaki güç çubuğu ve ele geçirilen bölgenin parlaması.
const MUHAREBE_ATIS_HIZI: float = 6.0
const MUHAREBE_ATIS_GENLIGI: float = 0.15
const GUC_CUBUGU_BOYUTU: Vector2 = Vector2(44.0, 8.0)
const PARLAMA_SURESI_MS: int = 700
const PARLAMA_OPAKLIGI: float = 0.55

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
## Aynı bölgedeki bütün tümenler tek kutuda gösterilir: solda toplam güç, sağında her tür
## için işareti ve tümen sayısı. Bölge adları gibi yakınlıktan bağımsız sabit ekran
## boyutundadır; genişlik içerikle değişir, yükseklik ve en küçük genişlik sabittir.
const BIRLIK_KUTU_BOYUTU: Vector2 = Vector2(56.0, 34.0)
const BIRLIK_KUTU_IC_BOSLUGU: float = 8.0
## Tür işaretinin kapladığı kare (piksel) ve işaretle sayısı arasındaki boşluk.
const TUR_ISARETI_BOYUTU: float = 17.0
const TUR_ISARETI_ARALIGI: float = 4.0
const TUR_ISARETI_KALINLIGI: float = 3.0
## Tahkimatlı bölgenin adının solundaki küçük kale işareti.
const TAHKIMAT_ISARETI_BOYUTU: float = 22.0
const TAHKIMAT_ISARETI_RENGI: Color = Color(0.62, 0.62, 0.66)
const TAHKIMAT_YAZI_BOYUTU: int = 20
const BIRLIK_KUTU_KENAR_RENGI: Color = Color(0.0, 0.0, 0.0, 0.85)
const BIRLIK_KUTU_KENAR_KALINLIGI: float = 3.0
const BIRLIK_YAZI_BOYUTU: int = 22
## Kutu, bölge adıyla çakışmasın diye etiket noktasının üstüne çizilir. Bu yer başka bir
## kutuya çarpıyorsa solu, sağı ve kat kat daha üstü denenir (bkz. _birlik_kutularini_yerlestir).
const BIRLIK_KONUM_PAYI: Vector2 = Vector2(0.0, -40.0)
## Kutu için denenen yedek kat sayısı (her katta üst, sol ve sağ).
const BIRLIK_YEDEK_KAT_SAYISI: int = 4
## Tümen kutuları, bölge ayrıntıları (sınırlar, adlar) en az bu oranda belirince çizilir;
## daha uzakta kutular sınırsız bir haritada yığılıp okunmaz oluyordu.
const BIRLIK_GORUNURLUK_ESIGI: float = 0.5
## Yerinden kaymış kutuyu bölgesine bağlayan ince çizgi.
const BIRLIK_BAG_CIZGISI_RENGI: Color = Color(0.0, 0.0, 0.0, 0.7)
const BIRLIK_BAG_CIZGISI_KALINLIGI: float = 2.0
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
## Bölgeler sıklaştıkça (1095 bölge) eşik de yükseldi: eskiden 1,7-2,6 idi.
const BOLGE_BELIRME_BASI: float = 2.4
const BOLGE_BELIRME_SONU: float = 3.4

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
## Ele geçirilip parlayan bölgeler: bölge id'si -> {"bas": başlangıç (ms), "ag": beyaz ağ}.
var _parlamalar: Dictionary[String, Dictionary] = {}
## Yürüyen tümenler (kayarak çizilir): "kaynak>hedef|sahip" -> özet.
var _yuruyen_ozetler: Dictionary[String, Dictionary] = {}
## Son çizimde ekranda süren bir animasyon (kayan tümen, atan muharebe işareti, parlama)
## vardı mı? Varsa üst katman her kare yeniden çizilir; yoksa yalnızca bir şey değişince.
var _animasyon_suruyor: bool = false
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
var _savastaki_ulke_sinirlari: PackedInt32Array = PackedInt32Array()
var _isgalli_bolge_sinirlari: PackedInt32Array = PackedInt32Array()


## Ülkenin haritadaki rengi (bkz. HaritaPaleti).
static func ulke_rengi(ulke: Ulke) -> Color:
	return HaritaPaleti.ulke_rengi(ulke)


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


## Oyuncunun gördüğü bölgeler değişince (Oyun.gorunurluk_degisti) çağrılır: karartma ağı
## yeniden kurulur, görünmeyen bölgelerdeki yabancı tümenler çizilmez olur.
func sisi_yenile() -> void:
	_dolgu_agini_kur()
	queue_redraw()
	_ust_katmani_yenile()


func _process(_delta: float) -> void:
	if _animasyon_suruyor:
		_ust_katmani_yenile()


## Animasyonlar şu an oynatılsın mı? Ayarlarda azaltılmışsa ya da oyun en yüksek hızda
## akarken oynatılmaz (simülasyonu yavaşlatmasın, göz yormasın).
func _animasyon_acik() -> bool:
	if Ayarlar.animasyonlar_azaltilmis:
		return false
	return not (Zaman.hiz >= Zaman.hiz_sayisi() and not Zaman.durdu)


## Ele geçirilen bölgeyi kısa bir parlamayla vurgular (Oyun.bolge_el_degistirdi). Oyuncunun
## görmediği bölgede ya da animasyonlar kapalıyken bir şey yapmaz.
func parlat(bolge_id: String) -> void:
	if _oyun == null or not _animasyon_acik() or not _oyun.oyuncu_bolgeyi_goruyor_mu(bolge_id):
		return
	if not _bolge_cokgenleri.has(bolge_id):
		return
	var siralar: PackedInt32Array = _bolge_cokgenleri[bolge_id]
	var renkler: PackedColorArray = PackedColorArray()
	for i: int in siralar.size():
		renkler.append(Color.WHITE)
	var ag: ArrayMesh = _ucgen_agi(siralar, renkler)
	if ag == null:
		return
	_parlamalar[bolge_id] = {"bas": Time.get_ticks_msec(), "ag": ag}
	_animasyon_suruyor = true
	_ust_katmani_yenile()


func _parlamalari_ciz() -> void:
	var simdi: int = Time.get_ticks_msec()
	for bolge_id: String in _parlamalar.keys():
		var t: float = float(simdi - int(_parlamalar[bolge_id]["bas"])) / PARLAMA_SURESI_MS
		if t >= 1.0:
			_parlamalar.erase(bolge_id)
			continue
		_ust_katman.draw_mesh(_parlamalar[bolge_id]["ag"], null, Transform2D.IDENTITY,
				Color(1.0, 1.0, 1.0, PARLAMA_OPAKLIGI * (1.0 - t)))
		_animasyon_suruyor = true


## Tümenler hareket edince ya da güçleri değişince çağrılır.
func birlikleri_yenile() -> void:
	_ust_katmani_yenile()


## Savaş ilan edilince ya da barış yapılınca çağrılır; savaştaki ülkelerin kırmızı
## çerçevesini günceller.
func savaslari_yenile() -> void:
	_cerceveleri_guncelle()
	_ust_katmani_yenile()


## Her oyun günü başında çağrılır: son işgal cezası günü içinde ele geçirilmiş, hâlâ ev
## sahibine dönmemiş bölgeleri turuncu bir çerçeveyle işaretler (bkz. Oyun.bolge_isgal_altinda_mi).
func isgalleri_yenile(su_anki_saat: int) -> void:
	var isgalliler: Dictionary[String, bool] = {}
	for bolge: Bolge in _dunya.bolge_listesi:
		if _oyun.bolge_isgal_altinda_mi(bolge, su_anki_saat):
			isgalliler[bolge.id] = true

	_isgalli_bolge_sinirlari = PackedInt32Array()
	if not isgalliler.is_empty():
		for i: int in _dunya.sinirlar.size():
			var sinir: Sinir = _dunya.sinirlar[i]
			if isgalliler.has(sinir.a) or isgalliler.has(sinir.b):
				_isgalli_bolge_sinirlari.append(i)
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
## eklendiği için küçük parçalar büyüklerin üstünde kalır. Oyuncunun görmediği bölgeler
## (savaş sisi) hafifçe koyu boyanır.
func _dolgu_agini_kur() -> void:
	var siralar: PackedInt32Array = PackedInt32Array()
	var renkler: PackedColorArray = PackedColorArray()
	for i: int in _dunya.cokgenler.size():
		var bolge_id: String = _dunya.cokgenler[i].bolge_id
		var renk: Color = ulke_rengi(_dunya.bolgenin_sahibi(bolge_id))
		if _oyun != null and not _oyun.oyuncu_bolgeyi_goruyor_mu(bolge_id):
			renk = renk.darkened(SIS_KARARTMASI)
		siralar.append(i)
		renkler.append(renk)
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
	_savastaki_ulke_sinirlari = PackedInt32Array()
	var secili_ulke: String = ""
	if _dunya.bolgeler.has(_secili_bolge):
		secili_ulke = _dunya.bolgeler[_secili_bolge].sahip
	var savastakiler: Dictionary[String, bool] = {}
	if _oyuncu != "":
		for ulke: Ulke in _dunya.ulke_listesi:
			if ulke.id != _oyuncu and _oyun.savasta_mi(_oyuncu, ulke.id):
				savastakiler[ulke.id] = true

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
		if not savastakiler.is_empty() and savastakiler.has(sahip_a) != savastakiler.has(sahip_b):
			_savastaki_ulke_sinirlari.append(i)


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

	_animasyon_suruyor = false
	if not _parlamalar.is_empty():
		_parlamalari_ciz()
	if _vurgu_agi != null:
		_ust_katman.draw_mesh(_vurgu_agi, null)
	_cerceve_ciz(_savastaki_ulke_sinirlari, SAVAS_RENGI, SAVAS_KALINLIGI, olcek)
	_cerceve_ciz(_isgalli_bolge_sinirlari, ISGAL_RENGI, ISGAL_KALINLIGI, olcek)
	_cerceve_ciz(_oyuncu_sinirlari, OYUNCU_RENGI, OYUNCU_KALINLIGI, olcek)
	_cerceve_ciz(_secili_ulke_sinirlari, SECILI_ULKE_RENGI, SECILI_ULKE_KALINLIGI, olcek)
	_cerceve_ciz(_secili_bolge_sinirlari, SECIM_RENGI, SECIM_KALINLIGI, olcek)
	_yol_cizgilerini_ciz(olcek)

	# Önce tümen kutularının yeri belirlenir; bölge adları kutulara çarpıyorsa yazılmaz
	# (tümen bilgisi bölge adından önemlidir; ad yakınlaşınca yine görünür).
	var kutu_alanlari: Array[Rect2] = []
	var ozetler: Dictionary[String, Dictionary] = _birlik_ozetleri(gorunen)
	var kutu_yerleri: Dictionary[String, Vector2] = _birlik_kutularini_yerlestir(ozetler, kutu_alanlari)
	_ulke_adlarini_ciz(gorunen, olcek)
	_bolge_adlarini_ciz(gorunen, olcek, kutu_alanlari)
	_birlikleri_ciz(olcek, ozetler, kutu_yerleri)
	_yuruyenleri_ciz(gorunen, olcek)
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


## Bölge adlarını ve başkent yıldızlarını çizer. Uzaktan hiçbiri görünmez (seçili bölgeninki
## de: uzaktan ülke adının üstüne biniyordu; seçimi sarı çerçeve ve alt panel zaten
## gösteriyor). Yalnızca ekrandaki bölgeler çizilir. Yakından seçili bölgenin adı, eşiğe
## bakılmadan yazılır. Bir tümen kutusuna (`kutu_alanlari`) çarpan ad yazılmaz.
func _bolge_adlarini_ciz(gorunen: Rect2, olcek: float, kutu_alanlari: Array[Rect2]) -> void:
	var opaklik: float = _bolge_gorunurlugu()
	if opaklik <= 0.0:
		return
	for i: int in _dunya.bolge_listesi.size():
		var bolge: Bolge = _dunya.bolge_listesi[i]
		var secili: bool = bolge.id == _secili_bolge
		if not gorunen.has_point(bolge.etiket):
			continue
		var ad_gorunur: bool = secili or _yakinlik >= _bolge_adi_esigi[i]
		var taban_y: float = YILDIZ_YARICAPI * 0.6 + BOLGE_ADI_BOYUTU if bolge.baskent else BOLGE_ADI_BOYUTU * 0.35
		if ad_gorunur and not secili:
			var genislik: float = _bolge_adi_genisligi[i]
			var ad_alani: Rect2 = Rect2(bolge.etiket * _yakinlik + Vector2(-genislik * 0.5, taban_y - BOLGE_ADI_BOYUTU * 0.8),
					Vector2(genislik, BOLGE_ADI_BOYUTU))
			for kutu: Rect2 in kutu_alanlari:
				if kutu.intersects(ad_alani):
					ad_gorunur = false
					break
		if not ad_gorunur and not bolge.baskent and bolge.tahkimat == 0:
			continue
		var oge_opakligi: float = 1.0 if secili else opaklik

		_ust_katman.draw_set_transform(bolge.etiket, 0.0, Vector2(olcek, olcek))
		if bolge.tahkimat > 0 and _oyun.oyuncu_bolgeyi_goruyor_mu(bolge.id):
			# Ad yazılıyorsa solunda, yazılmıyorsa etiket noktasının biraz altında durur.
			var tahkimat_yeri: Vector2 = Vector2(0.0, TAHKIMAT_ISARETI_BOYUTU)
			if ad_gorunur:
				tahkimat_yeri = Vector2(-_bolge_adi_genisligi[i] * 0.5 - TAHKIMAT_ISARETI_BOYUTU,
						taban_y - BOLGE_ADI_BOYUTU * 0.35)
			_tahkimat_isareti_ciz(tahkimat_yeri, bolge.tahkimat, oge_opakligi)
		if bolge.baskent:
			_yildiz_ciz(Vector2(0.0, -YILDIZ_YARICAPI * 0.6), oge_opakligi)
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
		if birlik.sahip != _oyun.oyuncu_ulkesi and not _oyun.oyuncu_bolgeyi_goruyor_mu(birlik.bolge_id):
			continue  # Savaş sisi: görmediği yerdeki yabancı yürüyüşü bilmez.
		var anahtar: String = "%s>%s" % [birlik.bolge_id, birlik.hedef_bolge_id]
		if cizilen.has(anahtar):
			continue
		cizilen[anahtar] = true
		var kaynak: Bolge = _dunya.bolgeler.get(birlik.bolge_id)
		var hedef: Bolge = _dunya.bolgeler.get(birlik.hedef_bolge_id)
		if kaynak == null or hedef == null:
			continue
		_ust_katman.draw_line(kaynak.etiket, hedef.etiket, YOL_CIZGISI_RENGI, YOL_CIZGISI_KALINLIGI * olcek, true)


## Ekrandaki her tümenli bölgenin özeti: bölge id'si -> {"guc": toplam güç, "sayilar": tür ->
## tümen sayısı, "sahipler": ülke id'si kümesi, "genislik": kutunun ekran genişliği}.
## Yalnızca yakınlaşınca (bölge ayrıntıları en az yarı belirmişken) dolar; uzaktan dünya genelinde
## yüzlerce kutu haritayı karmaşıklaştırmasın diye.
func _birlik_ozetleri(gorunen: Rect2) -> Dictionary[String, Dictionary]:
	var ozetler: Dictionary[String, Dictionary] = {}
	_yuruyen_ozetler = {}
	if _oyun == null or _bolge_gorunurlugu() < BIRLIK_GORUNURLUK_ESIGI:
		return ozetler
	var kaydir: bool = _animasyon_acik()
	for birlik: Birlik in _oyun.birlikler:
		if kaydir and birlik.hedef_bolge_id != "":
			_yuruyene_ekle(birlik)
			continue
		var ozet: Dictionary = ozetler.get(birlik.bolge_id, {})
		if ozet.is_empty():
			var bolge: Bolge = _dunya.bolgeler.get(birlik.bolge_id)
			if bolge == null or not gorunen.has_point(bolge.etiket):
				continue
			# Savaş sisi: görünmeyen bölgede (orada oyuncunun tümeni de olamaz) hiçbir tümen ve
			# dolayısıyla muharebe işareti çizilmez.
			if not _oyun.oyuncu_bolgeyi_goruyor_mu(bolge.id):
				continue
			ozet = {"guc": 0.0, "sayilar": {}, "sahipler": {}}
			ozetler[birlik.bolge_id] = ozet
		ozet["guc"] += birlik.guc
		ozet["sayilar"][birlik.tur] = int(ozet["sayilar"].get(birlik.tur, 0)) + 1
		ozet["sahipler"][birlik.sahip] = float(ozet["sahipler"].get(birlik.sahip, 0.0)) + birlik.guc
	for bolge_id: String in ozetler:
		ozetler[bolge_id]["genislik"] = _birlik_kutusu_genisligi(ozetler[bolge_id])
	return ozetler


## Yürüyen tümeni, aynı yolda aynı ülkenin yürüyen tümenleriyle tek kutuda toplar. Savaş
## sisi: yabancı tümen yalnızca yola çıktığı bölge görünüyorsa gösterilir.
func _yuruyene_ekle(birlik: Birlik) -> void:
	if birlik.sahip != _oyun.oyuncu_ulkesi and not _oyun.oyuncu_bolgeyi_goruyor_mu(birlik.bolge_id):
		return
	var anahtar: String = "%s>%s|%s" % [birlik.bolge_id, birlik.hedef_bolge_id, birlik.sahip]
	var ozet: Dictionary = _yuruyen_ozetler.get(anahtar, {})
	if ozet.is_empty():
		ozet = {"guc": 0.0, "sayilar": {}, "sahipler": {}, "birlik": birlik}
		_yuruyen_ozetler[anahtar] = ozet
	ozet["guc"] += birlik.guc
	ozet["sayilar"][birlik.tur] = int(ozet["sayilar"].get(birlik.tur, 0)) + 1
	ozet["sahipler"][birlik.sahip] = true


## Yürüyen tümen kutularını kaynakla hedef arasındaki yolda, geçen zamana göre kaydırarak
## çizer (saatler arasında da akıcı olsun diye Zaman.saat_kesri kullanılır).
func _yuruyenleri_ciz(gorunen: Rect2, olcek: float) -> void:
	if _yuruyen_ozetler.is_empty():
		return
	var simdi: float = float(Zaman.toplam_saat) + (0.0 if Zaman.durdu else Zaman.saat_kesri())
	for anahtar: String in _yuruyen_ozetler:
		var ozet: Dictionary = _yuruyen_ozetler[anahtar]
		var birlik: Birlik = ozet["birlik"]
		var kaynak: Bolge = _dunya.bolgeler.get(birlik.bolge_id)
		var hedef: Bolge = _dunya.bolgeler.get(birlik.hedef_bolge_id)
		if kaynak == null or hedef == null:
			continue
		var cikis: int = birlik.cikis_saati if birlik.cikis_saati >= 0 else birlik.varis_saati
		var t: float = clampf((simdi - cikis) / maxf(1.0, float(birlik.varis_saati - cikis)), 0.0, 1.0)
		var konum: Vector2 = kaynak.etiket.lerp(hedef.etiket, t)
		if not gorunen.has_point(konum):
			continue
		ozet["genislik"] = _birlik_kutusu_genisligi(ozet)
		var sahip: Ulke = _dunya.ulkeler.get(birlik.sahip)
		_ust_katman.draw_set_transform(konum, 0.0, Vector2(olcek, olcek))
		_birlik_kutusu_ciz(ulke_rengi(sahip) if sahip != null else Color.GRAY, ozet, Vector2.ZERO)
		if not Zaman.durdu:
			_animasyon_suruyor = true


## Kutunun genişliği: iç boşluk + güç yazısı + her tür için (aralık + işaret + sayı).
func _birlik_kutusu_genisligi(ozet: Dictionary) -> float:
	var genislik: float = BIRLIK_KUTU_IC_BOSLUGU * 2.0 + _yazi_genisligi(str(roundi(ozet["guc"])))
	for tur: String in BirlikTurleri.SIRA:
		var sayi: int = ozet["sayilar"].get(tur, 0)
		if sayi > 0:
			genislik += BIRLIK_KUTU_IC_BOSLUGU + TUR_ISARETI_BOYUTU + TUR_ISARETI_ARALIGI + _yazi_genisligi(str(sayi))
	return maxf(genislik, BIRLIK_KUTU_BOYUTU.x)


func _yazi_genisligi(metin: String) -> float:
	return _yazi_tipi.get_string_size(metin, HORIZONTAL_ALIGNMENT_LEFT, -1.0, BIRLIK_YAZI_BOYUTU).x


## Aynı bölgedeki tümenleri tek kutuda çizer (bkz. _birlik_ozetleri).
## `kutu_yerleri`, _birlik_kutularini_yerlestir()'in seçtiği yerlerdir.
func _birlikleri_ciz(olcek: float, ozetler: Dictionary[String, Dictionary],
		kutu_yerleri: Dictionary[String, Vector2]) -> void:
	for bolge_id: String in ozetler:
		var bolge: Bolge = _dunya.bolgeler[bolge_id]
		var sahip: Ulke = _dunya.bolgenin_sahibi(bolge_id)
		var renk: Color = ulke_rengi(sahip) if sahip != null else Color.GRAY
		var yer: Vector2 = kutu_yerleri.get(bolge_id, BIRLIK_KONUM_PAYI)
		_ust_katman.draw_set_transform(bolge.etiket, 0.0, Vector2(olcek, olcek))
		if yer != BIRLIK_KONUM_PAYI:
			# Kutu kalabalık yüzünden bölgesinden uzaklaştı: hangi bölgenin olduğu belli olsun.
			_ust_katman.draw_line(Vector2.ZERO, yer + Vector2(0.0, BIRLIK_KUTU_BOYUTU.y * 0.5),
					BIRLIK_BAG_CIZGISI_RENGI, BIRLIK_BAG_CIZGISI_KALINLIGI, true)
		_birlik_kutusu_ciz(renk, ozetler[bolge_id], yer)
		if ozetler[bolge_id]["sahipler"].size() > 1:
			_muharebe_isareti_ciz(yer, ozetler[bolge_id], bolge)


## Ekrandaki tümen kutularına, birbirlerinin üstüne binmeyecek yerler seçer: güçlü bölgeden
## zayıfa, her kutu için etiketin üstü, solu, sağı ve kat kat daha üstü sırayla denenir
## (hiçbiri boş değilse varsayılan yer kullanılır). Seçilen
## yerleri (bölge id'si -> etikete göre ekran pikseli) döndürür; kutuların kapladığı alanları
## da `kutu_alanlari`na (kamera kaymasından bağımsız, yalnızca yakınlığa bağlı koordinatlarla) ekler.
func _birlik_kutularini_yerlestir(ozetler: Dictionary[String, Dictionary],
		kutu_alanlari: Array[Rect2]) -> Dictionary[String, Vector2]:
	var yerler: Dictionary[String, Vector2] = {}
	var bolge_idleri: Array[String] = []
	bolge_idleri.assign(ozetler.keys())
	bolge_idleri.sort_custom(func(a: String, b: String) -> bool: return ozetler[a]["guc"] > ozetler[b]["guc"])

	for bolge_id: String in bolge_idleri:
		var genislik: float = ozetler[bolge_id]["genislik"]
		# Muharebe işareti kutunun sağında durduğu için alan sağa doğru biraz geniş tutulur.
		var boyut: Vector2 = Vector2(genislik + MUHAREBE_ISARETI_YARICAPI * 2.0 + 10.0, BIRLIK_KUTU_BOYUTU.y)
		var yan: float = genislik * 0.5 + MUHAREBE_ISARETI_YARICAPI + 20.0
		var adim: float = BIRLIK_KUTU_BOYUTU.y + YAZI_ARALIGI
		var adaylar: Array[Vector2] = []
		for kat: int in BIRLIK_YEDEK_KAT_SAYISI:
			var orta: Vector2 = BIRLIK_KONUM_PAYI + Vector2(0.0, -adim * kat)
			adaylar.append_array([orta, orta + Vector2(-yan, 0.0), orta + Vector2(yan, 0.0)])
		var temel: Vector2 = _dunya.bolgeler[bolge_id].etiket * _yakinlik
		var yarim: Vector2 = Vector2(genislik, BIRLIK_KUTU_BOYUTU.y) * 0.5
		var secilen: Vector2 = BIRLIK_KONUM_PAYI
		for aday: Vector2 in adaylar:
			var alan: Rect2 = Rect2(temel + aday - yarim, boyut).grow(YAZI_ARALIGI * 0.5)
			var carpiyor: bool = false
			for dolu: Rect2 in kutu_alanlari:
				if dolu.intersects(alan):
					carpiyor = true
					break
			if not carpiyor:
				secilen = aday
				break
		yerler[bolge_id] = secilen
		kutu_alanlari.append(Rect2(temel + secilen - yarim, boyut))
	return yerler


## `merkez` (BIRLIK_KONUM_PAYI) ölçeklenmiş yerel çerçeve içinde uygulanır ki kutu,
## yakınlıktan bağımsız olarak bölge etiketine göre hep aynı ekran uzaklığında kalsın
## (konum dönüşüm köküne eklenseydi, kamera yakınlığıyla birlikte ekranda büyürdü).
func _birlik_kutusu_ciz(renk: Color, ozet: Dictionary, merkez: Vector2 = BIRLIK_KONUM_PAYI) -> void:
	var yarim: Vector2 = Vector2(ozet["genislik"], BIRLIK_KUTU_BOYUTU.y) * 0.5
	var kose: PackedVector2Array = PackedVector2Array([
		merkez + Vector2(-yarim.x, -yarim.y), merkez + Vector2(yarim.x, -yarim.y),
		merkez + Vector2(yarim.x, yarim.y), merkez + Vector2(-yarim.x, yarim.y),
	])
	_ust_katman.draw_colored_polygon(kose, renk)
	kose.append(kose[0])
	_ust_katman.draw_polyline(kose, BIRLIK_KUTU_KENAR_RENGI, BIRLIK_KUTU_KENAR_KALINLIGI, true)

	var taban_y: float = merkez.y + BIRLIK_YAZI_BOYUTU * 0.35
	var x: float = merkez.x - yarim.x + BIRLIK_KUTU_IC_BOSLUGU
	var guc_metni: String = str(roundi(ozet["guc"]))
	_yazi_ciz(guc_metni, Vector2(x, taban_y), BIRLIK_YAZI_BOYUTU, 1.0)
	x += _yazi_genisligi(guc_metni)
	for tur: String in BirlikTurleri.SIRA:
		var sayi: int = ozet["sayilar"].get(tur, 0)
		if sayi == 0:
			continue
		x += BIRLIK_KUTU_IC_BOSLUGU
		_tur_isareti_ciz(tur, Vector2(x + TUR_ISARETI_BOYUTU * 0.5, merkez.y))
		x += TUR_ISARETI_BOYUTU + TUR_ISARETI_ARALIGI
		var metin: String = str(sayi)
		_yazi_ciz(metin, Vector2(x, taban_y), BIRLIK_YAZI_BOYUTU, 1.0)
		x += _yazi_genisligi(metin)


## Tümen türünün sade işareti (TUR_ISARETI_BOYUTU'luk karede, koyu kenarlı beyaz):
## piyade çarpı, zırhlı yatay oval, topçu dolu daire.
func _tur_isareti_ciz(tur: String, merkez: Vector2) -> void:
	var r: float = TUR_ISARETI_BOYUTU * 0.5
	var kenar: Color = BIRLIK_KUTU_KENAR_RENGI
	match tur:
		"zirhli":
			var oval: PackedVector2Array = PackedVector2Array()
			for k: int in 21:
				var aci: float = TAU * k / 20.0
				oval.append(merkez + Vector2(cos(aci) * r, sin(aci) * r * 0.55))
			_ust_katman.draw_polyline(oval, kenar, TUR_ISARETI_KALINLIGI + 3.0, true)
			_ust_katman.draw_polyline(oval, Color.WHITE, TUR_ISARETI_KALINLIGI, true)
		"topcu":
			_ust_katman.draw_circle(merkez, r * 0.7 + 1.5, kenar)
			_ust_katman.draw_circle(merkez, r * 0.7, Color.WHITE)
		_:
			var a: Vector2 = Vector2(r * 0.8, r * 0.8)
			var b: Vector2 = Vector2(r * 0.8, -r * 0.8)
			for renk_kalinlik: Array in [[kenar, TUR_ISARETI_KALINLIGI + 3.0], [Color.WHITE, TUR_ISARETI_KALINLIGI]]:
				_ust_katman.draw_line(merkez - a, merkez + a, renk_kalinlik[0], renk_kalinlik[1], true)
				_ust_katman.draw_line(merkez - b, merkez + b, renk_kalinlik[0], renk_kalinlik[1], true)


## Tahkimatlı bölgenin küçük kale işareti: gri, dişli bir kule ve içinde seviyesi.
## `merkez`, bölge etiketinin ölçeklenmiş yerel çerçevesindedir.
func _tahkimat_isareti_ciz(merkez: Vector2, seviye: int, opaklik: float) -> void:
	var y: float = TAHKIMAT_ISARETI_BOYUTU * 0.5
	var d: float = y / 3.0
	# Üstte üç diş olan bir kule silueti.
	var kule: PackedVector2Array = PackedVector2Array([
		merkez + Vector2(-y, y), merkez + Vector2(-y, -y), merkez + Vector2(-y + d, -y),
		merkez + Vector2(-y + d, -y + d), merkez + Vector2(-d * 0.5, -y + d), merkez + Vector2(-d * 0.5, -y),
		merkez + Vector2(d * 0.5, -y), merkez + Vector2(d * 0.5, -y + d), merkez + Vector2(y - d, -y + d),
		merkez + Vector2(y - d, -y), merkez + Vector2(y, -y), merkez + Vector2(y, y),
	])
	_ust_katman.draw_colored_polygon(kule, Color(TAHKIMAT_ISARETI_RENGI, opaklik))
	kule.append(kule[0])
	_ust_katman.draw_polyline(kule, Color(BIRLIK_KUTU_KENAR_RENGI, opaklik), 2.0, true)
	var metin: String = str(seviye)
	var genislik: float = _yazi_tipi.get_string_size(metin, HORIZONTAL_ALIGNMENT_LEFT, -1.0, TAHKIMAT_YAZI_BOYUTU).x
	_yazi_ciz(metin, merkez + Vector2(-genislik * 0.5, y * 0.2 + TAHKIMAT_YAZI_BOYUTU * 0.35), TAHKIMAT_YAZI_BOYUTU, opaklik)


## Tümen kutusunun sağına, birden çok ülkenin tümeni bulunan (savaşan) bölgeyi işaretleyen
## kırmızı bir daire çizer. `_birlik_kutusu_ciz` ile aynı ölçeklenmiş yerel çerçevede çalışır.
## Animasyonlar açıksa işaret hafifçe atar. Altındaki küçük çubuk tarafların güç oranını
## gösterir: solda savunanın (bölgenin sahibi), sağda saldıranların rengi.
func _muharebe_isareti_ciz(kutu_merkezi: Vector2, ozet: Dictionary, bolge: Bolge) -> void:
	var merkez: Vector2 = kutu_merkezi + Vector2(float(ozet["genislik"]) * 0.5 + MUHAREBE_ISARETI_YARICAPI + 10.0, 0.0)
	var yaricap: float = MUHAREBE_ISARETI_YARICAPI
	if _animasyon_acik():
		yaricap *= 1.0 + MUHAREBE_ATIS_GENLIGI * sin(Time.get_ticks_msec() / 1000.0 * MUHAREBE_ATIS_HIZI)
		_animasyon_suruyor = true
	_ust_katman.draw_circle(merkez, yaricap, MUHAREBE_ISARETI_RENGI)
	_ust_katman.draw_arc(merkez, yaricap, 0.0, TAU, 24, Color.WHITE, 2.0)

	var gucler: Dictionary = ozet["sahipler"]
	var toplam: float = maxf(float(ozet["guc"]), 0.001)
	var savunan_guc: float = float(gucler.get(bolge.sahip, 0.0))
	var saldiran_sahip: String = ""
	for sahip: String in gucler:
		if sahip != bolge.sahip:
			saldiran_sahip = sahip
			break
	var savunan_rengi: Color = ulke_rengi(_dunya.ulkeler[bolge.sahip])
	var saldiran: Ulke = _dunya.ulkeler.get(saldiran_sahip)
	var saldiran_rengi: Color = ulke_rengi(saldiran) if saldiran != null else Color.GRAY
	var sol_ust: Vector2 = merkez + Vector2(-GUC_CUBUGU_BOYUTU.x * 0.5, MUHAREBE_ISARETI_YARICAPI + 6.0)
	var savunan_payi: float = GUC_CUBUGU_BOYUTU.x * clampf(savunan_guc / toplam, 0.0, 1.0)
	_ust_katman.draw_rect(Rect2(sol_ust, GUC_CUBUGU_BOYUTU), saldiran_rengi)
	_ust_katman.draw_rect(Rect2(sol_ust, Vector2(savunan_payi, GUC_CUBUGU_BOYUTU.y)), savunan_rengi)
	_ust_katman.draw_rect(Rect2(sol_ust, GUC_CUBUGU_BOYUTU), BIRLIK_KUTU_KENAR_RENGI, false, 2.0)


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
