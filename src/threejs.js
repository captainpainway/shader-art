import React from 'react';

export const Three = (props) => {

    let script = document.createElement('script');
    script.src = `${props.scene}`;
    script.id = 'three_script';
    document.body.appendChild(script);

    return (
        <div id="threejs"></div>
    )
};
