import { LightningElement,api } from 'lwc';

import EXISTING_NUMBER from '@salesforce/label/c.GTS_Existing_Number';
import RENEWAL_REVISION from '@salesforce/label/c.GTS_Renewal_or_Revision';
import RENEWAL_BUTTON from "@salesforce/label/c.GTS_Renewal";
import REVISION_BUTTON from "@salesforce/label/c.GTS_Revision";
import PURPOSE_APPLICATION from '@salesforce/label/c.GTS_Purpose_of_Application';


export default class GtsLicenseRenewPurposeOfApplicant extends LightningElement {
    @api jobRequestRecord;
    @api isReadOnly = false;
    labels = {
        PURPOSE_APPLICATION,
        EXISTING_NUMBER,
        RENEWAL_BUTTON,
        RENEWAL_REVISION,
        REVISION_BUTTON
    }

    renewRevisionValue;

    connectedCallback(){
        console.log('GtsLicenseRenewPurposeOfApplicant',this.jobRequestRecord.GTS_Renewal_Revision__c);
        console.log('GtsLicenseRenewPurposeOfApplicant GTS_Existing_Number__c',this.jobRequestRecord.GTS_Existing_Number__c);
        this.renewRevisionValue = this.jobRequestRecord.GTS_Renewal_Revision__c;
    }

    get options() {
        return [
            { label: RENEWAL_BUTTON, value: 'Renewal' },
            { label: REVISION_BUTTON, value: 'Revision' }
        ];
    }

    handleChange(event) {
        this.renewRevisionValue = event.detail.value;
        this.handleDispatchEvent();
    }

    handleDispatchEvent(){
        const purposeOfApplicationChanged = new CustomEvent("purposeofapplicationchanged", {
            detail : {
                renewRevision : this.renewRevisionValue
            }
        });
        this.dispatchEvent(purposeOfApplicationChanged);
    }
}