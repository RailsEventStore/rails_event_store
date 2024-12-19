import BrowserOnly from "@docusaurus/BrowserOnly";
import React, { useEffect, useRef } from "react";

const AsciinemaContent = ({ src, id }) => {
  const ref = useRef(null);

  useEffect(() => {
    const script = document.createElement("script");
    script.src = src;
    script.id = id;
    script.async = true;
    ref.current?.appendChild(script);

    return () => {
      ref.current?.removeChild(script);
    };
  }, [src, id]);

  return <div ref={ref} />;
};

const AsciinemaWidget = (props) => {
  return (
    <BrowserOnly fallback={<div>Loading asciinema cast...</div>}>
      {() => <AsciinemaContent {...props} />}
    </BrowserOnly>
  );
};

export default AsciinemaWidget;
