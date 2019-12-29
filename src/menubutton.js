import React from 'react';
import './menubutton.css';

export const Menubutton = (props) => {
    return (
        <div>
            <div className={"ham1 " + props.togglestatus}></div>
            <div className={"ham2 " + props.togglestatus}></div>
            <div className={"ham3 " + props.togglestatus}></div>
        </div>
    )
};
