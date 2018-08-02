#ifdef GL_ES
precision highp float;
#endif

// https://thebookofshaders.com/10/

uniform vec2 resolution;
uniform float time;

float random(vec2 s, float t) {
    return fract(sin(dot(s.xy, vec2(0.0, t))) * (time + 10.0));
}

void main() {
    vec2 s = gl_FragCoord.xy / resolution;
    gl_FragColor = vec4(vec3(random(s, 83.8), random(s, 14.3), random(s, 94.6)), 1.0);
}
