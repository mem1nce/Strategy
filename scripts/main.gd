extends Node2D
## Ana sahne: dünya verisini yükler, harita görünümünü, kamerayı ve arayüzü kurup
## birbirine bağlar. Sahne ağacı burada script'ten kurulur.

## Haritanın üst ve alt kenarının, arayüzün altından çıkarılabilmesi için ekranın
## içine çekilebileceği pay (piksel). Üst çubuğun ve alt panelin yüksekliğine göre seçildi.
const UST_BOSLUK: float = 180.0
const ALT_BOSLUK: float = 340.0
## Dokunulan noktada bölge yoksa bu yarıçap içindeki en yakın bölge seçilir (ekran pikseli).
const YAKIN_DOKUNMA_YARICAPI: float = 30.0

## "--ekran-goruntusu <dosya>" komut satırı argümanı; harita yerleşsin diye biraz beklenir,
## sonra ekran PNG olarak kaydedilip oyun kapanır. Çağırmak için (proje klasöründen):
##   Godot --path . -- --ekran-goruntusu /tam/yol/goruntu.png
const EKRAN_GORUNTUSU_BAYRAGI: String = "--ekran-goruntusu"
const EKRAN_GORUNTUSU_BEKLEME_SANIYE: float = 2.0

var _oyun: Oyun = null
var _harita: HaritaGorunumu = null
var _kamera: HaritaKamerasi = null
var _arayuz: Arayuz = null
var _ana_menu: AnaMenu = null
var _ses: SesYoneticisi = null
## Açılışta bulunan kayıt (varsa); "Devam et" seçilince uygulanır (bkz. _devam_secildi).
var _bekleyen_kayit: Dictionary = {}
## Birlik kartı açıkken, kartta gösterilen (ve bir sonraki hedef seçiminde yürütülecek)
## tümenler; seçim yoksa boştur. "Yarısını ayır" bu listeyi küçültebilir.
var _secili_birlikler: Array[Birlik] = []
## Alt panelde gösterilen bölgenin id'si; "Tümen kur" / "Fabrika kur" bu bölgeye sıralanır.
var _secili_bolge_id: String = ""


