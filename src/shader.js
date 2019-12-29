import React from 'react';
import './shader.css';

class Shader extends React.Component {
    constructor(props) {
        super(props);
        this.canvas = document.createElement('canvas');
        this.gl = null;
        this.currentProgram = null;
        this.timeLocation = null;
        this.resolutionLocation = null;
        this.buffer = null;
        this.parameters = {
            start_time: new Date().getTime(),
            screenWidth: 0,
            screenHeight: 0
        };
        this.state = {
            time: 0,
            vertex_shader: this.props.vertex,
            fragment_shader: this.props.fragment
        };
        this.animationFrame = null;
    }

    async componentDidMount() {
        await this.startShaders();
        await this.animate();
    }

    async startShaders() {
        const vertex_shader = await this.importShader(this.state.vertex_shader);
        const fragment_shader = await this.importShader(this.state.fragment_shader);

        try {
            this.gl = this.canvas.getContext('experimental-webgl');
        } catch(err) {}

        if(!this.gl) {
            throw "Cannot create WebGL context."
        }

        this.buffer = this.gl.createBuffer();
        this.gl.bindBuffer(this.gl.ARRAY_BUFFER, this.buffer);
        this.gl.bufferData(this.gl.ARRAY_BUFFER, new Float32Array([-1.0, -1.0, 1.0, -1.0, -1.0, 1.0, 1.0, -1.0, 1.0, 1.0, -1.0, 1.0]), this.gl.STATIC_DRAW);

        this.currentProgram = this.createShaderProgram(vertex_shader, fragment_shader);

        this.timeLocation = this.gl.getUniformLocation(this.currentProgram, 'time');
        this.resolutionLocation = this.gl.getUniformLocation(this.currentProgram, 'resolution');
    }

    componentDidUpdate(prevProps, prevState, snapshot) {
        if (this.props != prevProps) {
            this.setState({vertex_shader: this.props.vertex});
            this.setState({fragment_shader: this.props.fragment});
            this.startShaders();
        }
        this.animationFrame = requestAnimationFrame(this.animate.bind(this));
    }

    componentWillUnmount() {
        cancelAnimationFrame(this.animationFrame);
    }

    async importShader(shader) {
        let response = await fetch(shader);
        return await response.text();
    }

    createShaderProgram(vertex, fragment) {
        const program = this.gl.createProgram(),
            vert_shader = this.createShader(vertex, this.gl.VERTEX_SHADER),
            frag_shader = this.createShader(fragment, this.gl.FRAGMENT_SHADER);

        if (vert_shader === null || frag_shader === null) {
            return null;
        }

        this.gl.attachShader(program, vert_shader);
        this.gl.attachShader(program, frag_shader);

        this.gl.deleteShader(vert_shader);
        this.gl.deleteShader(frag_shader);

        this.gl.linkProgram(program);

        return program;
    }

    createShader(src, type) {
        const shader = this.gl.createShader(type);
        this.gl.shaderSource(shader, src);
        this.gl.compileShader(shader);

        if(!this.gl.getShaderParameter(shader, this.gl.COMPILE_STATUS)) {
            console.log((type == this.gl.VERTEX_SHADER ? "VERTEX" : "FRAGMENT") + " SHADER:\n" + this.gl.getShaderInfoLog(shader));
            return null;
        }

        return shader;
    }

    resize() {
        if(this.canvas.width != this.canvas.clientWidth || this.canvas.height != this.canvas.clientHeight) {
            this.canvas.width = this.canvas.clientWidth;
            this.canvas.height = this.canvas.clientHeight;
            this.parameters.screenWidth = this.canvas.width;
            this.parameters.screenHeight = this.canvas.height;
            this.gl.viewport(0, 0, this.canvas.width, this.canvas.height);
        }
    }

    animate() {
        this.resize();
        this.setState({time: new Date().getTime() - this.parameters.start_time});

        this.gl.clear(this.gl.COLOR_BUFFER_BIT | this.gl.DEPTH_BUFFER_BIT);
        this.gl.useProgram(this.currentProgram);
        this.gl.uniform1f(this.timeLocation, this.state.time / 1000);
        this.gl.uniform2f(this.resolutionLocation, this.parameters.screenWidth, this.parameters.screenHeight);

        this.gl.bindBuffer(this.gl.ARRAY_BUFFER, this.buffer);
        this.gl.vertexAttribPointer(this.vertex_position, 2, this.gl.FLOAT, false, 0, 0);
        this.gl.enableVertexAttribArray(this.vertex_position);
        this.gl.drawArrays(this.gl.TRIANGLES, 0, 6);
        this.gl.disableVertexAttribArray(this.vertex_position);
    }

    render() {
        return (
            <div style={{height: '100%'}} ref={(nodeElement) => {nodeElement && nodeElement.appendChild(this.canvas)}}/>
        )
    }
}

export default Shader;
