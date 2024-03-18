import { LightningElement, api, track, wire } from "lwc";
import { CurrentPageReference } from "lightning/navigation";
import VIEW_ALL_LABEL from "@salesforce/label/c.iCare_Portal_View_all";
import HOME_LABEL from "@salesforce/label/c.iCare_Portal_Home";

export default class ICareViewAllJobHome extends LightningElement {
  isReportToBeShown;
  tableName = "Home";
  hrefString = "/iCare/s/"
  label = {
    VIEW_ALL_LABEL,
    HOME_LABEL
  };

  @wire(CurrentPageReference)
  getStateParameters(currentPageReference) {
    if (currentPageReference) {
      this.isReportToBeShown =
        currentPageReference.state?.ir === "true" ? true : false;
      this.tableName = currentPageReference.state?.tb;
      if(this.tableName.includes('GTS')){
        this.hrefString = '/iCareGTS/s/';
      }
    }
  }
}