class_name Gecis
extends RefCounted
## Arayüzün kısa geçiş animasyonları: panellerin solarak açılıp kapanması ve düğmelerin
## basılınca hafifçe küçülüp geri gelmesi. "Animasyonlar: Azaltılmış" (Ayarlar) seçiliyse
## hepsi anında olur. Simülasyonla ilgisi yoktur; yalnızca görünüşü değiştirir.

const SURE: float = 0.16
const BASILI_OLCEK: float = 0.94
const META: StringName = &"gecis_tween"


## Paneli gösterir; animasyonlar açıksa saydamdan solarak belirir.
static func ac(panel: CanvasItem) -> void:
	_eski_tweeni_durdur(panel)
	panel.show()
	if Ayarlar.animasyonlar_azaltilmis:
		panel.modulate.a = 1.0
		return
	panel.modulate.a = 0.0
	var tween: Tween = panel.create_tween()
	tween.tween_property(panel, "modulate:a", 1.0, SURE)
	panel.set_meta(META, tween)


## Paneli gizler; animasyonlar açıksa solarak kaybolur.
static func kapat(panel: CanvasItem) -> void:
	if not panel.visible:
		return
	_eski_tweeni_durdur(panel)
	if Ayarlar.animasyonlar_azaltilmis:
		panel.hide()
		return
	var tween: Tween = panel.create_tween()
	tween.tween_property(panel, "modulate:a", 0.0, SURE)
	tween.tween_callback(func() -> void:
		panel.hide()
		panel.modulate.a = 1.0)
	panel.set_meta(META, tween)


## Panel her görünür olduğunda (show() ile de açılsa) solarak belirmesini sağlar.
static func belirmeyi_bagla(panel: CanvasItem) -> void:
	panel.visibility_changed.connect(func() -> void:
		if panel.visible and not Ayarlar.animasyonlar_azaltilmis and not panel.has_meta(META):
			panel.modulate.a = 0.0
			var tween: Tween = panel.create_tween()
			tween.tween_property(panel, "modulate:a", 1.0, SURE)
			tween.tween_callback(func() -> void: panel.remove_meta(META))
			panel.set_meta(META, tween))


## Düğme basılınca hafifçe küçülür, bırakılınca geri gelir.
static func dugmeyi_bagla(dugme: BaseButton) -> void:
	dugme.button_down.connect(func() -> void: _olcekle(dugme, BASILI_OLCEK))
	dugme.button_up.connect(func() -> void: _olcekle(dugme, 1.0))


static func _olcekle(dugme: Control, olcek: float) -> void:
	if Ayarlar.animasyonlar_azaltilmis or not dugme.is_inside_tree():
		dugme.scale = Vector2.ONE
		return
	dugme.pivot_offset = dugme.size * 0.5
	var tween: Tween = dugme.create_tween()
	tween.tween_property(dugme, "scale", Vector2(olcek, olcek), SURE * 0.5)


static func _eski_tweeni_durdur(panel: CanvasItem) -> void:
	if panel.has_meta(META):
		var eski: Variant = panel.get_meta(META)
		if eski is Tween and (eski as Tween).is_valid():
			(eski as Tween).kill()
		panel.remove_meta(META)
