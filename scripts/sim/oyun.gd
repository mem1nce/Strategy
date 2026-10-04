class_name Oyun
extends RefCounted
## Oyunun durumu: dünya ve oyuncunun seçtiği ülke.
##
## Birlik, savaş ve ekonomi eklendikçe onların durumu da buraya bağlanacak.

## Oyuncu ülkesini seçtiğinde bir kez yayılır.
signal oyuncu_secildi(ulke_id: String)
## Bir tümen yürümeye başladığında ya da vardığında yayılır.
signal birlikler_degisti
## İki ülke arasında savaş ilan edildiğinde yayılır.
signal savas_ilan_edildi(ulke_a: String, ulke_b: String)
## Bir bölgenin sahibi değiştiğinde (ör. boş düşman bölgesi ele geçirilince) yayılır.
signal bolge_sahipligi_degisti

const DENGE_DOSYASI: String = "res://data/balance.json"
## Tümenin güç altına düştüğünde yok sayıldığı eşik.
const ASGARI_GUC: float = 1.0

var dunya: Dunya = null
## Oyuncunun yönettiği ülkenin id'si. Seçim yapılmadıysa boştur.
var oyuncu_ulkesi: String = ""
## Dünyadaki bütün tümenler.
var birlikler: Array[Birlik] = []
## Savaştaki ülke çiftleri. Anahtar iki ülke id'sinin sıralı birleşimidir (bkz. _savas_anahtari).
var _savaslar: Dictionary[String, bool] = {}

# Muharebe sabitleri (data/balance.json -> "savas"); varsayılanlar dosya okunamazsa kullanılır.
var _savunan_avantaji: float = 1.25
var _deniz_cezasi: float = 0.70
var _saatlik_kayip_orani: float = 0.05
var _cekilme_esigi: float = 0.25


func _init(yeni_dunya: Dunya) -> void:
	dunya = yeni_dunya
	birlikler = OrduKurucu.baslangic_birliklerini_olustur(dunya)

	var ayarlar: Dictionary = VeriOkuyucu.sozluk_oku(DENGE_DOSYASI).get("savas", {})
	_savunan_avantaji = float(ayarlar.get("savunan_avantaji", _savunan_avantaji))
	_deniz_cezasi = float(ayarlar.get("deniz_cezasi", _deniz_cezasi))
	_saatlik_kayip_orani = float(ayarlar.get("saatlik_kayip_orani", _saatlik_kayip_orani))
	_cekilme_esigi = float(ayarlar.get("cekilme_esigi", _cekilme_esigi))


## Verilen bölgedeki tümenler.
func bolgedeki_birlikler(bolge_id: String) -> Array[Birlik]:
	var sonuc: Array[Birlik] = []
	for birlik: Birlik in birlikler:
		if birlik.bolge_id == bolge_id:
			sonuc.append(birlik)
	return sonuc


## Verilen tümenleri (hepsi aynı bölgede olmalı) hedef bölgeye yürütür. Süre, YolBulucu'dan
## (kara komşuluğu 24 saat, deniz yolu daha yavaş) gelir. Hedef kendi toprağın değilse,
## yalnızca hedefin sahibiyle savaştaysan kabul edilir. `su_anki_saat`, Zaman.toplam_saat
## değeridir; Oyun'un Zaman autoload'ına bağlı olmadan sınanabilmesi için parametre olarak
## alınır. `tasinacaklar` boşsa ya da yürütme kabul edilmezse false döner.
func birlikleri_yurut(tasinacaklar: Array[Birlik], hedef_bolge_id: String, su_anki_saat: int) -> bool:
	if tasinacaklar.is_empty():
		return false
	var kaynak_bolge_id: String = tasinacaklar[0].bolge_id
	var kaynak_sahibi: Ulke = dunya.bolgenin_sahibi(kaynak_bolge_id)
	var hedef_sahibi: Ulke = dunya.bolgenin_sahibi(hedef_bolge_id)
	if kaynak_sahibi == null or hedef_sahibi == null:
		return false
	if kaynak_sahibi.id != hedef_sahibi.id and not savasta_mi(kaynak_sahibi.id, hedef_sahibi.id):
		return false
	var yol: Array[String] = dunya.yol_bulucu.en_kisa_yol(kaynak_bolge_id, hedef_bolge_id)
	if yol.size() < 2:
		return false
	var sure: float = dunya.yol_bulucu.en_kisa_sure(kaynak_bolge_id, hedef_bolge_id)
	if sure < 0.0:
		return false
	# Son adım deniz yoluysa, muharebede saldırgan deniz cezası alır (bkz. _muharebeyi_coz).
	var onceki_bolge_id: String = yol[yol.size() - 2]
	var denizden: bool = dunya.bolgeler[onceki_bolge_id].deniz_gecisleri.has(hedef_bolge_id)

	var varis: int = su_anki_saat + maxi(1, roundi(sure))
	for birlik: Birlik in tasinacaklar:
		birlik.hedef_bolge_id = hedef_bolge_id
		birlik.varis_saati = varis
		birlik.son_adim_deniz_mi = denizden
	birlikler_degisti.emit()
	return true


