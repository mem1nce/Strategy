extends Node
## Zaman yöneticisi (autoload: Zaman).
##
## 1 tick = 1 oyun saati. Oyun saatini ilerletir ve sinyal yayar; ekonomi, savaş
## gibi sistemler ileride bu sinyallere bağlanacak. Hiçbir şey çizmez, girdi okumaz.
## Düğüm olmasının tek nedeni her karede _process ile gerçek zamanı sayabilmektir.

## Her oyun saatinde bir kez yayılır.
signal saat_gecti(toplam_saat: int)
## Her gün başında (saat 00:00 olunca), saat_gecti'den sonra yayılır.
signal gun_basladi(toplam_gun: int)
## Durdurma ya da hız değişince yayılır.
signal durum_degisti
## Oyunun bitiş tarihine ulaşılınca bir kez yayılır.
signal sure_doldu

const DENGE_DOSYASI: String = "res://data/balance.json"

## Oyunun başından beri geçen saat.
var toplam_saat: int = 0
var durdu: bool = true
## Seçili hız (1'den başlar).
var hiz: int = 1
## Bitiş tarihine ulaşıldı mı?
var bitti: bool = false
var baslangic_yili: int = 1931

var _bitis_saati: int = 0
## Her hız için saniyede atılacak tick sayısı.
var _hizlar: PackedFloat32Array = PackedFloat32Array([2.0, 6.0, 24.0])
var _kare_basina_azami_tick: int = 5
## Henüz tick'e dönüşmemiş gerçek zaman (tick cinsinden).
var _birikim: float = 0.0


func _ready() -> void:
	_ayarlari_yukle()


func _process(delta: float) -> void:
	if durdu or bitti:
		return
	_birikim += delta * _hizlar[hiz - 1]
	var atilan: int = 0
	while _birikim >= 1.0 and atilan < _kare_basina_azami_tick and not durdu:
		_birikim -= 1.0
		atilan += 1
		bir_saat_ilerle()
	# Cihaz yetişemediyse biriken zamanı at; oyun yavaşlar ama takılmaz.
	if _birikim >= 1.0:
		_birikim = 0.0


## Oyunu bir saat ilerletir. Durdurulmuş olsa da çalışır (sınama için).
func bir_saat_ilerle() -> void:
	if bitti:
		return
	toplam_saat += 1
	saat_gecti.emit(toplam_saat)
	if Takvim.saat(toplam_saat) == 0:
		gun_basladi.emit(Takvim.gun_sayisi(toplam_saat))
	if toplam_saat >= _bitis_saati:
		bitti = true
		durdu = true
		_birikim = 0.0
		durum_degisti.emit()
		sure_doldu.emit()


func durdur() -> void:
	if durdu:
		return
	durdu = true
	durum_degisti.emit()


func devam_et() -> void:
	if not durdu or bitti:
		return
	durdu = false
	_birikim = 0.0
	durum_degisti.emit()


func durdurmayi_degistir() -> void:
	if durdu:
		devam_et()
	else:
		durdur()


func hiz_sec(yeni_hiz: int) -> void:
	var sinirli: int = clampi(yeni_hiz, 1, _hizlar.size())
	if sinirli == hiz:
		return
	hiz = sinirli
	durum_degisti.emit()


func hiz_sayisi() -> int:
	return _hizlar.size()


func tarih_metni() -> String:
	return Takvim.metin(toplam_saat, baslangic_yili)


func _ayarlari_yukle() -> void:
	var veri: Dictionary = VeriOkuyucu.sozluk_oku(DENGE_DOSYASI)
	var ayarlar: Dictionary = veri.get("zaman", {})
	baslangic_yili = int(ayarlar.get("baslangic_yili", 1931))
	var bitis_yili: int = int(ayarlar.get("bitis_yili", 1935))
	_bitis_saati = Takvim.yil_basi_saati(bitis_yili, baslangic_yili)
	_kare_basina_azami_tick = maxi(1, int(ayarlar.get("kare_basina_azami_tick", 5)))

	var hiz_listesi: Array = ayarlar.get("hizlar_tick_saniye", [])
	if not hiz_listesi.is_empty():
		_hizlar = PackedFloat32Array()
		for deger: Variant in hiz_listesi:
			_hizlar.append(float(deger))
