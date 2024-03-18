import { LightningElement, api, track, wire } from "lwc";
import getAllItemsForType from "@salesforce/apex/CMSController.getAllItemsForType";

export default class CmsAccordion extends LightningElement {
  @api managedContentType = "FAQ";
  @api titleFieldName = "Question";
  @api contentFieldName = "Answer";
  @api orderingFieldName = "Order";
  @track items;
  @track error;

  @api get topics() {
    return this._topics?.length > 0 ? this._topics : undefined;
  }
  set topics(value) {
    this._topics = value?.includes(",")
      ? value.split(/\s*,\s*/)
      : value?.length > 0
      ? [value.trim()]
      : [];
  }

  _topics = [];
  @wire(getAllItemsForType, {
    managedContentType: "$managedContentType",
    topics: "$_topics",
    itemsPerPage: null,
    pageNumber: null,
    language: null
  })
  wiredContent({ error, data }) {
    if (data) {
      let tempData = [].concat(JSON.parse(JSON.stringify(data.content.items)));
      tempData = this.processReturnData(tempData);
      this.items = tempData;
      this.error = undefined;
    } else if (error) {
      this.error = error;
      this.items = undefined;
    }
  }

  processReturnData(items) {
    for (let item of items) {
      if (!item.contentNodes[this.orderingFieldName]) {
        item.contentNodes[this.orderingFieldName] = { value: "" };
      }
      item.contentNodes.title = {
        value: item.contentNodes[this.titleFieldName]
          ? item.contentNodes[this.titleFieldName].value
          : ""
      };
      item.contentNodes.content = {
        value: item.contentNodes[this.contentFieldName]
          ? item.contentNodes[this.contentFieldName].value
              .replaceAll("&lt;", "<")
              .replaceAll("&gt;", ">")
              .replaceAll("&amp;", "&")
              .replaceAll("&quot;", '"')
          : ""
      };
    }
    items.sort((a, b) =>
      a.contentNodes[this.orderingFieldName].value >
      b.contentNodes[this.orderingFieldName].value
        ? 1
        : -1
    );
    return items;
  }
}