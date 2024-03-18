import { LightningElement, api, track, wire } from "lwc";
import getAllItemsForType from "@salesforce/apex/CMSController.getAllItemsForType";

export default class Cmstilecollection extends LightningElement {
  // MAXIMUM items displayed per page is 24, despite CMS supporting up to 25 items per page.
  // This is to ensure we always have sufficient room to work out whether there are more CMS items to view,
  // beyond what the user can currently see
  @api get itemsPerPage() {
    return this._itemsPerPage;
  }
  set itemsPerPage(value) {
    this._itemsPerPage = value;
    this.itemsPerPagePadded = value > 24 ? 24 : value;
  }
  @api managedContentType = "";
  @api buttonLabel = "Read More";
  @api titleColour = "#FFF";
  @api subtitleColour = "#FFF";
  @api bodyColour = "#FFF";
  @api buttonLabelColour = "#FFF";
  @api buttonBorderColour = "#FFF";
  @api buttonVariant = "btn2";
  @api colOrRowContents = "row";
  @api alignContentsV = false;
  @api alignContentsH = false;
  @api reverseContents = false;
  @api additionalClasses = "cms-tile";
  @api showTitle;
  @api disableLinkify = false;
  @api titleFieldName = "Title";
  @api subtitleFieldName = "Summary";
  @api orderingFieldName = "";
  @api imageFieldName = "";
  @api enableTwoColumns;
  @track items;
  @track error;

  @track data;
  @track error;
  @track pageNumber = 0;
  @track disableNext = true;

  tileType = "Info";

  renderedCallback() {
    if (this.hasRendered) {
      return;
    }
    if (this.enableTwoColumns) {
      this.template.querySelector(".tiles").classList.add("flex");
    }
    this.hasRendered = true;
  }

  @wire(getAllItemsForType, {
    managedContentType: "$managedContentType",
    itemsPerPage: "$itemsPerPage",
    pageNumber: "$pageNumber"
  })
  wiredContent({ error, data }) {
    if (data) {
      this.disableNext = !data.moreItemsAvailable;
      let tempData = [].concat(JSON.parse(JSON.stringify(data.content.items)));
      tempData = this.processReturnData(tempData);
      this.data = tempData;
      this.error = undefined;
    } else if (error) {
      this.error = error;
      this.data = undefined;
    }
  }

  nextPage() {
    this.pageNumber++;
  }

  previousPage() {
    this.pageNumber--;
  }

  get pageNumberOffset() {
    return this.pageNumber + 1;
  }

  get disablePrevious() {
    return this.pageNumber == 0;
  }

  processReturnData(items) {
    for (let item of items) {
      if (!item.contentNodes[this.orderingFieldName]) {
        item.contentNodes[this.orderingFieldName] = { value: "" };
      }
      item.contentNodes.title = {
        value:
          this.showTitle && item.contentNodes[this.titleFieldName]
            ? item.contentNodes[this.titleFieldName].value
            : ""
      };
      item.contentNodes.subtitle = {
        value: item.contentNodes[this.subtitleFieldName]
          ? item.contentNodes[this.subtitleFieldName].value
              .replaceAll("&lt;", "<")
              .replaceAll("&gt;", ">")
          : ""
      };
      item.contentNodes.image = {
        url: item.contentNodes[this.imageFieldName]
          ? item.contentNodes[this.imageFieldName].url
          : ""
      };
      item.contentUrl =
        "/" +
        this.managedContentType.replaceAll("_", "-").toLowerCase() +
        "/" +
        item.contentUrlName +
        "-" +
        item.contentKey;
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