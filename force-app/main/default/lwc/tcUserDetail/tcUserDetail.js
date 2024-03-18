import { LightningElement, api, wire } from "lwc";
import userId from "@salesforce/user/Id";
import { label } from "c/labelService";
import getUserDetails from "@salesforce/apex/TC_UserDetailController.getUserDetails";

export default class TcUserDetail extends LightningElement {
  @api recordId;
  labels = label;
  name;
  title;

  /**
   * Retrieve relevant fields from the user in scope (recordId).
   */
  @wire(getUserDetails, {
    recordId: "$recordId"
  })
  wiredRecord({ error, data }) {
    if (data) {
      this.name = data.FirstName + " " + data.LastName;
      this.title = data.Title;
    }
  }

  get viewingOwnUser() {
    return this.recordId === userId;
  }
}