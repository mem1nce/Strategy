class_name GecitPaneli
extends PanelContainer
## Alt panel: Ticaret modunda haritadaki bir geçide dokununca açılır (STIL.md). Başlıkta geçit
## simgesi ve adı, durum rozeti (açık / kapalı); altında kontrol eden ülkeler (bayraklarıyla),
## geçen rota sayısı ve günlük geçiş ücreti geliri. Yalnızca gösterir; veriyi main.gd hazırlar.

const BAYRAK_YUKSEKLIGI: float = 36.0

var _ad: Label = null
var _durum_yeri: HBoxContainer = null
var _bayraklar: HBoxContainer = null
var _kontrol: IstatistikSatiri = null
var _rotalar: IstatistikSatiri = null
var _gelir: IstatistikSatiri = null
var _havzalar: IstatistikSatiri = null


func _ready() -> void:
	var dikey: VBoxContainer = Bilesenler.yigin(ArayuzTemasi.BOSLUK_1)
	add_child(dikey)
	var baslik: HBoxContainer = Bilesenler.sira(ArayuzTemasi.BOSLUK_2)
	dikey.add_child(baslik)
	baslik.add_child(Simgeler.dugum("gecit", 40.0, TicaretKatmani.GECIT_RENGI))
	_ad = Bilesenler.baslik("", ArayuzTemasi.YAZI_ALT_BASLIK)
	baslik.add_child(_ad)
	_durum_yeri = Bilesenler.sira(0)
	baslik.add_child(_durum_yeri)
	_bayraklar = Bilesenler.sira(ArayuzTemasi.BOSLUK_1)
	_bayraklar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_bayraklar.alignment = BoxContainer.ALIGNMENT_END
	baslik.add_child(_bayraklar)

	var izgara: GridContainer = GridContainer.new()
	izgara.columns = 2
	izgara.add_theme_constant_override("h_separation", ArayuzTemasi.BOSLUK_4)
	izgara.add_theme_constant_override("v_separation", 2)
	dikey.add_child(izgara)
	_kontrol = IstatistikSatiri.new("diplomasi", "Kontrol eden")
	_havzalar = IstatistikSatiri.new("baris", "Bağladığı denizler")
	_rotalar = IstatistikSatiri.new("ticaret", "Geçen ticaret rotası")
	_gelir = IstatistikSatiri.new("para", "Günlük geçiş ücreti")
	for satir: IstatistikSatiri in [_kontrol, _havzalar, _rotalar, _gelir]:
		satir.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		izgara.add_child(satir)
	hide()


## `ozet`: {"ad": String, "sahipler": Array[Ulke], "havzalar": Array[String], "rota": int,
## "gelir": float, "kapali_gun": int (olayla kapalıysa kalan gün, değilse 0)}. Boş verilirse gizlenir.
func goster(ozet: Dictionary) -> void:
	if ozet.is_empty():
		hide()
		return
	_ad.text = str(ozet.get("ad", ""))
	for cocuk: Node in _durum_yeri.get_children():
		cocuk.queue_free()
	var kapali_gun: int = int(ozet.get("kapali_gun", 0))
	if kapali_gun > 0:
		_durum_yeri.add_child(Bilesenler.rozet("Kapalı: %d gün" % kapali_gun, ArayuzTemasi.TEHLIKE))
	else:
		_durum_yeri.add_child(Bilesenler.rozet("Açık", ArayuzTemasi.BASARI, ArayuzTemasi.VURGU_USTU))
	for cocuk: Node in _bayraklar.get_children():
		cocuk.queue_free()
	var adlar: PackedStringArray = PackedStringArray()
	for ulke: Ulke in (ozet.get("sahipler", []) as Array):
		_bayraklar.add_child(Bayraklar.dugum(ulke, BAYRAK_YUKSEKLIGI))
		adlar.append(ulke.ad)
	_kontrol.deger_ayarla(", ".join(adlar) if not adlar.is_empty() else "yok")
	_havzalar.deger_ayarla(" – ".join(PackedStringArray(ozet.get("havzalar", []))))
	_rotalar.deger_ayarla(str(int(ozet.get("rota", 0))))
	var gelir: float = float(ozet.get("gelir", 0.0))
	_gelir.deger_ayarla("+%s/gün" % Bicim.tutar(gelir), ArayuzTemasi.BASARI if gelir > 0.0 else ArayuzTemasi.SOLUK_YAZI)
	show()
