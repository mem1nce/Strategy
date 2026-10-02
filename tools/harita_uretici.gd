@tool
extends RefCounted
## Kalmera kıtasının haritasını üreten araç.
##
## Sabit bir tohumla Voronoi hücreleri üretir, 72 tanesini kara yapar, altı ülkeye
## paylaştırır ve sonucu data/provinces.json ile data/countries.json dosyalarına yazar.
## Oyun çalışırken kullanılmaz; oyun yalnızca bu iki dosyayı okur.
##
## Çalıştırmak için: tools/harita_uret_editor.gd (Godot içinden) ya da
## tools/harita_uret_cli.gd (komut satırından).

const BOLGE_DOSYASI: String = "res://data/provinces.json"
const ULKE_DOSYASI: String = "res://data/countries.json"

## Aynı tohum her zaman aynı haritayı verir. Başka bir harita için bu sayıyı değiştir.
const TOHUM: int = 1931
const DUNYA_BOYUTU: Vector2 = Vector2(4200.0, 2400.0)
## Deniz dahil toplam Voronoi hücresi.
const NOKTA_SAYISI: int = 200
const BLOK_BASINA_BOLGE: int = 36
const ULKE_BASINA_BOLGE: int = 12
## Hücreleri birbirine yakın büyüklükte yapmak için noktaların kaç kez ortalanacağı.
const GEVSETME_TURU: int = 3
## Bu kadar yakın köşeler tek köşe sayılır (çok kısa sınırları yok eder).
const KOSE_BIRLESTIRME: float = 24.0
const AZAMI_DENEME: int = 200

## Kıtanın en-boy oranı. Yalnızca oran önemlidir.
const KITA_ORANI: Vector2 = Vector2(1750.0, 760.0)
## Kenarların ne kadar girintili çıkıntılı olacağı (parça uzunluğuna oranla).
const KIYI_OYNAMA: float = 0.24
const SINIR_OYNAMA: float = 0.10
## Kenarlar bu uzunluktan kısa parçalara bölünene kadar kırılır.
const PARCA_UZUNLUGU: float = 44.0

const DAG_SAYISI: int = 11
const ORMAN_SAYISI: int = 19

const BLOKLAR: Array[Dictionary] = [
	{"id": "kuzey", "ad": "Kuzey Antlaşması"},
	{"id": "guney", "ad": "Güney Birliği"},
]

## Sıra önemlidir: önce kuzey bloğu (batıdan doğuya), sonra güney bloğu (batıdan doğuya).
const ULKELER: Array[Dictionary] = [
	{"id": "vardanya", "ad": "Vardanya", "blok": "kuzey", "renk": "#3b6fb6"},
	{"id": "kelmor", "ad": "Kelmor", "blok": "kuzey", "renk": "#4a9e5c"},
	{"id": "suvat", "ad": "Suvat", "blok": "kuzey", "renk": "#8c5fb8"},
	{"id": "darmek", "ad": "Darmek", "blok": "guney", "renk": "#c4453d"},
	{"id": "yelbor", "ad": "Yelbor", "blok": "guney", "renk": "#e6c84a"},
	{"id": "orsin", "ad": "Orsin", "blok": "guney", "renk": "#cc7426"},
]

## Bölge adı havuzu. Hepsi uydurmadır; en az 72 ad olmalıdır.
const ADLAR: PackedStringArray = [
	"Aldaz", "Sevrik", "Tulmar", "Korvaz", "Yelgeç", "Demirök", "Bozdur", "Kızılöz",
	"Gökseren", "Taşvar", "Sarkun", "Erdiz", "Ulgar", "Çavruk", "Narbük", "Kumsar",
	"Dumran", "Oğulca", "Tirmen", "Balkır", "Savruk", "Yağızlı", "Koçar", "Berköz",
	"Altıntav", "Güzbel", "Harsın", "Çiğdek", "Sülmez", "Karaöz", "Ayvar", "Tozluca",
	"Ermek", "Yundak", "Bürgen", "Kavran", "Selgin", "Özbük", "Dolunca", "Tekinsu",
	"Uzgeçit", "Yalmuk", "Kırçal", "Sığruk", "Pınarbel", "Aksuvar", "Çelmek", "Öveçli",
	"Tamruk", "Gedirge", "İnceöz", "Morkaya", "Batırga", "Sungar", "Yazgır", "Kelvan",
	"Durbuk", "Emrek", "Çakmar", "Uğran", "Karlıbel", "Solvan", "Tanrak", "Böğürt",
	"Günsar", "Ortabük", "Dağyaka", "Kuşvan", "Elvaç", "Sazören", "Tuzgan", "Yörsün",
	"Ardıl", "Bengiz", "Çörten", "Kıymaz", "Zerdin", "Mengir", "İldem", "Şavkın",
	"Varnık", "Ozanca", "Dirgen", "Tepsin",
]

