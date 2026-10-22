class_name InsaIsi
extends RefCounted
## Bir ülkenin üretim kuyruğundaki tek bir iş: yeni tümen, fabrika, tahkimat ya da liman (bkz. Oyun).

enum Tur { TUMEN, FABRIKA, TAHKIMAT, LIMAN }

var tur: Tur = Tur.TUMEN
var sahip: String = ""
var bolge_id: String = ""
## Tümen işinde kurulacak tümenin türü (bkz. BirlikTurleri); başka işlerde kullanılmaz.
var birlik_turu: String = BirlikTurleri.VARSAYILAN
## Yalnızca kuyruğun önündeki iş ilerler (tek kuyruk); kalan saat 0 olunca iş tamamlanır.
var kalan_saat: int = 0
## Maden açığında iş saatte 1'den az ilerler (bkz. Piyasa.insaat_hizi); ilerlemenin küsuratı
## burada birikir, 1'i geçince kalan saat bir azalır.
var kesir: float = 0.0
