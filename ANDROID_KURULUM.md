# Android'e kurulum (Windows 11)

Bu bilgisayarda kontrol edildi (2026-10-07):

| Gerekli | Durum |
|---|---|
| JDK | ✅ Microsoft OpenJDK 21 (`C:\Program Files\Microsoft\jdk-21.0.11.10-hotspot`) |
| Android SDK | ✅ `%LOCALAPPDATA%\Android\Sdk` (build-tools 36.1.0, platform android-36, adb) |
| Godot'da SDK ve JDK yolları | ✅ Düzenleyici Ayarları → Dışa Aktar → Android'de ayarlı |
| Hata ayıklama anahtarı (debug keystore) | ✅ `%APPDATA%\Godot\keystores\debug.keystore` |
| **Godot 4.7.2 dışa aktarma şablonları** | ❌ **Yok** (`%APPDATA%\Godot\export_templates` boş) |

Eksik olan tek şey dışa aktarma şablonları. Godot bu yüzden şu hatayla APK üretmiyor:
`Beklenen yolda herhangi bir dışa aktarma şablonu bulunamadı: .../4.7.2.stable/android_debug.apk`.

Projedeki Android ön ayarı hazır (`export_presets.cfg`): izin yok, internet yok, yatay ekran,
tam ekran, yalnızca arm64, geçici paket adı `com.ornek.yerkure`, simge `icons/`.

## 1. Dışa aktarma şablonlarını kur (bir kez)

1. Godot 4.7.2'yi aç ve **Yerküre** projesini aç.
2. Üst menüden **Editör → Dışa Aktarma Şablonlarını Yönet...** seç.
3. Açılan pencerede **İndir ve Yükle** düğmesine bas (yaklaşık 1 GB; birkaç dakika sürer).
4. Bitince pencerede "4.7.2.stable" için şablonların kurulu olduğu yazar. Pencereyi kapat.

İndirme çalışmazsa: tarayıcıda godotengine.org → Download → Windows → **Export templates**
(`Godot_v4.7.2-stable_export_templates.tpz`) dosyasını indir; aynı pencerede **Dosyadan Yükle**
ile bu dosyayı seç.

## 2. Hata ayıklama APK'sını üret

1. Godot'da **Proje → Dışa Aktar...** seç.
2. Solda **Android** ön ayarı seçili olmalı (hazır geliyor). Üstte kırmızı bir uyarı
   kalmamalı.
3. Alttaki **Projeyi Dışa Aktar...** düğmesine bas.
4. Dosya adı olarak `builds/yerkure-debug.apk` gelir. **Hata Ayıklama ile Dışa Aktar**
   kutusu işaretli kalsın, **Kaydet**'e bas.
5. APK, proje klasöründe `builds\yerkure-debug.apk` olarak oluşur. Bu klasör `.gitignore`'da;
   APK depoya girmez.

Komut satırından da üretilebilir (proje klasöründe, PowerShell'de):

```
& "$env:USERPROFILE\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe" --headless --path . --export-debug Android builds/yerkure-debug.apk
```

## 3. Telefona yükle

### Yol A: USB kablosuyla (önerilen)

1. Telefonda **Ayarlar → Telefon hakkında** bölümüne gir, **Yapı numarası**na 7 kez dokun
   ("Artık geliştiricisiniz" yazar).
2. **Ayarlar → Sistem → Geliştirici seçenekleri**nde **USB hata ayıklama**yı aç.
3. Telefonu USB ile bilgisayara bağla; telefonda "USB hata ayıklamaya izin verilsin mi?"
   sorusuna **İzin ver** de.
4. PowerShell'de proje klasöründe:

   ```
   & "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" devices
   & "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" install -r builds\yerkure-debug.apk
   ```

   İlk komut telefonu listelemeli; ikincisi "Success" yazmalı. Uygulama, telefonda
   **Yerküre** adıyla görünür.

Godot'un sağ üstündeki Android simgesine (Bir tıkla dağıt) basmak da aynı işi yapar.

### Yol B: Dosyayı kopyalayarak

1. `builds\yerkure-debug.apk` dosyasını telefona kopyala (USB, bulut ya da e-posta).
2. Telefonda dosyaya dokun. "Bilinmeyen uygulamaları yükle" izni istenirse, dosyayı açtığın
   uygulamaya (ör. Dosyalar) izin ver ve **Yükle**'ye bas.

## Notlar

- Paket adı (`com.ornek.yerkure`) geçicidir. Mağazaya çıkmadan önce kalıcı bir ada karar
  verilmeli; yayımlandıktan sonra değiştirilemez.
- Hata ayıklama APK'sı yalnızca deneme içindir. Mağaza için ayrıca bir yayın anahtarı
  (release keystore) oluşturulur; bu anahtar depoya **asla** konmaz.
