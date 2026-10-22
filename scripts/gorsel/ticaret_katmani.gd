class_name TicaretKatmani
extends Node2D
## Haritadaki ticaret katmanı (TASARIM 9c, STIL.md → Harita). Oyun durumunu yalnızca okur.
##
## - Ticaret modunda: bütün rotalar (kalınlık değerle artar; oyuncunun rotaları altın ve
##   belirgin, ötekiler soluk), seviye rozetli limanlar, kontrol edenin bayrağıyla geçitler,
##   petrol ve maden üreten bölgelerin simgeleri, rotalarda kayan küçük gemi (deniz) ve kamyon
##   (kara) simgeleri. Araçlar oyun zamanıyla ilerler (oyun durunca durur), en çok AZAMI_ARAC
##   tanedir ve üç toplu çizimle (MultiMesh) çizilir; "Grafik: Düşük" ayarında kapalıdır.
## - Siyasi modda: yalnızca oyuncunun rotaları, ince ve soluk.
## - Öbür modlarda bir şey çizmez.

const AZAMI_ARAC: int = 120
## Araçların hızı (harita birimi / oyun saati) ve bir rotada araçlar arası yaklaşık aralık.
const ARAC_HIZI: float = 4.0
const ARAC_ARALIGI: float = 450.0
const ROTA_BASINA_AZAMI_ARAC: int = 3
## Araç simgesinin ekrandaki boyu ve altındaki koyu yuvarlak zeminin boyu (piksel).
const ARAC_BOYUTU: float = 22.0
const ARAC_ZEMINI_BOYUTU: float = 34.0
const ARAC_ZEMINI_RENGI: Color = Color(0.055, 0.078, 0.114, 0.85)
## Rota çizgisi kalınlığı (piksel): en düşük değerli rotadan en yükseğe.
const ROTA_EN_INCE: float = 2.0
const ROTA_EN_KALIN: float = 9.0
const OYUNCU_ROTA_RENGI: Color = Color("#E6AE48")
const DIGER_ROTA_RENGI: Color = Color(0.93, 0.95, 0.98, 0.3)
const DIGER_ARAC_RENGI: Color = Color(0.93, 0.95, 0.98, 0.7)
const ROTA_ALT_RENGI: Color = Color(0.0, 0.0, 0.0, 0.45)
## Siyasi modda oyuncunun rotaları ince ve soluk.
const SIYASI_ROTA_RENGI: Color = Color(0.902, 0.682, 0.282, 0.45)
const SIYASI_ROTA_KALINLIGI: float = 2.0
## Haritadaki işaretler (liman, geçit, kaynak): koyu yuvarlak zemin üstünde simge (piksel).
const ISARET_BOYUTU: float = 26.0
const ROZET_RENGI: Color = Color(0.055, 0.078, 0.114, 0.92)
const LIMAN_RENGI: Color = Color("#8EC5EA")
const GECIT_RENGI: Color = Color("#FFE08A")
const KAPALI_GECIT_RENGI: Color = Color("#E25B5B")
const PETROL_RENGI: Color = Color("#E0A85A")
const MADEN_RENGI: Color = Color("#C9D1DE")
const BAYRAK_BOYUTU: Vector2 = Vector2(30.0, 22.0)
const SEVIYE_YAZI_BOYUTU: int = 18
## Liman seviyesi bu yakınlıktan sonra görünür: 3. seviye her zaman, 2. seviye orta, 1. yakında.
const LIMAN_GORUNME_YAKINLIGI: Array[float] = [0.0, 2.4, 1.5, 0.0]
## Kaynak simgeleri: en büyük üreticinin bu oranından büyükler her zaman, ötekiler yakınlaşınca.
const KAYNAK_HER_ZAMAN_ORANI: float = 0.25
const KAYNAK_GORUNME_YAKINLIGI: float = 2.4
## Geçide dokunma yarıçapı (piksel).
const GECIT_DOKUNMA_YARICAPI: float = 40.0