var _rng: RandomNumberGenerator
## Voronoi hücrelerinin merkez noktaları.
var _noktalar: PackedVector2Array = PackedVector2Array()
## Hücrelerin paylaştığı köşe havuzu.
var _koseler: PackedVector2Array = PackedVector2Array()
## Her hücrenin köşe numaraları (sırayla).
var _hucre_koseleri: Array[PackedInt32Array] = []
## Her hücrenin komşu hücre numaraları.
var _komsular: Array[Array] = []
## Kenar (küçük köşe no, büyük köşe no) -> o kenarı paylaşan hücreler.
var _kenar_hucreleri: Dictionary[Vector2i, Array] = {}
## Hücre dünya sınırına değiyor mu? Değenler her zaman denizdir.
var _kenarda: Array[bool] = []
## Hücrenin ülke sırası (ULKELER içindeki yeri). Deniz için -1.
var _ulke_no: PackedInt32Array = PackedInt32Array()
var _kuzey: Array[int] = []
var _guney: Array[int] = []
var _arazi: Array[String] = []
var _baskent: PackedInt32Array = PackedInt32Array()
var _ikinci_sehir: PackedInt32Array = PackedInt32Array()
var _zafer: PackedInt32Array = PackedInt32Array()
var _insan: PackedInt32Array = PackedInt32Array()
var _celik: PackedInt32Array = PackedInt32Array()
var _petrol: PackedInt32Array = PackedInt32Array()
var _fabrika: PackedInt32Array = PackedInt32Array()

var _bolge_kayitlari: Array[Dictionary] = []
var _ulke_kayitlari: Array[Dictionary] = []


## Haritayı üretir ve dosyalara yazar. Başarılıysa true döner.
func calistir() -> bool:
	if ADLAR.size() < BLOK_BASINA_BOLGE * 2:
		push_error("Harita üretici: ad havuzu yetersiz (%d ad var)." % ADLAR.size())
		return false
	for deneme: int in AZAMI_DENEME:
		var hata: String = _dene(deneme)
		if hata != "":
			print("  deneme %d olmadı: %s" % [deneme, hata])
			continue
		if not _yaz():
			return false
		print("Harita üretildi (tohum %d, deneme %d)." % [TOHUM, deneme])
		_ozet_yaz()
		return true
	push_error("Harita üretici: %d denemede uygun harita bulunamadı." % AZAMI_DENEME)
	return false


## Tek bir deneme yapar. Başarılıysa boş metin, değilse nedenini döndürür.
func _dene(deneme: int) -> String:
	_rng = RandomNumberGenerator.new()
	_rng.seed = TOHUM * 1000 + deneme

	_noktalar = PackedVector2Array()
	for i: int in NOKTA_SAYISI:
		_noktalar.append(Vector2(_rng.randf() * DUNYA_BOYUTU.x, _rng.randf() * DUNYA_BOYUTU.y))

	var hucreler: Array[PackedVector2Array] = _voronoi()
	for tur: int in GEVSETME_TURU:
		for i: int in NOKTA_SAYISI:
			_noktalar[i] = _agirlik_merkezi(hucreler[i])
		hucreler = _voronoi()

	var hata: String = _agi_kur(hucreler)
	if hata != "":
		return hata
	hata = _karayi_sec()
	if hata != "":
		return hata
	hata = _ulkelere_bol()
	if hata != "":
		return hata
	_sehirleri_sec()
	_araziyi_dagit()
	_kaynaklari_dagit()
	return _kayitlari_kur()


# --- Voronoi ---------------------------------------------------------------

