import { LightningElement, api, wire } from 'lwc';
import TRACK_JOBS_LABEL from '@salesforce/label/c.iCare_Portal_Track_Jobs';
import WAITING_JOB_TEXT from '@salesforce/label/c.GTS_Waiting_Job_Text';
import apexGetJobDetails from '@salesforce/apex/GTSJobLifecycle.getJobInspectionNumber';
import apexGetJobStatusPath from '@salesforce/apex/GTSJobLifecycle.getJobStatusPath';


export default class GtsJobLifecycle extends LightningElement {
    @api jobId;
    jobInspectionNumber;
    steps;
    awaitingForAstra;

    label = {
        TRACK_JOBS_LABEL,
        WAITING_JOB_TEXT
    };

    @wire(apexGetJobDetails, {jobId : "$jobId"})
    apexGetJobDetails({ error, data }){
        if(data){
            console.log(data);
            this.jobInspectionNumber = data;
        }else if (error){
            console.log('error getting Inspection Nr. ',error);
        }
    }

    @wire(apexGetJobStatusPath, {jobId : "$jobId"})
    getJobDetails({ error, data }){
        if(data){
            console.log(data);
            this.steps = JSON.parse(data);
            this.awaitingForAstra = (this.steps.length == 0);
        }else if (error){
            console.log('error getting Steps. ',error);
        }
    }

}