func _ready() -> void:
	# Zaman bir autoload'dır ve sahne yeniden yüklenince (geri tuşuyla ana menüye dönüş) eski
	# saatini korur; her açılışta baştan, kilitli ve durmuş başlar (kayıt varsa sonra uygulanır).
	Zaman.durumu_uygula({})
	Ayarlar.yukle()
	_ses = SesYoneticisi.new()
	_ses.name = "Ses"
	add_child(_ses)
	# Bundan sonra eklenen her düğme basılınca tepki verir ve tıklama sesi çıkarır; her panel
	# görünür olunca solarak belirir (bkz. Gecis).
	get_tree().node_added.connect(_dugum_eklendi)

	var dunya: Dunya = Dunya.yukle()
	if dunya == null:
		push_error("Dünya verisi yüklenemedi; oyun başlatılamıyor.")
		return
	_oyun = Oyun.new(dunya)
	_bekleyen_kayit = KayitYoneticisi.yukle()
	_oyun.oyuncu_secildi.connect(_oyuncu_secildi)
	_oyun.birlikler_degisti.connect(_birlikler_degisti)
	_oyun.hazine_degisti.connect(_hazine_degisti)
	_oyun.oyun_kazanildi.connect(_oyun_kazanildi)
	_oyun.oyun_kaybedildi.connect(_oyun_kaybedildi)
	Zaman.saat_gecti.connect(_oyun.saat_ilerledi)
	Zaman.saat_gecti.connect(func(_saat: int) -> void: _uretimi_guncelle())
	Zaman.saat_gecti.connect(func(_saat: int) -> void: _teknoloji_ilerlemesini_guncelle())
	Zaman.gun_basladi.connect(func(gun: int) -> void: _oyun.gun_basladi(gun * 24))
	Zaman.gun_basladi.connect(func(gun: int) -> void: _harita.isgalleri_yenile(gun * 24))
	Zaman.gun_basladi.connect(func(_gun: int) -> void: _otomatik_kaydet())
	_oyun.insa_kuyrugu_degisti.connect(func(ulke_id: String) -> void:
		if ulke_id == _oyun.oyuncu_ulkesi:
			_uretimi_guncelle())

	_harita = HaritaGorunumu.new()
	_harita.name = "Harita"
	add_child(_harita)
	_harita.kur(dunya, _oyun)
	_oyun.bolge_sahipligi_degisti.connect(_harita.yenile)
	_oyun.savas_ilan_edildi.connect(func(_a: String, _b: String) -> void: _harita.savaslari_yenile())
	_oyun.baris_yapildi.connect(func(_a: String, _b: String) -> void: _harita.savaslari_yenile())
	_oyun.tahkimat_degisti.connect(_tahkimat_degisti)
	_oyun.gorunurluk_degisti.connect(_gorunurluk_degisti)
	_oyun.bolge_el_degistirdi.connect(_bolge_el_degistirdi)
	_oyun.muharebe_basladi.connect(_muharebe_basladi)
	_oyun.insa_tamamlandi.connect(func(ulke_id: String, _bolge_id: String) -> void:
		if ulke_id == _oyun.oyuncu_ulkesi:
			_ses.cal("uretim"))
	_oyun.savas_ilan_edildi.connect(func(a: String, b: String) -> void:
		if _oyun.oyuncu_ulkesi in [a, b]:
			_ses.cal("savas_ilani"))
	_oyun.ulke_teslim_oldu.connect(_ulke_teslim_oldu)

	_kamera = HaritaKamerasi.new()
	_kamera.name = "Kamera"
	add_child(_kamera)
	_kamera.gorunum_degisti.connect(_gorunum_degisti)
	_kamera.dokunuldu.connect(_haritaya_dokunuldu)
	_kamera.kur(Rect2(Vector2.ZERO, dunya.boyut), UST_BOSLUK, ALT_BOSLUK)

	_arayuz = Arayuz.new()
	_arayuz.name = "Arayuz"
	add_child(_arayuz)
	_arayuz.kur(dunya)
	_arayuz.oyna_istendi.connect(_oyun.oyuncuyu_sec)
	_arayuz.komsular_degisti.connect(_harita.komsulari_goster)
	_arayuz.yarisini_ayir_istendi.connect(_yarisini_ayir_istendi)
	_arayuz.insa_istendi.connect(_insa_istendi)
	_arayuz.tumen_istendi.connect(_tumen_istendi)
	InsaDugmeleri.maliyetleri_ayarla(_oyun.fabrika_maliyeti(), _oyun.tahkimat_azami_seviye())
	_arayuz.teknoloji_istendi.connect(_teknolojiyi_ac)
	_arayuz.arastirma_istendi.connect(_arastirma_istendi)
	_oyun.teknoloji_degisti.connect(func(ulke_id: String) -> void:
		if ulke_id == _oyun.oyuncu_ulkesi and _arayuz.teknoloji_acik_mi():
			_teknolojiyi_goster())
	_arayuz.savas_istendi.connect(_savas_istendi)
	_arayuz.baris_istendi.connect(_baris_istendi)
	_arayuz.yz_yonetimi_degisti.connect(func(acik: bool) -> void: _oyun.yz_oyuncuyu_yonetsin = acik)
	_arayuz.siralama_istendi.connect(func() -> void: _arayuz.siralamayi_goster(_oyun.guc_siralamasi(), _oyun.oyuncu_ulkesi))
	_arayuz.bildirime_dokunuldu.connect(_bildirime_dokunuldu)
	_arayuz.menuye_donus_istendi.connect(_menuye_don)
	Zaman.durum_degisti.connect(_guc_modunu_guncelle)
	_guc_modunu_guncelle()
	_oyun.bildirim_gonder.connect(_arayuz.bildirim_goster)

	_ana_menu = AnaMenu.new()
	_ana_menu.name = "AnaMenu"
	add_child(_ana_menu)
	_ana_menu.kur()
	_ana_menu.yeni_oyun_istendi.connect(_yeni_oyun_secildi)
	_ana_menu.devam_istendi.connect(_devam_secildi)
	_ana_menu.goster(not _bekleyen_kayit.is_empty(),
			_bekleyen_kayit.is_empty() and KayitYoneticisi.eski_kayit_mi())

	print("Dünya yüklendi: %d ülke, %d bölge, %d çokgen, üçgenlenemeyen %d." % [
		dunya.ulke_listesi.size(), dunya.bolge_listesi.size(), dunya.cokgenler.size(),
		_harita.ucgenlenemeyenler.size()])

	_ekran_goruntusu_istendiyse_kaydet()


