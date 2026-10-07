class_name Bolge
extends RefCounted
## Bir bölgenin verisi. Bölge, bir şehrin çevresidir ve o şehrin adını taşır.

## Örnek: "TUR_1"
var id: String = ""
## Bölgenin "ev sahibi" ülkesinin id'si: id'nin öneki ("TUR_1" -> "TUR"). Sahip değişse de
## değişmez; ekonomi (bkz. Oyun.bolge_sanayisi) her gün her bölge için okuduğu için yüklerken
## bir kez çıkarılır.
var ev_sahibi: String = ""
var ad: String = ""
## Herhangi bir bölgenin sahibi her değiştiğinde bir artar (ör. uzun koşu, bölge paylarını
## yalnızca sahiplik değişince yeniden sayar).
static var sahiplik_surumu: int = 0
## Sahip değişince (bölge, eski sahip) ile çağrılır. Bölgeyi kuran Dunya bunu ayarlar ki
## ülke-bölge önbelleğini (bkz. Dunya.ulkenin_bolgeleri) baştan kurmadan güncelleyebilsin.
var sahip_dinleyicisi: Callable = Callable()

## Bölgenin şu anki sahibi olan ülkenin id'si. Oyun içinde değişebilir.
var sahip: String = "":
	set(deger):
		if deger != sahip:
			var eski: String = sahip
			sahip = deger
			Bolge.sahiplik_surumu += 1
			if sahip_dinleyicisi.is_valid():
				sahip_dinleyicisi.call(self, eski)
## Bu bölge, başlangıçtaki sahibinin başkenti mi?
var baskent: bool = false
var nufus: int = 0
## Son ele geçirildiği saat (Zaman.toplam_saat); hiç el değiştirmediyse -1. Ekonomide
## işgal cezası için kullanılır (bkz. Oyun.bolge_sanayisi).
var isgal_saati: int = -1
## Bölgede kurulan fabrikaların sanayiye kattığı toplam (bkz. Oyun.bolge_sanayisi,
## Oyun._insayi_tamamla).
var fabrika_sanayisi: float = 0.0
## Tahkimat seviyesi (0-3). Her seviye burada savunana avantaj verir; bölge el değiştirince
## bir seviye düşer (bkz. Oyun._bolgeyi_devret).
var tahkimat: int = 0
## Bölge, en az bir kıyı (deniz) sınırına değiyor mu?
var kiyi: bool = false
## Bölge adının ve işaretlerinin çizileceği nokta (en büyük çokgenin içinde).
var etiket: Vector2 = Vector2.ZERO
## Ortak sınır paylaşan bölgelerin id'leri (başka ülkelerinkiler dahil).
var kara_komsulari: PackedStringArray = PackedStringArray()
## Arada dar bir su bulunan, kara komşusu olmayan bölgelerin id'leri.
var deniz_gecisleri: PackedStringArray = PackedStringArray()
## Bölgeyi oluşturan toprak parçaları (anakara ve adalar), büyükten küçüğe.
var cokgenler: Array[Cokgen] = []
## Çokgenlerin toplam alanı (harita birimi kare).
var alan: float = 0.0

## Oyun._muharebeleri_isle'nin her saat kurduğu tümen dizininin bu bölgedeki parçası. Sözlük
## yerine bölgenin üstünde tutulur, çünkü dizin her saat bütün tümenler için kurulur ve metin
## anahtarlı sözlük işlemleri ~1100 bölgede belirgin yavaştı. `dizin_damgasi` dizinin hangi
## kuruluşuna ait olduğunu gösterir; eskiyse liste boş sayılır. Yalnızca Oyun kullanır.
var dizin_damgasi: int = -1
var dizin_birlikleri: Array = []
var dizin_ilk_sahip: String = ""
var dizin_cekismeli: bool = false


## Bölgenin bütün çokgenlerini kapsayan sınır kutusu (bildirime dokununca kamerayı
## bölgeye odaklamak için, bkz. HaritaKamerasi.odaklan).
func sinir_kutusu() -> Rect2:
	var kutu: Rect2 = Rect2(etiket, Vector2.ZERO)
	for cokgen: Cokgen in cokgenler:
		kutu = kutu.merge(cokgen.sinir_kutusu)
	return kutu


static func sozlukten(veri: Dictionary) -> Bolge:
	var bolge: Bolge = Bolge.new()
	bolge.id = str(veri.get("id", ""))
	bolge.ev_sahibi = bolge.id.get_slice("_", 0)
	bolge.ad = str(veri.get("ad", bolge.id))
	bolge.sahip = str(veri.get("sahip", ""))
	bolge.baskent = bool(veri.get("baskent", false))
	bolge.nufus = int(veri.get("nufus", 0))
	bolge.kiyi = bool(veri.get("kiyi", false))
	bolge.etiket = Cokgen.noktaya_cevir(veri.get("etiket", []))
	bolge.kara_komsulari = _metin_listesi(veri.get("kara_komsulari", []))
	bolge.deniz_gecisleri = _metin_listesi(veri.get("deniz_gecisleri", []))

	var cokgen_listesi: Array = veri.get("cokgenler", [])
	for nokta_listesi: Array in cokgen_listesi:
		var cokgen: Cokgen = Cokgen.listeden(nokta_listesi, bolge.id)
		if cokgen.noktalar.size() >= 3:
			bolge.cokgenler.append(cokgen)
			bolge.alan += cokgen.alan
	return bolge


static func _metin_listesi(deger: Variant) -> PackedStringArray:
	var sonuc: PackedStringArray = PackedStringArray()
	if deger is Array:
		var liste: Array = deger
		for oge: Variant in liste:
			sonuc.append(str(oge))
	return sonuc
