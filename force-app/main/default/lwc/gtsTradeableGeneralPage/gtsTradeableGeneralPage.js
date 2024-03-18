import { LightningElement, api} from 'lwc';
import COMMERCIAL_SERVICE_REQUIRED from '@salesforce/label/c.GTS_Commercial_Service_Required';
import OTHER_VALUE from '@salesforce/label/c.GTS_Other_Value';
import GENERAL_INFO from '@salesforce/label/c.GTS_GeneralInformation_SOW';
import FINAL_REPORT_LABEL from "@salesforce/label/c.GTS_Final_Report_Label";
import STATEMENT_OF_WORK from "@salesforce/label/c.GTS_Statement_Of_Work";

export default class GtsTradeableGeneralPage extends LightningElement {
    @api isReadOnly = false;
    @api jobRequestRecord;
    comServReq;
    @api recordTypeId;
    @api isOtherValue = false;
    otherValue;
    astraCodeOptions = [];

    programValue;
    programLabel;


    labels = {
        GENERAL_INFO,
        COMMERCIAL_SERVICE_REQUIRED,
        OTHER_VALUE,
        FINAL_REPORT_LABEL,
        STATEMENT_OF_WORK
    }

    connectedCallback(){
        this.programValue = this.jobRequestRecord.GTS_Program__c;
        this.programLabel = this.jobRequestRecord.ProgramName;
    }


    get programFilters(){
        return JSON.stringify({'GTS_Active__c' : true, GTS_Associated_Form_Type__c : 'COMMERCIAL SERVICE'});
    }

    handleProgramSelection(event){
        this.programValue = (event.detail.selectedRecord.Id != undefined) ? event.detail.selectedRecord.Id : '';
        this.programLabel = (event.detail.selectedRecord.Name != undefined) ? event.detail.selectedRecord.Name : '';

        if(this.programLabel.includes('Other')){
            this.isOtherValue = true;
        }else{
            this.isOtherValue = false;
            this.otherValue = '';
        }
        this.handleDispatchEvent();
    }

    handleOtherValueChange(event){
        this.otherValue = event.detail.value;
        this.handleDispatchEvent();
    }

    handleDispatchEvent(){
        const generalInfoChanged = new CustomEvent("generalinfochanged", {
            detail : {
                comServReq : this.programValue,
                programName : this.programLabel,
                otherValue : this.otherValue
            }
        });
        this.dispatchEvent(generalInfoChanged);
    }

    handleSOWChange(event) {
        this.dispatchEvent(
          new CustomEvent("sowchange", { detail: event.detail.value })
        );
    }
    
    handleFinalReportChange(event) {
        this.dispatchEvent(
          new CustomEvent("finalreportchange", { detail: event.detail.value })
        );
    }
    
}