import { apiInitializer } from "discourse/lib/api";
import { ajax } from "discourse/lib/ajax";
import { schedule } from "@ember/runloop";
import TopicPreviewTooltip from "../components/topic-preview-tooltip";
import TopicPreviewModal from "../components/topic-preview-modal";

const cache = new Map();
let tooltipHost = null;

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

function closeTooltip() {
  if (tooltipHost) {
    tooltipHost.remove();
    tooltipHost = null;
  }
}

function ensureTooltipHost() {
  if (tooltipHost) {
    return tooltipHost;
  }

  tooltipHost = document.createElement("div");
  tooltipHost.className = "topic-preview-tooltip-host";
  document.body.appendChild(tooltipHost);
  return tooltipHost;
}

function openModal(modal, model) {
  modal.show(TopicPreviewModal, { model });
}

export default apiInitializer((api) => {
  api.decorateCookedElement((element, helper) => {
    const post = helper.getPost();
    if (!post) return;

    const settings = api.container.lookup("service:theme-settings")?.themeSettings || {};
    const modal = api.container.lookup("service:modal");

    element.querySelectorAll(".topic-preview-trigger").forEach((trigger) => {
      if (trigger.dataset.previewBound === "1") return;
      trigger.dataset.previewBound = "1";

      const topicId = trigger.dataset.topicId;
      if (!topicId || !isAllowed(topicId, settings)) return;

      let hoverTimer = null;

      trigger.addEventListener("mouseenter", () => {
        hoverTimer = window.setTimeout(async () => {
          const model = await fetchPreview(topicId, settings);

          closeTooltip();
          const host = ensureTooltipHost();

          schedule("afterRender", () => {
            api.renderGlimmer
              ? api.renderGlimmer(TopicPreviewTooltip, host, {
                  model,
                  anchor: trigger,
                  onOpenModal: () => openModal(modal, model),
                  onClose: closeTooltip,
                })
              : null;
          });
        }, Number(settings.hover_delay_ms || 180));
      });

      trigger.addEventListener("mouseleave", () => {
        if (hoverTimer) window.clearTimeout(hoverTimer);
        closeTooltip();
      });

      trigger.addEventListener("click", async (e) => {
        e.preventDefault();
        const model = await fetchPreview(topicId, settings);
        openModal(modal, model);
      });
    });
  });
});
