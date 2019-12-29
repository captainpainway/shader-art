import React, {useState} from 'react';
import {Button} from './button';
import './code.css';
import {Codebutton} from "./codebutton";

export const Code = (props) => {
    const [toggle, setToggle] = useState('closed');

    return (
        <div className={"code " + toggle}>
            <Button left={'510px'} top={'60px'} onToggle={(val) => setToggle(val)}>
                <Codebutton togglestatus={toggle}/>
            </Button>
            <div className="select">
                <div className="vertex_code">{props.vertex}</div>
                <div className="fragment_code">{props.fragment}</div>
            </div>
        </div>
    )
};
