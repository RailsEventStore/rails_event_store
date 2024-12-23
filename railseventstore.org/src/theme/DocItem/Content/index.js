import React from "react";
import Content from "@theme-original/DocItem/Content";

export default function ContentWrapper(props) {
  return (
    <>
      <div className="prose prose-lg dark:prose-invert">
        <Content {...props} />
      </div>
    </>
  );
}