## Sahneye eklenen her düğüme sunum katmanının ortak tepkilerini bağlar: düğmeler basılınca
## hafifçe küçülür ve tıklama sesi çıkarır, paneller görünür olunca solarak belirir.
func _dugum_eklendi(dugum: Node) -> void:
	if dugum is BaseButton:
		Gecis.dugmeyi_bagla(dugum)
		(dugum as BaseButton).pressed.connect(func() -> void: _ses.cal("tiklama"))
	elif dugum is PanelContainer:
		Gecis.belirmeyi_bagla(dugum)


## Bir bölge el değiştirdi: görünüyorsa kısa bir parlama; oyuncu aldıysa ses.
func _bolge_el_degistirdi(bolge_id: String, _eski: String, yeni: String) -> void:
	_harita.parlat(bolge_id)
	if yeni == _oyun.oyuncu_ulkesi and yeni != "":
		_ses.cal("ele_gecirme")


## Yeni bir muharebe başladı: oyuncunun bölgesinde ya da oyuncunun tümenleriyle olduysa ses.
func _muharebe_basladi(bolge_id: String) -> void:
	if not _oyun.oyuncu_secildi_mi() or not _oyun.oyuncu_bolgeyi_goruyor_mu(bolge_id):
		return
	var ilgili: bool = _oyun.dunya.bolgeler[bolge_id].sahip == _oyun.oyuncu_ulkesi
	if not ilgili:
		for birlik: Birlik in _oyun.bolgedeki_birlikler(bolge_id):
			if birlik.sahip == _oyun.oyuncu_ulkesi:
				ilgili = true
				break
	if ilgili:
		_ses.cal("muharebe")


## Oyuncunun savaştığı bir ülke teslim olunca tam ekran şerit ve ses.
func _ulke_teslim_oldu(ulke_id: String, _galip_id: String) -> void:
	if ulke_id == _oyun.oyuncu_ulkesi or not _oyun.savasta_mi(_oyun.oyuncu_ulkesi, ulke_id):
		return
	_arayuz.serit_goster("%s TESLİM OLDU" % _oyun.dunya.ulkeler[ulke_id].ad.to_upper(), ArayuzTemasi.ETKIN_RENK)
	_ses.cal("ele_gecirme")


## Uygulama arka plana geçtiğinde (telefonda) ya da kapatılmak istendiğinde (bilgisayarda)
## otomatik kaydeder.
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED:
		# Telefonda arka plana geçince oyun durur ve kaydedilir.
		Zaman.durdur()
		_otomatik_kaydet()
	elif what == NOTIFICATION_WM_CLOSE_REQUEST:
		_otomatik_kaydet()
	elif what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_geri_istendi()


