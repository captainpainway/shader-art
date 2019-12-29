#ifdef GL_ES
precision highp float;
#endif

uniform float time;
uniform vec2 resolution;

const int MAX_MARCHING_STEPS = 255;
const float MIN_DIST = 0.0;
const float MAX_DIST = 100.0;
const float EPSILON = 0.0001;
const vec3 AMBIENT_LIGHT = vec3(0.5);

// Rotation function from https://www.shadertoy.com/view/4tcGDr
mat3 rotateY(float theta) {
    float c = cos(theta);
    float s = sin(theta);
    return mat3(
        vec3(c, 0.0, s),
        vec3(0.0, 1.0, 0.0),
        vec3(-s, 0.0, c)
    );
}

float sphere(vec3 p, float s) {
    return length(p) - s;
}

float displace(vec3 p) {
    p = rotateY(time / 2.0) * p;
    float d1 = sphere(p, 8.0);
    float d2 = sin(sin(time / 5.0) * 1.2 * p.x) * sin(sin(time / 5.0) * 1.2 * p.y) * sin(sin(time / 5.0) * 1.2 * p.z);
    return d1 + d2;
}

float scene(vec3 p) {
    return displace(p);
}

/*
    https://www.shadertoy.com/view/llt3R4
    Return the shortest distance from the camera to the scene surface.

    cam: The ray origin, the scene camera.
    dir: The normalized direction in which to march the ray.
    start: The starting distance from the camera.
    end: The maximum distance from the camera before giving up.
*/
float raymarch(vec3 cam, vec3 dir, float start, float end) {
    float depth = start; // Depth begins at start point.
    for (int i = 0; i < MAX_MARCHING_STEPS; i++) {
        float dist = scene(cam + depth * dir);
        if (dist < EPSILON) {
            return depth; // If we hit the sphere, return that measurement.
        }
        depth += dist; // If we haven't hit the sphere yet, increment the depth.
        if (depth >= end) {
            return end; // If we make it to the end, we haven't hit the sphere.
        }

    }
    return end;
}

/*
    Return the normalized direction of the ray.

    fov: Vertical field of view in degrees.
    size: Resolution of the output image.
    fc: The x,y coordinate of the pixel in the output image.
*/
vec3 rayDir(float fov, vec2 size, vec2 fc) {
    vec2 xy = fc - size / 2.0;
    float z = size.y / tan(radians(fov) / 2.0);
    return normalize(vec3(xy, -z));
}

/*
    Functions for phong shading.
    https://www.shadertoy.com/view/lt33z7
    Estimate the normal of the surface of the sphere at point p.
*/
vec3 estNormal(vec3 p) {
    return normalize(vec3(
        scene(vec3(p.x + EPSILON, p.y, p.z)) - scene(vec3(p.x - EPSILON, p.y, p.z)),
        scene(vec3(p.x, p.y + EPSILON, p.z)) - scene(vec3(p.x, p.y - EPSILON, p.z)),
        scene(vec3(p.x, p.y, p.z + EPSILON)) - scene(vec3(p.x, p.y, p.z - EPSILON))
    ));
}

/*
    A light source for phong shading.

    d: Diffuse color.
    s: Specular color.
    alpha: Shininess coefficient.
    p: Position of the point being lit.
    cam: Camera position.
    pos: Position of the light.
    intensity: Color/intensity of the light.
*/
vec3 light(vec3 d, vec3 s, float alpha, vec3 p, vec3 cam, vec3 pos, vec3 intensity) {
    vec3 N = estNormal(p);
    vec3 L = normalize(pos - p);
    vec3 V = normalize(cam - p);
    vec3 R = normalize(reflect(-L, N));

    float dotLN = dot(L, N);
    float dotRV = dot(R, V);

    if(dotLN < 0.0) {
        // The light is not visible from this point on the surface.
        return vec3(0.0);
    }

    if(dotRV < 0.0) {
        // Light reflection in the opposite direction of the camera, apply only diffuse.
        return intensity * (d * dotLN);
    }

    return intensity * (d * dotLN + s * pow(dotRV, alpha));
}

/*
    Apply phong shading with lights.

    a: Ambient color.
    d: Diffuse color.
    s: Specular color.
    alpha: Shininess coefficient.
    p: Position of the point being lit.
    cam: Camera position.
*/
vec3 phongShading(vec3 a, vec3 d, vec3 s, float alpha, vec3 p, vec3 cam) {
    vec3 color = AMBIENT_LIGHT * a;
    vec3 lightPos = vec3(20.0, 20.0, 40.0);
    vec3 lightIntensity = vec3(0.4);

    color += light(d, s, alpha, p, cam, lightPos, lightIntensity);

    return color;
}

void main() {
    vec3 dir = rayDir(45.0, resolution, gl_FragCoord.xy);
    vec3 cam = vec3(0.0, 0.0, 50.0);
    float dist = raymarch(cam, dir, MIN_DIST, MAX_DIST);

    if(dist > MAX_DIST - EPSILON) {
        // Didn't hit anything.
        gl_FragColor = vec4(vec3(0.0), 1.0);
        return;
    }

    vec3 p = cam + dist * dir;
    vec3 a = vec3(0.0);
    vec3 d = vec3(0.95, 0.53, 0.7);
    vec3 s = vec3(1.0);
    float alpha = 100.0;

    vec3 color = phongShading(a, d, s, alpha, p, cam);

    gl_FragColor = vec4(color, 1.0);
}