class_name InsaIsi
extends RefCounted
## Bir ülkenin üretim kuyruğundaki tek bir iş: yeni tümen, fabrika ya da tahkimat (bkz. Oyun).

enum Tur { TUMEN, FABRIKA, TAHKIMAT }

var tur: Tur = Tur.TUMEN
var sahip: String = ""
var bolge_id: String = ""
## Tümen işinde kurulacak tümenin türü (bkz. BirlikTurleri); başka işlerde kullanılmaz.
var birlik_turu: String = BirlikTurleri.VARSAYILAN
## Yalnızca kuyruğun önündeki iş ilerler (tek kuyruk); kalan saat 0 olunca iş tamamlanır.
var kalan_saat: int = 0