var _dunya: Dunya = null
var _oyun: Oyun = null
var _mod: HaritaPaleti.Mod = HaritaPaleti.Mod.SIYASI
var _oyuncu: String = ""
var _yakinlik: float = 1.0
var _gorunen: Rect2 = Rect2()
var _yazi_tipi: Font = null
## Çizilecek rotalar: {"parcalar": Array[PackedVector2Array] (harita kenarında bölünmüş),
## "noktalar": PackedVector2Array, "kumulatif": PackedFloat32Array (her noktaya kadar uzunluk),
## "deniz": Array (her parça denizde mi), "uzunluk": float, "deger": float, "oyuncu": bool}.
var _rotalar: Array[Dictionary] = []
var _en_buyuk_deger: float = 1.0
## Araçlar: {"rota": _rotalar sırası, "faz": başlangıç uzaklığı (harita birimi)}.
var _araclar: Array[Dictionary] = []
var _zemin_katmani: MultiMeshInstance2D = null
var _gemi_katmani: MultiMeshInstance2D = null
var _kamyon_katmani: MultiMeshInstance2D = null
var _son_arac_zamani: float = -1.0
var _son_arac_yakinligi: float = -1.0


func kur(dunya: Dunya, oyun: Oyun) -> void:
	_dunya = dunya
	_oyun = oyun
	_yazi_tipi = ArayuzTemasi.arayuz_fontu(600)
	# Simgeler asıl boyutlarından küçük çizilir; mipmap'le pürüzsüz küçülürler.
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_zemin_katmani = _arac_katmani(_yuvarlak_doku())
	_gemi_katmani = _arac_katmani(Simgeler.doku("gemi"))
	_kamyon_katmani = _arac_katmani(Simgeler.doku("kamyon"))
	yenile()


## Harita modunu değiştirir.
func modu_ayarla(mod: HaritaPaleti.Mod) -> void:
	_mod = mod
	_araclari_guncelle(true)
	queue_redraw()


func oyuncuyu_ayarla(ulke_id: String) -> void:
	_oyuncu = ulke_id
	yenile()


## Kamera değişti: görünen alan (harita birimi) ve yakınlık.
func gorunumu_ayarla(gorunen: Rect2, yakinlik: float) -> void:
	_gorunen = gorunen
	_yakinlik = yakinlik
	if _mod == HaritaPaleti.Mod.TICARET or _mod == HaritaPaleti.Mod.SIYASI:
		queue_redraw()
	_araclari_guncelle(false)


## Anlaşmalar, rotalar, limanlar ya da geçit sahipleri değişince çağrılır.
func yenile() -> void:
	_rotalari_kur()
	_araclari_dagit()
	_araclari_guncelle(true)
	queue_redraw()


## "Grafik: Düşük" ayarı değişince araçlar açılır ya da kapanır.
func grafigi_uygula() -> void:
	_araclari_guncelle(true)


## Verilen harita noktasına (ekranda GECIT_DOKUNMA_YARICAPI içinde) en yakın geçidin id'si; yoksa boş.
func gecit_bul(nokta: Vector2) -> String:
	if _oyun == null:
		return ""
	var sinir: float = GECIT_DOKUNMA_YARICAPI / _yakinlik
	var secilen: String = ""
	for gecit: Dictionary in _oyun.ticaret.gecitler:
		var uzaklik: float = (gecit["merkez"] as Vector2).distance_to(nokta)
		if uzaklik <= sinir:
			sinir = uzaklik
			secilen = gecit["id"]
	return secilen


func _process(_delta: float) -> void:
	if _araclar_acik() and not Zaman.durdu:
		_araclari_guncelle(false)


# --- Rotalar ---------------------------------------------------------------------------

