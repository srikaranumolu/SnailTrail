shader_type canvas_item;

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}

uniform float speed = 0.5;

void fragment() {
	vec2 new_uv = UV;
	new_uv.x += TIME * speed;
	
	COLOR = texture(TEXTURE, new_uv);
}