## Android geri tuşu: önce açık pencere/paneli kapatır, sonra seçimi kaldırır; ikisi de yoksa
## "Ana menüye dönülsün mü?" diye sorar. Ana menüdeyken (alt paneli yoksa) uygulamadan çıkar.
func _geri_istendi() -> void:
	if _ana_menu.gorunur_mu():
		if not _ana_menu.geri_basildi():
			get_tree().quit()
		return
	if _arayuz.acik_paneli_kapat():
		return
	if _secili_bolge_id != "" or not _secili_birlikler.is_empty():
		_bolgeyi_sec("")
		return
	_arayuz.menuye_donus_sor()


## Onaylanınca oyun kaydedilir ve sahne baştan yüklenir: ana menü "Devam et" etkin açılır.
func _menuye_don() -> void:
	_otomatik_kaydet()
	Zaman.durdur()
	get_tree().reload_current_scene()


## Oyun durmuşken (ya da ülke seçilmeden) işlemci az kullanılır ve ekran kapanabilir; zaman
## akarken ekran kapanmaz.
func _guc_modunu_guncelle() -> void:
	var akiyor: bool = not Zaman.durdu and not Zaman.kilitli
	OS.low_processor_usage_mode = not akiyor
	DisplayServer.screen_set_keep_on(akiyor)


## Oyuncu henüz ülkesini seçmediyse kaydedecek bir ilerleme yoktur.
func _otomatik_kaydet() -> void:
	if _oyun != null and _oyun.oyuncu_secildi_mi():
		KayitYoneticisi.kaydet(_oyun, Zaman.durumu_al())


## Ana menüde "Yeni oyun" onaylandı (AnaMenu eski kaydı zaten sildi). _oyun ve dünya hiç
## kayıt uygulanmadan taze kurulmuştu; yalnızca seçilen savaş sisi tercihi uygulanır, oyuncu
## normal "Ülkeni seç" akışıyla karşılaşır.
func _yeni_oyun_secildi(savas_sisi: bool) -> void:
	_oyun.savas_sisi = savas_sisi


## Ana menüde "Devam et" seçildi: açılışta okunan kaydı şimdi uygular.
func _devam_secildi() -> void:
	_oyun.kayittan_yukle(_bekleyen_kayit["oyun_verisi"])
	Zaman.durumu_uygula(_bekleyen_kayit["zaman_durumu"])
	_oyuncu_secildi(_oyun.oyuncu_ulkesi)
	_arayuz.yz_yonetimini_goster(_oyun.yz_oyuncuyu_yonetsin)


## Bir bildirim kartına dokunulunca kamerayı ilgili bölgeye odaklar (bölge id'si boşsa
## ya da artık yoksa bir şey yapmaz — bildirim kartı zaten BildirimKutusu'nda kapanmıştı).
func _bildirime_dokunuldu(bolge_id: String) -> void:
	var bolge: Bolge = _oyun.dunya.bolgeler.get(bolge_id)
	if bolge != null:
		_kamera.odaklan(bolge.sinir_kutusu())


## Kamera her kaydığında ya da yakınlaştığında haritaya yeni görünümü bildirir.
func _gorunum_degisti() -> void:
	_harita.gorunumu_ayarla(_kamera.position, _kamera.zoom.x, get_viewport_rect().size)


## Dokunulan bölgeyi seçer. Tam o noktada bölge yoksa yakındaki en yakın bölgeye bakılır
## (küçük bölgeler ve adalar için). O da yoksa seçim kalkar.
func _haritaya_dokunuldu(dunya_konumu: Vector2) -> void:
	var cokgen: Cokgen = _oyun.dunya.noktadaki_cokgen(dunya_konumu)
	if cokgen == null:
		cokgen = _oyun.dunya.en_yakin_cokgen(dunya_konumu, YAKIN_DOKUNMA_YARICAPI / _kamera.zoom.x)
	_bolgeyi_sec(cokgen.bolge_id if cokgen != null else "")


