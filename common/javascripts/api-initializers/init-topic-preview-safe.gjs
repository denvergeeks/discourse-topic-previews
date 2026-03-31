import { apiInitializer } from "discourse/lib/api";

export default apiInitializer("topic-preview-hello", (api) => {
  // 1) Global proof of life
  console.log(
    "[topic-preview-hello] theme component JS LOADED for site:",
    window.location.hostname
  );

  // 2) Every decoration proof
  api.decorateCookedElement((element /*, helper */) => {
    console.log(
      "[topic-preview-hello] decorateCookedElement on",
      element.tagName,
      element.className
    );

    // Visually mark the element
    element.style.outline = "3px solid magenta";
  });
});
