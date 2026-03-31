import { apiInitializer } from "discourse/lib/api";

export default apiInitializer("topic-preview-debug", (api) => {
  console.log("[topic-preview-debug] initializer running");

  api.decorateCookedElement((element /*, helper */) => {
    console.log("[topic-preview-debug] decorateCookedElement", element);

    const links = element.querySelectorAll(".post__contents a, .cooked a");
    console.log("[topic-preview-debug] found links:", links.length);

    links.forEach((link) => {
      const href = link.getAttribute("href") || "";
      console.log("[topic-preview-debug] link href:", href);

      const m = href.match(/^\/t\/(?:[^/]+\/)?(\d+)(?:\/.*)?$/);
      if (!m) return;

      const topicId = m[1];
      console.log("[topic-preview-debug] INTERNAL TOPIC LINK ->", topicId);

      if (link.dataset.previewBound === "1") return;
      link.dataset.previewBound = "1";

      link.addEventListener("mouseenter", () => {
        console.log("[topic-preview-debug] HOVER on topic", topicId);
        link.style.backgroundColor = "yellow"; // visible debug effect
      });

      link.addEventListener("mouseleave", () => {
        console.log("[topic-preview-debug] LEAVE topic", topicId);
        link.style.backgroundColor = "";
      });
    });
  });
});
