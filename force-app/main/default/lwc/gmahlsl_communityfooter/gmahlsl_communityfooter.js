import { LightningElement, api } from "lwc";
import { NavigationMixin } from 'lightning/navigation';

const DEFAULT_NEW_WINDOW_STATE = true;
export default class gmahlsl_communityfooter extends NavigationMixin(LightningElement) {
  @api label1;
  @api label2;
  @api label3;
  @api label4;
  @api label5;
  @api label6;

  @api link1;
  @api link2;
  @api link3;
  @api link4;
  @api link5;
  @api link6;

  @api link1NewWindow;
  @api link2NewWindow;
  @api link3NewWindow;
  @api link4NewWindow;
  @api link5NewWindow;
  @api link6NewWindow;
  

  @api twitterUrl;
  @api linkedInUrl;
  @api facebookUrl;
  @api instagramUrl;

  @api bottomLogo;
  @api bottomText;

  @api backgroundColour;
  @api textColour;
  @api bottomBackgroundColour;
  @api bottomTextColour;

  linkProperties = [];

  get hasLabels() {
    return this.linkProperties.length>0;
  }

  get hasSocial() {
    return (
      this.twitterUrl ||
      this.linkedInUrl ||
      this.facebookUrl ||
      this.instagramUrl
    );
  }

  get displayFooterTop() {
    return (
      this.linkProperties.length>0 ||
      this.twitterUrl ||
      this.linkedInUrl ||
      this.facebookUrl ||
      this.instagramUrl
    );
  }

  get displayFooterBottom() {
    return (
      this.bottomLogo ||
      this.bottomText
    );
  }

  get hasBottomLogos() {
    return this.bottomLogo;
  }

  get hasBottomText() {
    return this.bottomText;
  }

  hasRendered = false;

  renderedCallback() {
    if (!this.hasRendered) {
      this.hasRendered = true;
      this.parseLinksToArrays();
      if (this.backgroundColour) {
        this.template
          .querySelector(".top")
          .style.setProperty("--bgcolour", this.backgroundColour);
      }
      if (this.textColour) {
        this.template
          .querySelector(".top")
          .style.setProperty("--textcolour", this.textColour);
      }
      if (this.bottomBackgroundColour) {
        this.template
          .querySelector(".bottom")
          .style.setProperty("--bottombgcolour", this.bottomBackgroundColour);
      }
      if (this.bottomTextColour) {
        this.template
          .querySelector(".bottom")
          .style.setProperty("--bottomtextcolour", this.bottomTextColour);
      }
    }
  }

  parseLinksToArrays() {
    this.linkProperties = [];
    if (this.label1) {
      this.linkProperties.push({
        id: 1,
        link: this.link1,
        label: this.label1,
        newWindow: (this.link1NewWindow===undefined ? DEFAULT_NEW_WINDOW_STATE : this.link1NewWindow)
      });
    }
    if (this.label2) {
      this.linkProperties.push({
        id: 2,
        link: this.link2,
        label: this.label2,
        newWindow: (this.link2NewWindow===undefined ? DEFAULT_NEW_WINDOW_STATE : this.link2NewWindow)
      });
    }
    if (this.label3) {
      this.linkProperties.push({
        id: 3,
        link: this.link3,
        label: this.label3,
        newWindow:  (this.link3NewWindow===undefined ? DEFAULT_NEW_WINDOW_STATE : this.link3NewWindow)
      });
    }
    if (this.label4) {
      this.linkProperties.push({
        id: 4,
        link: this.link4,
        label: this.label4,
        newWindow:  (this.link4NewWindow===undefined ? DEFAULT_NEW_WINDOW_STATE : this.link4NewWindow)
      });
    }
    if (this.label5) {
      this.linkProperties.push({
        id: 5,
        link: this.link5,
        label: this.label5,
        newWindow:  (this.link5NewWindow===undefined ? DEFAULT_NEW_WINDOW_STATE : this.link5NewWindow)
      });
    }
    if (this.label6) {
      this.linkProperties.push({
        id: 6,
        link: this.link6,
        label: this.label6,
        newWindow:  (this.link6NewWindow===undefined ? DEFAULT_NEW_WINDOW_STATE : this.link6NewWindow)
      });
    }
  }

  navigateToPage(event) {
    let thisId = parseInt(event.currentTarget.dataset.id);
    let thisLinkProperties = this.linkProperties.find(x => x.id === thisId);
    let thisUrl = thisLinkProperties.link; 
    let isAbsoluteUrl = (thisUrl.includes('http://') || thisUrl.includes('https://'));
    let isRelativeUrl = thisUrl.includes('/');
    let isEmailAddress =  (thisUrl.includes('mailto:'));
    let windowProperty = (thisLinkProperties.newWindow ? '_blank' : '_self');
    windowProperty = (isEmailAddress ? '_self' : windowProperty);

    if (!isAbsoluteUrl && !isEmailAddress && !isRelativeUrl) {
      this[NavigationMixin.GenerateUrl]({
        type: "comm__namedPage",
        attributes: {
          name: thisUrl
        }
      }).then((url) => {
        window.open(url, windowProperty);
      });
    } else {
      window.open(thisUrl, windowProperty);
    }
  } 
}