class_name Birlik
extends RefCounted
## Tek bir tümen: belirli bir ülkeye ait, bir bölgede duran birlik.
##
## Türü piyade, zırhlı ya da topçudur (bkz. BirlikTurleri). Güç 0-100 arasıdır; muharebe
## ve bakım bunu azaltır.

var sahip: String = ""
## "piyade", "zirhli" ya da "topcu" (bkz. BirlikTurleri).
var tur: String = BirlikTurleri.VARSAYILAN
var bolge_id: String = ""
var guc: float = 0.0
## Yürüyorsa gideceği bölge; durağansa boştur.
var hedef_bolge_id: String = ""
## Yürüyorsa vardığı an (Zaman.toplam_saat cinsinden); durağansa -1.
var varis_saati: int = -1
## Son emrinin son adımı deniz yoluyla mıydı? Muharebede saldırgan deniz cezası için.
var son_adim_deniz_mi: bool = false


func yuruyor_mu() -> bool:
	return hedef_bolge_id != ""
