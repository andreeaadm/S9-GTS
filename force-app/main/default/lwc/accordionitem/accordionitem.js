import { LightningElement, api } from "lwc";

export default class Accordionitem extends LightningElement {
  @api accordionItemClass;
  @api label;
  contentClassLocal = "";

  constructor() {
    super();
    this.template.addEventListener("click", this.recalculateMaxHeightOnClick);
  }

  @api get contentClass() {
    // item-content class is required in order for certain template.querySelectors to work
    return this.contentClassLocal &&
      this.contentClassLocal.includes("item-content")
      ? this.contentClassLocal
      : "item-content " + this.contentClassLocal;
  }
  set contentClass(value) {
    this.contentClassLocal = value;
  }

  doClick(evt) {
    evt.preventDefault();
    evt.stopPropagation();
    // accordion listens for this event and closes all accordion items if trueAccordion is true.
    // The event must bubble because accordionitems are added to accordion via slots
    // and so the event can only be handled by creating an event listener in accordion.js
    this.dispatchEvent(
      new CustomEvent("accordionitemclick", { bubbles: true })
    );
    this.toggleItem();
  }

  recalculateMaxHeightOnClick = () => {
    this.recalculateMaxHeight(true);
  };

  recalculateMaxHeight(isClick) {
    let itemContent = this.template.querySelector(".item-content");
    let contentSlot = this.template.querySelector(".contentslot");
    if (itemContent && contentSlot) {
      let contentNode = contentSlot.assignedNodes();
      if (contentNode && !isClick) {
        itemContent.style.maxHeight = itemContent.style.maxHeight
          ? ""
          : contentNode[0].clientHeight + 15 + "px";
      } else if (contentNode) {
        itemContent.style.maxHeight = contentNode[0].clientHeight + 15 + "px";
      }
    }
  }

  @api toggleItem() {
    this.accordionItemClass =
      this.accordionItemClass === "active" ? "" : "active";
    this.recalculateMaxHeight();
  }

  @api closeItem() {
    this.accordionItemClass = "";
    let itemContent = this.template.querySelector(".item-content");
    if (itemContent) {
      itemContent.style.maxHeight = "";
    }
  }
}