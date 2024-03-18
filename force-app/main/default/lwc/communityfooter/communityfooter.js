import { LightningElement, api } from "lwc";
import { NavigationMixin } from "lightning/navigation";
export default class Communityfooter extends NavigationMixin(LightningElement) {
  @api label1;
  @api label2;
  @api label3;
  @api label4;
  @api label5;
  @api label6;
  @api label7;
  @api label8;
  @api link1;
  @api link2;
  @api link3;
  @api link4;
  @api link5;
  @api link6;
  @api link7;
  @api link8;
  @api twitterUrl;
  @api linkedInUrl;
  @api facebookUrl;
  @api instagramUrl;
  @api footerText;
  @api logo1;
  @api logo2;
  @api logo3;
  @api bottomText1;
  @api bottomText2;
  @api bottomText3;
  @api bottomLinkText1;
  @api bottomLinkText2;
  @api bottomLink1;
  @api bottomLink2;
  @api backgroundColour;
  @api textColour;
  @api bottomBackgroundColour;
  @api bottomTextColour;

  get hasLabels() {
    return (
      this.label1 ||
      this.label2 ||
      this.label3 ||
      this.label4 ||
      this.label5 ||
      this.label6 ||
      this.label7 ||
      this.label8
    );
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
      this.label1 ||
      this.label2 ||
      this.label3 ||
      this.label4 ||
      this.label5 ||
      this.label6 ||
      this.label7 ||
      this.label8 ||
      this.twitterUrl ||
      this.linkedInUrl ||
      this.facebookUrl ||
      this.instagramUrl
    );
  }
  get displayFooterBottom() {
    return (
      this.logo1 ||
      this.logo2 ||
      this.logo3 ||
      this.bottomText1 ||
      this.bottomText2 ||
      this.bottomText3
    );
  }
  get hasBottomLogos() {
    return this.logo1 || this.logo2 || this.logo3;
  }
  get hasBottomText() {
    return this.bottomText1 || this.bottomText2 || this.bottomText3;
  }
  hasRendered = false;

  renderedCallback() {
    if (!this.hasRendered) {
      this.hasRendered = true;
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

  navigateToPage(evt) {
    console.debug(evt.currentTarget.dataset.link);
    if (evt.currentTarget.dataset.link.includes("mailto:")) {
      let url = evt.currentTarget.dataset.link;
      console.debug(url);
      window.open(url, "_blank");
    }
    this[NavigationMixin.GenerateUrl]({
      type: "comm__namedPage",
      attributes: {
        pageName: evt.currentTarget.dataset.link,
        actionName: "view"
      }
    }).then((url) => {
      console.debug(url);
      window.open(url, "_blank");
    });
  }
}