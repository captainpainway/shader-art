#ifdef GL_ES
precision highp float;
#endif

// This is the canvas width and height from boilerplate.js.
uniform vec2 resolution;

void main() {
    // Get the coordinates of each fragment shader pixel.
    vec2 s = gl_FragCoord.xy / resolution;

    vec3 color;
    if (gl_FragCoord.x < resolution.x / 2.0) {
        // Half the screen gets one horizontal gradient...
        color = vec3(1.0 * s.y, 0.7, 0.3);
    } else {
        // ...The other half of the screen gets another.
        color = vec3(0.3, 0.75 * s.y, 0.7);
    }

    // Put the colors on the screen.
    gl_FragColor = vec4(color, 1.0);
}
