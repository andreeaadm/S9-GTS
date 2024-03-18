import { LightningElement, api, wire, track } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import { CurrentPageReference } from "lightning/navigation";
import LOGO_RESOURCE from "@salesforce/resourceUrl/siteLogo";
import getNavIconsForConfig from "@salesforce/apex/CommunityHeaderController.getNavIconsForConfig";
import getBuilderNavItems from "@salesforce/apex/CommunityHeaderController.getBuilderNavItems";
import isGuest from "@salesforce/user/isGuest";
import basePath from "@salesforce/community/basePath";

export default class Siteheader extends NavigationMixin(LightningElement) {
  /**
   * the menuName (NavigationMenuLinkSet.MasterLabel) exposed by the .js-meta.xml
   */
  @api menuName = "Default Navigation";
  @api configDevName;
  @api iconType = "Font Awesome";
  @api allowRegistration = false;
  @api showProfileMenu = false;
  @track mobMenuActive = false;
  @track menuItems = [];
  @track iconConfig;
  @track error;
  /**
   * if the items have been loaded
   */
  @track currentUrl = "";
  @track isLoaded = false;
  /**
   * the published state of the site, used to determine from which schema to
   * fetch the NavigationMenuItems
   */
  publishedState;
  isGuestUser = isGuest;

  get logoutLink() {
    const sitePrefix = basePath.replace(/\/s$/i, ""); // site prefix is the site base path without the trailing "/s"
    return sitePrefix + "/secur/logout.jsp";
  }

  get logoSrc() {
    return LOGO_RESOURCE;
  }

  get styleClass() {
    return this.mobMenuActive ? "topnav active" : "topnav";
  }

  connectedCallback() {
    this.currentUrl = window.location.href;
    let _this = this;
    window.addEventListener("popstate", function () {
      _this.currentUrl = window.location.href;
    });
  }

  navToRoot() {
    let homeRef = {
      type: "comm__namedPage",
      attributes: {
        name: "Home"
      }
    };
    this[NavigationMixin.Navigate](homeRef);
  }

  @wire(getBuilderNavItems, {
    menuName: "$menuName",
    publishedState: "$publishedState"
  })
  wiredMenuItems({ error, data }) {
    if (data && !this.isLoaded) {
      var map = {},
        node,
        roots = [],
        i;
      var menuItems = data
        .map((item, index) => {
          map[item.Id] = index;
          return {
            target: item.Target,
            id: index,
            parentId: item.ParentId ? item.ParentId : undefined,
            label: item.Label,
            defaultListViewId: item.DefaultListViewId,
            type: item.Type,
            accessRestriction: item.AccessRestriction,
            subMenu: undefined // initialize child menu items
          };
        })
        .filter((item) => {
          // Only show "Public" items if guest user
          return (
            item.accessRestriction === "None" ||
            (item.accessRestriction === "LoginRequired" && !this.isGuestUser)
          );
        });

      for (i = 0; i < menuItems.length; i += 1) {
        node = menuItems[i];
        console.debug(JSON.stringify(node));
        if (node.parentId !== undefined) {
          if (menuItems[map[node.parentId]].subMenu !== undefined) {
            menuItems[map[node.parentId]].subMenu.push(node);
          } else {
            menuItems[map[node.parentId]].subMenu = new Array(node);
          }
        } else {
          roots.push(node);
        }
      }

      this.menuItems = roots;
      this.error = undefined;
      this.isLoaded = true;
    } else if (error) {
      this.error = error;
      this.menuItems = [];
      this.isLoaded = true;
      console.log(`Navigation menu error: ${JSON.stringify(this.error)}`);
    }
  }

  @wire(getNavIconsForConfig, { configDevName: "$configDevName" })
  itemConfig({ error, data }) {
    if (data && !this.isLoaded) {
      this.iconConfig = data;
    } else if (error) {
      this.error = error;
      this.iconConfig = undefined;
      console.error(error);
    }
  }

  /**
   * Using the CurrentPageReference, check if the app is 'commeditor'.
   *
   * If the app is 'commeditor', then the page will use 'Draft' NavigationMenuItems.
   * Otherwise, it will use the 'Live' schema.
   */
  @wire(CurrentPageReference)
  setCurrentPageReference(currentPageReference) {
    const app =
      currentPageReference &&
      currentPageReference.state &&
      currentPageReference.state.app;
    if (app === "commeditor") {
      this.publishedState = "Draft";
    } else {
      this.publishedState = "Live";
    }
  }

  toggleMenu() {
    this.mobMenuActive = !this.mobMenuActive;
  }

  hideMenu(evt) {
    // TODO: check which parent menu item (based on parentId from event-firing child) needs to be highlighted
    // Highlight it by calling a function on the each sitemenuitem. Only the correct one will add the selected state and all others will remove it.
    for (let item of this.template.querySelectorAll("c-sitemenuitem")) {
      // call function on each, passing in parentId from the click event as a parameter
    }
    this.mobMenuActive = false;
  }
}