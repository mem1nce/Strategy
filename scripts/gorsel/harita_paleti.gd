class_name HaritaPaleti
extends RefCounted
## Ülke renkleri. Haritadan bağımsız tutulur ki bayraklar, arayüz ve sınama betikleri
## haritayı (ve onun bağlı olduğu Zaman autoload'unu) yüklemeden ülke rengini bulabilsin.

## Ülkelerin renk indeksine (1-9; Natural Earth MAPCOLOR9, komşular farklı indeks alır)
## karşılık gelen dokuz renk. Hangi iki indeks komşu olursa olsun ayırt edilsinler diye ton
## çemberine yayılır ve ton olarak yakın olanların açıklığı farklıdır (ör. koyu yeşim ile açık
## gök mavisi). Kabartma çarpılınca koyulaşacakları için orta-açık tutuldular; koyu lacivert
## denizden ve altın vurgudan ayrışırlar.
const PALET: Array[Color] = [
	Color("#D2604F"), Color("#E8914A"), Color("#E3D06C"),
	Color("#8DBA5A"), Color("#3F9C78"), Color("#6CBCD4"),
	Color("#5E70C4"), Color("#B48AD2"), Color("#C2577F"),
]


## Harita modları (haritanın sol kenarındaki düğmeler): siyasi (ülke renkleri), diplomasi
## (oyuncuya göre: kendisi / savaştığı / tarafsız) ve ekonomi (bölgelerin sanayisi).
enum Mod { SIYASI, DIPLOMASI, EKONOMI }

## Diplomasi modu renkleri. İttifak olmadığı için müttefik rengi yoktur.
const BEN_RENGI: Color = Color("#4FB985")
const DUSMAN_RENGI: Color = Color("#E25B5B")
const TARAFSIZ_RENGI: Color = Color("#8A93A6")
## Ekonomi modu: sanayisi azdan çoğa giden renk merdiveni.
const EKONOMI_MERDIVENI: Array[Color] = [
	Color("#2A3546"), Color("#2F6F7C"), Color("#8DBA5A"), Color("#E6AE48"), Color("#FFE6A6"),
]


## Ülkenin haritadaki rengi.
static func ulke_rengi(ulke: Ulke) -> Color:
	return PALET[posmod(ulke.renk_indeksi - 1, PALET.size())]


## Ekonomi modunda 0 (sanayisiz) ile 1 (en sanayili bölge) arasındaki değerin rengi.
static func ekonomi_rengi(oran: float) -> Color:
	var t: float = clampf(oran, 0.0, 1.0) * (EKONOMI_MERDIVENI.size() - 1)
	var i: int = mini(int(t), EKONOMI_MERDIVENI.size() - 2)
	return EKONOMI_MERDIVENI[i].lerp(EKONOMI_MERDIVENI[i + 1], t - i)
