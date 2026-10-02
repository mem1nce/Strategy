shader_type canvas_item;
render_mode unshaded;

// Sınır çizgilerini, kamera ne kadar yakınlaşırsa yakınlaşsın ekranda aynı kalınlıkta çizer.
//
// Çizgiler bir kez ağ (mesh) olarak kurulur: her nokta, çizginin iki yanı için iki köşe
// olur. Köşeler aynı yerde durur; ekranda ne kadar açılacaklarına burada, ekran kartında
// karar verilir. Böylece yakınlık değişince ağı baştan kurmak gerekmez.

uniform vec4 renk : source_color = vec4(0.0, 0.0, 0.0, 1.0);
// Çizginin ekrandaki kalınlığı (piksel).
uniform float kalinlik = 2.0;
// Kameranın yakınlığı; kamera değiştikçe güncellenir.
uniform float yakinlik = 1.0;

// Çizginin ortasından kenarına: -1 ile +1 arası.
varying float kenar;

void vertex() {
	// UV, çizgiye dik yöndür (köşelerde gönye payı eklenmiş). Kenarı yumuşatmak için
	// çizgi bir piksel daha geniş açılır.
	VERTEX += UV * (kalinlik * 0.5 + 1.0) / yakinlik;
	kenar = COLOR.r * 2.0 - 1.0;
}

void fragment() {
	// Çizginin ortasına piksel cinsinden uzaklık; kenarda bir piksellik yumuşak geçiş.
	float uzaklik = abs(kenar) * (kalinlik * 0.5 + 1.0);
	float ortu = clamp(kalinlik * 0.5 + 0.5 - uzaklik, 0.0, 1.0);
	COLOR = vec4(renk.rgb, renk.a * ortu);
}
