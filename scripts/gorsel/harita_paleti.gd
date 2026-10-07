class_name HaritaPaleti
extends RefCounted
## Ülke renkleri. Haritadan bağımsız tutulur ki bayraklar, arayüz ve sınama betikleri
## haritayı (ve onun bağlı olduğu Zaman autoload'unu) yüklemeden ülke rengini bulabilsin.

## Ülkelerin renk indeksine (1-9) karşılık gelen dokuz sakin renk.
const PALET: Array[Color] = [
	Color("#c97b6b"), Color("#d9a066"), Color("#d8c878"),
	Color("#9dbb6f"), Color("#6fae8f"), Color("#6fa8b8"),
	Color("#7f8fc4"), Color("#a584bd"), Color("#c487a6"),
]


## Ülkenin haritadaki rengi.
static func ulke_rengi(ulke: Ulke) -> Color:
	return PALET[posmod(ulke.renk_indeksi - 1, PALET.size())]