## Her nokta için Voronoi hücresini hesaplar: dünya dikdörtgeni, diğer bütün
## noktalarla arasındaki orta dikme ile kırpılır.
func _voronoi() -> Array[PackedVector2Array]:
	var sonuc: Array[PackedVector2Array] = []
	var kutu: PackedVector2Array = PackedVector2Array([
		Vector2(0.0, 0.0),
		Vector2(DUNYA_BOYUTU.x, 0.0),
		Vector2(DUNYA_BOYUTU.x, DUNYA_BOYUTU.y),
		Vector2(0.0, DUNYA_BOYUTU.y),
	])
	for i: int in _noktalar.size():
		var p: Vector2 = _noktalar[i]
		var hucre: PackedVector2Array = kutu
		for j: int in _noktalar.size():
			if j == i:
				continue
			var q: Vector2 = _noktalar[j]
			hucre = _kirp(hucre, (p + q) * 0.5, q - p)
		sonuc.append(hucre)
	return sonuc


## Dışbükey çokgenin, `orta` noktasından geçen ve normali `yon` olan doğrunun
## gerisinde kalan parçasını döndürür.
static func _kirp(cokgen: PackedVector2Array, orta: Vector2, yon: Vector2) -> PackedVector2Array:
	var sonuc: PackedVector2Array = PackedVector2Array()
	var adet: int = cokgen.size()
	for k: int in adet:
		var a: Vector2 = cokgen[k]
		var b: Vector2 = cokgen[(k + 1) % adet]
		var da: float = (a - orta).dot(yon)
		var db: float = (b - orta).dot(yon)
		if da <= 0.0:
			sonuc.append(a)
		if (da < 0.0 and db > 0.0) or (da > 0.0 and db < 0.0):
			sonuc.append(a + (b - a) * (da / (da - db)))
	return sonuc


static func _agirlik_merkezi(cokgen: PackedVector2Array) -> Vector2:
	var alan: float = 0.0
	var toplam: Vector2 = Vector2.ZERO
	var adet: int = cokgen.size()
	for k: int in adet:
		var a: Vector2 = cokgen[k]
		var b: Vector2 = cokgen[(k + 1) % adet]
		var capraz: float = a.cross(b)
		alan += capraz
		toplam += (a + b) * capraz
	if absf(alan) < 0.0001:
		return cokgen[0] if adet > 0 else Vector2.ZERO
	return toplam / (3.0 * alan)


# --- Hücre ağı -------------------------------------------------------------

## Hücrelerin köşelerini ortak bir havuzda birleştirir, kenarları ve komşulukları çıkarır.
func _agi_kur(hucreler: Array[PackedVector2Array]) -> String:
	_koseler = PackedVector2Array()
	_hucre_koseleri = []
	_komsular = []
	_kenar_hucreleri = {}
	_kenarda = []

	for i: int in hucreler.size():
		var kenarda: bool = false
		var halka: PackedInt32Array = PackedInt32Array()
		for p: Vector2 in hucreler[i]:
			if p.x < 0.5 or p.y < 0.5 or p.x > DUNYA_BOYUTU.x - 0.5 or p.y > DUNYA_BOYUTU.y - 0.5:
				kenarda = true
			var no: int = _kose_no(p)
			if halka.is_empty() or halka[halka.size() - 1] != no:
				halka.append(no)
		if halka.size() > 1 and halka[0] == halka[halka.size() - 1]:
			halka.remove_at(halka.size() - 1)
		if halka.size() < 3:
			return "bir hücre çok küçük"
		for a: int in halka.size():
			for b: int in range(a + 1, halka.size()):
				if halka[a] == halka[b]:
					return "bir hücre kendine değiyor"
		_hucre_koseleri.append(halka)
		_kenarda.append(kenarda)
		_komsular.append([])

	for i: int in _hucre_koseleri.size():
		var halka: PackedInt32Array = _hucre_koseleri[i]
		for k: int in halka.size():
			var anahtar: Vector2i = _kenar_anahtari(halka[k], halka[(k + 1) % halka.size()])
			if not _kenar_hucreleri.has(anahtar):
				_kenar_hucreleri[anahtar] = []
			_kenar_hucreleri[anahtar].append(i)

	for anahtar: Vector2i in _kenar_hucreleri:
		var liste: Array = _kenar_hucreleri[anahtar]
		if liste.size() > 2:
			return "bir kenar ikiden fazla hücreye ait"
		if liste.size() == 2:
			var a: int = liste[0]
			var b: int = liste[1]
			if not _komsular[a].has(b):
				_komsular[a].append(b)
			if not _komsular[b].has(a):
				_komsular[b].append(a)
	return ""


