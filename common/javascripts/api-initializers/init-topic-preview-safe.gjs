import { apiInitializer } from "discourse/lib/api";
import { ajax } from "discourse/lib/ajax";

const cache = new Map();
let activeTooltip = null;

function getAllowedTopicIds(settings) {
  return (settings.enabled_topics || "")
    .split(",")
    .map((s) => s.trim())
    .filter(Boolean);
}

function isAllowed(topicId, settings) {
  const allowed = getAllowedTopicIds(settings);
  return allowed.length === 0 || allowed.includes(String(topicId));
}

function fetchPreview(topicId, settings) {
  const key = `${topicId}:${settings.preview_mode}`;
  if (cache.has(key)) {
    return cache.get(key);
  }

  const promise = ajax(`/t/${topicId}.json`).then((data) => {
    const cooked = data.post_stream?.posts?.[0]?.cooked || "";
    const excerpt = data.excerpt || "";
    return {
      id: data.id,
      title: data.title,
      url: data.slug ? `/t/${data.slug}/${data.id}` : `/t/${data.id}`,
      excerpt,
      cooked,
      previewHtml: settings.preview_mode === "cooked" ? (cooked || excerpt) : (excerpt || cooked),
    };
  });

  cache.set(key, promise);
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
    <div class="topic-preview-actions">
      <a href="${model.url}" class="btn btn-small btn-primary">Open</a>
      <button type="button" class="btn btn-small btn-secondary close-tooltip">Close</button>
    </div>
  `;

  document.body.appendChild(tooltip);
  activeTooltip = tooltip;

  // Position tooltip
  const rect = trigger.getBoundingClientRect();
  tooltip.style.position = "fixed";
  tooltip.style.left = `${Math.min(rect.left, window.innerWidth - 380)}px`;
  tooltip.style.top = `${rect.bottom + 8}px`;
  tooltip.style.maxWidth = "380px";

  tooltip.querySelector(".close-tooltip").onclick = () => hideTooltip();
}

function hideTooltip() {
  if (activeTooltip) {
    activeTooltip.remove();
    activeTooltip = null;
  }
}

function openModal(modal, model) {
  modal.show("topic-preview-modal", { model });
}

export default apiInitializer((api) => {
  api.decorateCookedElement((element, helper) => {
    // REMOVED: const post = helper.getPost();  <-- This was causing the error
    // No post check needed for tooltip triggers

    const settings = api.container.lookup("service:theme-settings")?.themeSettings || {};
    const modal = api.container.lookup("service:modal");

    element.querySelectorAll(".topic-preview-trigger").forEach((trigger) => {
      if (trigger.dataset.previewBound === "1") return;
      trigger.dataset.previewBound = "1";

      const topicId = trigger.dataset.topicId;
      if (!topicId || !isAllowed(topicId, settings)) return;

      let hoverTimer;

      trigger.addEventListener("mouseenter", () => {
        hoverTimer = window.setTimeout(async () => {
          const model = await fetchPreview(topicId, settings);
          showTooltip(trigger, model);
        }, Number(settings.hover_delay_ms || 180));
      });

      trigger.addEventListener("mouseleave", () => {
        window.clearTimeout(hoverTimer);
        hideTooltip();
      });

      trigger.addEventListener("click", async (e) => {
        e.preventDefault();
        const model = await fetchPreview(topicId, settings);
        openModal(modal, model);
      });
    });
  });
});
