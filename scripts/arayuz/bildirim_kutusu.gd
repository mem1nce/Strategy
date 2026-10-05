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
const YAZI_BOYUTU: int = 32
## Aynı anda en fazla bu kadar kart gösterilir; yenisi gelince en eskisi atılır
## (okunmamış bildirimler sonsuza kadar birikmesin diye).
const AZAMI_KART: int = 4


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("separation", 10)


## Yeni bir bildirim kartı ekler; en yeni en üstte durur.
func ekle(metin: String, bolge_id: String) -> void:
	var kart: Button = Button.new()
	kart.text = metin
	kart.custom_minimum_size = KART_BOYUTU
	kart.focus_mode = Control.FOCUS_NONE
	kart.clip_text = true
	kart.add_theme_font_size_override("font_size", YAZI_BOYUTU)
	kart.pressed.connect(func() -> void:
		bildirime_dokunuldu.emit(bolge_id)
		kart.queue_free())
	add_child(kart)
	move_child(kart, 0)
	if get_child_count() > AZAMI_KART:
		get_child(get_child_count() - 1).queue_free()