func _rotalari_kur() -> void:
	_rotalar = []
	_en_buyuk_deger = 0.001
	if _oyun == null:
		return
	var genislik: float = _dunya.boyut.x
	for a: Dictionary in _oyun.ticaret.anlasmalar:
		var rota: Dictionary = a["rota"]
		var yol: Array = rota.get("yol", [])
		if yol.size() < 2:
			continue
		var noktalar: PackedVector2Array = PackedVector2Array([yol[0]])
		var kumulatif: PackedFloat32Array = PackedFloat32Array([0.0])
		for i: int in range(1, yol.size()):
			var onceki: Vector2 = noktalar[noktalar.size() - 1]
			var nokta: Vector2 = yol[i]
			# Haritanın doğu-batı kenarından dolanan parça: nokta öbür yana taşınır, çizgi kesilmez.
			while nokta.x - onceki.x > genislik * 0.5:
				nokta.x -= genislik
			while onceki.x - nokta.x > genislik * 0.5:
				nokta.x += genislik
			kumulatif.append(kumulatif[kumulatif.size() - 1] + onceki.distance_to(nokta))
			noktalar.append(nokta)
		# Kenardan taşan rota, haritanın öbür kenarında da (kaydırılmış kopyasıyla) çizilir.
		var parcalar: Array[PackedVector2Array] = [noktalar]
		var kutu: Rect2 = _kutu(noktalar)
		if kutu.position.x < 0.0:
			parcalar.append(_kaydir(noktalar, genislik))
		if kutu.end.x > genislik:
			parcalar.append(_kaydir(noktalar, -genislik))
		var deger: float = float(a["deger"])
		_en_buyuk_deger = maxf(_en_buyuk_deger, deger)
		_rotalar.append({"parcalar": parcalar, "noktalar": noktalar, "kumulatif": kumulatif,
			"deniz": rota.get("deniz", []), "uzunluk": kumulatif[kumulatif.size() - 1], "deger": deger,
			"oyuncu": _oyuncu != "" and (a["a"] == _oyuncu or a["b"] == _oyuncu)})


func _draw() -> void:
	if _oyun == null:
		return
	var olcek: float = 1.0 / _yakinlik
	if _mod == HaritaPaleti.Mod.SIYASI:
		for rota: Dictionary in _rotalar:
			if rota["oyuncu"]:
				_rota_ciz(rota, SIYASI_ROTA_RENGI, SIYASI_ROTA_KALINLIGI * olcek, false)
		return
	if _mod != HaritaPaleti.Mod.TICARET:
		return
	# Önce soluk rotalar, sonra oyuncununkiler (üstte).
	for oyuncu_mu: bool in [false, true]:
		for rota: Dictionary in _rotalar:
			if rota["oyuncu"] != oyuncu_mu:
				continue
			var oran: float = sqrt(clampf(float(rota["deger"]) / _en_buyuk_deger, 0.0, 1.0))
			var kalinlik: float = lerpf(ROTA_EN_INCE, ROTA_EN_KALIN, oran) * olcek
			_rota_ciz(rota, OYUNCU_ROTA_RENGI if oyuncu_mu else DIGER_ROTA_RENGI, kalinlik, oyuncu_mu)
	_kaynaklari_ciz(olcek)
	_limanlari_ciz(olcek)
	_gecitleri_ciz(olcek)


func _rota_ciz(rota: Dictionary, renk: Color, kalinlik: float, alt_cizgili: bool) -> void:
	for parca: PackedVector2Array in rota["parcalar"]:
		if not _gorunen.intersects(_kutu(parca)):
			continue
		if alt_cizgili:
			draw_polyline(parca, ROTA_ALT_RENGI, kalinlik + 3.0 / _yakinlik)
		draw_polyline(parca, renk, kalinlik)


static func _kaydir(noktalar: PackedVector2Array, x: float) -> PackedVector2Array:
	var sonuc: PackedVector2Array = PackedVector2Array()
	for nokta: Vector2 in noktalar:
		sonuc.append(Vector2(nokta.x + x, nokta.y))
	return sonuc


static func _kutu(noktalar: PackedVector2Array) -> Rect2:
	var kutu: Rect2 = Rect2(noktalar[0], Vector2.ZERO)
	for nokta: Vector2 in noktalar:
		kutu = kutu.expand(nokta)
	return kutu


# --- İşaretler -------------------------------------------------------------------------

