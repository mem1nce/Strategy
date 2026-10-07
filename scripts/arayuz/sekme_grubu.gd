class_name SekmeGrubu
extends PanelContainer
## Ortak "sekme" bileşeni (STIL.md): bir hap içinde yan yana düğmeler; aynı anda yalnızca biri
## seçilidir ve vurgu renginde görünür. Seçim değişince `secildi(sira)` yayılır.

signal secildi(sira: int)

var _sira: HBoxContainer = null
var _grup: ButtonGroup = ButtonGroup.new()


func _init() -> void:
	add_theme_stylebox_override("panel", ArayuzTemasi.kutu(ArayuzTemasi.YUZEY, ArayuzTemasi.KOSE_BUYUK, 4))
	_sira = Bilesenler.sira(4)
	add_child(_sira)


## Bir sekme ekler ve düğmesini döndürür. İlk eklenen seçili başlar.
func ekle(metin: String, simge: String = "", boyut: Vector2 = Vector2(104.0, 96.0)) -> Button:
	var dugme: Button = Bilesenler.ikincil_dugme(metin, simge, boyut)
	dugme.theme_type_variation = ArayuzTemasi.SEKME
	dugme.toggle_mode = true
	dugme.button_group = _grup
	dugme.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var sira: int = _sira.get_child_count()
	dugme.toggled.connect(func(acik: bool) -> void:
		if acik:
			secildi.emit(sira))
	_sira.add_child(dugme)
	if sira == 0:
		dugme.set_pressed_no_signal(true)
	return dugme


## Seçili sekmeyi sinyal yaymadan değiştirir.
func sec(sira: int) -> void:
	if sira >= 0 and sira < _sira.get_child_count():
		(_sira.get_child(sira) as Button).set_pressed_no_signal(true)
