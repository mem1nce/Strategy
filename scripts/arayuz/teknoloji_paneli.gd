class_name TeknolojiPaneli
extends PanelContainer
## Üst çubuktaki "Teknoloji" düğmesiyle açılıp kapanan panel: her dal için bir satır, her
## seviye için bir kutu (ne verdiği, fiyatı, süresi). Biten seviyeler vurgulu, sıradaki
## seviye dokunulabilir, sonrakiler kapalıdır. Başlığın yanında süren araştırmanın ilerleme
## çubuğu durur. Sıralama paneli gibi üst çubukla alt panelin arasına sığar.

## Oyuncu araştırılabilir bir kutuya dokunduğunda, dalın adıyla yayılır.
signal arastirma_istendi(dal: String)

const DAL_ADI_GENISLIGI: float = 220.0
const KUTU_BOYUTU: Vector2 = Vector2(430.0, 112.0)
const KUTU_YAZI_BOYUTU: int = ArayuzTemasi.YAZI_KUCUK
## Dalların simgeleri (art/icons).
const DAL_SIMGELERI: Dictionary[String, String] = {
	"sanayi": "sanayi", "silah": "muharebe", "savunma": "tahkimat", "lojistik": "uretim"}
const CUBUK_BOYUTU: Vector2 = Vector2(420.0, 40.0)
## Kapalı kutuların yazısı da okunabilsin diye temadakinden açık.
const KAPALI_YAZI_RENGI: Color = ArayuzTemasi.IKINCIL_YAZI

## Dal -> o dalın seviye kutuları (seviye 1'den başlayarak).
var _kutular: Dictionary[String, Array] = {}
var _durum: Label = null
var _cubuk: ProgressBar = null
## Oyuncunun araştırma süresi çarpanı (ülke bonusu varsa 1'den küçük; bkz. Oyun.arastirma_sure_carpani).
var sure_carpani: float = 1.0


func _ready() -> void:
	# Başlıklı panel kendi zeminini çizer; bu düğüm yalnızca kap.
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	var panel: BaslikliPanel = BaslikliPanel.new("Teknoloji")
	panel.isaret_ayarla(Simgeler.dugum("teknoloji", 40.0, ArayuzTemasi.VURGU))
	add_child(panel)
	var dikey: VBoxContainer = panel.govde
	dikey.add_theme_constant_override("separation", ArayuzTemasi.BOSLUK_1)
	_durum = Bilesenler.ikincil_yazi()
	panel.sag_alan.add_child(_durum)
	_cubuk = Bilesenler.ilerleme_cubugu(ArayuzTemasi.VURGU, 16.0)
	_cubuk.custom_minimum_size = Vector2(CUBUK_BOYUTU.x, 16.0)
	panel.sag_alan.add_child(_cubuk)

	for dal: String in Teknoloji.DALLAR:
		var satir: HBoxContainer = HBoxContainer.new()
		satir.add_theme_constant_override("separation", 12)
		dikey.add_child(satir)
		var ad: HBoxContainer = Bilesenler.sira(ArayuzTemasi.BOSLUK_1)
		ad.custom_minimum_size = Vector2(DAL_ADI_GENISLIGI, 0.0)
		ad.add_child(Simgeler.dugum(DAL_SIMGELERI.get(dal, "teknoloji"), 34.0))
		var ad_yazisi: Label = Label.new()
		ad_yazisi.text = Teknoloji.ad(dal)
		ad_yazisi.add_theme_font_override("font", ArayuzTemasi.arayuz_fontu(600))
		ad.add_child(ad_yazisi)
		satir.add_child(ad)
		var liste: Array[Button] = []
		for seviye: int in range(1, Teknoloji.azami_seviye() + 1):
			var kutu: Button = Button.new()
			kutu.custom_minimum_size = KUTU_BOYUTU
			kutu.focus_mode = Control.FOCUS_NONE
			kutu.add_theme_font_size_override("font_size", KUTU_YAZI_BOYUTU)
			kutu.add_theme_color_override("font_disabled_color", KAPALI_YAZI_RENGI)
			kutu.pressed.connect(func() -> void: arastirma_istendi.emit(dal))
			satir.add_child(kutu)
			liste.append(kutu)
		_kutular[dal] = liste
	hide()


## Paneli oyuncunun güncel durumuyla doldurur. `seviyeler`: dal -> seviye; `suren`:
## Oyun.suren_arastirma()'nın döndürdüğü sözlük (yoksa boş).
func goster(seviyeler: Dictionary, suren: Dictionary) -> void:
	var suren_dal: String = str(suren.get("dal", ""))
	for dal: String in Teknoloji.DALLAR:
		var mevcut: int = int(seviyeler.get(dal, 0))
		var liste: Array = _kutular[dal]
		for i: int in liste.size():
			var seviye: int = i + 1
			var kutu: Button = liste[i]
			var aciklama: String = Teknoloji.seviye_aciklamasi(dal, seviye)
			var bitti: bool = seviye <= mevcut
			var siradaki: bool = seviye == mevcut + 1
			kutu.theme_type_variation = ArayuzTemasi.VURGULU_DUGME if bitti else &""
			# Biten kutular vurgulu kalsın diye kapatılmaz, yalnızca dokunuşu yok sayar.
			kutu.mouse_filter = Control.MOUSE_FILTER_IGNORE if bitti else Control.MOUSE_FILTER_STOP
			kutu.disabled = not bitti and (not siradaki or not suren.is_empty())
			if bitti:
				kutu.text = "Seviye %d - tamam\n%s" % [seviye, aciklama]
			elif siradaki and dal == suren_dal:
				kutu.text = "Seviye %d - araştırılıyor\n%s" % [seviye, aciklama]
			else:
				kutu.text = "Seviye %d\n%s\nFiyat %d · %d gün" % [seviye, aciklama,
						roundi(Teknoloji.maliyet(seviye)), roundi(Teknoloji.sure_saat(seviye) * sure_carpani / 24.0)]
	ilerlemeyi_goster(seviyeler, suren)
	show()


## Yalnızca başlığın yanındaki durum yazısını ve ilerleme çubuğunu günceller (her oyun saati).
func ilerlemeyi_goster(seviyeler: Dictionary, suren: Dictionary) -> void:
	if suren.is_empty():
		_durum.text = "Araştırma yok: sıradaki bir seviyeye dokun."
		_cubuk.hide()
		return
	var dal: String = suren["dal"]
	var toplam: float = maxf(1.0, float(suren["toplam_saat"]))
	var kalan: int = int(suren["kalan_saat"])
	_durum.text = "%s %d araştırılıyor, %d gün kaldı" % [Teknoloji.ad(dal), int(seviyeler.get(dal, 0)) + 1,
			ceili(kalan / 24.0)]
	_cubuk.value = 1.0 - kalan / toplam
	_cubuk.show()
