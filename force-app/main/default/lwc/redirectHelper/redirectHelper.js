import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import USER_ID_FIELD from '@salesforce/user/Id';

const USER_OBJECT_NAME = 'User';

const CONDITION_RUNNING_USER_MATCHED = 'runningUserMatches';
export default class RedirectHelper extends LightningElement {
    @api recordId;
    @api redirectionParams;
    redirectionProcessed = false;

    @wire(getRecord, { recordId: '$recordId', layoutTypes: ['Full'] })
    processRedirect({ error, data }) {
        if (data) {
            if (!this.redirectionParams || this.redirectionProcessed) {
                return;
            }
            const redirectionParamsJSON = JSON.parse(this.redirectionParams);
            //e.g. {"condition":"runningUserMatches", "page":"/my-profile/"}
            switch(data.apiName) {
                case USER_OBJECT_NAME:
                    this.redirectionsForUser(redirectionParamsJSON);
                    break;
                default:
                    break;
            }
            this.redirectionProcessed = true;
        } else if (error) {
            console.log('error: ', error);
        }
    }
    
    redirectionsForUser(redirectionParamsJSON) {
        if (this.recordId===USER_ID_FIELD && redirectionParamsJSON.condition===CONDITION_RUNNING_USER_MATCHED) {
            window.location.replace(redirectionParamsJSON.page);
        }
    }
}