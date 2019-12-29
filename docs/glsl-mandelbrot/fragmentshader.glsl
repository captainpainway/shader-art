#ifdef GL_ES
precision highp float;
#endif

uniform vec2 resolution;

const int ITER = 15;
float SCALE = (resolution.x / resolution.y) * 0.002;

float brot(vec2 c) {
    vec2 z = c;
    for (int i = 0; i < ITER; i++) {
        float x = (z.x * z.x - z.y * z.y) + c.x;
        float y = (z.y * z.x + z.x * z.y) + c.y;

        if ((x * x + y * y) > 40.0) return 0.0;
        z.x = x;
        z.y = y;

    }
    return abs(z.x) + abs(z.y);
}

void main() {
    vec2 z, c;

    c.x = (gl_FragCoord.x) * SCALE - resolution.x * (SCALE / 2.0) - 0.7;
    c.y = (gl_FragCoord.y) * SCALE - resolution.y * (SCALE / 2.0);

    vec3 color = vec3(0.03, brot(c) * 0.75, brot(c) * 0.7);
    gl_FragColor = vec4(color, 1.0);
}