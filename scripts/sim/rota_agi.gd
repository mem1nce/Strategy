class_name RotaAgi
extends AStar2D
## Ticaret rotalarının ağı (bkz. TASARIM.md 9b. Ticaret yolları ve geçitler; veri
## data/trade.json, tools/ticaret_uret.py).
##
## Düğümler: her bölge için bir kara düğümü; her kıyı bölgesinin değdiği her deniz havzası için
## bir deniz düğümü; her geçit için bir geçit düğümü. Kenarlar: kara komşulukları (kara
## düğümleri), bölgenin kendi kıyısına iniş (kara ↔ deniz, maliyetsiz), deniz kenarları (aynı
## havzada ya da açık okyanusta) ve geçitten geçen kenarlar (deniz → geçit → deniz).
## Maliyet, AStar2D'nin varsayılanıdır: iki düğüm arası uzaklık × varılan düğümün ağırlığı
## (kara `kara_carpani` kat pahalıdır: deniz tercih edilir).
##
## Bir rota sorgusunda yalnızca izin verilen bölgelerin kara düğümleri açıktır (taraflar ve
## limanı olmayan tarafın barıştaki kara komşuları) ve kapalı geçitlerin düğümleri kapatılır;
## sonra ilk kapalı hâle döndürülür.

var _kara: Dictionary[String, int] = {}
var _deniz: Dictionary[String, int] = {}
var _gecit_dugumu: Dictionary[String, int] = {}
## Düğüm -> {"bolge": id, "tur": "kara"|"deniz"|"gecit", "gecit": id}
var _dugum_bilgisi: Dictionary[int, Dictionary] = {}
var _sonraki: int = 0


static func kur(dunya: Dunya, veri: Dictionary, kara_carpani: float, buz_carpani: float = 8.0) -> RotaAgi:
	var ag: RotaAgi = RotaAgi.new()
	for bolge: Bolge in dunya.bolge_listesi:
		var d: int = ag._dugum_ekle(bolge.etiket, kara_carpani, {"bolge": bolge.id, "tur": "kara"})
		ag._kara[bolge.id] = d
		ag.set_point_disabled(d, true)
	var havzalar: Dictionary = veri.get("bolge_havzalari", {})
	# Kuzey Buz Denizi kıyılarında deniz yolu buz yüzünden pahalıdır.
	var buzlu: Dictionary = {}
	for bolge_id: Variant in (veri.get("buzlu_bolgeler", []) as Array):
		buzlu[str(bolge_id)] = true
	for bolge_id: String in havzalar:
		var bolge: Bolge = dunya.bolgeler.get(bolge_id)
		if bolge == null:
			continue
		for havza: String in (havzalar[bolge_id] as Array):
			var d: int = ag._dugum_ekle(bolge.etiket, buz_carpani if buzlu.has(bolge_id) else 1.0,
					{"bolge": bolge_id, "tur": "deniz"})
			ag._deniz[_anahtar(bolge_id, havza)] = d
			ag.connect_points(ag._kara[bolge_id], d)
	for bolge: Bolge in dunya.bolge_listesi:
		for komsu_id: String in bolge.kara_komsulari:
			if ag._kara.has(komsu_id):
				ag.connect_points(ag._kara[bolge.id], ag._kara[komsu_id])
	for gecit: Dictionary in (veri.get("gecitler", []) as Array):
		var merkez: Array = gecit.get("merkez", [0.0, 0.0])
		ag._gecit_dugumu[str(gecit["id"])] = ag._dugum_ekle(Vector2(float(merkez[0]), float(merkez[1])), 1.0,
				{"tur": "gecit", "gecit": str(gecit["id"])})
	for kenar: Array in (veri.get("deniz_kenarlari", []) as Array):
		var a: int = ag._deniz.get(_anahtar(str(kenar[0]), str(kenar[1])), -1)
		var b: int = ag._deniz.get(_anahtar(str(kenar[2]), str(kenar[3])), -1)
		if a < 0 or b < 0 or a == b:
			continue
		var gecit_id: String = str(kenar[4])
		if gecit_id == "":
			ag.connect_points(a, b)
		elif ag._gecit_dugumu.has(gecit_id):
			ag.connect_points(a, ag._gecit_dugumu[gecit_id])
			ag.connect_points(ag._gecit_dugumu[gecit_id], b)
	return ag


