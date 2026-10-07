class_name BaslikliPanel
extends PanelContainer
## Ortak "başlıklı panel" bileşeni (STIL.md): üstte isteğe bağlı bayrak ya da simge ile Cinzel
## başlık ve sağında isteğe bağlı öğeler, altında ince ayraç, onun altında `govde`.

var baslik_sirasi: HBoxContainer = null
var baslik: Label = null
## Başlık satırının sağındaki öğeler (ör. rozet, kapat düğmesi) buraya eklenir.
var sag_alan: HBoxContainer = null
var govde: VBoxContainer = null
var _isaret: Control = null


func _init(metin: String = "") -> void:
	var dikey: VBoxContainer = Bilesenler.yigin(ArayuzTemasi.BOSLUK_2)
	add_child(dikey)
	baslik_sirasi = Bilesenler.sira(ArayuzTemasi.BOSLUK_2)
	dikey.add_child(baslik_sirasi)
	baslik = Bilesenler.baslik(metin)
	baslik.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	baslik.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	baslik_sirasi.add_child(baslik)
	sag_alan = Bilesenler.sira(ArayuzTemasi.BOSLUK_1)
	baslik_sirasi.add_child(sag_alan)
	dikey.add_child(HSeparator.new())
	govde = Bilesenler.yigin(ArayuzTemasi.BOSLUK_1)
	dikey.add_child(govde)


func baslik_ayarla(metin: String) -> void:
	baslik.text = metin


## Başlığın soluna bir bayrak ya da simge koyar (öncekinin yerine).
func isaret_ayarla(isaret: Control) -> void:
	if _isaret != null:
		_isaret.queue_free()
	_isaret = isaret
	if isaret != null:
		baslik_sirasi.add_child(isaret)
		baslik_sirasi.move_child(isaret, 0)