func _kose_no(p: Vector2) -> int:
	var esik: float = KOSE_BIRLESTIRME * KOSE_BIRLESTIRME
	for k: int in _koseler.size():
		if _koseler[k].distance_squared_to(p) <= esik:
			return k
	_koseler.append(p)
	return _koseler.size() - 1


static func _kenar_anahtari(a: int, b: int) -> Vector2i:
	return Vector2i(mini(a, b), maxi(a, b))


# --- Kara, bloklar ve ülkeler ----------------------------------------------

## Kıtanın biçimini belirler: merkeze yakın 36 kuzey ve 36 güney hücresi kara olur.
## Kıyı çizgisi birkaç dalgayla bozulur ki kıta düzgün bir elips gibi görünmesin.
func _karayi_sec() -> String:
	var merkez: Vector2 = DUNYA_BOYUTU * 0.5
	var f1: float = _rng.randf_range(0.0, TAU)
	var f2: float = _rng.randf_range(0.0, TAU)
	var f3: float = _rng.randf_range(0.0, TAU)

	var puan: PackedFloat32Array = PackedFloat32Array()
	puan.resize(_noktalar.size())
	_kuzey = []
	_guney = []
	for i: int in _noktalar.size():
		if _kenarda[i]:
			continue
		var d: Vector2 = (_noktalar[i] - merkez) / KITA_ORANI
		var aci: float = d.angle()
		var kiyi: float = 1.0 + 0.13 * sin(2.0 * aci + f1) + 0.09 * sin(3.0 * aci + f2) \
				+ 0.06 * sin(5.0 * aci + f3)
		puan[i] = d.length() / kiyi
		if _noktalar[i].y < merkez.y:
			_kuzey.append(i)
		else:
			_guney.append(i)

	if _kuzey.size() < BLOK_BASINA_BOLGE or _guney.size() < BLOK_BASINA_BOLGE:
		return "yeterli hücre yok"
	var siralayici: Callable = func(a: int, b: int) -> bool: return puan[a] < puan[b]
	_kuzey.sort_custom(siralayici)
	_guney.sort_custom(siralayici)
	_kuzey.resize(BLOK_BASINA_BOLGE)
	_guney.resize(BLOK_BASINA_BOLGE)

	_ulke_no = PackedInt32Array()
	_ulke_no.resize(_noktalar.size())
	_ulke_no.fill(-1)
	for h: int in _kuzey:
		_ulke_no[h] = 0
	for h: int in _guney:
		_ulke_no[h] = 0

	if not _bagli_mi(_kuzey):
		return "kuzey bloğu tek parça değil"
	if not _bagli_mi(_guney):
		return "güney bloğu tek parça değil"
	var kara: Array[int] = _kuzey.duplicate()
	kara.append_array(_guney)
	if not _bagli_mi(kara):
		return "kıta tek parça değil"
	if _gol_var_mi():
		return "kıtanın içinde göl var"
	return ""


## Her bloğun 36 hücresini batıdan doğuya dizip 12'şerli üç ülkeye böler.
func _ulkelere_bol() -> String:
	var bloklar: Array[Array] = [_kuzey, _guney]
	for blok: int in bloklar.size():
		var liste: Array[int] = []
		liste.assign(bloklar[blok])
		liste.sort_custom(func(a: int, b: int) -> bool: return _noktalar[a].x < _noktalar[b].x)
		for s: int in liste.size():
			@warning_ignore("integer_division")
			_ulke_no[liste[s]] = blok * 3 + s / ULKE_BASINA_BOLGE
	for u: int in ULKELER.size():
		if not _bagli_mi(_ulke_hucreleri(u)):
			return "%s tek parça değil" % ULKELER[u]["ad"]
	return ""


func _ulke_hucreleri(u: int) -> Array[int]:
	var sonuc: Array[int] = []
	for i: int in _ulke_no.size():
		if _ulke_no[i] == u:
			sonuc.append(i)
	return sonuc


