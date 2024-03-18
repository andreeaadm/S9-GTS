import { LightningElement, api } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import ASK_OUR_EXPERTS from "@salesforce/label/c.iCare_Expert_Title";
import ASK_OUR_EXPERTS_TEXT_1 from "@salesforce/label/c.iCare_Ask_Our_Experts_Text_1";
import ASK_OUR_EXPERTS_TEXT_2 from "@salesforce/label/c.iCare_Ask_Our_Experts_Text_2";
import CONNECT_WITH_US from "@salesforce/label/c.Connect_With_Us";
import GTS_HEADER from "@salesforce/label/c.GTS_Expert_Query_Header";
import GTS_REGULATORY from "@salesforce/label/c.GTS_Regulatory_Updates";
import GTS_REGULATORY_TEXT from "@salesforce/label/c.GTS_Regulatory_Text";
import GTS_VIEW_ALL_NEWS from "@salesforce/label/c.GTS_View_All_News";
import GTS_CONNECT_WITH_US from "@salesforce/label/c.GTS_Connect_With_Us";
export default class ExpertDisplayText extends NavigationMixin(
  LightningElement
) {
  customLabels = {
    ASK_OUR_EXPERTS: ASK_OUR_EXPERTS,
    ASK_OUR_EXPERTS_TEXT_1: ASK_OUR_EXPERTS_TEXT_1,
    ASK_OUR_EXPERTS_TEXT_2: ASK_OUR_EXPERTS_TEXT_2,
    CONNECT_WITH_US: CONNECT_WITH_US,
    GTS_HEADER: GTS_HEADER
  };
  @api isRegulatoryUpdatesVisible;
  @api title;
  @api text;

  get selectedTitle() {
    return this.customLabels[this.title];
  }

  get selectedText() {
    return this.customLabels[this.text];
  }

  get selectedRegulatory() {
    return GTS_REGULATORY;
  }

  get selectedRegulatoryText() {
    return GTS_REGULATORY_TEXT;
  }

  get selectedViewAllNews() {
    return GTS_VIEW_ALL_NEWS;
  }

  handleConnectWithUsClick() {
    this[NavigationMixin.Navigate]({
      type: "standard__webPage",
      attributes: {
        url: GTS_CONNECT_WITH_US
      }
    });
  }
}