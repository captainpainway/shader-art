#ifdef GL_ES
precision highp float;
#endif

uniform float time;
uniform vec2 resolution;

const int MAX_MARCHING_STEPS = 1000;
const float MIN_DISTANCE = 0.0;
const float MAX_DISTANCE = 100.0;
const float EPSILON = 0.0001;

float sphere(vec3 p) {
    return length(p) - 1.0;
}

float tor(vec3 p, vec2 t) {
    vec2 q = vec2(length(p.xz) - t.x, p.y);
    return length(q) - t.y;
}

vec3 twist(vec3 p) {
    float c = cos(sin(time * 2.0) * 6.0 * p.y);
    float s = sin(sin(time * 2.0) * 6.0 * p.y);
    mat2 m = mat2(c, -s, s, c);
    return vec3(m * p.xz, p.y);
}

mat4 rotationMatrix(vec3 axis, float angle) {
    vec3 a = normalize(axis);
    float s = sin(angle) * -1.0;
    float c = cos(angle);
    float oc = 1.0 - c;
    return mat4(
        oc * a.x * a.x + c, oc * a.x * a.y - a.z * s, oc * a.z * a.x + a.y * s, 0.0,
        oc * a.x * a.y + a.z * s, oc * a.y * a.y + c, oc * a.y * a.z - a.x * s, 0.0,
        oc * a.z * a.x - a.y * s, oc * a.y * a.z + a.x * s, oc * a.z * a.z + c, 0.0,
        0.0, 0.0, 0.0, 0.0
    );
}

vec3 rotator(vec3 p, mat4 m) {
    vec3 q = (m * vec4(p, 0.0)).xyz;
    return q;
}

float scene(vec3 p) {
    vec3 t = twist(p);
    mat4 matrix = rotationMatrix(vec3(0.0, 1.0, 1.0), time);
    vec3 r = rotator(t, matrix);
    return tor(r, vec2(0.6, 0.3));
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
    vec3 light1Pos = vec3(4.0, 5.0, 5.0);
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
    vec3 eye = vec3(0.0, 0.0, 5.0);
    mat4 viewToWorld = viewMatrix(eye, vec3(0.0, 0.0, 0.0), vec3(0.0, 1.0, 0.0));
    vec3 worldDir = (viewToWorld * vec4(dir, 0.0)).xyz;
    float dist = raymarch(eye, dir, MIN_DISTANCE, MAX_DISTANCE);

    if (dist > MAX_DISTANCE - EPSILON) {
        gl_FragColor = vec4(0.1, 0.1, 0.1, 1.0);
        return;
    }

    vec3 p = eye + dist * dir;
    vec3 ambient = vec3(0.5, 0.6, 0.8);
    vec3 diffuse = vec3(0.5, 0.6, 0.8);
    vec3 specular = vec3(1.0, 1.0, 1.0);
    float shininess = 10.0;

    vec3 color = phongIllumination(ambient, diffuse, specular, shininess, p, eye);

    gl_FragColor = vec4(color, 1.0);
}