func _bagli_mi(kume: Array[int]) -> bool:
	if kume.is_empty():
		return false
	var icinde: Dictionary[int, bool] = {}
	for h: int in kume:
		icinde[h] = true
	var gorulen: Dictionary[int, bool] = {kume[0]: true}
	var kuyruk: Array[int] = [kume[0]]
	var bas: int = 0
	while bas < kuyruk.size():
		var h: int = kuyruk[bas]
		bas += 1
		for k: int in _komsular[h]:
			if icinde.has(k) and not gorulen.has(k):
				gorulen[k] = true
				kuyruk.append(k)
	return gorulen.size() == kume.size()


## Dünya kenarından ulaşılamayan bir deniz hücresi varsa true döner.
func _gol_var_mi() -> bool:
	var gorulen: Dictionary[int, bool] = {}
	var kuyruk: Array[int] = []
	var deniz_sayisi: int = 0
	for i: int in _ulke_no.size():
		if _ulke_no[i] >= 0:
			continue
		deniz_sayisi += 1
		if _kenarda[i]:
			gorulen[i] = true
			kuyruk.append(i)
	var bas: int = 0
	while bas < kuyruk.size():
		var h: int = kuyruk[bas]
		bas += 1
		for k: int in _komsular[h]:
			if _ulke_no[k] < 0 and not gorulen.has(k):
				gorulen[k] = true
				kuyruk.append(k)
	return gorulen.size() != deniz_sayisi


## Verilen hücrelerden başlayarak, kara üzerinden kaç adımda varıldığını döndürür.
func _mesafeler(baslangic: Array[int]) -> PackedInt32Array:
	var mesafe: PackedInt32Array = PackedInt32Array()
	mesafe.resize(_noktalar.size())
	mesafe.fill(-1)
	var kuyruk: Array[int] = baslangic.duplicate()
	for h: int in baslangic:
		mesafe[h] = 0
	var bas: int = 0
	while bas < kuyruk.size():
		var h: int = kuyruk[bas]
		bas += 1
		for k: int in _komsular[h]:
			if _ulke_no[k] >= 0 and mesafe[k] < 0:
				mesafe[k] = mesafe[h] + 1
				kuyruk.append(k)
	return mesafe


# --- Şehirler, arazi ve kaynaklar ------------------------------------------

## Her ülkeye bir başkent (cepheden uzak, ülkenin ortasına yakın) ve bir şehir seçer.
func _sehirleri_sec() -> void:
	_arazi = []
	_arazi.resize(_noktalar.size())
	_arazi.fill("")
	_baskent = PackedInt32Array()
	_baskent.resize(ULKELER.size())
	_ikinci_sehir = PackedInt32Array()
	_ikinci_sehir.resize(ULKELER.size())

	var cepheye_mesafe: Array[PackedInt32Array] = [_mesafeler(_guney), _mesafeler(_kuzey)]
	for u: int in ULKELER.size():
		var hucreler: Array[int] = _ulke_hucreleri(u)
		var orta: Vector2 = Vector2.ZERO
		for h: int in hucreler:
			orta += _noktalar[h]
		orta /= float(hucreler.size())

		@warning_ignore("integer_division")
		var mesafe: PackedInt32Array = cepheye_mesafe[u / 3]
		var en_iyi: int = hucreler[0]
		var en_iyi_puan: float = -INF
		for h: int in hucreler:
			var puan: float = float(mini(mesafe[h], 3)) * 10000.0 - _noktalar[h].distance_to(orta)
			if puan > en_iyi_puan:
				en_iyi_puan = puan
				en_iyi = h
		_baskent[u] = en_iyi

		var adaylar: Array[int] = []
		for h: int in hucreler:
			if h != en_iyi and not _komsular[en_iyi].has(h):
				adaylar.append(h)
		if adaylar.is_empty():
			for h: int in hucreler:
				if h != en_iyi:
					adaylar.append(h)
		_ikinci_sehir[u] = adaylar[_rng.randi_range(0, adaylar.size() - 1)]

		_arazi[_baskent[u]] = "sehir"
		_arazi[_ikinci_sehir[u]] = "sehir"