## Verilen tümenleri yarıya ayırır ve ayrılan yarıyı döndürür; kalan yarı `stok`ta, aynı
## bölgede kalır. Tek tümen varsa gücü ikiye bölünüp yeni bir tümen oluşturulur (güç 2'den
## azsa bölünemeyecek kadar küçüktür, boş dizi döner). Birden çok tümen varsa sayıca yarısı
## ayrılır (3 tümende 1'i ayrılır, 2'si kalır).
func yariya_ayir(stok: Array[Birlik]) -> Array[Birlik]:
	if stok.is_empty():
		return []
	if stok.size() == 1:
		var tek: Birlik = stok[0]
		if tek.guc < 2.0:
			return []
		var yeni: Birlik = Birlik.new()
		yeni.sahip = tek.sahip
		yeni.bolge_id = tek.bolge_id
		yeni.guc = tek.guc / 2.0
		tek.guc -= yeni.guc
		birlikler.append(yeni)
		birlikler_degisti.emit()
		return [yeni]
	return stok.slice(0, stok.size() / 2)


## Zaman ilerledikçe çağrılır; varış saatine ulaşan tümenleri hedeflerine taşır. Boş bir
## düşman bölgesine varan tümen orayı ele geçirir. Ardından bütün muharebeler bir saat ilerler.
func saat_ilerledi(su_anki_saat: int) -> void:
	var tasima_oldu: bool = false
	for birlik: Birlik in birlikler:
		if birlik.yuruyor_mu() and su_anki_saat >= birlik.varis_saati:
			birlik.bolge_id = birlik.hedef_bolge_id
			birlik.hedef_bolge_id = ""
			birlik.varis_saati = -1
			tasima_oldu = true
			if _bos_dusman_bolgesini_isgal_et(birlik):
				bolge_sahipligi_degisti.emit()
	if tasima_oldu:
		birlikler_degisti.emit()
	_muharebeleri_isle()


## Gelen tümen, savaşta olduğu ve içinde savunan (bölgenin o anki sahibine ait) tümen
## kalmamış bir düşman bölgesine girdiyse orayı ele geçirir. Savunan varsa (muharebe
## sürüyorsa) işgal gerçekleşmez.
func _bos_dusman_bolgesini_isgal_et(gelen: Birlik) -> bool:
	var bolge: Bolge = dunya.bolgeler.get(gelen.bolge_id)
	if bolge == null or bolge.sahip == gelen.sahip or not savasta_mi(bolge.sahip, gelen.sahip):
		return false
	for digeri: Birlik in bolgedeki_birlikler(gelen.bolge_id):
		if digeri.sahip == bolge.sahip:
			return false
	bolge.sahip = gelen.sahip
	return true


## Birden çok ülkenin tümeni bulunan (dolayısıyla savaşan) her bölgede muharebeyi bir saat
## ilerletir.
func _muharebeleri_isle() -> void:
	var bolge_gruplari: Dictionary[String, Array] = {}
	for birlik: Birlik in birlikler:
		if birlik.yuruyor_mu():
			continue
		if not bolge_gruplari.has(birlik.bolge_id):
			bolge_gruplari[birlik.bolge_id] = [] as Array[Birlik]
		(bolge_gruplari[birlik.bolge_id] as Array[Birlik]).append(birlik)

	for bolge_id: String in bolge_gruplari:
		var katilanlar: Array[Birlik] = bolge_gruplari[bolge_id]
		var sahipler: Dictionary[String, bool] = {}
		for birlik: Birlik in katilanlar:
			sahipler[birlik.sahip] = true
		if sahipler.size() > 1:
			_muharebeyi_coz(dunya.bolgeler[bolge_id], katilanlar)


