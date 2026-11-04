// La mappa originale con le province evidenziabili: «ids» dice a quale provincia appartiene ogni punto,
// «evidenza» ha un colore (con trasparenza) per ognuna delle 47 province.
shader_type spatial;
render_mode diffuse_burley;

uniform sampler2D mappa : source_color, filter_linear_mipmap, repeat_disable;
uniform sampler2D ids : filter_nearest, repeat_disable;
uniform sampler2D evidenza : source_color, filter_nearest, repeat_disable;

void fragment() {
	vec3 c = texture(mappa, UV).rgb;
	float id = texture(ids, UV).r * 255.0;
	vec4 e = texture(evidenza, vec2((floor(id + 0.5) + 0.5) / 64.0, 0.5));
	float pulsa = 0.85 + 0.15 * sin(TIME * 3.0);
	c = mix(c, e.rgb, e.a * pulsa);
	ALBEDO = c * 0.78;
	ROUGHNESS = 0.9;
	SPECULAR = 0.25;
}