## Şehir olmayan bölgelere gürültü haritasıyla dağ, orman ve ova dağıtır.
## Gürültü sayesinde dağlar ve ormanlar dağınık değil, kümeler hâlinde çıkar.
func _araziyi_dagit() -> void:
	var yukselti: FastNoiseLite = FastNoiseLite.new()
	yukselti.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	yukselti.seed = _rng.randi_range(0, 1000000)
	yukselti.frequency = 1.0 / 800.0
	var nem: FastNoiseLite = FastNoiseLite.new()
	nem.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	nem.seed = _rng.randi_range(0, 1000000)
	nem.frequency = 1.0 / 600.0

	var kalan: Array[int] = []
	for i: int in _ulke_no.size():
		if _ulke_no[i] >= 0 and _arazi[i] == "":
			kalan.append(i)

	kalan.sort_custom(func(a: int, b: int) -> bool:
		return yukselti.get_noise_2dv(_noktalar[a]) > yukselti.get_noise_2dv(_noktalar[b]))
	for s: int in mini(DAG_SAYISI, kalan.size()):
		_arazi[kalan[s]] = "dag"
	kalan = kalan.slice(mini(DAG_SAYISI, kalan.size()))

	kalan.sort_custom(func(a: int, b: int) -> bool:
		return nem.get_noise_2dv(_noktalar[a]) > nem.get_noise_2dv(_noktalar[b]))
	for s: int in kalan.size():
		_arazi[kalan[s]] = "orman" if s < ORMAN_SAYISI else "ova"


func _kaynaklari_dagit() -> void:
	var adet: int = _noktalar.size()
	_zafer = _sifir_dizisi(adet)
	_insan = _sifir_dizisi(adet)
	_celik = _sifir_dizisi(adet)
	_petrol = _sifir_dizisi(adet)
	_fabrika = _sifir_dizisi(adet)

	for u: int in ULKELER.size():
		var hucreler: Array[int] = _ulke_hucreleri(u)
		var sehir_disi: Array[int] = []
		for h: int in hucreler:
			if _arazi[h] != "sehir":
				sehir_disi.append(h)
		_karistir(sehir_disi)

		# İnsan gücü: şehirler kalabalık, dağlar tenhadır.
		for h: int in hucreler:
			match _arazi[h]:
				"sehir":
					_insan[h] = 40 if h == _baskent[u] else 32
				"ova":
					_insan[h] = 16 + 4 * _rng.randi_range(0, 2)
				"orman":
					_insan[h] = 8 + 4 * _rng.randi_range(0, 2)
				_:
					_insan[h] = 4 + 4 * _rng.randi_range(0, 1)

		# Çelik: önce dağlarda, dağ yoksa ormanlarda.
		var celik_adaylari: Array[int] = _oncelikle_sirala(sehir_disi, ["dag", "orman", "ova"])
		for s: int in 3:
			_celik[celik_adaylari[s]] = _rng.randi_range(2, 3)

		# Petrol: çelik çıkmayan bölgelerde, önce ovalarda.
		var celiksiz: Array[int] = []
		for h: int in sehir_disi:
			if _celik[h] == 0:
				celiksiz.append(h)
		var petrol_adaylari: Array[int] = _oncelikle_sirala(celiksiz, ["ova", "orman", "dag"])
		_petrol[petrol_adaylari[0]] = _rng.randi_range(1, 2)
		_petrol[petrol_adaylari[1]] = 1

		# Fabrika: başkentte 3, şehirde 2, ayrıca 1-3 bölgede birer tane.
		_fabrika[_baskent[u]] = 3
		_fabrika[_ikinci_sehir[u]] = 2
		var fabrika_adaylari: Array[int] = _oncelikle_sirala(sehir_disi, ["ova", "orman", "dag"])
		for s: int in _rng.randi_range(1, 3):
			_fabrika[fabrika_adaylari[s]] = 1

		# Zafer puanı: başkent 5, şehir 3, fabrikası ya da kaynağı olan bölge 1.
		for h: int in hucreler:
			if h == _baskent[u]:
				_zafer[h] = 5
			elif _arazi[h] == "sehir":
				_zafer[h] = 3
			elif _fabrika[h] > 0 or _celik[h] > 0 or _petrol[h] > 0:
				_zafer[h] = 1


static func _sifir_dizisi(adet: int) -> PackedInt32Array:
	var dizi: PackedInt32Array = PackedInt32Array()
	dizi.resize(adet)
	dizi.fill(0)
	return dizi


## Listeyi tohumlu rastgele sayı üreteciyle karıştırır (sonuç hep aynı çıksın diye).
func _karistir(liste: Array) -> void:
	for i: int in range(liste.size() - 1, 0, -1):
		var j: int = _rng.randi_range(0, i)
		var gecici: Variant = liste[i]
		liste[i] = liste[j]
		liste[j] = gecici


