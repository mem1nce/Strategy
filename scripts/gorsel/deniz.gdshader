shader_type canvas_item;
render_mode unshaded;

// Denizi çizer: kıyıya yakın açık, açıkta koyu bir derinlik geçişi ve üstünde hafif dalgalar.
//
// Kıyıya yakınlık assets/relief.png'nin deniz piksellerinden okunur (bkz.
// tools/kabartma_uret.py): kıyıda düz değer, açık denizde 0. Harita alanının dışı açık denizdir.
// Dalgalar yalnızca iki sinüs dalgası katmanıdır (ucuz); ekranda çok sıkışacak kadar
// uzaklaşınca söner ki titreşmesin.

uniform sampler2D kabartma : filter_linear_mipmap, repeat_disable;
uniform vec2 harita_boyutu = vec2(4096.0, 2066.0);
// Dokudaki düz değer (206 / 255).
uniform float duz_deger = 0.808;
uniform vec4 derin_renk : source_color = vec4(0.051, 0.106, 0.165, 1.0);
uniform vec4 orta_renk : source_color = vec4(0.086, 0.208, 0.298, 1.0);
uniform vec4 kiyi_renk : source_color = vec4(0.200, 0.408, 0.494, 1.0);
// Dalgaların zamanı (saniye); oyun akarken harita günceller, dururken sabit kalır.
uniform float zaman = 0.0;
// Kameranın yakınlığı (dalgaların ekranda ne kadar sık görüneceğini bulmak için).
uniform float yakinlik = 1.0;

varying vec2 dunya;

void vertex() {
	dunya = VERTEX;
}

// Verilen periyottaki (harita birimi) dalga deseni: -1 ile 1 arası; ekranda 6 pikselden
// sıkışınca söner.
float dalga(vec2 p, float periyot, float hiz) {
	float sonum = smoothstep(6.0, 18.0, periyot * yakinlik);
	vec2 q = p / periyot;
	float w = sin(q.x + q.y * 0.6 + zaman * hiz) * sin(q.y * 1.3 - q.x * 0.5 - zaman * hiz * 0.7);
	return w * sonum;
}

void fragment() {
	vec2 uv = dunya / harita_boyutu;
	float yakin = 0.0;
	if (uv.x >= 0.0 && uv.x <= 1.0 && uv.y >= 0.0 && uv.y <= 1.0) {
		yakin = clamp(texture(kabartma, uv).r / duz_deger, 0.0, 1.0);
	}
	vec3 renk = mix(derin_renk.rgb, orta_renk.rgb, smoothstep(0.0, 0.45, yakin));
	renk = mix(renk, kiyi_renk.rgb, smoothstep(0.5, 1.0, yakin));
	float w = dalga(dunya, 90.0, 0.5) * 0.6 + dalga(dunya, 22.0, 0.9) * 0.4;
	renk *= 1.0 + w * 0.035 * (0.6 + 0.4 * yakin);
	COLOR = vec4(renk, 1.0);
}