## Bölgeyi haritada vurgular ve alt panelde gösterir. Boş id seçimi kaldırır.
##
## Birlik kartı açıkken (bkz. _secili_birlikler) başka bir bölgeye dokunmak, karttaki
## tümenleri dokunulan bölgeye yürütme emri olarak yorumlanır; emir kabul edilmezse
## (ör. düşman toprağı) dokunulan bölge normal şekilde gösterilir. Aksi hâlde, oyuncunun
## kendi tümenlerinin olduğu bir bölgeyse bölge paneli yerine birlik paneli açılır.
func _bolgeyi_sec(bolge_id: String) -> void:
	if not _secili_birlikler.is_empty() and bolge_id != "" and bolge_id != _secili_birlikler[0].bolge_id:
		if _oyun.birlikleri_yurut(_secili_birlikler, bolge_id, Zaman.toplam_saat):
			_ses.cal("emir")
			_secili_birlikler = []
			_secili_bolge_id = ""
			_harita.secimi_ayarla("")
			_arayuz.bolgeyi_goster(null, false)
			return

	var bolge: Bolge = _oyun.dunya.bolgeler.get(bolge_id)
	_secili_bolge_id = bolge_id if bolge != null else ""
	_harita.secimi_ayarla(bolge_id)
	_tahkimat_dugmesini_guncelle()
	var kendi_bolgen: bool = bolge != null and _oyun.oyuncu_secildi_mi() and bolge.sahip == _oyun.oyuncu_ulkesi
	if kendi_bolgen:
		var birlikler: Array[Birlik] = _oyun.bolgedeki_birlikler(bolge_id)
		if not birlikler.is_empty():
			_arayuz.birligi_goster(bolge, birlikler, _oyun.dunya.ulkeler[_oyun.oyuncu_ulkesi])
			_secili_birlikler = birlikler
			return
	_secili_birlikler = []
	var yabanci_bolge: bool = bolge != null and _oyun.oyuncu_secildi_mi() and bolge.sahip != _oyun.oyuncu_ulkesi
	var savasta: bool = yabanci_bolge and _oyun.savasta_mi(_oyun.oyuncu_ulkesi, bolge.sahip)
	var savas_dugmesi_gorunur: bool = yabanci_bolge and not savasta \
			and _oyun.dunya.ulkeler_komsu_mu(_oyun.oyuncu_ulkesi, bolge.sahip)
	_arayuz.bolgeyi_goster(bolge, not _oyun.oyuncu_secildi_mi(), savas_dugmesi_gorunur, savasta, kendi_bolgen)
	if bolge != null:
		_arayuz.bolge_birliklerini_yaz(_birlik_bilgisi(bolge), _oyun.oyuncu_bolgeyi_goruyor_mu(bolge.id))


## Bölge panelindeki birlik satırı. Savaş sisi altında görünmeyen bölge için "bilinmiyor".
func _birlik_bilgisi(bolge: Bolge) -> String:
	if not _oyun.oyuncu_bolgeyi_goruyor_mu(bolge.id):
		return "Birlikler: bilinmiyor"
	var birlikler: Array[Birlik] = _oyun.bolgedeki_birlikler(bolge.id)
	if birlikler.is_empty():
		return "Birlikler: yok"
	var guc: float = 0.0
	for birlik: Birlik in birlikler:
		guc += birlik.guc
	return "Birlikler: %d (güç %d)" % [birlikler.size(), roundi(guc)]


## Oyuncunun gördüğü bölgeler değişti: harita karartmasını ve açık bölge panelini yeniler.
func _gorunurluk_degisti() -> void:
	_harita.sisi_yenile()
	if _secili_bolge_id != "" and _secili_birlikler.is_empty():
		var bolge: Bolge = _oyun.dunya.bolgeler[_secili_bolge_id]
		_arayuz.bolge_birliklerini_yaz(_birlik_bilgisi(bolge), _oyun.oyuncu_bolgeyi_goruyor_mu(bolge.id))


