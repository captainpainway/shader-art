window.requestAnimationFrame =  window.requestAnimationFrame || (() => {
    return window.webkitRequestAnimationFrame ||
        window.mozRequestAnimationFrame ||
        window.oRequestAnimationFrame ||
        window.msRequestAnimationFrame ||
        function (callback) {
            window.setTimeout(callback, 1000/60);
        }
});

let canvas,
    gl,
    buffer,
    vertex_shader,
    fragment_shader,
    currentProgram,
    vertex_position,
    timeLocation,
    resolutionLocation,
    parameters = {
        start_time: new Date().getTime(),
        time: 0,
        screenWidth: 0,
        screenHeight: 0
    };

init();

async function importShader(shader) {
    let response = await fetch(shader);
    let data = await response.text();
    return data;
}

async function init() {
    fragment_shader = await importShader('fragmentshader.glsl');
    vertex_shader = await importShader('vertexshader.glsl');

    canvas = document.querySelector('canvas');

    try {
        gl = canvas.getContext('experimental-webgl');
    } catch(err) {}

    if(!gl) {
        throw "Cannot create WebGL context."
    }

    buffer = gl.createBuffer();
    gl.bindBuffer(gl.ARRAY_BUFFER, buffer);
    gl.bufferData(gl.ARRAY_BUFFER, new Float32Array([-1.0, -1.0, 1.0, -1.0, -1.0, 1.0, 1.0, -1.0, 1.0, 1.0, -1.0, 1.0]), gl.STATIC_DRAW);

    currentProgram = createProgram(vertex_shader, fragment_shader);

    resolutionLocation = gl.getUniformLocation(currentProgram, 'resolution');

    animate();
}

function createProgram(vertex, fragment) {
    const program = gl.createProgram(),
        vert_shader = createShader(vertex, gl.VERTEX_SHADER),
        frag_shader = createShader(fragment, gl.FRAGMENT_SHADER);

    if (vert_shader === null || frag_shader === null) {
        return null;
    }

    gl.attachShader(program, vert_shader);
    gl.attachShader(program, frag_shader);

    gl.deleteShader(vert_shader);
    gl.deleteShader(frag_shader);

    gl.linkProgram(program);

    return program;
}

function createShader(src, type) {
    const shader = gl.createShader(type);
    gl.shaderSource(shader, src);
    gl.compileShader(shader);

    if(!gl.getShaderParameter(shader, gl.COMPILE_STATUS)) {
        console.log((type == gl.VERTEX_SHADER ? "VERTEX" : "FRAGMENT") + " SHADER:\n" + gl.getShaderInfoLog(shader));
        return null;
    }

    return shader;
}

function resize() {
    if(canvas.width != canvas.clientWidth || canvas.height != canvas.clientHeight) {
        canvas.width = canvas.clientWidth;
        canvas.height = canvas.clientHeight;
        parameters.screenWidth = canvas.width;
        parameters.screenHeight = canvas.height;
        gl.viewport(0, 0, canvas.width, canvas.height);
    }
}

function animate() {
    resize();
    render();
    requestAnimationFrame(animate);
}

function render() {
    if(!currentProgram) {
        return;
    }

    parameters.time = new Date().getTime() - parameters.start_time;

    gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
    gl.useProgram(currentProgram);
    gl.uniform2f(resolutionLocation, parameters.screenWidth, parameters.screenHeight);

    gl.bindBuffer(gl.ARRAY_BUFFER, buffer);
    gl.vertexAttribPointer(vertex_position, 2, gl.FLOAT, false, 0, 0);
    gl.enableVertexAttribArray(vertex_position);
    gl.drawArrays(gl.TRIANGLES, 0, 6);
    gl.disableVertexAttribArray(vertex_position);
}
