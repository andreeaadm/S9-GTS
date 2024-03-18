import { LightningElement, api, track, wire } from "lwc";
import getSingleItem from "@salesforce/apex/CMSController.getSingleItem";

export default class Cmstile extends LightningElement {
  @api contentKey;
  @api managedContentType = "Info";
  @api titleColour = "rgb(47, 46, 46)";
  @api subtitleColour = "rgb(47, 46, 46)";
  @api bodyColour = "rgb(47, 46, 46)";
  @api buttonLabelColour = "rgb(47, 46, 46)";
  @api buttonBorderColour = "rgb(47, 46, 46)";
  @api buttonVariant = "btn2";
  @api colOrRowContents = "row";
  @api alignContentsV = false;
  @api alignContentsH = false;
  @api reverseContents = false;
  @api additionalClasses = "cms-tile";
  @api showTitle;
  @api disableLinkify = false;
  @api imgFullWidth = false;

  @track data;
  @track error;

  tileType = "Info";

  get isInfo() {
    return this.managedContentType === "Info";
  }

  get isTC_Article() {
    return this.managedContentType === "TC_Article";
  }

  get hasTwoImages() {
    return this.data.contentNodes.Image.url && this.data.contentNodes.Icon.url;
  }

  @wire(getSingleItem, {
    contentKey: "$contentKey",
    managedContentType: "$managedContentType"
  })
  wiredContent({ error, data }) {
    if (data) {
      let tempData = JSON.parse(JSON.stringify(data.items[0]));
      if (!tempData.contentNodes.Image) {
        tempData.contentNodes.Image = { url: "" };
      }
      if (!tempData.contentNodes.Icon) {
        tempData.contentNodes.Icon = { url: "" };
      }
      if (!tempData.contentNodes.Subtitle) {
        tempData.contentNodes.Subtitle = { value: "" };
      } else {
        tempData.contentNodes.Subtitle.value =
          tempData.contentNodes.Subtitle.value
            .replaceAll("&lt;", "<")
            .replaceAll("&gt;", ">")
            .replaceAll("&amp;", "&");
      }
      if (!tempData.contentNodes.Body) {
        tempData.contentNodes.Body = { value: "" };
      } else {
        tempData.contentNodes.Body.value = tempData.contentNodes.Body.value
          .replaceAll("&lt;", "<")
          .replaceAll("&gt;", ">")
          .replaceAll("&amp;", "&")
          .replaceAll("&quot;", '"');
      }
      if (!tempData.contentNodes.Button_1_Label) {
        tempData.contentNodes.Button_1_Label = { value: "" };
      }
      if (!tempData.contentNodes.Button_1_Action) {
        tempData.contentNodes.Button_1_Action = { value: "" };
      }
      if (!tempData.contentNodes.Button_2_Label) {
        tempData.contentNodes.Button_2_Label = { value: "" };
      }
      if (!tempData.contentNodes.Button_2_Action) {
        tempData.contentNodes.Button_2_Action = { value: "" };
      }
      if (!this.showTitle) {
        tempData.contentNodes.Title.value = "";
      }
      this.data = tempData;
      this.error = undefined;
    } else if (error) {
      this.error = error;
      this.data = undefined;
    }
  }
}