## Bir bölgedeki muharebeyi bir saat ilerletir: her iki taraf, karşı tarafın etkin (bonus/
## ceza uygulanmış) toplam gücüyle orantılı kayıp alır. Savunan %25 avantajlıdır; son adımı
## deniz yoluyla gelen saldırgan tümenler %30 cezalıdır. Güç ASGARI_GUC altına düşen tümen
## yok sayılır. Bir taraf tükenirse ya da belirgin biçimde geride kalırsa (CEKILME_ESIGI)
## geri çekilir: en yakın dost komşu bölgeye taşınır, yoksa yok olur. Savunan tükenir ya da
## çekilirse (ikisinde de bölgede artık savunan kalmaz) bölge hemen saldırganın olur.
func _muharebeyi_coz(bolge: Bolge, katilanlar: Array[Birlik]) -> void:
	var savunanlar: Array[Birlik] = []
	var saldiranlar: Array[Birlik] = []
	for birlik: Birlik in katilanlar:
		if birlik.sahip == bolge.sahip:
			savunanlar.append(birlik)
		else:
			saldiranlar.append(birlik)
	if savunanlar.is_empty() or saldiranlar.is_empty():
		return

	var savunan_guc: float = _toplam_guc(savunanlar)
	var saldiran_guc: float = 0.0
	for birlik: Birlik in saldiranlar:
		saldiran_guc += birlik.guc * (_deniz_cezasi if birlik.son_adim_deniz_mi else 1.0)
	var etkin_savunan: float = savunan_guc * _savunan_avantaji

	_guc_azalt(savunanlar, saldiran_guc * _saatlik_kayip_orani)
	_guc_azalt(saldiranlar, etkin_savunan * _saatlik_kayip_orani)
	_olenleri_temizle(savunanlar)
	_olenleri_temizle(saldiranlar)
	birlikler_degisti.emit()

	if saldiranlar.is_empty():
		return  # Saldırgan tükendi; savunan (varsa) bölgede kalır.
	if savunanlar.is_empty():
		bolge.sahip = saldiranlar[0].sahip
		bolge_sahipligi_degisti.emit()
		return

	# Taraflardan biri belirgin şekilde geride kaldıysa geri çekilir. Savunan çekilirse
	# bölgeyi fiilen terk etmiş olur; bölge hemen saldırganın olur (boş bölge gibi).
	var yeni_savunan_guc: float = _toplam_guc(savunanlar)
	var yeni_saldiran_guc: float = _toplam_guc(saldiranlar)
	if yeni_savunan_guc < _cekilme_esigi * yeni_saldiran_guc:
		_geri_cek(savunanlar, bolge.id)
		bolge.sahip = saldiranlar[0].sahip
		bolge_sahipligi_degisti.emit()
	elif yeni_saldiran_guc < _cekilme_esigi * yeni_savunan_guc:
		_geri_cek(saldiranlar, bolge.id)


func _toplam_guc(liste: Array[Birlik]) -> float:
	var toplam: float = 0.0
	for birlik: Birlik in liste:
		toplam += birlik.guc
	return toplam


## Verilen toplam kaybı listedeki tümenlere, güçleriyle orantılı dağıtır.
func _guc_azalt(liste: Array[Birlik], toplam_kayip: float) -> void:
	var toplam_guc: float = _toplam_guc(liste)
	if toplam_guc <= 0.0:
		return
	var oran: float = minf(1.0, toplam_kayip / toplam_guc)
	for birlik: Birlik in liste:
		birlik.guc -= birlik.guc * oran


## Güç altına düşen tümenleri hem verilen listeden hem de Oyun.birlikler'den siler.
func _olenleri_temizle(liste: Array[Birlik]) -> void:
	var i: int = liste.size() - 1
	while i >= 0:
		if liste[i].guc < ASGARI_GUC:
			birlikler.erase(liste[i])
			liste.remove_at(i)
		i -= 1


## Listedeki her tümeni kendi ülkesine ait en yakın (ilk bulunan) komşu bölgeye çeker;
## öyle bir komşu yoksa tümen yok olur.
func _geri_cek(liste: Array[Birlik], bolge_id: String) -> void:
	for birlik: Birlik in liste.duplicate():
		var hedef: Bolge = null
		for komsu: Bolge in dunya.bolgenin_komsulari(bolge_id):
			if komsu.sahip == birlik.sahip:
				hedef = komsu
				break
		if hedef != null:
			birlik.bolge_id = hedef.id
		else:
			birlikler.erase(birlik)


## İki ülke savaşta mı?
func savasta_mi(ulke_a: String, ulke_b: String) -> bool:
	return _savaslar.has(_savas_anahtari(ulke_a, ulke_b))


## Savaş ilan eder. Yalnızca doğrudan (kara ya da deniz yoluyla) komşu, henüz savaşılmayan,
## var olan iki farklı ülke arasında kabul edilir. Kabul edilirse true döner.
func savas_ilan_et(ilan_eden: String, hedef: String) -> bool:
	if ilan_eden == hedef or not dunya.ulkeler.has(ilan_eden) or not dunya.ulkeler.has(hedef):
		return false
	if savasta_mi(ilan_eden, hedef) or not dunya.ulkeler_komsu_mu(ilan_eden, hedef):
		return false
	_savaslar[_savas_anahtari(ilan_eden, hedef)] = true
	savas_ilan_edildi.emit(ilan_eden, hedef)
	return true


func _savas_anahtari(ulke_a: String, ulke_b: String) -> String:
	return "%s|%s" % [ulke_a, ulke_b] if ulke_a < ulke_b else "%s|%s" % [ulke_b, ulke_a]


func oyuncu_secildi_mi() -> bool:
	return oyuncu_ulkesi != ""


## Oyuncunun ülkesini belirler. Ülke yalnızca bir kez seçilebilir.
## Seçim geçerliyse true döner.
func oyuncuyu_sec(ulke_id: String) -> bool:
	if oyuncu_secildi_mi() or not dunya.ulkeler.has(ulke_id):
		return false
	oyuncu_ulkesi = ulke_id
	oyuncu_secildi.emit(ulke_id)
	return true
