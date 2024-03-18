import { LightningElement, track, api, wire } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import { getRecord } from "lightning/uiRecordApi";
import isGuest from "@salesforce/user/isGuest";
import userId from "@salesforce/user/Id";
import oegenResources from "@salesforce/resourceUrl/oegenResources";
import { label } from "c/labelService";

export default class Navactions extends NavigationMixin(LightningElement) {
  @api showProfileMenu = false;
  @api allowRegistration = false;
  @track userFullName = "";
  @track userIsGuest = isGuest;

  labels = label;

  get profileIconUrl() {
    return oegenResources + "/images/icon_profile.png";
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

  handleClick(evt) {
    this.dispatchEvent(new CustomEvent("navigate"));
    switch (evt.target.dataset.id) {
      case "login":
        this.handleLoginClick();
        break;
      case "register":
        this.handleRegisterClick();
        break;
      case "logout":
        this.handleLogoutClick();
        break;
      case "profile":
        this.handleMyProfileClick();
        break;
      case "settings":
        this.handleMySettingsClick();
        break;
      case "account":
        this.handleAccountSettingsClick();
        break;
      default:
      // nothing
    }
  }

  handleRegisterClick() {
    this[NavigationMixin.Navigate]({
      type: "standard__webPage",
      attributes: {
        url: "/login/SelfRegister"
      }
    });
  }

  handleLoginClick() {
    this[NavigationMixin.Navigate]({
      type: "comm__loginPage",
      attributes: {
        actionName: "login"
      }
    });
  }

  handleLogoutClick() {
    this[NavigationMixin.Navigate]({
      type: "comm__loginPage",
      attributes: {
        actionName: "logout"
      }
    });
  }

  handleMyProfileClick() {
    this[NavigationMixin.Navigate]({
      type: "standard__recordPage",
      attributes: {
        recordId: userId,
        objectApiName: "User",
        actionName: "view"
      }
    });
  }

  handleMySettingsClick() {
    this[NavigationMixin.Navigate]({
      type: "standard__webPage",
      attributes: {
        url: "/settings/" + userId
      }
    });
  }

  handleAccountSettingsClick() {
    this[NavigationMixin.Navigate]({
      type: "standard__webPage",
      attributes: {
        url: "/my-account/"
      }
    });
  }
}