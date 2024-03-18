import { LightningElement, api, track, wire } from 'lwc';
import getPicklistOptions from '@salesforce/apex/DynamicPicklistController.getPicklistOptions';
import { publish, subscribe, unsubscribe, MessageContext } from "lightning/messageService";
import msgChannel from "@salesforce/messageChannel/GMAPortalMessageChannel__c";

import picklistOptionsLoadingLabel from '@salesforce/label/c.GMA_PicklistLoading_Text';

const ON_FOCUS_MESSAGE = 'DYNAMIC_PICKLIST_FOCUS';
const PRODUCT_FIELD_API_NAME = 'product__c';
const PRODUCT_OTHER_CATEGORY = 'Other';
const BACK_TEXT_FOR_PROD_CATEGORIES = '< back';

export default class DynamicPicklist extends LightningElement {
    @api objectapiname = '';
    @api fieldapiname = '';
    @api ismultiselect = '';
    @api label = '';
    @api picklistlabel = '';
    @api showRequired = false;
    valuesKeywordMap = new Map();
    matchingValues = [];
    @api preSelectedValues = [];
    @track selectedValues = [];
    @track showPicklistValue;
    @track box = 'inputbox';
    dealingWithProductPicklist = false;
    renderProductCategoriesView = false;
    renderProductPicklistBasedOnCategories = false;
    groupedMatchingValues = new Map();

    subscription = null;
    @wire(MessageContext)
    messageContext;

    valuesAreNotLoaded = true;

    subscribeToMessageChannel() {
        if (!this.subscription) {
            this.subscription = subscribe(
                this.messageContext,
                msgChannel,
                (message) => this.handleMessage(message)
            );
        }
    }

    unsubscribeToMessageChannel() {
        unsubscribe(this.subscription);
        this.subscription = null;
    }

    handleMessage(message) {
        if (message.messageType===ON_FOCUS_MESSAGE) {
            const differentPicklistIsActive = (this.fieldapiname != message.payload.fieldName);

            if (differentPicklistIsActive) {
                this.collapsePicklist();
            }
        }
    }

    connectedCallback(){
        this.subscribeToMessageChannel();

        this.dealingWithProductPicklist = (this.fieldapiname.toLowerCase()===PRODUCT_FIELD_API_NAME.toLowerCase());

        this.showPicklistValue = picklistOptionsLoadingLabel;
        getPicklistOptions({objectName: this.objectapiname, fieldName: this.fieldapiname})
            .then((result) => {
                let otherCategoryArray = [];
                for(var key in result){
                    this.valuesKeywordMap.set(key, result[key].picklistValue);
                    if (this.dealingWithProductPicklist) {
                        let categoryIsSet = (result[key].category!='' && result[key].category!==undefined);
                        if (!categoryIsSet) {
                            otherCategoryArray.push(result[key].picklistValue);
                        } else {
                            let thisCategory = result[key].category;
                            let subArray = (this.groupedMatchingValues.has(thisCategory) ? this.groupedMatchingValues.get(thisCategory) : []);
                            subArray.push(result[key].picklistValue);
                            this.groupedMatchingValues.set(thisCategory, subArray);
                        }
                    }
                }

                if (this.dealingWithProductPicklist) {
                    this.groupedMatchingValues = new Map([...this.groupedMatchingValues.entries()].sort());
                    if (otherCategoryArray.length>0) {
                        this.groupedMatchingValues.set(PRODUCT_OTHER_CATEGORY, otherCategoryArray);
                    }
                }
                this.showPicklistValue = this.picklistlabel;
                this.valuesAreNotLoaded = false;
            })
            .catch(error => {

            });
    }

    renderedCallback() {
        if (this.preSelectedValues.length>0 && this.selectedValues.length<1 && !this.valuesAreNotLoaded) {
            this.selectedValues = [ ...this.preSelectedValues];
            this.addToSectionHelper();
        }
    }

    disconnectedCallback() {
        this.unsubscribeToMessageChannel();
    }

    hanldeOnFocus(event) {
        const jsonMsg = {
            fieldName: this.fieldapiname
        };
        publish(this.messageContext, msgChannel, {
            messageType: ON_FOCUS_MESSAGE,
            payload: jsonMsg
        });
        this.renderMatchingValues(this.template.querySelector('lightning-input').value);
    }

    handleInputChange(event) {
        var inputText = event.detail.value.toLowerCase();
        this.renderMatchingValues(inputText);
    }

    collapsePicklist(event) {
        this.matchingValues = [];
    }

    renderMatchingValues(searchKeyword) {
        this.matchingValues = [];

        if (this.dealingWithProductPicklist && searchKeyword=='') {
            this.renderProductCategoriesView = true;
            for(const [key, value] of this.groupedMatchingValues) {
                this.matchingValues.push(key);
            }
        } else {
            this.renderProductCategoriesView = false;
            this.renderProductPicklistBasedOnCategories = false;
            for(const [key, value] of this.valuesKeywordMap){
                var keywords = key.split(';');
                for(const keyword of keywords){
                    if(keyword.includes(searchKeyword) && !this.selectedValues.includes(value)){
                        this.matchingValues.push(value);
                        break;
                    }
                }
            }
        }

        //if search keyword was blank and there were no more values found, disable the input
        if (searchKeyword=='' && this.matchingValues.length < 1) {
            this.template.querySelector('lightning-input').disabled = true;
            this.template.querySelector('lightning-input').style = 'display:none;';
        }
    }

    addToSelection(event){
        let selectedValue = event.target.dataset.id;
        if (this.renderProductCategoriesView) {
            this.matchingValues = [];
            this.matchingValues = this.groupedMatchingValues.get(selectedValue).slice(0);
            this.matchingValues.unshift(BACK_TEXT_FOR_PROD_CATEGORIES);
            this.renderProductCategoriesView = false;
            this.renderProductPicklistBasedOnCategories = true;
        } else if (selectedValue===BACK_TEXT_FOR_PROD_CATEGORIES) {
            this.renderProductCategoriesView = true;
            this.matchingValues = [];
            for(const [key, value] of this.groupedMatchingValues) {
                this.matchingValues.push(key);
            }
        } else if (selectedValue!='') {
            this.selectedValues.push(selectedValue);
            this.addToSectionHelper();
            // Send event of selection content
            const selectionEvent = new CustomEvent("selectionchange", {
                detail: this.selectedValues
            });
            this.dispatchEvent(selectionEvent);
        }
    }

    addToSectionHelper() {
        this.template.querySelector('lightning-input').value = null;
        
        if (this.ismultiselect==='false') {
            //not multi-select, e.g. product
            this.template.querySelector('lightning-input').disabled = true;
            this.template.querySelector('lightning-input').style = 'display:none;';
        } else {
            this.renderMatchingValues('');
        }
        this.matchingValues = [];
        this.box = 'selectedinputbox';
    }

    removeSelection(event){
        this.selectedValues.splice(event.currentTarget.dataset.id, 1);

        this.template.querySelector('lightning-input').style = 'display:inline-flex;';

        let picklistIsDisabled = this.template.querySelector('lightning-input').disabled;
        if(picklistIsDisabled){
            this.template.querySelector('lightning-input').disabled = false;
        }
        if(this.selectedValues.length == 0){
            this.showPicklistValue = this.picklistlabel;
            this.box = 'inputbox';
        }
        // Send event of selection content
        const selectionEvent = new CustomEvent("selectionchange", {
            detail: this.selectedValues
          });
        this.dispatchEvent(selectionEvent);  
    }

    get hasMatchingValues() {
        return this.matchingValues.length>0;
    }
}