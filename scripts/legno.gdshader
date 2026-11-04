// Piano del tavolo: venature di legno scuro generate al volo.
shader_type spatial;
render_mode diffuse_burley;

float rumore(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}
float morbido(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(rumore(i), rumore(i + vec2(1.0, 0.0)), u.x), mix(rumore(i + vec2(0.0, 1.0)), rumore(i + vec2(1.0, 1.0)), u.x), u.y);
}
void fragment() {
	vec3 w = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float v = w.z * 9.0 + morbido(w.xz * vec2(0.8, 4.0)) * 2.0 + morbido(w.xz * 0.5) * 3.0;
	float ven = 0.5 + 0.5 * sin(v);
	ven = pow(ven, 2.0) * 0.6;
	vec3 chiaro = vec3(0.30, 0.18, 0.10);
	vec3 scuro = vec3(0.19, 0.11, 0.06);
	ALBEDO = mix(chiaro, scuro, ven * 0.8 + morbido(w.xz * 8.0) * 0.2);
	ROUGHNESS = 0.55;
	SPECULAR = 0.35;
}
