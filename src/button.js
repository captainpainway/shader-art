import React from 'react';

export const Button = (props) => {
    const toggleClosed = () => {
        const newclass = (status) => {
            return status === 'closed' ? '' : 'closed';
        };
        props.onToggle(newclass);
    };

    return (
        <div className={"button"} style={{left: props.left, top: props.top}} onClick={toggleClosed}>
            {props.children}
        </div>
    )
};