## Bölge ya da birlik panelinde "Fabrika kur" / "Tahkimat kur"a basıldı: seçili (kendi)
## bölgede iş sıralanır. Kabul edilmezse nedeni bildirim olarak gösterilir.
func _insa_istendi(tur: String) -> void:
	if _secili_bolge_id == "" or not _oyun.oyuncu_secildi_mi():
		return
	var ulke_id: String = _oyun.oyuncu_ulkesi
	if tur == "tahkimat":
		var seviye: int = _oyun.sonraki_tahkimat_seviyesi(ulke_id, _secili_bolge_id)
		_siralama_sonucunu_bildir(_oyun.tahkimat_sirala(ulke_id, _secili_bolge_id), "Tahkimat",
				_oyun.tahkimat_maliyeti(seviye))
		_tahkimat_dugmesini_guncelle()
	else:
		_siralama_sonucunu_bildir(_oyun.fabrika_sirala(ulke_id, _secili_bolge_id), "Fabrika",
				_oyun.fabrika_maliyeti(ulke_id))


## Tür seçim panelinde bir tümen türü seçildi: seçili (kendi) bölgede o türde tümen sıralanır.
func _tumen_istendi(birlik_turu: String) -> void:
	if _secili_bolge_id == "" or not _oyun.oyuncu_secildi_mi():
		return
	_siralama_sonucunu_bildir(_oyun.tumen_sirala(_oyun.oyuncu_ulkesi, _secili_bolge_id, birlik_turu),
			"%s tümen" % BirlikTurleri.ad(birlik_turu), _oyun.tumen_maliyeti(birlik_turu, _oyun.oyuncu_ulkesi))


func _siralama_sonucunu_bildir(kabul: bool, ad: String, maliyet: float) -> void:
	_ses.cal("onay" if kabul else "hata")
	if kabul:
		_arayuz.bildirim_goster("%s sıraya alındı: %s." % [ad, _oyun.dunya.bolgeler[_secili_bolge_id].ad],
				_secili_bolge_id)
	elif _oyun.kuyruktaki_is_sayisi(_oyun.oyuncu_ulkesi) >= Oyun.AZAMI_KUYRUK_UZUNLUGU:
		_arayuz.bildirim_goster("İnşa kuyruğu dolu (en çok %d iş)." % Oyun.AZAMI_KUYRUK_UZUNLUGU, "")
	else:
		_arayuz.bildirim_goster("Hazine yetmiyor (%s: %d)." % [ad, roundi(maliyet)], "")


## "Tahkimat" düğmesine seçili bölgenin seviyesini ve bir sonraki seviyenin fiyatını yazar.
func _tahkimat_dugmesini_guncelle() -> void:
	if _secili_bolge_id == "" or not _oyun.oyuncu_secildi_mi():
		return
	var seviye: int = _oyun.sonraki_tahkimat_seviyesi(_oyun.oyuncu_ulkesi, _secili_bolge_id)
	InsaDugmeleri.tahkimat_durumunu_ayarla(_oyun.dunya.bolgeler[_secili_bolge_id].tahkimat,
			_oyun.tahkimat_maliyeti(seviye) if seviye > 0 else 0.0)


## Bir bölgenin tahkimatı yükseldi: harita işaretini ve (o bölge gösteriliyorsa) paneli yeniler.
func _tahkimat_degisti(bolge_id: String) -> void:
	_harita.birlikleri_yenile()
	if bolge_id != _secili_bolge_id:
		return
	if _secili_birlikler.is_empty():
		_bolgeyi_sec(bolge_id)
	else:
		# Birlik kartı açık: seçimi ("Yarısını ayır" ile küçülmüş olabilir) bozmadan yenile.
		_arayuz.birligi_goster(_oyun.dunya.bolgeler[bolge_id], _secili_birlikler,
				_oyun.dunya.ulkeler[_oyun.oyuncu_ulkesi])