## Listedeki hücreleri verilen arazi sırasına göre dizer.
func _oncelikle_sirala(liste: Array[int], sira: Array[String]) -> Array[int]:
	var sonuc: Array[int] = []
	for tur: String in sira:
		for h: int in liste:
			if _arazi[h] == tur:
				sonuc.append(h)
	return sonuc


# --- Çokgenler ve kayıtlar -------------------------------------------------

## İki köşe arasındaki düz kenarı, ortasından rastgele kaydırarak girintili çıkıntılı yapar.
## Sonuç a'dan b'ye sıralıdır ve iki ucu da içerir.
func _kenari_oyna(a: Vector2, b: Vector2, oynama: float) -> PackedVector2Array:
	var noktalar: PackedVector2Array = PackedVector2Array([a, b])
	var parca: float = a.distance_to(b)
	while parca > PARCA_UZUNLUGU:
		var yeni: PackedVector2Array = PackedVector2Array()
		for k: int in noktalar.size() - 1:
			var p: Vector2 = noktalar[k]
			var q: Vector2 = noktalar[k + 1]
			var orta: Vector2 = (p + q) * 0.5 + (q - p).orthogonal() * _rng.randf_range(-oynama, oynama)
			yeni.append(p)
			yeni.append(orta)
		yeni.append(noktalar[noktalar.size() - 1])
		noktalar = yeni
		parca *= 0.5
	return noktalar


func _kayitlari_kur() -> String:
	# Karaya değen her kenarı bir kez oynat; iki komşu aynı noktaları paylaşsın.
	var kenar_noktalari: Dictionary[Vector2i, PackedVector2Array] = {}
	for anahtar: Vector2i in _kenar_hucreleri:
		var kara_sayisi: int = 0
		for h: int in _kenar_hucreleri[anahtar]:
			if _ulke_no[h] >= 0:
				kara_sayisi += 1
		if kara_sayisi == 0:
			continue
		var oynama: float = KIYI_OYNAMA if kara_sayisi == 1 else SINIR_OYNAMA
		kenar_noktalari[anahtar] = _kenari_oyna(_koseler[anahtar.x], _koseler[anahtar.y], oynama)

	# Bölge numaraları: ülke sırasıyla, her ülkede batıdan doğuya.
	var sirali: Array[int] = []
	var hucre_id: Dictionary[int, String] = {}
	for u: int in ULKELER.size():
		var hucreler: Array[int] = _ulke_hucreleri(u)
		hucreler.sort_custom(func(a: int, b: int) -> bool: return _noktalar[a].x < _noktalar[b].x)
		for h: int in hucreler:
			sirali.append(h)
			hucre_id[h] = "b%02d" % sirali.size()

	var adlar: Array[String] = []
	adlar.assign(ADLAR)
	_karistir(adlar)

	_bolge_kayitlari = []
	for s: int in sirali.size():
		var h: int = sirali[s]
		var halka: PackedInt32Array = _hucre_koseleri[h]
		var cokgen: PackedVector2Array = PackedVector2Array()
		for k: int in halka.size():
			var a: int = halka[k]
			var b: int = halka[(k + 1) % halka.size()]
			var noktalar: PackedVector2Array = kenar_noktalari[_kenar_anahtari(a, b)]
			var adet: int = noktalar.size()
			for n: int in adet - 1:
				var p: Vector2 = (noktalar[n] if a < b else noktalar[adet - 1 - n]).round()
				if cokgen.is_empty() or cokgen[cokgen.size() - 1] != p:
					cokgen.append(p)
		if cokgen.size() > 1 and cokgen[0] == cokgen[cokgen.size() - 1]:
			cokgen.remove_at(cokgen.size() - 1)

		if cokgen.size() < 3:
			return "bir bölge çokgeni çok küçük"
		if _kendini_kesiyor_mu(cokgen):
			return "bir bölge çokgeni kendini kesiyor"
		if Geometry2D.triangulate_polygon(cokgen).is_empty():
			return "bir bölge çokgeni üçgenlenemiyor"
		var merkez: Vector2 = _agirlik_merkezi(cokgen).round()
		if not Geometry2D.is_point_in_polygon(merkez, cokgen):
			return "bir bölgenin merkezi dışarıda kalıyor"

		var komsu_idleri: Array[String] = []
		for k: int in _komsular[h]:
			if _ulke_no[k] >= 0:
				komsu_idleri.append(hucre_id[k])
		komsu_idleri.sort()

		var koseler: Array[Array] = []
		for p: Vector2 in cokgen:
			koseler.append([int(p.x), int(p.y)])

		_bolge_kayitlari.append({
			"id": hucre_id[h],
			"ad": adlar[s],
			"sahip": ULKELER[_ulke_no[h]]["id"],
			"arazi": _arazi[h],
			"komsular": komsu_idleri,
			"zafer_puani": _zafer[h],
			"insan_gucu": _insan[h],
			"celik": _celik[h],
			"petrol": _petrol[h],
			"fabrika": _fabrika[h],
			"merkez": [int(merkez.x), int(merkez.y)],
			"kose_noktalari": koseler,
		})

	_ulke_kayitlari = []
	for u: int in ULKELER.size():
		var kayit: Dictionary = ULKELER[u].duplicate()
		kayit["baskent"] = hucre_id[_baskent[u]]
		_ulke_kayitlari.append(kayit)
	return ""


