shader_type canvas_item;
render_mode unshaded;

// Bir sınırın yalnızca bir yanına düşen, içe doğru solan yumuşak bant: ülke sınırlarının iç
// tarafındaki koyu şerit ve seçili bölgenin iç parıltısı.
//
// Ağ, sınır çizgisi ağı gibi bir kez kurulur: her nokta için çizginin üstünde bir köşe
// (UV = 0, renk opaklığı 1) ve bandın iç kenarında bir köşe (UV = içe dönük gönye yönü,
// renk opaklığı 0). Bandın ekrandaki genişliği burada verilir; yakınlık değişince ağ
// yeniden kurulmaz.

// Bandın ekrandaki genişliği (piksel).
uniform float genislik = 8.0;
uniform float yakinlik = 1.0;
uniform float opaklik = 1.0;

void vertex() {
	VERTEX += UV * genislik / yakinlik;
}

void fragment() {
	float t = COLOR.a;
	COLOR = vec4(COLOR.rgb, opaklik * t * sqrt(t));
}
