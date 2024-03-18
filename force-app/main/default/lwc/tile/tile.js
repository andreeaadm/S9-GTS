import { LightningElement, api, track } from "lwc";
import { NavigationMixin } from "lightning/navigation";

export default class Tile extends NavigationMixin(LightningElement) {
  @api title;
  @api subTitle;
  @api value;
  @api label;
  @api contentText;
  @api buttonLabel;
  @api buttonLabel2;
  @api buttonVariant = "main";
  @api buttonVariant2 = "main";
  @api btnIcon;
  @api btnIcon2;
  @api btnIconFill;
  @api btnIconFill2;
  @api btnIconStroke;
  @api btnIconStroke2;
  @api navUrl; // a complete URL
  @api navUrl2; // a complete URL
  @api navPage; // a community page name
  @api navPage2; // a community page name
  @api fieldId;
  @api disabled;
  @api borderColour = "#cecece";
  @api borderColourHover = "#1b5297";
  @api iconColour = "#1b5297";
  @api contentImgSrc = "";
  @api disableLinkify = false;
  @api scrollToId = "";
  @api get faValue() {
    return this._faValue;
  }
  set faValue(value) {
    this._faValue = value;
    if (this.hasRendered) {
      this.initCssVarsAndSlots();
    }
  }
  @api get imgSrc() {
    return this._imgSrc;
  }
  set imgSrc(value) {
    this._imgSrc = value;
    if (this.hasRendered) {
      this.initCssVarsAndSlots();
    }
  }
  @api get icon1Src() {
    return this._icon1Src;
  }
  set icon1Src(value) {
    this._icon1Src = value;
    if (this.hasRendered) {
      this.initCssVarsAndSlots();
    }
  }
  @api get icon2Src() {
    return this._icon2Src;
  }
  set icon2Src(value) {
    this._icon2Src = value;
    if (this.hasRendered) {
      this.initCssVarsAndSlots();
    }
  }
  @api get bgSrc() {
    return this._bgSrc;
  }
  set bgSrc(value) {
    this._bgSrc = value;
    if (this.hasRendered) {
      this.generateStyleClass();
      this.initCssVarsAndSlots();
    }
  }
  @api get bgSize() {
    return this._bgSize;
  }
  set bgSize(value) {
    this._bgSize = value;
    if (this.hasRendered) {
      this.initCssVarsAndSlots();
    }
  }
  @api get heroMinHeight() {
    return this._heroMinHeight;
  }
  set heroMinHeight(value) {
    this._heroMinHeight = value;
    if (this.hasRendered) {
      this.initCssVarsAndSlots();
    }
  }
  @api get heroContentWidth() {
    return this._heroContentWidth;
  }
  set heroContentWidth(value) {
    this._heroContentWidth = value;
    if (this.hasRendered) {
      this.initCssVarsAndSlots();
    }
  }
  @api get backgroundOverlayColour() {
    return this._backgroundOverlayColour;
  }
  set backgroundOverlayColour(value) {
    this._backgroundOverlayColour = value;
    if (this.hasRendered) {
      this.generateStyleClass();
      this.initCssVarsAndSlots();
    }
  }
  @api get backgroundColour() {
    return this._backgroundColour;
  }
  set backgroundColour(value) {
    this._backgroundColour = value;
    if (this.hasRendered) {
      this.initCssVarsAndSlots();
    }
  }
  @api get backgroundColourContent() {
    return this._backgroundColourContent;
  }
  set backgroundColourContent(value) {
    this._backgroundColourContent = value;
    if (this.hasRendered) {
      this.initCssVarsAndSlots();
    }
  }
  @api get titleColour() {
    return this._titleColour;
  }
  set titleColour(value) {
    this._titleColour = value;
    if (this.hasRendered) {
      this.initCssVarsAndSlots();
    }
  }
  @api get subTitleColour() {
    return this._subTitleColour;
  }
  set subTitleColour(value) {
    this._subTitleColour = value;
    if (this.hasRendered) {
      this.initCssVarsAndSlots();
    }
  }
  @api get contentColour() {
    return this._contentColour;
  }
  set contentColour(value) {
    this._contentColour = value;
    if (this.hasRendered) {
      this.initCssVarsAndSlots();
    }
  }
  /*
   * Input, Nav, Info, Hero
   */
  @api get type() {
    return this._type;
  }
  set type(value) {
    this._type = value;
    this.decideType();
    this.generateStyleClass();
  }
  /*
   * row or col
   */
  @api get colOrRowContents() {
    return this._colOrRowContents;
  }
  set colOrRowContents(value) {
    this._colOrRowContents = value;
    this.generateStyleClass();
  }
  @api get alignContentsV() {
    return this._alignContentsV;
  }
  set alignContentsV(value) {
    this._alignContentsV = value;
    this.generateStyleClass();
  }
  @api get alignContentsH() {
    return this._alignContentsH;
  }
  set alignContentsH(value) {
    this._alignContentsH = value;
    this.generateStyleClass();
  }
  @api get alignFinalContentBase() {
    return this._alignFinalContentBase;
  }
  set alignFinalContentBase(value) {
    this._alignFinalContentBase = value;
    this.generateStyleClass();
  }
  @api get reverseContents() {
    return this._reverseContents;
  }
  set reverseContents(value) {
    this._reverseContents = value;
    this.generateStyleClass();
  }
  @api get floatingContentColumn() {
    return this._floatingContentColumn;
  }
  set floatingContentColumn(value) {
    this._floatingContentColumn = value;
    this.generateStyleClass();
  }
  @api get heroTextAlignCenter() {
    return this._heroTextAlignCenter;
  }
  set heroTextAlignCenter(value) {
    this._heroTextAlignCenter = value;
    this.generateStyleClass();
  }
  @api get imgFullWidth() {
    return this._imgFullWidth;
  }
  set imgFullWidth(value) {
    this._imgFullWidth = value;
    this.generateStyleClass();
  }
  @api get additionalClasses() {
    return this._additionalClasses;
  }
  set additionalClasses(value) {
    this._additionalClasses = value;
    this.generateStyleClass();
  }
  @track _type = "Input";
  @track _colOrRowContents = "row";
  @track _alignContentsV = false;
  @track _alignContentsH = false;
  @track _imgFullWidth = false;
  @track _additionalClasses = "standard";
  @track _alignFinalContentBase = false;
  @track _reverseContents = false;
  @track _floatingContentColumn = false;
  @track _heroTextAlignCenter = false;
  @track _imgSrc = "";
  @track _icon1Src = "";
  @track _icon2Src = "";
  @track _bgSrc = "";
  @track _bgSize = "100% auto";
  @track _heroMinHeight = "380px";
  @track _heroContentWidth = "400px";
  @track _backgroundOverlayColour = "rgba(0,0,0,0)";
  @track _backgroundColour = "";
  @track _backgroundColourContent = "";
  @track _titleColour = "rgb(47, 46, 46)";
  @track _subTitleColour = "rgb(47, 46, 46)";
  @track _contentColour = "rgb(47, 46, 46)";
  @track _faValue;
  @track styleClass = "";
  @track isCheckbox = false;
  @track isRadio = false;
  @track isInfo = false;
  @track isNav = false;
  @track isHero = false;
  @track renderContentSlotTop = true;
  @track renderContentSlotBottom = true;
  @track hasMedia = true;

