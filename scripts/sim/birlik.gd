class_name Birlik
extends RefCounted
## Tek bir tümen: belirli bir ülkeye ait, bir bölgede duran birlik.
##
## Tek birlik türü (bkz. TASARIM.md 7. Birlikler). Güç 0-100 arasıdır; muharebe ve bakım
## ileride bunu değiştirecek.

var sahip: String = ""
var bolge_id: String = ""
var guc: float = 0.0
