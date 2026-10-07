shader_type canvas_item;
render_mode unshaded;

// Kara dolgusunu boyar: köşe rengi (bölgenin sahibinin rengi, sisle koyulaşmış) kabartmayla
// çarpılır ve üstüne hafif bir kâğıt dokusu biner.
//
// Kabartma assets/relief.png'nin kara piksellerinden okunur: düz arazi `duz_deger`, gölgeli
// yamaçlar daha koyu, ışık alanlar daha açık. Kâğıt dokusu iki katmanlı ucuz bir gürültüdür;
// ince katman ekranda sıkışacak kadar uzaklaşınca söner.

uniform sampler2D kabartma : filter_linear_mipmap, repeat_disable;
uniform vec2 harita_boyutu = vec2(4096.0, 2066.0);
uniform float duz_deger = 0.808;
// Kabartmanın ne kadar belirgin olacağı (1 = kaynaktaki kadar).
uniform float kabartma_gucu = 1.3;
uniform float kagit_gucu = 0.05;
uniform float yakinlik = 1.0;

varying vec2 dunya;

void vertex() {
	dunya = VERTEX;
}

// Sinüssüz karma (telefon ekran kartlarında da kararlı).
float karma(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float gurultu(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(karma(i), karma(i + vec2(1.0, 0.0)), u.x),
			mix(karma(i + vec2(0.0, 1.0)), karma(i + vec2(1.0, 1.0)), u.x), u.y);
}

void fragment() {
	float r = texture(kabartma, dunya / harita_boyutu).r / duz_deger;
	// Doku bir harita birimine bir piksel; çok yakından büyütülünce bulanık lekelere döner,
	// bu yüzden yakınlaştıkça kabartma yumuşar.
	float guc = kabartma_gucu * mix(1.0, 0.55, smoothstep(2.0, 8.0, yakinlik));
	float carpan = clamp(1.0 + (r - 1.0) * guc, 0.5, 1.3);
	float ince = (gurultu(dunya * 0.4) - 0.5) * smoothstep(2.0, 6.0, 2.5 * yakinlik);
	float kaba = gurultu(dunya * 0.05) - 0.5;
	float kagit = 1.0 + (ince * 0.6 + kaba) * kagit_gucu;
	COLOR = vec4(COLOR.rgb * carpan * kagit, COLOR.a);
}