static func _kendini_kesiyor_mu(cokgen: PackedVector2Array) -> bool:
	var adet: int = cokgen.size()
	for i: int in adet:
		var a: Vector2 = cokgen[i]
		var b: Vector2 = cokgen[(i + 1) % adet]
		for j: int in range(i + 2, adet):
			if i == 0 and j == adet - 1:
				continue
			var kesisim: Variant = Geometry2D.segment_intersects_segment(a, b, cokgen[j], cokgen[(j + 1) % adet])
			if kesisim != null:
				return true
	return false


# --- Dosyaya yazma ---------------------------------------------------------

func _yaz() -> bool:
	# Köşe listeleri tek satırda kalsın diye bölgeler elle biçimlendirilir.
	var bolge_metinleri: PackedStringArray = PackedStringArray()
	for kayit: Dictionary in _bolge_kayitlari:
		var satirlar: PackedStringArray = PackedStringArray()
		for anahtar: String in kayit:
			satirlar.append("\t\t\t%s: %s" % [JSON.stringify(anahtar), JSON.stringify(kayit[anahtar])])
		bolge_metinleri.append("\t\t{\n%s\n\t\t}" % ",\n".join(satirlar))

	var metin: String = "{\n"
	metin += "\t\"tohum\": %d,\n" % TOHUM
	metin += "\t\"dunya\": {\"genislik\": %d, \"yukseklik\": %d},\n" % [int(DUNYA_BOYUTU.x), int(DUNYA_BOYUTU.y)]
	metin += "\t\"bolgeler\": [\n%s\n\t]\n}\n" % ",\n".join(bolge_metinleri)
	if not _dosyaya_yaz(BOLGE_DOSYASI, metin):
		return false

	var ulke_verisi: Dictionary = {"bloklar": BLOKLAR, "ulkeler": _ulke_kayitlari}
	return _dosyaya_yaz(ULKE_DOSYASI, JSON.stringify(ulke_verisi, "\t", false) + "\n")


static func _dosyaya_yaz(yol: String, metin: String) -> bool:
	var dosya: FileAccess = FileAccess.open(yol, FileAccess.WRITE)
	if dosya == null:
		push_error("Harita üretici: %s yazılamadı (hata %d)." % [yol, FileAccess.get_open_error()])
		return false
	dosya.store_string(metin)
	dosya.close()
	print("  yazıldı: %s" % yol)
	return true


func _ozet_yaz() -> void:
	for u: int in ULKELER.size():
		var toplam: Dictionary[String, int] = {"zafer_puani": 0, "insan_gucu": 0, "celik": 0, "petrol": 0, "fabrika": 0}
		var arazi_sayisi: Dictionary[String, int] = {}
		for kayit: Dictionary in _bolge_kayitlari:
			if kayit["sahip"] != ULKELER[u]["id"]:
				continue
			for anahtar: String in toplam:
				toplam[anahtar] += int(kayit[anahtar])
			var arazi: String = kayit["arazi"]
			arazi_sayisi[arazi] = int(arazi_sayisi.get(arazi, 0)) + 1
		print("  %-9s başkent %s | %s | %s" % [ULKELER[u]["ad"], _ulke_kayitlari[u]["baskent"], toplam, arazi_sayisi])
