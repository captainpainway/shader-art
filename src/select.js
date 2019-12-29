import React, {useState} from 'react';
import {Button} from './button';
import './select.css';
import {Menubutton} from "./menubutton";

export const Select = (props) => {
    const [toggle, setToggle] = useState('closed');
    const [shader, setShader] = useState(props.shaderlist[0]);

    const newShader = (ele) => {
        setShader(ele);
        setToggle(!toggle ? 'closed': '');
        props.onSelect(ele);
    };

    const list = props.shaderlist.map(item => <li key={item} onClick={() => newShader(item)}>{item}</li>)

    return (
        <div className={"menu " + toggle}>
            <Button left={'310px'} top={'10px'} onToggle={(val) => setToggle(val)}>
                <Menubutton togglestatus={toggle}/>
            </Button>
            <div className="select">
                <h1>Shaders</h1>
                <ul>{list}</ul>
            </div>
        </div>
    )
};