  hasRendered = false;

  generateStyleClass() {
    // we always need the inner class
    let compositeClass = "inner";
    // process additional classes
    compositeClass += this.additionalClasses
      ? " " + this.additionalClasses
      : "";
    // process hero mode
    compositeClass += this.isHero ? " hero" : "";
    // process background image mode
    compositeClass += this.bgSrc ? " bg-v" : "";
    // process background overlay
    compositeClass += this.backgroundOverlayColour ? " overlay" : "";
    // process columnOrRowContents
    compositeClass +=
      this.colOrRowContents === "row" || this.colOrRowContents === "col"
        ? " " + this.colOrRowContents
        : "";
    // process alignContents vertical and horizontal
    compositeClass += this.alignContentsV ? " valign" : "";
    // process horizontal content alignment
    compositeClass += this.alignContentsH ? " halign" : "";
    // process final content alignment
    compositeClass += this.alignFinalContentBase ? " baselast" : "";
    // process full width image
    compositeClass += this.imgFullWidth ? " img-full" : "";
    // process content reversal
    compositeClass += this.reverseContents ? " reverse" : "";
    // process floating content in column mode
    compositeClass += this.floatingContentColumn ? " floatpan" : "";
    // process hero text align
    compositeClass += this.heroTextAlignCenter ? " text-align" : "";
    // process isInfo
    compositeClass += this.isInfo ? " info" : "";
    // set the style class value so that it's applied to the outer wrapping div
    this.styleClass = compositeClass;
  }

