// Nastro dei percorsi di marcia: bordo scuro, corpo del colore del giocatore e chevron che scorrono
// verso la meta. UV.x = distanza lungo il percorso (in unità del mondo), UV.y = 0..1 attraverso il nastro.
// COLOR.a = 1 per il percorso selezionato, più basso per gli altri.
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, blend_mix, shadows_disabled;

uniform float velocita = 0.9;
uniform float passo = 0.42;

void fragment() {
	float y = abs(UV.y - 0.5) * 2.0;           // 0 al centro, 1 sul bordo
	float bordo = smoothstep(0.62, 0.72, y);
	float fuori = smoothstep(0.92, 1.0, y);
	vec3 col = COLOR.rgb;
	// chevron: una V che punta avanti, ripetuta e animata
	float s = fract((UV.x - TIME * velocita) / passo);
	float v = fract(s + y * 0.32);
	float chev = smoothstep(0.0, 0.06, v) * (1.0 - smoothstep(0.30, 0.36, v));
	float lum = dot(col, vec3(0.3, 0.59, 0.11));
	vec3 chiaro = lum > 0.7 ? vec3(0.85, 0.55, 0.12) : mix(col, vec3(1.0, 0.97, 0.85), 0.75);
	vec3 corpo = mix(col * 0.95, chiaro, chev * (1.0 - bordo));
	vec3 c = mix(corpo, vec3(0.08, 0.05, 0.03), bordo);
	// la parte già "percorsa" all'inizio sfuma
	float inizio = smoothstep(0.0, 0.35, UV.x);
	ALBEDO = c;
	ALPHA = (1.0 - fuori) * inizio * (0.55 + 0.45 * COLOR.a);
}
