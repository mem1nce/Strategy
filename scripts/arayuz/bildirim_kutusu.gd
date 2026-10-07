class_name BildirimKutusu
extends VBoxContainer
## Oyuncuyla ilgili önemli olayları (sana savaş ilanı, bölge kaybı/kazancı, üretim bitti)
## küçük kartlar olarak üst üste gösterir. Bir karta dokunmak hem onu kapatır hem de
## (bölge id'si varsa) kamerayı ilgili bölgeye götürür.
##
## Zamanı durdurmaz; oyun arka planda sürerken bilgilendirir.

## Bir bildirim kartına dokunulduğunda, ilgili bölge id'siyle (yoksa boş) yayılır.
signal bildirime_dokunuldu(bolge_id: String)

const KART_BOYUTU: Vector2 = Vector2(620.0, 104.0)
const YAZI_BOYUTU: int = ArayuzTemasi.YAZI_KUCUK
## Aynı anda en fazla bu kadar kart gösterilir; yenisi gelince en eskisi atılır
## (okunmamış bildirimler sonsuza kadar birikmesin diye).
const AZAMI_KART: int = 4
## Kartın kayarak gelme süresi (sn) ve ekranın sağından ne kadar dışarıdan başladığı.
const KAYMA_SURESI: float = 0.25
const KAYMA_PAYI: float = 40.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("separation", ArayuzTemasi.BOSLUK_1)


## Yeni bir bildirim kartı ekler; en yeni en üstte durur. Kart: solda konuyu anlatan simge
## (`simge`, art/icons), varsa ilgili ülkenin bayrağı, sağda metin. Animasyonlar açıksa kart
## ekranın sağından kayarak gelir: kart, yerini kutuda tutan boş bir yuvanın içinde kaydırılır
## (kutu bir VBoxContainer olduğu için kartın kendi konumu doğrudan oynatılamaz).
func ekle(metin: String, bolge_id: String, ulke: Ulke = null, simge: String = "bildirim",
		vurgu: Color = ArayuzTemasi.VURGU) -> void:
	var yuva: Control = Control.new()
	yuva.custom_minimum_size = KART_BOYUTU
	yuva.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var kart: Button = Button.new()
	kart.size = KART_BOYUTU
	kart.focus_mode = Control.FOCUS_NONE
	# Solda konunun renginde ince şerit: kartlar bir bakışta ayırt edilsin.
	var zemin: StyleBoxFlat = ArayuzTemasi.kutu(ArayuzTemasi.YUZEY, ArayuzTemasi.KOSE, ArayuzTemasi.BOSLUK_1)
	zemin.border_color = vurgu
	zemin.border_width_left = 6
	zemin.shadow_color = ArayuzTemasi.GOLGE_RENGI
	zemin.shadow_size = 8
	zemin.shadow_offset = Vector2(0.0, 3.0)
	for durum: String in ["normal", "hover", "pressed", "hover_pressed"]:
		kart.add_theme_stylebox_override(durum, zemin)
	kart.pressed.connect(func() -> void:
		bildirime_dokunuldu.emit(bolge_id)
		yuva.queue_free())
	yuva.add_child(kart)

	var icerik: HBoxContainer = Bilesenler.sira(ArayuzTemasi.BOSLUK_2)
	icerik.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icerik.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icerik.offset_left = ArayuzTemasi.BOSLUK_2 + 6
	icerik.offset_right = -ArayuzTemasi.BOSLUK_2
	kart.add_child(icerik)
	icerik.add_child(Simgeler.dugum(simge, 40.0, vurgu))
	if ulke != null:
		var bayrak: Control = Bayraklar.dugum(ulke, 30.0)
		bayrak.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		icerik.add_child(bayrak)
	var yazi: Label = Label.new()
	yazi.text = metin
	yazi.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	yazi.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	yazi.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	yazi.max_lines_visible = 2
	yazi.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	yazi.add_theme_font_size_override("font_size", YAZI_BOYUTU)
	icerik.add_child(yazi)

	add_child(yuva)
	move_child(yuva, 0)
	if not Ayarlar.animasyonlar_azaltilmis:
		kart.position.x = KART_BOYUTU.x + KAYMA_PAYI
		kart.create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT) 				.tween_property(kart, "position:x", 0.0, KAYMA_SURESI)
	if get_child_count() > AZAMI_KART:
		get_child(get_child_count() - 1).queue_free()