## "Teknoloji" düğmesi açıldı: alt panel aynı yeri kapladığı için seçim kaldırılır.
func _teknolojiyi_ac() -> void:
	_bolgeyi_sec("")
	_teknolojiyi_goster()


## Teknoloji panelini oyuncunun güncel seviyeleri ve süren araştırmasıyla açar/yeniler.
func _teknolojiyi_goster() -> void:
	if not _oyun.oyuncu_secildi_mi():
		return
	var ulke_id: String = _oyun.oyuncu_ulkesi
	_arayuz.teknolojiyi_goster(_oyun.teknolojiler.get(ulke_id, {}), _oyun.suren_arastirma(ulke_id))


func _teknoloji_ilerlemesini_guncelle() -> void:
	if not _oyun.oyuncu_secildi_mi():
		return
	var ulke_id: String = _oyun.oyuncu_ulkesi
	_arayuz.teknoloji_ilerlemesini_goster(_oyun.teknolojiler.get(ulke_id, {}), _oyun.suren_arastirma(ulke_id))


## Teknoloji panelinde bir kutuya dokunuldu: araştırma başlar ya da nedeni bildirilir.
func _arastirma_istendi(dal: String) -> void:
	var ulke_id: String = _oyun.oyuncu_ulkesi
	if _oyun.arastirma_baslat(ulke_id, dal):
		_ses.cal("onay")
		return
	_ses.cal("hata")
	if not _oyun.suren_arastirma(ulke_id).is_empty():
		_arayuz.bildirim_goster("Aynı anda tek araştırma yapılabilir.", "")
	else:
		var seviye: int = _oyun.teknoloji_seviyesi(ulke_id, dal) + 1
		_arayuz.bildirim_goster("Hazine yetmiyor (Araştırma: %d)." % roundi(Teknoloji.maliyet(seviye)), "")


## Bir tümen yürümeye başlayınca ya da vardığında haritayı (kutular ve yol çizgileri) günceller.
func _birlikler_degisti() -> void:
	_harita.birlikleri_yenile()


## Her oyun günü başında (bir ülkenin hazinesi değiştiğinde) oyuncunun hazinesini üst
## çubuğa yazar. Oyuncu henüz seçilmediyse bir şey yapmaz.
func _hazine_degisti() -> void:
	if _oyun.oyuncu_secildi_mi():
		_arayuz.hazineyi_goster(_oyun.hazineler.get(_oyun.oyuncu_ulkesi, 0.0))


## Oyuncu zafer kazanınca (kıtasının %60'ı kendisinin olunca) çağrılır. Önemli bir olay
## olduğu için oyun durur; oyuncu "Kapat"tan sonra "Devam"a basarak sürdürebilir.
func _oyun_kazanildi() -> void:
	_arayuz.zaferi_goster()
	_ses.cal("zafer")
	Zaman.durdur()


## Oyuncunun ülkesi teslim olunca çağrılır.
func _oyun_kaybedildi() -> void:
	_arayuz.kaybi_goster()
	_ses.cal("kaybetme")
	Zaman.durdur()


## Bölge panelinde "Savaş ilan et" onaylandığında çağrılır. Kabul edilirse seçim kaldırılır.
func _savas_istendi(hedef_ulke_id: String) -> void:
	if _oyun.savas_ilan_et(_oyun.oyuncu_ulkesi, hedef_ulke_id, Zaman.toplam_saat):
		_bolgeyi_sec("")


## Bölge panelinde "Barış teklif et" düğmesine basıldığında çağrılır. Kabul edilirse (karşı
## taraf kaybediyorsa ya da savaş 180 günden uzun sürdüyse) seçim kaldırılır.
func _baris_istendi(hedef_ulke_id: String) -> void:
	if _oyun.baris_teklif_et(_oyun.oyuncu_ulkesi, hedef_ulke_id, Zaman.toplam_saat):
		_ses.cal("onay")
		_bolgeyi_sec("")
	else:
		_ses.cal("hata")


