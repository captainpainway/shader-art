import React from 'react';
import Shader from './shader';
import {Select} from './select';
import {Three} from './threejs';
import './app.css';

class App extends React.Component {
    constructor(props) {
        super(props);
        this.shaders = [
            'glsl-squishydonutspin',
            'glsl-bumpy-sphere',
            'glsl-kaleidoscope',
            'glsl-mandelbrot',
            'glsl-juliafractal',
            'glsl-cubes',
            'glsl-random-lines',
            'glsl-spinning-color-wheel',
            'glsl-just-a-cube',
            'glsl-very-basic',
            'threejs-icosphere-explode',
        ];
        this.state = {
            shader: this.shaders[0],
            openpopin: null
        };
        this.selectShader = this.selectShader.bind(this);
        this.vertex_shader = null;
        this.fragment_shader = null;
    }

    selectShader(value) {
        this.setState({shader: value});
    }

    render() {
        if (document.getElementById('three_script')) {
            document.body.removeChild(document.getElementById('three_script'));
        }
        let canvas;
        if (this.state.shader.search(/^threejs/) !== -1) {
            canvas = <Three scene={`${this.state.shader}/scene.js`}/>
        } else {
            canvas = <Shader vertex={`${this.state.shader}/vertexshader.glsl`} fragment={`${this.state.shader}/fragmentshader.glsl`}/>
        }
        return (
            <div style={{height: '100%'}}>
                <Select shaderlist={this.shaders} onSelect={this.selectShader}/>
                {canvas}
            </div>
        )
    }
}

export default App;
