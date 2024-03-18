import { LightningElement, api, wire } from "lwc";
import DECLARATION from "@salesforce/label/c.GTS_Declaration";
import DECLARATION_1 from "@salesforce/label/c.GTS_Declaration1";
import DECLARATION_2 from "@salesforce/label/c.GTS_Declaration2";
import DECLARATION_3 from "@salesforce/label/c.GTS_Declaration3";
import DECLARATION_4 from "@salesforce/label/c.GTS_Declaration4";
import DECLARATION_5 from "@salesforce/label/c.GTS_Declaration5";
import DECLARATION_6 from "@salesforce/label/c.GTS_Declaration6";
import DECLARATION_3_2 from "@salesforce/label/c.GTS_Declaration3_2";
import DECLARATION_3_3 from "@salesforce/label/c.GTS_Declaration3_3";
import DECLARATION_3_CO_LINK from "@salesforce/label/c.GTS_Declaration3_Intertek_terms_condition_Link";
import DECLARATION_3_CO_TEXT from "@salesforce/label/c.GTS_Declaration3_Intertek_terms_condition_Text";
import DECLARATION_3_TERMS_LINK from "@salesforce/label/c.GTS_Declaration3_Intertek_terms_Link";
import DECLARATION_3_TERMS from "@salesforce/label/c.GTS_Declaration3_Terms_and_Conditions";
import SUBMITTING_APPLICATION from "@salesforce/label/c.GTS_Submitting_Application";
import Id from "@salesforce/user/Id";
import getTermsAndConditions from "@salesforce/apex/iCare_GTSDeclarationController.getTermsAndConditions";
//import isWetIssuingOfficeMethod from '@salesforce/apex/GTS_DeclarationController.isWetIssuingOffice';

export default class GtsTradeableDeclaration extends LightningElement {
  @api isReadOnly;
  loggedInUserId = Id;
  isWetIssuingOffice = false;

  @api declaration1 = false;
  @api declaration2 = false;
  @api declaration3 = false;
  @api declaration4 = false;
  @api declaration5 = false;
  @api declaration6 = false;
  @api isCoC = false;

  get declaration1Value() {
    return this.declaration1;
  }

  @wire(getTermsAndConditions, {userId : "$loggedInUserId" })
  data({data,error}) {
    if (data) {
      this.isWetIssuingOffice = data[0]?.GTS_T_Cs_required__c === true ? true : false;
    } else if (error) {
      console.log("error : ", error);
    }
  }

  /*@wire(isWetIssuingOfficeMethod, {userId: '$loggedInUserId'})
    resultData({data, error}){
        if(data){
            if(data === 'YES'){
                this.isWetIssuingOffice = true;
            }else{
                this.isWetIssuingOffice = false;
            }
            console.error('Result : '+data);
        }else if(error){
            console.log('error wetissingoffice : ',error);
        }
    }*/

  connectedCallback() {
    this.dispatchCheckboxChange();
  }

  labels = {
    DECLARATION,
    DECLARATION_1,
    DECLARATION_2,
    DECLARATION_3,
    DECLARATION_3_2,
    DECLARATION_3_3,
    DECLARATION_3_CO_LINK,
    DECLARATION_3_CO_TEXT,
    DECLARATION_3_TERMS_LINK,
    DECLARATION_3_TERMS,
    SUBMITTING_APPLICATION,
    DECLARATION_4,
    DECLARATION_5,
    DECLARATION_6
  };

  handleDeclaration1Change(event) {
    this.declaration1 = event.target.checked;
    this.dispatchCheckboxChange();
  }

  handleDeclaration2Change(event) {
    this.declaration2 = event.target.checked;
    this.dispatchCheckboxChange();
  }

  handleDeclaration3Change(event) {
    this.declaration3 = event.target.checked;
    this.dispatchCheckboxChange();
  }

  handleDeclaration4Change(event) {
    this.declaration4 = event.target.checked;
    this.dispatchCheckboxChange();
  }

  handleDeclaration5Change(event) {
    this.declaration5 = event.target.checked;
    this.dispatchCheckboxChange();
  }

  handleDeclaration6Change(event) {
    this.declaration6 = event.target.checked;
    this.dispatchCheckboxChange();
  }

  dispatchCheckboxChange() {
    // Create a custom event
    const customEvent = new CustomEvent("declarationcheckboxchange", {
      detail: {
        declaration1: this.declaration1,
        declaration2: this.declaration2,
        declaration3: this.declaration3,
        declaration4: this.declaration4,
        declaration5: this.declaration5,
        declaration6: this.declaration6,
        isWetIssuingOffice : this.isWetIssuingOffice
      }
    });

    // Dispatch the custom event
    this.dispatchEvent(customEvent);
  }
}