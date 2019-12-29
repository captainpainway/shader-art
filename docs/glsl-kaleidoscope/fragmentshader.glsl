#ifdef GL_ES
precision highp float;
#endif

uniform float time;
uniform vec2 resolution;

const int MAX_MARCHING_STEPS = 255;
const float MIN_DIST = 0.0;
const float MAX_DIST = 50.0;
const float EPSILON = 0.0001;

float box(vec3 p, vec3 b, float r, vec3 c) {
    vec3 q = mod(p, c) - 0.5 * c;
    return length(max(abs(q) - b, 0.0)) - r;
}

float sphere(vec3 p, float s, vec3 c) {
    vec3 q = mod(p, c) - 0.5 * c;
    return length(q) - s;
}

float boxMinusSphere(float d1, float d2) {
    return max(-d1, d2);
}

float scene(vec3 p) {
    vec3 c = vec3(5.0, 5.0, 5.0);
    float b = box(p, vec3(0.4, 0.4, 0.4), 0.1, c);
    float s = sphere(p, abs(cos(time)) * 0.19 + 0.6, c);
    float u = boxMinusSphere(s, b);
    return u;
}

float distanceCalc(vec3 eye, vec3 direction, float start, float end) {
    float depth = start;
    for (int i = 0; i < MAX_MARCHING_STEPS; i++) {
        float dist = scene(eye + depth * direction);
        if (dist < EPSILON) {
            return depth;
        }
        depth += dist;
        if (depth >= end) {
            return end;
        }
    }
    return end;
}

vec3 rayDirection(float fov, vec2 size, vec2 fragCoord) {
    vec2 xy = fragCoord - size / 2.0;
    float z = size.y / tan(radians(fov) / 2.0);
    return normalize(vec3(xy, -z));
}

vec3 estimateNormal(vec3 p) {
    return normalize(vec3(
        scene(vec3(p.x + EPSILON, p.y, p.z)) - scene(vec3(p.x - EPSILON, p.y, p.z)),
        scene(vec3(p.x, p.y + EPSILON, p.z)) - scene(vec3(p.x, p.y - EPSILON, p.z)),
        scene(vec3(p.x, p.y, p.z  + EPSILON)) - scene(vec3(p.x, p.y, p.z - EPSILON))
    ));
}

mat4 viewMatrix(vec3 eye, vec3 center, vec3 up) {
    vec3 f = normalize(center - eye);
    vec3 s = normalize(cross(f, up));
    vec3 u = cross(s, f);
    return mat4(
        vec4(s, 0.0),
        vec4(u, 0.0),
        vec4(-f, 0.0),
        vec4(0.0, 0.0, 0.0, 1)
    );
}

void main() {
    vec3 dir = rayDirection(45.0, resolution.xy, gl_FragCoord.xy);
    vec3 eye = vec3(sin(time / 5.0), abs(sin(time / 5.0)), sin(time / 5.0));

    mat4 viewToWorld = viewMatrix(eye, vec3(0.0, 0.0, 0.0), vec3(0.0, sin(time), cos(time)));
    vec3 worldDir = (viewToWorld * vec4(dir, 0.0)).xyz;
    float dist = distanceCalc(eye, worldDir, MIN_DIST, MAX_DIST);

    if (dist > MAX_DIST - EPSILON) {
        gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0);
        return;
    }

    vec3 p = abs(eye + (sin(time / 2.0) * dist) * dir);
    vec3 color = estimateNormal(p);

    gl_FragColor = vec4(color, 1.0);
}