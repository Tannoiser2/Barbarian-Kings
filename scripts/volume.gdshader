// Effetti volumetrici per magie e azioni speciali: un cubo unitario in cui si "marcia" lungo il raggio
// di vista accumulando una nebbia rumorosa (funziona anche con il renderer Compatibility e sul web).
// forma: 0 sfera, 1 vortice (tornado), 2 nube piatta, 3 colonna che sale, 4 anello che si espande.
shader_type spatial;
render_mode unshaded, cull_back, depth_draw_never, blend_mix, shadows_disabled;

uniform vec4 colore : source_color = vec4(0.5, 0.7, 1.0, 1.0);
uniform vec4 colore2 : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform int forma = 0;
uniform float densita = 2.0;
uniform float dissolvenza = 0.0;   // 0 invisibile, 1 pieno (animata da GDScript)
uniform float vortice = 2.0;
uniform float salita = 0.4;
uniform float scala_rumore = 4.0;
uniform float bagliore = 0.6;       // quanto il colore chiaro emerge nelle parti dense
uniform float seme = 0.0;

float hash(vec3 p) {
	p = fract(p * 0.3183099 + vec3(0.1, 0.2, 0.3));
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float rumore(vec3 x) {
	vec3 i = floor(x);
	vec3 f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(hash(i), hash(i + vec3(1, 0, 0)), f.x),
				   mix(hash(i + vec3(0, 1, 0)), hash(i + vec3(1, 1, 0)), f.x), f.y),
			   mix(mix(hash(i + vec3(0, 0, 1)), hash(i + vec3(1, 0, 1)), f.x),
				   mix(hash(i + vec3(0, 1, 1)), hash(i + vec3(1, 1, 1)), f.x), f.y), f.z);
}

float fbm(vec3 p) {
	float v = 0.0;
	float a = 0.55;
	for (int i = 0; i < 4; i++) {
		v += a * rumore(p);
		p = p * 2.03 + vec3(1.7, 9.2, 3.1);
		a *= 0.5;
	}
	return v;
}

vec2 ruota(vec2 v, float a) {
	float c = cos(a);
	float s = sin(a);
	return vec2(c * v.x - s * v.y, s * v.x + c * v.y);
}

// densità nel punto p (coordinate del cubo, da -0.5 a 0.5), t tempo
float campo(vec3 p, float t) {
	float h = p.y + 0.5;   // 0 in basso, 1 in alto
	float forma_d = 0.0;
	vec3 q = p;
	if (forma == 0) {
		forma_d = 1.0 - length(p) / 0.5;
		q.xz = ruota(q.xz, t * vortice * 0.5);
	} else if (forma == 1) {
		float r = mix(0.06, 0.42, pow(h, 1.4));
		q.xz = ruota(q.xz, h * 9.0 + t * vortice);
		float d = abs(length(p.xz) - r * 0.65) / (0.08 + r * 0.45);
		forma_d = (1.0 - d) * smoothstep(0.0, 0.08, h) * smoothstep(1.0, 0.85, h);
	} else if (forma == 2) {
		forma_d = (1.0 - length(p.xz) / 0.5) * (1.0 - abs(p.y) / 0.5);
		q.xz += vec2(t * 0.05, t * 0.03);
	} else if (forma == 3) {
		forma_d = (1.0 - length(p.xz) / 0.45) * smoothstep(1.0, 0.2, h);
		q.y -= t * salita;
		q.xz = ruota(q.xz, t * vortice * 0.3);
	} else {
		float r = 0.12 + 0.3 * fract(t * 0.5);
		forma_d = (1.0 - abs(length(p.xz) - r) / 0.09) * (1.0 - abs(p.y) / 0.5);
	}
	if (forma_d <= 0.0) {
		return 0.0;
	}
	float n = fbm(q * scala_rumore + vec3(seme, -t * salita, seme * 0.7));
	float bordo = smoothstep(0.5, 0.36, max(max(abs(p.x), abs(p.y)), abs(p.z)));
	return clamp(forma_d * forma_d * bordo * smoothstep(0.3, 0.8, n) * 3.0, 0.0, 1.0);
}

void fragment() {
	mat4 inv_m = inverse(MODEL_MATRIX);
	vec3 cam = (inv_m * vec4(INV_VIEW_MATRIX[3].xyz, 1.0)).xyz;
	vec3 frag = (inv_m * (INV_VIEW_MATRIX * vec4(VERTEX, 1.0))).xyz;
	vec3 rd = normalize(frag - cam);
	// intersezione con il cubo unitario
	vec3 inv = 1.0 / rd;
	vec3 t0 = (vec3(-0.5) - cam) * inv;
	vec3 t1 = (vec3(0.5) - cam) * inv;
	vec3 tmin = min(t0, t1);
	vec3 tmax = max(t0, t1);
	float ta = max(max(tmin.x, tmin.y), max(tmin.z, 0.0));
	float tb = min(min(tmax.x, tmax.y), tmax.z);
	if (tb <= ta) {
		discard;
	}
	const int PASSI = 26;
	float dt = (tb - ta) / float(PASSI);
	float t = ta + dt * hash(vec3(FRAGCOORD.xy, 1.0));
	vec3 acc = vec3(0.0);
	float alfa = 0.0;
	for (int i = 0; i < PASSI; i++) {
		vec3 p = cam + rd * t;
		float d = campo(p, TIME) * densita * dissolvenza;
		if (d > 0.001) {
			float a = 1.0 - exp(-d * dt * 14.0);
			vec3 c = mix(colore.rgb, colore2.rgb, clamp(d * bagliore, 0.0, 1.0));
			acc += (1.0 - alfa) * a * c;
			alfa += (1.0 - alfa) * a;
			if (alfa > 0.97) {
				break;
			}
		}
		t += dt;
	}
	if (alfa < 0.01) {
		discard;
	}
	ALBEDO = acc / alfa;
	ALPHA = alfa * colore.a;
}