func _limanlari_ciz(olcek: float) -> void:
	for bolge: Bolge in _dunya.bolge_listesi:
		if bolge.liman <= 0 or _yakinlik < LIMAN_GORUNME_YAKINLIGI[mini(bolge.liman, 3)]:
			continue
		var merkez: Vector2 = bolge.etiket + Vector2(ISARET_BOYUTU * 0.9, -ISARET_BOYUTU * 0.9) * olcek
		if not _gorunen.has_point(merkez):
			continue
		_isaret_ciz("liman", merkez, LIMAN_RENGI, olcek)
		_yazi_ciz(str(bolge.liman), merkez + Vector2(ISARET_BOYUTU * 0.42, ISARET_BOYUTU * 0.62) * olcek, olcek)


func _gecitleri_ciz(olcek: float) -> void:
	for gecit: Dictionary in _oyun.ticaret.gecitler:
		var merkez: Vector2 = gecit["merkez"]
		if not _gorunen.has_point(merkez):
			continue
		var sahipler: Array[String] = _oyun.ticaret.gecit_sahipleri(_oyun, gecit["id"])
		var kapali: bool = _oyun.ticaret.kapali_gecitler.has(gecit["id"])
		if _oyuncu != "":
			for sahip: String in sahipler:
				if sahip != _oyuncu and _oyun.ticaret.ambargoda_mi(_oyun, sahip, _oyuncu):
					kapali = true
		# Geçit işareti öbür işaretlerden büyüktür ve çevresinde ince bir halka taşır (kapalıysa kırmızı).
		var r: float = (ISARET_BOYUTU * 0.625 + 2.0) * olcek
		draw_circle(merkez, r + 3.0 * olcek, KAPALI_GECIT_RENGI if kapali else GECIT_RENGI)
		_isaret_ciz("gecit", merkez, GECIT_RENGI, olcek, 1.25)
		var konum: Vector2 = merkez + Vector2(r + 6.0 * olcek, -BAYRAK_BOYUTU.y * 0.5 * olcek)
		for sahip: String in sahipler:
			var ulke: Ulke = _dunya.ulkeler.get(sahip)
			if ulke == null:
				continue
			var alan: Rect2 = Rect2(konum, BAYRAK_BOYUTU * olcek)
			draw_rect(alan.grow(1.5 * olcek), Color(0.0, 0.0, 0.0, 0.8))
			draw_texture_rect(Bayraklar.doku(ulke), alan, false)
			konum.x += (BAYRAK_BOYUTU.x + 4.0) * olcek


func _kaynaklari_ciz(olcek: float) -> void:
	var piyasa: Piyasa = _oyun.ekonomi.piyasa
	for kaynak: String in Piyasa.KAYNAKLAR:
		var uretimler: Dictionary = piyasa.bolge_uretimi.get(kaynak, {})
		var en_cok: float = 0.001
		for bolge_id: String in uretimler:
			en_cok = maxf(en_cok, float(uretimler[bolge_id]))
		var kayma: Vector2 = Vector2(-ISARET_BOYUTU * 0.9, -ISARET_BOYUTU * 0.9) if kaynak == "petrol" \
				else Vector2(-ISARET_BOYUTU * 0.9, ISARET_BOYUTU * 0.9)
		for bolge_id: String in uretimler:
			if _yakinlik < KAYNAK_GORUNME_YAKINLIGI and float(uretimler[bolge_id]) < en_cok * KAYNAK_HER_ZAMAN_ORANI:
				continue
			var bolge: Bolge = _dunya.bolgeler.get(bolge_id)
			if bolge == null:
				continue
			var merkez: Vector2 = bolge.etiket + kayma * olcek
			if _gorunen.has_point(merkez):
				_isaret_ciz(kaynak, merkez, PETROL_RENGI if kaynak == "petrol" else MADEN_RENGI, olcek, 0.85)


