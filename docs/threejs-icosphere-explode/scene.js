(function () {
    let camera, scene, renderer, controls;
    let material, mesh, materialShader;
    let particleMaterial, particleMaterialShader;

    init();
    animate();

    function init() {

        camera = new THREE.PerspectiveCamera( 70, window.innerWidth / window.innerHeight, 0.01, 10 );
        camera.position.set(-1, 0, 1);

        scene = new THREE.Scene();

        var light = new THREE.PointLight( 0xffffff, 1, 10 );
        light.position.set(0, 1, 1)
        camera.add(light);
        scene.add(camera);

        var ambient = new THREE.AmbientLight(0xffffff, 0.5);
        scene.add(ambient);

        createOuterIco();
        createSparkles();

        renderer = new THREE.WebGLRenderer( { antialias: true } );
        renderer.setSize( window.innerWidth, window.innerHeight );
        let appendLocation = document.getElementById('threejs');
        appendLocation.appendChild( renderer.domElement );

        controls = new THREE.OrbitControls(camera, renderer.domElement);
        controls.autoRotate = true;
        controls.enableDamping = true;

    }

    function createOuterIco() {
        let geometry = new THREE.IcosahedronBufferGeometry( 0.5, 0 );
        material = new THREE.MeshPhongMaterial();
        material.color.setRGB(0.7, 0.9, 0.95);
        material.opacity = 1.0;
        material.transparent = true;
        material.side = THREE.DoubleSide;

        let position = geometry.attributes.position;
        let numfaces = position.count / 3;
        let displacement = new Float32Array(position.count * 3);

        for (let f = 0; f < numfaces; f++) {
            let index = 9*f;

            for (let i = 0; i < 3; i++) {
                displacement[index + (3 * i)] = 1.0;
                displacement[index + (3 * i) + 1] = 1.0;
                displacement[index + (3 * i) + 2] = 1.0;
            }
        }

        geometry.setAttribute('displacement', new THREE.BufferAttribute(displacement, 3));

        material.onBeforeCompile = (shader) => {
            const token = '#include <worldpos_vertex>';
            shader.uniforms.amount = {value: 0.0};
            shader.vertexShader = `
            attribute vec3 displacement;
            uniform float amount;
        ` + shader.vertexShader;

            let shaderText = `
            vec3 newPosition = position + normal * displacement * amount;
            gl_Position = projectionMatrix * modelViewMatrix * vec4( newPosition, 1.0 );
        `;

            shader.vertexShader = shader.vertexShader.replace(token, shaderText);
            materialShader = shader;
        };

        mesh = new THREE.Mesh( geometry, material );
        scene.add( mesh );
    }

    function createSparkles() {
        let particles = new THREE.IcosahedronBufferGeometry(0.01, 4);
        particleMaterial = new THREE.PointsMaterial();
        let particleSystem = new THREE.Points(particles, particleMaterial);

        let position = particles.attributes.position;
        let numfaces = position.count / 3;
        let displacement = new Float32Array(position.count * 3);


        for (let f = 0; f < numfaces; f++) {
            let index = 9*f;

            for (let i = 0; i < 3; i++) {
                displacement[index + (3 * i)] = 1.0;
                displacement[index + (3 * i) + 1] = 1.0;
                displacement[index + (3 * i) + 2] = 1.0;
            }
        }
        particles.setAttribute('displacement', new THREE.BufferAttribute(displacement, 3, true));

        particleMaterial.onBeforeCompile = (shader) => {
            const token = '#include <worldpos_vertex>';
            shader.uniforms.amount = {value: 0.0};
            shader.uniforms.u_resolution = {type: 'v2', value: new THREE.Vector2(renderer.domElement.width, renderer.domElement.height)};
            shader.vertexShader = `
            attribute vec3 displacement;
            uniform float amount;
        ` + shader.vertexShader;

            let shaderText = `
            gl_PointSize = 2.0;
            vec3 newPosition = position + normal * displacement * amount;
            gl_Position = projectionMatrix * modelViewMatrix * vec4( newPosition, 1.0 );
        `;

            shader.vertexShader = shader.vertexShader.replace(token, shaderText);

            shader.fragmentShader = `
            uniform vec2 u_resolution;
        ` + shader.fragmentShader;

            let fragShaderNoise = `
            float random (in vec2 st) {
                return fract(sin(dot(st.xy, vec2(12.9898,78.233))) * 43758.5453123);
            }
            float noise (in vec2 st) {
                vec2 i = floor(st);
                vec2 f = fract(st);

                // Four corners in 2D of a tile
                float a = random(i);
                float b = random(i + vec2(1.0, 0.0));
                float c = random(i + vec2(0.0, 1.0));
                float d = random(i + vec2(1.0, 1.0));

                // Smooth Interpolation

                // Cubic Hermine Curve.  Same as SmoothStep()
                vec2 u = f*f*(3.0-2.0*f);
                // u = smoothstep(0.,1.,f);

                // Mix 4 corners percentages
                return mix(a, b, u.x) +
                        (c - a)* u.y * (1.0 - u.x) +
                        (d - b) * u.x * u.y;
            } 
        `;
            let fragShaderMain = `
            vec2 st = gl_FragCoord.xy;

            // Scale the coordinate system to see
            // some noise in action
            vec2 pos = vec2(st / 8.0);

            // Use the noise function
            float n = noise(pos);

            gl_FragColor = vec4(vec3(n), 1.0);
        `;
            shader.fragmentShader = shader.fragmentShader.replace('#include <common>', fragShaderNoise);
            shader.fragmentShader = shader.fragmentShader.replace('#include <premultiplied_alpha_fragment>', fragShaderMain);
            particleMaterialShader = shader;
        };

        scene.add(particleSystem);
    }

    function animate() {

        requestAnimationFrame( animate );

        if (materialShader) {
            materialShader.uniforms.amount.value = Math.abs((controls.getPolarAngle() - Math.PI / 2)) * 0.2;
            material.opacity = 1.0 - Math.abs((controls.getPolarAngle() - Math.PI / 2)) * 0.1;
        }
        if (particleMaterialShader) {
            particleMaterialShader.uniforms.amount.value = Math.abs((controls.getPolarAngle() - Math.PI / 2)) * 0.8;
        }

        controls.update();

        renderer.render( scene, camera );

    }
})()
