// darkness.glsl
// Post-processing shader for dark / unlit regions.
// Applied over the logical canvas when the active region's Beacon is not lit.
//
// Desaturates and darkens the world, then adds a warm amber vignette
// around the player to simulate Luma's inner light.
//
// Uniforms:
//   desaturate_amount — 0.0 (full colour) to 0.7 (heavily desaturated)
//   brightness        — 1.0 (normal) to 0.55 (dim)
//   player_screen_pos — player centre in window pixels (vec2)
//   vignette_radius   — radius of the player's light pool in window pixels

uniform float desaturate_amount;
uniform float brightness;
uniform vec2  player_screen_pos;
uniform float vignette_radius;

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
    vec4 pixel = Texel(tex, texture_coords) * color;

    // Desaturation
    float grey = dot(pixel.rgb, vec3(0.299, 0.587, 0.114));
    pixel.rgb  = mix(pixel.rgb, vec3(grey), desaturate_amount);

    // Global brightness reduction
    pixel.rgb *= brightness;

    // Warm amber vignette centred on the player
    float dist  = distance(screen_coords, player_screen_pos);
    float vfrac = 1.0 - clamp(dist / vignette_radius, 0.0, 1.0);
    vfrac       = vfrac * vfrac;                       // ease-in falloff
    pixel.rgb  += vec3(0.22, 0.11, 0.02) * vfrac;     // warm amber tint
    pixel.rgb  *= 1.0 + 0.55 * vfrac;                 // local brightness boost

    return vec4(clamp(pixel.rgb, 0.0, 1.0), pixel.a);
}
