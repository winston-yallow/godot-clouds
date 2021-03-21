shader_type spatial;
render_mode depth_draw_always;


uniform float transmission = 0.1;
uniform float proximity_fade_distance = 15.0;
uniform float cloud_speed = 0.2;
uniform vec2 direction = vec2(1.0, 1.0);
uniform vec2 uv_scale = vec2(0.002, 0.001);
uniform vec2 texture_increment = vec2(0.02, 0.02);
uniform sampler2D noisetexture: hint_albedo;

varying vec2 world_uv;
varying vec3 base_vert;


vec4 get_noise(vec2 uv, float time) {
    vec4 noise_a = texture(noisetexture, (uv * uv_scale) + (direction * time * cloud_speed * 0.02));
    vec4 noise_b = texture(noisetexture, (uv * uv_scale) + (direction * time * cloud_speed * 0.05));
    return smoothstep(0.15, 0.6, noise_a + noise_b);
}


void vertex() {
    world_uv = (WORLD_MATRIX * vec4(VERTEX, 1.0)).xz;
    
    // Approximate derivative along the z axis
    float height_up = get_noise(world_uv + vec2(0.0, -texture_increment.y), TIME).r;
    float height_down = get_noise(world_uv + vec2(0.0, texture_increment.y), TIME).r;
    
    // Approximate derivative along the x axis
    float height_left = get_noise(world_uv + vec2(texture_increment.x, 0.0), TIME).r;
    float height_right = get_noise(world_uv + vec2(-texture_increment.x, 0.0), TIME).r;
    
    BINORMAL = normalize(vec3(1.0, height_right - height_left, 0.0));
    TANGENT = normalize(vec3(0.0, height_up - height_down, 1.0));
    NORMAL = normalize(vec3(cross(TANGENT, BINORMAL)));
    
    // Save vertex before changing it so that we can use it in the fragment shader
    base_vert = VERTEX;
    
    // Only displace vertices within 300 units around mesh origin
    float height_factor = smoothstep(300, 150, length(VERTEX));
    VERTEX.y = get_noise(world_uv, TIME).r * 8.0 * height_factor;
}


void fragment() {
    float depth_tex = textureLod(DEPTH_TEXTURE, SCREEN_UV, 0.0).r;
    vec4 world_pos = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, depth_tex * 2.0 - 1.0, 1.0);
    world_pos.xyz /= world_pos.w;
    
    vec4 noise = get_noise(world_uv, TIME);
    
    // Always slightly transparent to let sun shine through
    ALPHA = clamp(noise.r * 1.5 + 0.4, 0.0, 1.0) * 0.998;
    
    // Fade out based on distance to other objects and on distance to origin
    float depth_factor = clamp(1.0 - smoothstep(world_pos.z + proximity_fade_distance, world_pos.z, VERTEX.z), 0.0, 1.0);
    float fade_factor = smoothstep(2500, 1000, length(base_vert));
    ALPHA *= depth_factor * fade_factor;
    
    ALBEDO = noise.rgb * 0.5 + 0.5;
    TRANSMISSION = vec3(transmission);
}