  get isInput() {
    return this.isRadio || this.isCheckbox;
  }

  connectedCallback() {
    this.decideType();
    this.generateStyleClass();
  }

  renderedCallback() {
    if (!this.hasRendered) {
      this.hasRendered = true;
      this.initCssVarsAndSlots();
    }
  }

  initCssVarsAndSlots() {
    // establish whether we should render the content slot
    let contentSlotTopNodes = [];
    if (this.template.querySelector(".contentslottop")) {
      contentSlotTopNodes = JSON.parse(
        JSON.stringify(
          this.template.querySelector(".contentslottop").assignedNodes()
        )
      );
    }
    if (contentSlotTopNodes && contentSlotTopNodes.length == 0) {
      this.renderContentSlotTop = false;
    }
    let contentSlotBottomNodes = [];
    if (this.template.querySelector(".contentslotbottom")) {
      contentSlotBottomNodes = JSON.parse(
        JSON.stringify(
          this.template.querySelector(".contentslotbottom").assignedNodes()
        )
      );
    }
    if (contentSlotBottomNodes && contentSlotBottomNodes.length == 0) {
      this.renderContentSlotBottom = false;
    }

    // process CSS variables
    this.template
      .querySelector("div")
      .style.setProperty("--icon1src", "url(" + this.icon1Src + ")");
    this.template
      .querySelector("div")
      .style.setProperty("--icon2src", "url(" + this.icon2Src + ")");
    this.template
      .querySelector("div")
      .style.setProperty("--bgoverlaycolour", this.backgroundOverlayColour);
    this.template
      .querySelector("div")
      .style.setProperty("--bgcolour", this.backgroundColour);
    this.template
      .querySelector("div")
      .style.setProperty("--bgcolourcontent", this.backgroundColourContent);
    this.template
      .querySelector("div")
      .style.setProperty("--titlecolour", this.titleColour);
    this.template
      .querySelector("div")
      .style.setProperty("--subtitlecolour", this.subTitleColour);
    this.template
      .querySelector("div")
      .style.setProperty("--contentcolour", this.contentColour);
    this.template
      .querySelector("div")
      .style.setProperty("--bordercolour", this.borderColour);
    this.template
      .querySelector("div")
      .style.setProperty("--bordercolourhover", this.borderColourHover);
    this.template
      .querySelector("div")
      .style.setProperty("--iconcolour", this.iconColour);
    this.template
      .querySelector("div")
      .style.setProperty("--bgsize", this.bgSize);
    this.template
      .querySelector("div")
      .style.setProperty("--bgsrc", "url(" + this.bgSrc + ")");
    this.template
      .querySelector("div")
      .style.setProperty("--herocontentwidth", this.heroContentWidth);
    this.template
      .querySelector("div")
      .style.setProperty("--herominheight", this.heroMinHeight);
    if (this.additionalClasses && this.additionalClasses.includes("contact-tile")) {
      this.template
        .querySelector("div")
        .style.setProperty("--aftermediatext", '"' + this.title + '"');
    }

    // establish whether we should render the media div
    let svgSlotNodes = [];
    if (this.template.querySelector(".svg")) {
      svgSlotNodes = JSON.parse(
        JSON.stringify(this.template.querySelector(".svg").assignedNodes())
      );
    }
    if (svgSlotNodes.length == 0 && !this.imgSrc && !this.faValue) {
      this.hasMedia = false;
    } else if (svgSlotNodes.length !== 0) {
      this.hasMedia = true;
      this.template.querySelector(".svg").style.setProperty("display", "block");
    } else {
      this.hasMedia = true;
      //this.template.querySelector('.svg').style.setProperty('display', 'none');
    }
  }

