import { LightningElement, api, wire, track } from 'lwc';
import getJobTimestampWithImages from '@salesforce/apex/iCare_DynamicProgressPathController.getJobTimestampWithImages';
import TRACK_JOBS_LABEL from '@salesforce/label/c.iCare_Portal_Track_Jobs';
import iCarePortalMessageChannel from '@salesforce/messageChannel/iCarePortalMessageChannel__c';
import {publish, MessageContext} from 'lightning/messageService'
import iconsResource from '@salesforce/resourceUrl/iconsTrackJob';

export default class ICareDynamicProgressPath extends LightningElement {
    @api recordId;
    jobsWithImages;
    error;
    iCareJobId;

    label = {
        TRACK_JOBS_LABEL
    };

    @wire(MessageContext)
    messageContext;

    @wire(getJobTimestampWithImages, { jobId: '$recordId' })
    wireJobsWithImages( { error, data } ) {
        if ( data ) {
            let tempRecs = [];
            
            //Assign the internal Job Id
            this.iCareJobId = data[0].iCareJobId;  //Internal Job Id for sub-banner

            data.forEach( ( record ) => {
                let tempRec = Object.assign( {}, record );
                tempRec.progressImage = iconsResource + '/' + tempRec.progressImage;
                tempRec.progressTrackImage = iconsResource + '/' + tempRec.progressTrackImage ;
                tempRecs.push( tempRec );
            });
            this.jobsWithImages = tempRecs;

            //Past the status to report download component
            let message = {message: data[0].currentStatus};
            publish(this.messageContext, iCarePortalMessageChannel, message);
        } else if ( error ) {
            this.error = error;
        }
    }
}