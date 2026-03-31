import { apiInitializer } from "discourse/lib/api";
import { ajax } from "discourse/lib/ajax";

const cache = new Map();
let activeTooltip = null;

function extractTopicIdFromHref(href) {
  if (!href) return null;
  // Matches /t/slug/123 or /t/123
  const m = href.match(/^\/t\/(?:[^/]+\/)?(\d+)(?:\/.*)?$/);
  return m ? m[1] : null;
}

function fetchPreview(topicId) {
  if (cache.has(topicId)) {
    return cache.get(topicId);
  }

  const promise = ajax(`/t/${topicId}.json`).then((data) => {
    const cooked = data.post_stream?.posts?.[0]?.cooked || "";
    const excerpt = data.excerpt || cooked || "";
    return {
      id: data.id,
      title: data.title,
      url: data.slug ? `/t/${data.slug}/${data.id}` : `/t/${data.id}`,
      previewHtml: excerpt,
    };
  });

  cache.set(topicId, promise);
  return promise;
}

function showTooltip(trigger, model) {
  if (activeTooltip) {
    activeTooltip.remove();
  }

  const tooltip = document.createElement("div");
  tooltip.className = "topic-preview-tooltip";
  tooltip.innerHTML = `
    <div class="topic-preview-title">${model.title}</div>
    <div class="topic-preview-excerpt">${model.previewHtml}</div>
  `;

  document.body.appendChild(tooltip);
  activeTooltip = tooltip;

  const rect = trigger.getBoundingClientRect();
  tooltip.style.position = "fixed";
  tooltip.style.left = `${Math.min(rect.left, window.innerWidth - 400)}px`;
  tooltip.style.top = `${rect.bottom + 8}px`;
}

function hideTooltip() {
  if (activeTooltip) {
    activeTooltip.remove();
    activeTooltip = null;
  }
}

export default apiInitializer("topic-preview-safe", (api) => {
  console.log("[topic-preview-safe] initializer running");

  api.decorateCookedElement((element /*, helper */) => {
    console.log("[topic-preview-safe] decorateCookedElement", element);

    element
      .querySelectorAll(".post__contents a, .cooked a")
      .forEach((trigger) => {
        if (trigger.dataset.previewBound === "1") return;

        const href = trigger.getAttribute("href") || "";
        const topicId = extractTopicIdFromHref(href);
        if (!topicId) return; // not a /t/... internal topic link

        trigger.dataset.previewBound = "1";
        console.log("[topic-preview-safe] binding trigger", href, "->", topicId);

        let hoverTimer;

        trigger.addEventListener("mouseenter", () => {
          console.log("[topic-preview-safe] mouseenter", topicId);
          hoverTimer = window.setTimeout(async () => {
            const model = await fetchPreview(topicId);
            showTooltip(trigger, model);
          }, 200);
        });

        trigger.addEventListener("mouseleave", () => {
          console.log("[topic-preview-safe] mouseleave", topicId);
          window.clearTimeout(hoverTimer);
          hideTooltip();
        });

        trigger.addEventListener("click", async (e) => {
          console.log("[topic-preview-safe] click", topicId);
          e.preventDefault();
          const model = await fetchPreview(topicId);
          // For now, just navigate; later you can open DModal here.
          window.location.href = model.url;
        });
      });
  });
});
