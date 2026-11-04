// Mappa moderna in rilievo: il terreno si alza secondo «rilievo» (montagne, colline, isola di Starhome),
// le province si evidenziano come sulla mappa originale e il mare luccica.
shader_type spatial;
render_mode diffuse_burley;

uniform sampler2D mappa : source_color, filter_linear_mipmap, repeat_disable;
uniform sampler2D ids : filter_nearest, repeat_disable;
uniform sampler2D evidenza : source_color, filter_nearest, repeat_disable;
uniform sampler2D rilievo : filter_linear, repeat_disable;
uniform float altezza = 1.0;
uniform vec2 passo = vec2(0.001, 0.001);
uniform vec2 dim = vec2(20.0, 30.0);

float h(vec2 uv) {
	return texture(rilievo, uv).r * altezza;
}

void vertex() {
	VERTEX.y += h(UV);
	float hx = h(UV + vec2(passo.x, 0.0)) - h(UV - vec2(passo.x, 0.0));
	float hz = h(UV + vec2(0.0, passo.y)) - h(UV - vec2(0.0, passo.y));
	NORMAL = normalize(vec3(-hx / (2.0 * passo.x * dim.x), 1.0, -hz / (2.0 * passo.y * dim.y)));
}

void fragment() {
	vec3 c = texture(mappa, UV).rgb;
	float id = floor(texture(ids, UV).r * 255.0 + 0.5);
	bool mare = id > 0.5 && id < 17.5;
	if (mare) {
		float onda = sin(UV.x * 220.0 + TIME * 1.3) * sin(UV.y * 160.0 - TIME * 0.9);
		c += vec3(0.02, 0.035, 0.04) * onda;
	}
	vec4 e = texture(evidenza, vec2((id + 0.5) / 64.0, 0.5));
	float pulsa = 0.85 + 0.15 * sin(TIME * 3.0);
	c = mix(c, e.rgb, e.a * pulsa);
	ALBEDO = c * 0.82;
	ROUGHNESS = mare ? 0.32 : 0.88;
	SPECULAR = mare ? 0.55 : 0.2;
}
