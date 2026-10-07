class_name SesYoneticisi
extends Node
## Kısa ses efektlerini çalar (sesler tools/ses_uret.py ile üretilir, sounds/ klasöründedir).
##
## Yalnızca oyuncuyu ilgilendiren olaylarda çağrılır (bkz. main.gd). Sesler üst üste
## binmesin diye her sesin bir bekleme süresi vardır; en yüksek oyun hızında bu süre uzar.
## Aynı anda en çok AZAMI_KANAL ses çalar. Ayarlar.sessiz ve Ayarlar.ses_duzeyi'ne uyar.

const SESLER: Dictionary[String, String] = {
	"tiklama": "res://sounds/click.wav",
	"onay": "res://sounds/confirm.wav",
	"hata": "res://sounds/error.wav",
	"emir": "res://sounds/order.wav",
	"muharebe": "res://sounds/battle.wav",
	"ele_gecirme": "res://sounds/capture.wav",
	"savas_ilani": "res://sounds/war.wav",
	"uretim": "res://sounds/production.wav",
	"zafer": "res://sounds/victory.wav",
	"kaybetme": "res://sounds/defeat.wav",
}
const AZAMI_KANAL: int = 4
## Aynı sesin iki çalınışı arasındaki en kısa süre (milisaniye).
const BEKLEME_MS: int = 250
## En yüksek oyun hızında olay sesleri (tıklama dışı) için bekleme.
const HIZLI_BEKLEME_MS: int = 1200

var _akislar: Dictionary[String, AudioStream] = {}
var _kanallar: Array[AudioStreamPlayer] = []
var _son_calinma: Dictionary[String, int] = {}


func _ready() -> void:
	for ad: String in SESLER:
		var akis: AudioStream = load(SESLER[ad])
		if akis != null:
			_akislar[ad] = akis
	for i: int in AZAMI_KANAL:
		var kanal: AudioStreamPlayer = AudioStreamPlayer.new()
		add_child(kanal)
		_kanallar.append(kanal)


## `ad`, SESLER'deki anahtarlardan biridir. Sessizse, ses bekleme süresindeyse ya da boş
## kanal yoksa çalınmaz.
func cal(ad: String) -> void:
	if Ayarlar.sessiz or Ayarlar.ses_duzeyi <= 0.0 or not _akislar.has(ad):
		return
	var simdi: int = Time.get_ticks_msec()
	var bekleme: int = BEKLEME_MS
	if ad != "tiklama" and Zaman.hiz >= Zaman.hiz_sayisi() and not Zaman.durdu:
		bekleme = HIZLI_BEKLEME_MS
	if simdi - _son_calinma.get(ad, -100000) < bekleme:
		return
	for kanal: AudioStreamPlayer in _kanallar:
		if not kanal.playing:
			_son_calinma[ad] = simdi
			kanal.stream = _akislar[ad]
			kanal.volume_db = linear_to_db(Ayarlar.ses_duzeyi)
			kanal.play()
			return
