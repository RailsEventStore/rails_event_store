import BrowserOnly from '@docusaurus/BrowserOnly';
import React, { useEffect, useRef } from 'react';
import 'asciinema-player/dist/bundle/asciinema-player.css';

const AsciinemaWidget = ({ src, id}) => {
  return (
    <BrowserOnly fallback={<div>Loading asciinema cast...</div>}>
      {() => {
        const ref = useRef(null);

        useEffect(() => {
            const script = document.createElement('script');
            script.src = src;
            script.id = id;
            script.async = true;
            ref.current.appendChild(script);
        
            return () => {
              ref.current.removeChild(script);
            };
          }, [ref,src, id]);

        return <div ref={ref} />;
      }}
    </BrowserOnly>
  );
};

export default AsciinemaWidget;