class_name InsaIsi
extends RefCounted
## Bir ülkenin üretim kuyruğundaki tek bir iş: yeni tümen ya da fabrika (bkz. Oyun).

enum Tur { TUMEN, FABRIKA }

var tur: Tur = Tur.TUMEN
var sahip: String = ""
var bolge_id: String = ""
## Yalnızca kuyruğun önündeki iş ilerler (tek kuyruk); kalan saat 0 olunca iş tamamlanır.
var kalan_saat: int = 0