## Birlik kartındaki "Yarısını ayır" düğmesine basıldığında çağrılır. Ayrılan yarı sonraki
## hedef seçiminde yürütülür; panel yeni (küçülmüş) seçimi gösterir.
func _yarisini_ayir_istendi() -> void:
	if _secili_birlikler.is_empty():
		return
	var bolge_id: String = _secili_birlikler[0].bolge_id
	var ayrilan: Array[Birlik] = _oyun.yariya_ayir(_secili_birlikler)
	if ayrilan.is_empty():
		return
	_secili_birlikler = ayrilan
	var bolge: Bolge = _oyun.dunya.bolgeler[bolge_id]
	_arayuz.birligi_goster(bolge, _secili_birlikler, _oyun.dunya.ulkeler[_oyun.oyuncu_ulkesi])


## Oyuncu ülkesini seçti: ülke işaretlenir, kamera oraya kayar, zaman düğmeleri açılır.
func _oyuncu_secildi(ulke_id: String) -> void:
	# Ülke bonusu fiyatları değiştirebilir (fabrika, piyade, araştırma süresi).
	InsaDugmeleri.maliyetleri_ayarla(_oyun.fabrika_maliyeti(ulke_id), _oyun.tahkimat_azami_seviye())
	var fiyatlar: Dictionary = {}
	for tur: String in BirlikTurleri.SIRA:
		fiyatlar[tur] = _oyun.tumen_maliyeti(tur, ulke_id)
	_arayuz.oyuncu_fiyatlarini_ayarla(fiyatlar, _oyun.arastirma_sure_carpani(ulke_id))
	var ulke: Ulke = _oyun.dunya.ulkeler[ulke_id]
	_bolgeyi_sec("")
	_harita.oyuncuyu_ayarla(ulke_id)
	_arayuz.oyuncuyu_goster(ulke)
	_arayuz.hazineyi_goster(_oyun.hazineler.get(ulke_id, 0.0))
	_uretimi_guncelle()
	_harita.isgalleri_yenile(Zaman.toplam_saat)
	_kamera.odaklan(ulke.anakara_kutusu)
	Zaman.kilidi_ac()


## Üst çubuktaki üretim göstergesini oyuncunun inşa kuyruğunun önündeki işle günceller
## (her saat ve kuyruk her değiştiğinde çağrılır; bkz. _ready()'deki bağlamalar).
func _uretimi_guncelle() -> void:
	if not _oyun.oyuncu_secildi_mi():
		return
	_arayuz.uretimi_goster(_oyun.onde_ki_is(_oyun.oyuncu_ulkesi),
			_oyun.kuyruktaki_is_sayisi(_oyun.oyuncu_ulkesi))


## Komut satırında "--ekran-goruntusu <dosya>" verildiyse harita yerleştikten sonra
## ekranı PNG olarak kaydeder ve oyunu kapatır. Görsel değişikliklerden sonra sınamak içindir.
func _ekran_goruntusu_istendiyse_kaydet() -> void:
	var argumanlar: PackedStringArray = OS.get_cmdline_user_args()
	var sira: int = argumanlar.find(EKRAN_GORUNTUSU_BAYRAGI)
	if sira == -1:
		return
	var yol: String = argumanlar[sira + 1] if sira + 1 < argumanlar.size() else "user://ekran_goruntusu.png"
	await get_tree().create_timer(EKRAN_GORUNTUSU_BEKLEME_SANIYE).timeout
	var goruntu: Image = get_viewport().get_texture().get_image()
	var hata: Error = goruntu.save_png(yol)
	if hata == OK:
		print("Ekran görüntüsü kaydedildi: %s" % yol)
	else:
		push_error("Ekran görüntüsü kaydedilemedi (hata %d): %s" % [hata, yol])
	get_tree().quit()
