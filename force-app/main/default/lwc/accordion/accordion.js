import { LightningElement, api } from "lwc";

export default class Accordion extends LightningElement {
  // Should the accordion behave like a "true" accordion - i.e. there can only ever be one accordion item open at once
  @api trueAccordion = false;
  // Should all items be open by default? Only valid where trueAccordion = false
  @api allOpenByDefault = false;
  // A class that gets applied to the accordion ul
  @api accordionClass;
  @api get openItem() {
    return this._openItem;
  }
  set openItem(value) {
    this._openItem = value;
    if (value !== undefined && value !== null && this.hasRendered) {
      this.toggleItemByIndex(value);
    }
  }

  _openItem; // index, first item being 0
  hasRendered = false;

  constructor() {
    super();
    this.template.addEventListener(
      "accordionitemclick",
      this.handleAccordionItemClick.bind(this)
    );
  }

  renderedCallback() {
    if (!this.hasRendered) {
      if (this.allOpenByDefault && !this.trueAccordion) {
        this.toggleAllItems();
      } else if (this.openItem !== undefined && this.openItem !== null) {
        this.openItem = parseInt(this.openItem);
        this.toggleItemByIndex(this.openItem);
      }
      this.hasRendered = true;
    }
  }

  handleAccordionItemClick(evt) {
    evt.stopPropagation();
    if (this.trueAccordion) {
      this.closeAllItems();
    }
  }

  toggleItemByIndex(index) {
    let contentSlot, contentNodes;
    contentSlot = this.template.querySelector(".content");
    if (contentSlot) {
      contentNodes = contentSlot.assignedNodes();
    }
    for (let i = 0; i < contentNodes.length; i++) {
      if (i !== index) {
        contentNodes[i].closeItem();
      } else {
        contentNodes[i].toggleItem();
      }
    }
  }

  closeAllItems() {
    let contentSlot = this.template.querySelector(".content");
    let contentNodes = contentSlot.assignedNodes();
    contentNodes.forEach((item) => {
      item.closeItem();
    });
  }

  toggleAllItems() {
    let contentSlot = this.template.querySelector(".content");
    let contentNodes = contentSlot.assignedNodes();
    contentNodes.forEach((item) => {
      item.toggleItem();
    });
  }
}