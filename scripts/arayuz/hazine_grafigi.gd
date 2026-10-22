class_name HazineGrafigi
extends Control
## Bütçe panelindeki son 90 günün hazine grafiği (STIL.md): sıfır çizgisi, artıda başarı,
## eksi (borç) bölümünde tehlike renginde yarı saydam alan ve üstünde çizgi. Değerler
## eskiden yeniye sıralıdır.

const CIZGI_KALINLIGI: float = 3.0
const ALAN_OPAKLIGI: float = 0.22

var _degerler: PackedFloat32Array = PackedFloat32Array()


func degerleri_ayarla(degerler: PackedFloat32Array) -> void:
	_degerler = degerler
	queue_redraw()


func _draw() -> void:
	var alan: Rect2 = Rect2(Vector2.ZERO, size)
	draw_style_box(ArayuzTemasi.kutu(ArayuzTemasi.BASILI_YUZEY, ArayuzTemasi.KOSE, 0), alan)
	if _degerler.size() < 2:
		var yazi: String = "Grafik birkaç gün sonra dolar."
		var font: Font = ArayuzTemasi.arayuz_fontu(400)
		var genislik: float = font.get_string_size(yazi, HORIZONTAL_ALIGNMENT_LEFT, -1.0, ArayuzTemasi.YAZI_MINIK).x
		draw_string(font, Vector2((size.x - genislik) * 0.5, size.y * 0.5 + 8.0), yazi,
				HORIZONTAL_ALIGNMENT_LEFT, -1.0, ArayuzTemasi.YAZI_MINIK, ArayuzTemasi.SOLUK_YAZI)
		return
	var en_az: float = 0.0
	var en_cok: float = 0.0
	for deger: float in _degerler:
		en_az = minf(en_az, deger)
		en_cok = maxf(en_cok, deger)
	var aralik: float = maxf(en_cok - en_az, 1.0)
	var pay: float = 10.0
	var ic: Rect2 = alan.grow(-pay)
	var sifir_y: float = ic.position.y + ic.size.y * (en_cok / aralik)
	draw_line(Vector2(ic.position.x, sifir_y), Vector2(ic.end.x, sifir_y), ArayuzTemasi.KENAR, 2.0)

	var noktalar: PackedVector2Array = PackedVector2Array()
	for i: int in _degerler.size():
		var x: float = ic.position.x + ic.size.x * float(i) / float(_degerler.size() - 1)
		var y: float = ic.position.y + ic.size.y * ((en_cok - _degerler[i]) / aralik)
		noktalar.append(Vector2(x, y))
	# Her aralık kendi işaretinin renginde sıfır çizgisine kadar boyanır.
	for i: int in noktalar.size() - 1:
		var a: Vector2 = noktalar[i]
		var b: Vector2 = noktalar[i + 1]
		var orta: float = (_degerler[i] + _degerler[i + 1]) * 0.5
		var renk: Color = ArayuzTemasi.BASARI if orta >= 0.0 else ArayuzTemasi.TEHLIKE
		draw_colored_polygon(PackedVector2Array([a, b, Vector2(b.x, sifir_y), Vector2(a.x, sifir_y)]),
				Color(renk, ALAN_OPAKLIGI))
		draw_line(a, b, renk, CIZGI_KALINLIGI, true)
