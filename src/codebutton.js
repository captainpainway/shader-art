import React from 'react';
import './codebutton.css';

export const Codebutton = (props) => {
    return (
        <div>
            <div className={"code1 " + props.togglestatus}></div>
            <div className={"code2 " + props.togglestatus}></div>
            <div className={"code3 " + props.togglestatus}></div>
        </div>
    )
};
