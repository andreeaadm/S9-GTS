import { LightningElement, api , wire} from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import EXPERT_NAME from '@salesforce/schema/iCare_Expert__c.Name';
import EXPERT_ROLE from '@salesforce/schema/iCare_Expert__c.iCare_Role__c';
import GTS_EXPERT_ROLE from '@salesforce/schema/iCare_Expert__c.GTS_Role__c';
import EXPERT_COUNTRY from '@salesforce/schema/iCare_Expert__c.GTS_Country__c';
import EXPERT_BIO from '@salesforce/schema/iCare_Expert__c.iCare_Bio__c';
import GTS_EXPERT_BIO from '@salesforce/schema/iCare_Expert__c.GTS_Bio__c';
import EXPERT_PICTURE from '@salesforce/schema/iCare_Expert__c.iCare_Profile_Picture__c';
import EXPERT_OBJECT from '@salesforce/schema/iCare_Expert__c';
import CONTACT_BUTTON from '@salesforce/label/c.iCare_Contact_Expert_Button'
import getGtsExpertTranslation from '@salesforce/apex/iCareExpertComponentController.getGtsExpertTranslation'

export default class ICareExpertCard extends LightningElement {


    customLabel = {
        CONTACT_BUTTON
    }


    @api recordid;
    @api experttype;
    @api usercountry;

    objectApiName = EXPERT_OBJECT;
    expertName = EXPERT_NAME;
    expertRole = EXPERT_ROLE;
    gtsExpertRole = GTS_EXPERT_ROLE;
    expertPicture = EXPERT_PICTURE;
    expertBio = EXPERT_BIO;
    gtsExpertBio = GTS_EXPERT_BIO;
    expertCountry = EXPERT_COUNTRY;
    global;
    expertNameValue;

    @wire(getRecord, { recordId: '$recordid', fields: [EXPERT_NAME] })
    objectRecord({data, error}) {
        if (data) {
            this.expertNameValue = getFieldValue(data, EXPERT_NAME);
        }
    }
    @wire (getGtsExpertTranslation, {expertId : '$recordid'})
    translationRecord({data,error}){
        if(data){
            this.gtsExpertBio = data.GTS_Bio_Translation__c;
            this.gtsExpertRole = data.GTS_Role_Translation__c;
        }
    }
    
    get countryValue(){
        if(this.experttype != 'Global'){
        return this.usercountry;
        } else{
        return 'Global Expert';
        }
    }
    
    selectExpert(){
        const event = new CustomEvent('selectedexpert',{
            detail: {   recordid : this.recordid,
                        expertname : this.expertNameValue
                    }
        });
        this.dispatchEvent(event);
    }
}