## Koyu yuvarlak zemin üstünde simge (STIL.md: harita simgeleri).
func _isaret_ciz(ad: String, merkez: Vector2, renk: Color, olcek: float, buyukluk: float = 1.0) -> void:
	var r: float = ISARET_BOYUTU * 0.5 * buyukluk * olcek
	draw_circle(merkez, r + 2.0 * olcek, ROZET_RENGI)
	var boyut: float = ISARET_BOYUTU * 0.78 * buyukluk * olcek
	draw_texture_rect(Simgeler.doku(ad), Rect2(merkez - Vector2.ONE * boyut * 0.5, Vector2.ONE * boyut), false, renk)


func _yazi_ciz(metin: String, konum: Vector2, olcek: float) -> void:
	draw_set_transform(konum, 0.0, Vector2.ONE * olcek)
	draw_string_outline(_yazi_tipi, Vector2.ZERO, metin, HORIZONTAL_ALIGNMENT_LEFT, -1, SEVIYE_YAZI_BOYUTU, 4,
			Color(0.0, 0.0, 0.0, 0.85))
	draw_string(_yazi_tipi, Vector2.ZERO, metin, HORIZONTAL_ALIGNMENT_LEFT, -1, SEVIYE_YAZI_BOYUTU, Color.WHITE)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# --- Araçlar ---------------------------------------------------------------------------

func _araclar_acik() -> bool:
	return _mod == HaritaPaleti.Mod.TICARET and not Ayarlar.grafik_dusuk and not _araclar.is_empty()


## Araçları rotalara dağıtır: önce oyuncunun rotaları, sonra değerliden ucuza; rota başına
## uzunluğuna göre 1-3 araç, toplam en çok AZAMI_ARAC.
func _araclari_dagit() -> void:
	_araclar = []
	var siralar: Array[int] = []
	for i: int in _rotalar.size():
		siralar.append(i)
	siralar.sort_custom(func(x: int, y: int) -> bool:
		if _rotalar[x]["oyuncu"] != _rotalar[y]["oyuncu"]:
			return _rotalar[x]["oyuncu"]
		return float(_rotalar[x]["deger"]) > float(_rotalar[y]["deger"]))
	for sira: int in siralar:
		var uzunluk: float = _rotalar[sira]["uzunluk"]
		var sayi: int = clampi(ceili(uzunluk / ARAC_ARALIGI), 1, ROTA_BASINA_AZAMI_ARAC)
		# Aynı rotanın araçları rotanın gidiş-dönüşüne eşit aralıkla yayılır.
		var baslangic: float = float(absi(hash(sira)) % 1000) / 1000.0
		for k: int in sayi:
			if _araclar.size() >= AZAMI_ARAC:
				return
			_araclar.append({"rota": sira, "faz": fposmod(baslangic + float(k) / sayi, 1.0) * 2.0 * uzunluk})


