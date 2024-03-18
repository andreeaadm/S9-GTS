import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import basePath from '@salesforce/community/basePath';

export default class Sitemenuitem extends NavigationMixin(LightningElement) {
    /**
     * the NavigationMenuItem from the Apex controller, 
     * contains a label and a target.
     */
    @api item = {};
    @api currentUrl = '';
    @api get iconType() {
        return this._iconType;
    }
    set iconType(value) {
        this._iconType = value;
        this.initIcon();
    }
    @api get itemConfig() {
        return this._iconConfig;
    }
    set itemConfig(value) {
        this._iconConfig = value;
        this.initIcon();
    }

    @track imgUrl = '';
    @track faValue = '';
    @track href = 'javascript:void(0);';

    _iconType = '';
    _iconConfig;

    /**
     * the PageReference object used by lightning/navigation
     */
    pageReference;

    get itemClass() {
        let styleClass;
        if(this.item.parentId !== undefined) {
            styleClass = 'child';
        }
        if(this.currentUrl.substring(this.currentUrl.lastIndexOf('/')) == this.item.target) {
            styleClass = styleClass + ' selected';
        }
        return styleClass;
    }

    connectedCallback() {
        this.initIcon();
        this.initPageReference();
    }

    initIcon() {
        let itemLabelShort = this.item.label.replace(/\s+/g, "");
        if(this.item && itemLabelShort) {
            switch(this.iconType) {
                /* DYNAMIC COMPONENT CREATION IS NOT SUPPORTED IN LWC */
                /*
                case "SVG":
                    resetIcons(cmp);
                    let svgComponentName = iconConfig && iconConfig[itemLabelShort] ? iconConfig[itemLabelShort].SVG_Component_Name__c : "";
                    if (svgComponentName) {
                        $A.createComponent("c:" + svgComponentName, { "class": "nav-svg", "aura:id": "svg" }, function (newSvg, status, error) {
                            if (status === "SUCCESS") {
                                let svg = cmp.get("v.svg");
                                svg.push(newSvg);
                                cmp.set("v.svg", svg);
                            }
                        });
                    }
                    break;
                */
                case "Image":
                    // grab the correct image url from metadata passed in
                    this.resetIcons();
                    let imageUrl = this.iconConfig && this.iconConfig[itemLabelShort] ? this.iconConfig[itemLabelShort].Image_URL__c : "";
                    this.imgUrl = imageUrl;
                    break;
                
                case "Font Awesome":
                    this.resetIcons();
                    // grab the correct font awesome value from metadata passed in
                    let faValue = this.iconConfig && this.iconConfig[itemLabelShort] ? this.iconConfig[itemLabelShort].Font_Awesome_Class__c : "";
                    this.faValue = faValue;
                    break;
                
                default:
                    this.resetIcons();
                    break;
            }
        }
    }

    initPageReference() {
        const { type, target, defaultListViewId } = this.item;
        
        // get the correct PageReference object for the menu item type
        if (type === 'SalesforceObject') {
            // aka "Salesforce Object" menu item
            this.pageReference = {
                type: 'standard__objectPage',
                attributes: { 
                    objectApiName: target
                },
                state: {
                    filterName: defaultListViewId
                }
            };
        } else if (type === 'InternalLink') {
            // aka "Site Page" menu item

            // WARNING: Normally you shouldn't use 'standard__webPage' for internal relative targets, but
            // we don't have a way of identifying the Page Reference type of an InternalLink URL
            this.pageReference = {
                type: 'standard__webPage',
                attributes: {
                    url: basePath + target
                }
            };
        } else if (type === 'ExternalLink') {
            // aka "External URL" menu item
            this.pageReference = {
                type: 'standard__webPage',
                attributes: {
                    url: target
                }
            };
        }

        // use the NavigationMixin from lightning/navigation to generate the URL for navigation. 
        if (this.pageReference) {
            this[NavigationMixin.GenerateUrl](this.pageReference)
                .then(url => {
                    this.href = url;
                });
        }
    }

    resetIcons() {
        this.imgUrl = undefined;
        this.faValue = undefined;
    }

    handleClick(evt) {
        // use the NavigationMixin from lightning/navigation to perform the navigation.
        evt.stopPropagation();
        evt.preventDefault();
        if (this.pageReference) {
            this.dispatchEvent(new CustomEvent('click', {
                detail: this.item.parentId
            }));
            this[NavigationMixin.Navigate](this.pageReference);
            setTimeout(
                function() {
                    history.pushState({}, '', window.location.href);
                    window.dispatchEvent(new Event('popstate'));
                }, 0
            );
        } else {
            console.log(`Navigation menu type "${this.item.type}" not implemented for item ${JSON.stringify(this.item)}`);
        }
    }

}