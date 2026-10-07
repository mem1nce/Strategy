class_name YolBulucu
extends AStar2D
## Bölgeler arasında, saat cinsinden süreye göre en hızlı yolu bulur.
##
## Kara komşuluğu geçişi, iki bölgenin etiket noktaları arasındaki mesafeyle orantılıdır
## (alt ve üst sınırla); böylece sık bölgeli ülkelerde yürümek anlamsızca yavaşlamaz. Deniz
## yolu da mesafeyle orantılıdır ama taban süresi yüzünden belirgin biçimde daha yavaştır (bkz. TASARIM.md 7. Birlikler, data/balance.json → "hareket").
## Yalnızca coğrafyaya bakar; "savaşta olmadığın ülkeye giremezsin" gibi kurallar bunun
## üstüne, hareket emrini veren kod tarafından uygulanır (henüz yok).

const DENGE_DOSYASI: String = "res://data/balance.json"

var _bolge_id: Dictionary[String, int] = {}
var _id_bolge: PackedStringArray = PackedStringArray()
## (küçük sıra, büyük sıra) -> saat.
var _saat: Dictionary[Vector2i, float] = {}


static func kur(dunya: Dunya) -> YolBulucu:
	var ayarlar: Dictionary = VeriOkuyucu.sozluk_oku(DENGE_DOSYASI).get("hareket", {})
	var kara_saat_birim_basi: float = float(ayarlar.get("kara_saat_birim_basi", 0.33))
	var kara_asgari_saat: float = float(ayarlar.get("kara_asgari_saat", 8.0))
	var kara_azami_saat: float = float(ayarlar.get("kara_azami_saat", 48.0))
	var deniz_taban_saat: float = float(ayarlar.get("deniz_taban_saat", 48.0))
	var deniz_saat_birim_basi: float = float(ayarlar.get("deniz_saat_birim_basi", 1.5))

	var yb: YolBulucu = YolBulucu.new()
	for i: int in dunya.bolge_listesi.size():
		var bolge: Bolge = dunya.bolge_listesi[i]
		yb._id_bolge.append(bolge.id)
		yb._bolge_id[bolge.id] = i
		yb.add_point(i, bolge.etiket)

	for bolge: Bolge in dunya.bolge_listesi:
		var a: int = yb._bolge_id[bolge.id]
		for komsu_id: String in bolge.kara_komsulari:
			var mesafe: float = bolge.etiket.distance_to(dunya.bolgeler[komsu_id].etiket)
			yb._baglanti_ekle(a, yb._bolge_id[komsu_id],
					clampf(mesafe * kara_saat_birim_basi, kara_asgari_saat, kara_azami_saat))
		for komsu_id: String in bolge.deniz_gecisleri:
			var komsu: Bolge = dunya.bolgeler[komsu_id]
			var uzaklik: float = bolge.etiket.distance_to(komsu.etiket)
			yb._baglanti_ekle(a, yb._bolge_id[komsu_id], deniz_taban_saat + uzaklik * deniz_saat_birim_basi)
	return yb


## İki bölge arasındaki en hızlı yolun bölge id listesi (başlangıç ve bitiş dahil).
## Yol yoksa (dünya verisi tek parça olduğu için pratikte olmamalı) boş dizi döner.
func en_kisa_yol(bolge_a: String, bolge_b: String) -> Array[String]:
	if not _bolge_id.has(bolge_a) or not _bolge_id.has(bolge_b):
		return []
	var siralar: PackedInt64Array = get_id_path(_bolge_id[bolge_a], _bolge_id[bolge_b])
	var sonuc: Array[String] = []
	for sira: int in siralar:
		sonuc.append(_id_bolge[sira])
	return sonuc


## İki bölge arasındaki en hızlı yolun toplam süresi (saat). Yol yoksa -1 döner.
func en_kisa_sure(bolge_a: String, bolge_b: String) -> float:
	if bolge_a == bolge_b:
		return 0.0
	var yol: Array[String] = en_kisa_yol(bolge_a, bolge_b)
	if yol.is_empty():
		return -1.0
	return yol_suresi(yol)


## en_kisa_yol()'un döndürdüğü bir yolun toplam süresi (saat). Yolu zaten bulmuş olan
## çağıran, aramayı ikinci kez yaptırmamak için bunu kullanır.
func yol_suresi(yol: Array[String]) -> float:
	var toplam: float = 0.0
	for i: int in yol.size() - 1:
		toplam += _compute_cost(_bolge_id[yol[i]], _bolge_id[yol[i + 1]])
	return toplam


func _baglanti_ekle(a: int, b: int, saat: float) -> void:
	if not are_points_connected(a, b):
		connect_points(a, b)
	_saat[Vector2i(mini(a, b), maxi(a, b))] = saat


## AStar2D'nin varsayılan (iki nokta arası Öklid uzaklığı) maliyetini, gerçek saat
## cinsinden süreyle değiştirir.
func _compute_cost(from_id: int, to_id: int) -> float:
	return _saat.get(Vector2i(mini(from_id, to_id), maxi(from_id, to_id)), 1.0)


## Her zaman 0 döner: kıyaslama için kullanılan tahmini maliyet gerçek maliyeti hiçbir
## zaman aşmamalı (admissible heuristic); saatler coğrafi uzaklıkla orantılı olmadığından
## (alt sınır ve deniz yolunun taban süresi yüzünden) güvenli tek seçenek budur.
func _estimate_cost(_from_id: int, _to_id: int) -> float:
	return 0.0
