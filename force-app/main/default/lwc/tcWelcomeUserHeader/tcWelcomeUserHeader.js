import { LightningElement, wire } from "lwc";
import { getRecord } from "lightning/uiRecordApi";
import { label, format} from "c/labelService";
import userId from "@salesforce/user/Id";


export default class TcInventoryListHeader extends LightningElement {
  labels = label;
  userFullName = "";

  get headerText() {
    return format(label.TC_WELCOME_TO_TOXCLEAR, this.userFullName);
  }
  
  // use wire service to get current user data
  @wire(getRecord, { recordId: userId, fields: ["User.Name"] })
  userData({ error, data }) {
    if (data) {
      this.userFullName = data.fields.Name.value;
    } else if (error) {
      console.error(error);
    }
  }
}