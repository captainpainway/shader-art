#ifdef GL_ES
precision highp float;
#endif

uniform vec2 resolution;
uniform float time;

const int ITER = 15;
float SCALE = (resolution.x / resolution.y) * 0.002;
vec2 c = vec2(sin(time * 0.5) + 0.5, sin(time * 0.5) + 0.3);

vec3 julia(vec2 z) {
    for (int i = 0; i < ITER; i++) {
        float x = (z.x * z.x - z.y * z.y) + c.x;
        float y = (z.y * z.x + z.x * z.y) + c.y;

        if ((x * x + y * y) > 10.0) return vec3(0.0, 0.0, 0.0);
        z.x = x;
        z.y = y;

    }
    return vec3(0.0, z.x, z.x);
}

void main() {
    vec2 z;

    z.x = (gl_FragCoord.x) * SCALE - resolution.x * (SCALE / 2.0);
    z.y = (gl_FragCoord.y) * SCALE - resolution.y * (SCALE / 2.0);

    vec3 color = julia(z);
    gl_FragColor = vec4(color, 1.0);
}