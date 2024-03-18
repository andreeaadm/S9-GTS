import { LightningElement, track } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import getNotifications from "@salesforce/apex/NotificationsController.getNotifications";
export default class HomeNotificationsTile extends NavigationMixin(
  LightningElement
) {
  @track isEmpty = true;
  @track showModal = false;
  @track notifications = [];
  @track isLoading = true;
  @track hasLoaded = false;
  rowLimit = 6;

  connectedCallback() {
    this.getData();
  }

  getData() {
    getNotifications({
      rowLimit: this.rowLimit
    })
      .then((response) => {
        if (response) {
          this.notifications = response;
          this.isEmpty = response.length && response.length > 0 ? false : true;
          this.error = undefined;
          this.isLoading = false;
          this.hasLoaded = true;
        } else if (error) {
          this.error = error;
          this.notifications = [];
          this.isEmpty = true;
          this.isLoading = false;
          this.hasLoaded = true;
        }
      })
      .catch((error) => {
        if (error) {
          this.error = error;
          this.notifications = [];
          this.isLoading = false;
        }
      });
  }

  handleClick(evt) {
    let recordId = evt.currentTarget.dataset.id;
    this[NavigationMixin.Navigate]({
      type: "standard__recordPage",
      attributes: {
        recordId: recordId,
        actionName: "view"
      }
    });
  }
}