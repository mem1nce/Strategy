class_name Gorunurluk
extends RefCounted
## Savaş sisi: bir ülkenin hangi bölgeleri "gördüğü".
##
## Bir ülke şunları görür: kendi bölgeleri, kendi tümenlerinin bulunduğu bölgeler ve bunlara
## kara ya da deniz yoluyla komşu bölgeler. Görünmeyen bölgelerde başka ülkelerin tümenleri ve
## muharebeleri bilinmez; bölgelerin kime ait olduğu ise her zaman bilinir. Oyuncu da yapay
## zekâ da bu kuralla görür (bkz. Oyun.oyuncu_bolgeyi_goruyor_mu, Oyun._yz_gorunur_bolgeler).


## `birlik_bolgeleri`: ülkenin tümenlerinin bulunduğu bölge id'leri (anahtar olarak).
## Dönen sözlüğün anahtarları görünen bölge id'leridir.
static func gorunur_bolgeler(dunya: Dunya, ulke_id: String, birlik_bolgeleri: Dictionary) -> Dictionary[String, bool]:
	var kaynaklar: Dictionary[String, bool] = {}
	for bolge: Bolge in dunya.ulkenin_bolgeleri(ulke_id):
		kaynaklar[bolge.id] = true
	for bolge_id: String in birlik_bolgeleri:
		kaynaklar[bolge_id] = true
	var sonuc: Dictionary[String, bool] = {}
	for bolge_id: String in kaynaklar:
		var bolge: Bolge = dunya.bolgeler.get(bolge_id)
		if bolge == null:
			continue
		sonuc[bolge_id] = true
		for komsu_id: String in bolge.kara_komsulari:
			sonuc[komsu_id] = true
		for komsu_id: String in bolge.deniz_gecisleri:
			sonuc[komsu_id] = true
	return sonuc