## Araçların konumlarını ve boylarını toplu çizimlere yazar. `zorla` değilse yalnızca oyun
## zamanı ya da yakınlık değiştiyse yazılır.
func _araclari_guncelle(zorla: bool) -> void:
	if _gemi_katmani == null:
		return
	var acik: bool = _araclar_acik()
	_zemin_katmani.visible = acik
	_gemi_katmani.visible = acik
	_kamyon_katmani.visible = acik
	if not acik:
		return
	var zaman: float = float(Zaman.toplam_saat) + Zaman.saat_kesri()
	if not zorla and zaman == _son_arac_zamani and _yakinlik == _son_arac_yakinligi:
		return
	_son_arac_zamani = zaman
	_son_arac_yakinligi = _yakinlik
	var olcek: float = 1.0 / _yakinlik
	var zemin: MultiMesh = _zemin_katmani.multimesh
	var gemiler: MultiMesh = _gemi_katmani.multimesh
	var kamyonlar: MultiMesh = _kamyon_katmani.multimesh
	var gemi_sayisi: int = 0
	var kamyon_sayisi: int = 0
	for i: int in _araclar.size():
		var arac: Dictionary = _araclar[i]
		var rota: Dictionary = _rotalar[arac["rota"]]
		var uzunluk: float = rota["uzunluk"]
		if uzunluk <= 0.0:
			continue
		# Gidiş-dönüş: rotanın sonuna varan araç geri döner.
		var yol: float = fposmod(zaman * ARAC_HIZI + float(arac["faz"]), 2.0 * uzunluk)
		if yol > uzunluk:
			yol = 2.0 * uzunluk - yol
		var kumulatif: PackedFloat32Array = rota["kumulatif"]
		var parca: int = clampi(kumulatif.bsearch(yol) - 1, 0, kumulatif.size() - 2)
		var noktalar: PackedVector2Array = rota["noktalar"]
		var boy: float = maxf(kumulatif[parca + 1] - kumulatif[parca], 0.0001)
		var konum: Vector2 = noktalar[parca].lerp(noktalar[parca + 1], clampf((yol - kumulatif[parca]) / boy, 0.0, 1.0))
		konum.x = fposmod(konum.x, _dunya.boyut.x)
		var deniz: Array = rota["deniz"]
		var denizde: bool = parca >= deniz.size() or bool(deniz[parca])
		var renk: Color = OYUNCU_ROTA_RENGI if rota["oyuncu"] else DIGER_ARAC_RENGI
		zemin.set_instance_transform_2d(i, Transform2D(0.0, Vector2.ONE * ARAC_ZEMINI_BOYUTU * olcek, 0.0, konum))
		zemin.set_instance_color(i, ARAC_ZEMINI_RENGI)
		var donusum: Transform2D = Transform2D(0.0, Vector2.ONE * ARAC_BOYUTU * olcek, 0.0, konum)
		if denizde:
			gemiler.set_instance_transform_2d(gemi_sayisi, donusum)
			gemiler.set_instance_color(gemi_sayisi, renk)
			gemi_sayisi += 1
		else:
			kamyonlar.set_instance_transform_2d(kamyon_sayisi, donusum)
			kamyonlar.set_instance_color(kamyon_sayisi, renk)
			kamyon_sayisi += 1
	zemin.visible_instance_count = _araclar.size()
	gemiler.visible_instance_count = gemi_sayisi
	kamyonlar.visible_instance_count = kamyon_sayisi


## Birim kare (−0,5…0,5) üstünde dokulu, örnek başına renk ve dönüşüm alan toplu çizim.
func _arac_katmani(doku: Texture2D) -> MultiMeshInstance2D:
	var kare: ArrayMesh = ArrayMesh.new()
	var diziler: Array = []
	diziler.resize(Mesh.ARRAY_MAX)
	diziler[Mesh.ARRAY_VERTEX] = PackedVector2Array([Vector2(-0.5, -0.5), Vector2(0.5, -0.5), Vector2(0.5, 0.5), Vector2(-0.5, 0.5)])
	diziler[Mesh.ARRAY_TEX_UV] = PackedVector2Array([Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)])
	diziler[Mesh.ARRAY_INDEX] = PackedInt32Array([0, 1, 2, 0, 2, 3])
	kare.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, diziler)
	var coklu: MultiMesh = MultiMesh.new()
	coklu.transform_format = MultiMesh.TRANSFORM_2D
	coklu.use_colors = true
	coklu.mesh = kare
	coklu.instance_count = AZAMI_ARAC
	coklu.visible_instance_count = 0
	var katman: MultiMeshInstance2D = MultiMeshInstance2D.new()
	katman.multimesh = coklu
	katman.texture = doku
	katman.visible = false
	add_child(katman)
	return katman


## Araçların altındaki yumuşak kenarlı koyu daire.
static func _yuvarlak_doku() -> Texture2D:
	var gecis: Gradient = Gradient.new()
	gecis.offsets = PackedFloat32Array([0.0, 0.8, 1.0])
	gecis.colors = PackedColorArray([Color.WHITE, Color.WHITE, Color(1.0, 1.0, 1.0, 0.0)])
	var doku: GradientTexture2D = GradientTexture2D.new()
	doku.gradient = gecis
	doku.fill = GradientTexture2D.FILL_RADIAL
	doku.fill_from = Vector2(0.5, 0.5)
	doku.fill_to = Vector2(1.0, 0.5)
	doku.width = 64
	doku.height = 64
	return doku
