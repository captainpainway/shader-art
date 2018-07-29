#ifdef GL_ES
precision highp float;
#endif

uniform float time;
uniform vec2 resolution;

const int MAX_MARCHING_STEPS = 1000;
const float MIN_DISTANCE = 0.0;
const float MAX_DISTANCE = 100.0;
const float EPSILON = 0.0001;

float roundBox(vec3 p, vec3 b, float r) {
    return length(max(abs(p) - b, 0.0)) - r;
}

float repeat(vec3 p, vec3 c) {
    vec3 q = mod(p, c) - 0.5 * c;
    return roundBox(q, vec3(0.2, 0.2, 0.2), 0.5);
}

float scene(vec3 p) {
    return repeat(p, vec3(3.0, 3.0, 3.0));
}

float raymarch(vec3 eye, vec3 direction, float start, float end) {
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
        scene(vec3(p.x, p.y, p.z + EPSILON)) - scene(vec3(p.x, p.y, p.z - EPSILON))
    ));
}

vec3 phongLight(vec3 diffuse, vec3 specular, float alpha, vec3 p, vec3 eye, vec3 lightPos, vec3 lightIntensity) {
    vec3 N = estimateNormal(p);
    vec3 L = normalize(lightPos - p);
    vec3 V = normalize(eye - p);
    vec3 R = normalize(reflect(-L, N));

    float dotLN = dot(L, N);
    float dotRV = dot(R, V);

    if (dotLN < 0.0) {
        return vec3(0.0, 0.0, 0.0);
    }

    if (dotRV < 0.0) {
        return lightIntensity * (diffuse * dotLN);
    }
    return lightIntensity * (diffuse * dotLN + specular * pow(dotRV, alpha));
}

vec3 phongIllumination(vec3 ambient, vec3 diffuse, vec3 specular, float alpha, vec3 p, vec3 eye) {
    const vec3 ambientLight = 0.5 * vec3(1.0, 1.0, 1.0);
    vec3 color = ambientLight * ambient;
    vec3 light1Pos = vec3(4.0, 5.0, -time * 10.0);
    vec3 light1Intensity = vec3(0.4, 0.4, 0.4);
    color += phongLight(diffuse, specular, alpha, p, eye, light1Pos, light1Intensity);
    return color;
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
    vec3 dir = rayDirection(50.0, resolution.xy, gl_FragCoord.xy);
    vec3 eye = vec3(3.0, 0.0, -time * 10.0);
    mat4 viewToWorld = viewMatrix(eye, vec3(0.0, 0.0, 0.0), vec3(0.0, 1.0, 0.0));
    vec3 worldDir = (viewToWorld * vec4(dir, 0.0)).xyz;
    float dist = raymarch(eye, dir, MIN_DISTANCE, MAX_DISTANCE);

    if (dist > MAX_DISTANCE - EPSILON) {
        vec2 st = gl_FragCoord.xy/resolution.xy;
        float pct = 0.6 - distance(st, vec2(0.5));
        vec3 color = vec3(0.0 * pct, 0.8 * pct, 1.0 * pct);
        gl_FragColor = vec4(color, 1.0);
        return;
    }

    vec3 p = eye + dist * dir;
    vec3 ambient = vec3(0.0, 0.6, 0.8);
    vec3 diffuse = vec3(0.0, 0.6, 0.8);
    vec3 specular = vec3(1.0, 1.0, 1.0);
    float shininess = 50.0;

    vec3 color = phongIllumination(ambient, diffuse, specular, shininess, p, eye);

    gl_FragColor = vec4(color, 1.0);
}