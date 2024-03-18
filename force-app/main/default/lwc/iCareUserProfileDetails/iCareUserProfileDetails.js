import { LightningElement, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import USER_ID from '@salesforce/user/Id';

import ACCOUNT_LABEL from '@salesforce/label/c.iCare_Portal_Account';
import DETAILS_LABEL from '@salesforce/label/c.iCare_Portal_Your_Details';
import EMAIL_LABEL from '@salesforce/label/c.iCare_Portal_Email';
import MOBILE_LABEL from '@salesforce/label/c.iCare_Portal_Mobile';
import NAME_LABEL from '@salesforce/label/c.iCare_Portal_Name';
import PHONE_LABEL from '@salesforce/label/c.iCare_Portal_Phone';
import TITLE_LABEL from '@salesforce/label/c.iCare_Portal_Title';

export default class ICareUserProfileDetails extends LightningElement {
    labels = {
        ACCOUNT_LABEL,
        DETAILS_LABEL,
        EMAIL_LABEL,
        MOBILE_LABEL,
        NAME_LABEL,
        PHONE_LABEL,
        TITLE_LABEL,
    }

    user;

    @wire(getRecord,
            { recordId: USER_ID,
              fields: ['User.Account.Name', 'User.Name', 'User.Email', 'User.Phone', 'User.Title', 'User.MobilePhone'] })
    wiredUser({ error, data }) {

        if (data) {
            this.user = {
                account: data.fields.Account.displayValue,
                name: data.fields.Name.value,
                title: (data.fields.Title.value != undefined) ? data.fields.Title.value : '-',
                email: data.fields.Email.value,
                phone: (data.fields.Phone.value != undefined) ? data.fields.Phone.value : '-',
                mobile: (data.fields.MobilePhone.value != undefined) ? data.fields.MobilePhone.value : '-'
            }
        } else if (error) {
            console.error(error);
        }
    }

    get currentUser() {
        return this.user;
    }
}