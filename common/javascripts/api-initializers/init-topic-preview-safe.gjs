import { apiInitializer } from "discourse/lib/api";
import { ajax } from "discourse/lib/ajax";

const cache = new Map();
let activeTooltip = null;

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
  tooltip.style.left = `${rect.left}px`;
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

    element.querySelectorAll(".topic-preview-trigger").forEach((trigger) => {
      if (trigger.dataset.previewBound === "1") return;
      trigger.dataset.previewBound = "1";

      console.log("[topic-preview-safe] binding trigger", trigger);

      const topicId = trigger.dataset.topicId;
      if (!topicId) {
        console.warn("[topic-preview-safe] missing data-topic-id on trigger");
        return;
      }

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
        window.location.href = model.url;
      });
    });
  });
});
