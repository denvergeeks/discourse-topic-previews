import Component from "@glimmer/component";
import DModal from "discourse/components/d-modal";

export default class TopicPreviewModal extends Component {
  get model() {
    return this.args.model;
  }

  <template>
    <DModal @title={{this.model.title}}>
      <:body>
        <div class="topic-preview-modal">
          <div class="topic-preview-excerpt">{{html-safe this.model.previewHtml}}</div>
          <a class="btn btn-primary" href={{this.model.url}}>Open topic</a>
        </div>
      </:body>
    </DModal>
  </template>
}