  decideType() {
    switch (this.type) {
      case "Checkbox":
        this.isCheckbox = true;
        this.isRadio = this.isInfo = this.isNav = this.isHero = false;
        break;
      case "Radio":
        this.isRadio = true;
        this.isCheckbox = this.isInfo = this.isNav = this.isHero = false;
        break;
      case "Info":
        this.isInfo = true;
        this.isCheckbox = this.isRadio = this.isNav = this.isHero = false;
        break;
      case "Nav":
        this.isNav = true;
        this.isCheckbox = this.isRadio = this.isInfo = this.isHero = false;
        break;
      case "Hero":
        this.isHero = true;
        this.isCheckBox = this.isRadio = this.isInfo = this.isNav = false;
        break;
      default:
        this.isCheckbox = true;
        this.isRadio = this.isInfo = this.isNav = this.isHero = false;
    }
  }

  handleClick(evt) {
    evt.stopPropagation();
    if (!this.disabled && this.isInput) {
      if (evt.target.tagName !== "C-INPUT") {
        this.template.querySelector("c-input").click();
      }
    } else if (this.isNav || evt.target.tagName === "C-BUTTON") {
      if (evt.target?.dataset?.id === "btn2") {
        if (this.navUrl2) {
          this[NavigationMixin.Navigate]({
            type: "standard__webPage",
            attributes: {
              url: this.navUrl2
            }
          });
        } else if (this.navPage2) {
          this[NavigationMixin.Navigate]({
            type: "comm__namedPage",
            attributes: {
              name: this.navPage2
            }
          });
        }
      } else if (this.navUrl) {
        this[NavigationMixin.Navigate]({
          type: "standard__webPage",
          attributes: {
            url: this.navUrl
          }
        });
      } else if (this.navPage) {
        this[NavigationMixin.Navigate]({
          type: "comm__namedPage",
          attributes: {
            name: this.navPage
          }
        });
      } else {
        this.dispatchEvent(
          new CustomEvent("click", {
            detail: { title: this.title, recordId: this.fieldId }
          })
        );
      }
    }
  }

  handleChange(evt) {
    evt.stopPropagation();
    const value =
      evt.detail.value !== undefined ? evt.detail.value : evt.target.value;
    this.dispatchEvent(
      new CustomEvent("change", {
        bubbles: true,
        detail: {
          fieldId: this.fieldId,
          label: this.label,
          value: value,
          type: this.type
        }
      })
    );
  }

  @api uncheck() {
    this.template.querySelector("c-input").uncheck();
  }
  @api getChecked() {
    return this.template.querySelector("c-input").getChecked();
  }
  @api getType() {
    return this.type;
  }
  @api getLabel() {
    return this.label;
  }
  @api processUncheck(label) {
    this.template.querySelector("c-input").processUncheck(label);
  }
  @api validate() {
    return this.template.querySelector("c-input").validate();
  }
  @api scrollTo() {
    this.template
      .querySelector('div[data-id="' + this.scrollToId + '"]')
      .scrollIntoView();
  }
}