static func _anahtar(bolge_id: String, havza: String) -> String:
	return "%s|%s" % [bolge_id, havza]


func _dugum_ekle(konum: Vector2, agirlik: float, bilgi: Dictionary) -> int:
	var d: int = _sonraki
	_sonraki += 1
	add_point(d, konum, agirlik)
	_dugum_bilgisi[d] = bilgi
	return d


## İki bölge arasında rota bulur. `acik_bolgeler`: kara düğümü açılacak bölgeler;
## `kapali_gecitler`: bu rotaya kapalı geçitler. Sonuç: {"yol": Array[Vector2] (çizim için
## noktalar), "deniz": Array[bool] (her parçanın denizde mi olduğu), "gecitler": Array[String],
## "bolgeler": Array[String] (geçilen bölgeler, sırayla), "kara_bolgeleri": Array[String]
## (karadan geçilenler), "uzunluk": float}; rota yoksa boş.
func rota_bul(baslangic: String, bitis: String, acik_bolgeler: Array[String], kapali_gecitler: Array[String]) -> Dictionary:
	if not _kara.has(baslangic) or not _kara.has(bitis):
		return {}
	for bolge_id: String in acik_bolgeler:
		if _kara.has(bolge_id):
			set_point_disabled(_kara[bolge_id], false)
	for gecit_id: String in kapali_gecitler:
		if _gecit_dugumu.has(gecit_id):
			set_point_disabled(_gecit_dugumu[gecit_id], true)
	set_point_disabled(_kara[baslangic], false)
	set_point_disabled(_kara[bitis], false)
	var yol: PackedInt64Array = get_id_path(_kara[baslangic], _kara[bitis])
	for bolge_id: String in acik_bolgeler:
		if _kara.has(bolge_id):
			set_point_disabled(_kara[bolge_id], true)
	set_point_disabled(_kara[baslangic], true)
	set_point_disabled(_kara[bitis], true)
	for gecit_id: String in kapali_gecitler:
		if _gecit_dugumu.has(gecit_id):
			set_point_disabled(_gecit_dugumu[gecit_id], false)
	if yol.is_empty():
		return {}
	var noktalar: Array[Vector2] = []
	var deniz: Array[bool] = []
	var gecitler: Array[String] = []
	var bolgeler: Array[String] = []
	var kara_bolgeleri: Array[String] = []
	var uzunluk: float = 0.0
	for i: int in yol.size():
		var bilgi: Dictionary = _dugum_bilgisi[yol[i]]
		var konum: Vector2 = get_point_position(yol[i])
		if bilgi["tur"] == "gecit":
			gecitler.append(str(bilgi["gecit"]))
		else:
			var bolge_id: String = str(bilgi["bolge"])
			if bolgeler.is_empty() or bolgeler[bolgeler.size() - 1] != bolge_id:
				bolgeler.append(bolge_id)
			if bilgi["tur"] == "kara" and not kara_bolgeleri.has(bolge_id):
				kara_bolgeleri.append(bolge_id)
		if not noktalar.is_empty() and konum.is_equal_approx(noktalar[noktalar.size() - 1]):
			continue
		if not noktalar.is_empty():
			uzunluk += konum.distance_to(noktalar[noktalar.size() - 1])
			# Parça, iki ucu da kara düğümü değilse denizdedir.
			var onceki: Dictionary = _dugum_bilgisi[yol[i - 1]]
			deniz.append(not (bilgi["tur"] == "kara" and onceki["tur"] == "kara"))
		noktalar.append(konum)
	return {"yol": noktalar, "deniz": deniz, "gecitler": gecitler, "bolgeler": bolgeler,
		"kara_bolgeleri": kara_bolgeleri, "uzunluk": uzunluk}


## Geçidin düğümü kapalı mı (bkz. rota_bul)? Sınamalar için.
func gecit_var_mi(gecit_id: String) -> bool:
	return _gecit_dugumu.has(gecit_id)
