import { LightningElement, track, api, wire } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import { getRecord } from "lightning/uiRecordApi";
import isGuest from "@salesforce/user/isGuest";
import userId from "@salesforce/user/Id";
import oegenResources from "@salesforce/resourceUrl/oegenResources";
import { label } from "c/labelService";
import isguest from '@salesforce/user/isGuest';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getCurrentUser from '@salesforce/apex/GmaPortalHelper.getCurrentUser';
import expiredSessionMessage from '@salesforce/label/c.GMA_User_ExpiredSession_Error';

const SESSION_STORAGE_LOGGED_IN_CHECK = 'u_info';


export default class Navactions extends NavigationMixin(LightningElement) {
  isGuestUser = isguest;
  timeIntervalInstance;
  @api showProfileMenu = false;
  @api allowRegistration = false;
  @track userFullName = "";
  @track userIsGuest = isGuest;

  labels = label;

  get profileIconUrl() {
    return oegenResources + "/images/icon_profile.png";
  }

  @wire(getRecord, { recordId: userId, fields: ["User.Name"] })
  userData({ error, data }) {
    if (data) {
      this.userFullName = data.fields.Name.value;
    } else if (error) {
      console.error(error);
    }
  }

  renderedCallback() {

    //manage session state information and needed actions
    if (this.isGuestUser) {
    //if on page load we know it is a guest user, we clear session storage param as we are starting fresh
      sessionStorage.removeItem(SESSION_STORAGE_LOGGED_IN_CHECK); 
    } else {
    //if on page load we are dealing with logged in user, set up interval
    //to keep checking if user Id for given session changes (from logged in to guest likely)
    //and when this happens, redirect to start page
      clearInterval(this.timeIntervalInstance);
      this.timeIntervalInstance = setInterval(function() {
        getCurrentUser({})
            .then((result) => {
              if (!sessionStorage.getItem(SESSION_STORAGE_LOGGED_IN_CHECK)) {
                sessionStorage.setItem(SESSION_STORAGE_LOGGED_IN_CHECK, result.Id); 
              } else {
                const storedUserId = sessionStorage.getItem(SESSION_STORAGE_LOGGED_IN_CHECK);
                if (storedUserId!==result.Id) {
                  this.dispatchEvent(
                    new ShowToastEvent({
                        message: expiredSessionMessage,
                        variant: "error",
                        mode: "sticky"
                    })
                  );

                  setTimeout(function() {
                    var relativeUrl = window.location.pathname;
                    relativeUrl = relativeUrl.substring(0, relativeUrl.indexOf('/s/'));
                    relativeUrl += '/s/';
                    window.location.replace(relativeUrl);
                  }, 5000);
                }
              }
            })
            .catch((error) => {
              console.log('user load error', error);
            });
      }.bind(this), 20000);
    }
  }

  handleClick(evt) {
    this.dispatchEvent(new CustomEvent("navigate"));
    switch (evt.currentTarget.dataset.id) {
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
      case "orders":
        this.handleMyOrdersClick();
        break;   
      case "resetpassword":
        this.handleResetPasswordClick();
        break;
      case "cases":
        this.handleMyCasesClick();
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
      type: "standard__webPage",
      attributes: {
        url: "/my-profile/" 
      }
    });
  }

  handleMySettingsClick() {
    this[NavigationMixin.Navigate]({
      type: "standard__webPage",
      attributes: {
        url: "/settings/" 
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

  handleMyOrdersClick() {
    this[NavigationMixin.Navigate]({
      type: "standard__webPage",
      attributes: {
        url: "/my-orders/"
      }
    });
  }

  handleMyCasesClick() {
    this[NavigationMixin.Navigate]({
      type: "standard__webPage",
      attributes: {
        url: "/my-cases/"
      }
    });
  }

  handleResetPasswordClick() {
    var relativeUrl = window.location.pathname;
    relativeUrl = relativeUrl.substring(0, relativeUrl.indexOf('/s/'));
    relativeUrl += '/s/';

    this[NavigationMixin.GenerateUrl]({
      type: "standard__webPage",
      attributes: {
        url: relativeUrl + "login/ForgotPassword"
      }
    }).then(url => {window.open(url) });
  }
}