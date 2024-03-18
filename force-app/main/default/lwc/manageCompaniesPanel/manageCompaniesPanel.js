import { LightningElement, track, wire } from "lwc";
import getData from "@salesforce/apex/ManageCompaniesPanelController.getData";

export default class ManageCompaniesPanel extends LightningElement {
  // use @wire to grab the appropriate CGA first name, last name and email in order to build out cgaMessage
  // "If you require access to specific reports, please email [FirstName] [LastName], [Email]."
  @wire(getData)
  wiredData;
  @track buttonHidden = true;

  get renderMe() {
    return (
      this.wiredData.data &&
      (this.wiredData.data.message || this.wiredData.data.isAdmin)
    );
  }
}