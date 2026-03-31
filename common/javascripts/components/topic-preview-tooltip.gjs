import Component from "@glimmer/component";
import DTooltip from "discourse/float-kit/components/d-tooltip";

export default class TopicPreviewTooltip extends Component {
  get model() {
    return this.args.model;
  }

  get onOpenModal() {
    return this.args.onOpenModal;
  }

  get onClose() {
    return this.args.onClose;
  }

  <template>
    <DTooltip @placement="top" @interactive={{true}}>
      <:content>
        <div class="topic-preview-tooltip">
          <div class="topic-preview-title">{{this.model.title}}</div>
          <div class="topic-preview-excerpt">{{html-safe this.model.previewHtml}}</div>

          <div class="topic-preview-actions">
            <button type="button" class="btn btn-small btn-primary" {{on "click" this.onOpenModal}}>
              Open
            </button>
            <button type="button" class="btn btn-small" {{on "click" this.onClose}}>
              Close
            </button>
          </div>
        </div>
      </:content>
    </DTooltip>
  </template>
}
