import { LightningElement, api, wire, track} from 'lwc';

import getMandatoryFieldsFromProgramName from "@salesforce/apex/GTSJobRequestController.getMandatoryFieldsFromProgramName";

import ACID_NO from '@salesforce/label/c.GTS_ACID';
import AWB_NO from '@salesforce/label/c.GTS_AWB_No_BL_No';
import BL_NO from '@salesforce/label/c.GTS_BL_No';
import CERTIFICATE_NO from '@salesforce/label/c.GTS_Certificate_Origin_No';
import CERTIFICATE_DATE from '@salesforce/label/c.GTS_Certificate_Origin_Date';
import CUSTOMER_NO from '@salesforce/label/c.GTS_Customer_Dealer_No';
import DOCUMENT_NO from '@salesforce/label/c.GTS_Document_No';
import DOCUMENT_DATE from '@salesforce/label/c.GTS_Document_Date';
import EXPORTER_COMMERCIAL_REG_NO from '@salesforce/label/c.GTS_Exporter_Commercial_Registration_No';
import FASEH_No from '@salesforce/label/c.GTS_FASEH_Request_No';
import FDI_NO from '@salesforce/label/c.GTS_FDI_IDF_No';
import IDF_NO from '@salesforce/label/c.GTS_IDF';
import IMPORT_LICENCE_NO from '@salesforce/label/c.GTS_Import_Licence_No';
import IMPORTER_CODE from '@salesforce/label/c.GTS_Importer_Code';
import IMPORTER_REG_NO from '@salesforce/label/c.GTS_Importer_Commercial_Registration_No';
import ICE_NO from '@salesforce/label/c.GTS_ICE';
import LC_DATE from '@salesforce/label/c.GTS_LC_Date';
import LC_NO from '@salesforce/label/c.GTS_LC_No';
import EXPORTER_NO from '@salesforce/label/c.GTS_Number_of_Exporter';
import IMPORTER_NO from '@salesforce/label/c.GTS_Number_of_Importer';
import PR_NO from '@salesforce/label/c.GTS_PR_NEF_E_force_No';
import PROFORMA_NO from '@salesforce/label/c.GTS_Proforma_Invoice_No';
import PROFORMA_DATE from '@salesforce/label/c.GTS_Proforma_Invoice_Date';
import UESW_NO from '@salesforce/label/c.GTS_UESW_Application_No';
import URC_NO from '@salesforce/label/c.GTS_UCR_No';
import NO_FIELDS from '@salesforce/label/c.GTS_DocShip_NoFields';
import SHIPMENT_DOC from '@salesforce/label/c.GTS_Shipment_Document';
import OTHER_NO from '@salesforce/label/c.GTS_Others_please_specify';

export default class GtsCoCShipmentDocument extends LightningElement {
    @api isReadOnly;
    @api jobRequestRecord;
    jobRequestRecordCopy;
    @track dataLoaded = false;
    labels = {
        ACID_NO,
        AWB_NO,
        BL_NO,
        CERTIFICATE_NO,
        CERTIFICATE_DATE,
        CUSTOMER_NO,
        DOCUMENT_NO,
        DOCUMENT_DATE,
        EXPORTER_COMMERCIAL_REG_NO,
        FASEH_No,
        FDI_NO,
        IDF_NO,
        IMPORT_LICENCE_NO,
        IMPORTER_CODE,
        IMPORTER_REG_NO,
        ICE_NO,
        LC_DATE,
        LC_NO,
        EXPORTER_NO,
        IMPORTER_NO,
        PR_NO,
        PROFORMA_NO,
        PROFORMA_DATE,
        UESW_NO,
        URC_NO,
        NO_FIELDS,
        SHIPMENT_DOC,
        OTHER_NO
    }

//    acidNo;
//    awbNo;
//    blNo;
//    certificateNo;
//    certificateDate;
//    customerDealerNo;
//    transportDocumentNo;
//    transportDocumentDate;
//    fASEHNo;
//    idfNo;
//    importLicenceNo;
//    importerCode;

    jobRequestRecordCopy;

    handleACIDNo(event){
        this.jobRequestRecordCopy.GTS_ACID_No__c =  event.target.value;
        this.handleDispatchEvent();
    }
    handleAWBNo(event){
        this.jobRequestRecordCopy.GTS_AWB_No__c =  event.target.value;
        this.handleDispatchEvent();
    }
    handleBLNo(event){
        this.jobRequestRecordCopy.GTS_BL_No__c =  event.target.value;
        this.handleDispatchEvent();
    }
    handleCertificateNo(event){
        this.jobRequestRecordCopy.GTS_Certificate_Origin_No__c =  event.target.value;
        this.handleDispatchEvent();
    }
    handleCertificateDate(event){
        this.jobRequestRecordCopy.GTS_Certificate_Origin_Date__c =  event.target.value;
        this.handleDispatchEvent();
    }
    handleCustomerNo(event){
        this.jobRequestRecordCopy.GTS_Customer_Dealer_No__c =  event.target.value;
        this.handleDispatchEvent();
    }
    handleDocumentNo(event){
        this.jobRequestRecordCopy.GTS_Transport_Document_No__c =  event.target.value;
        this.handleDispatchEvent();
    }
    handleDocumentDate(event){
        this.jobRequestRecordCopy.GTS_Transport_Document_Date__c =  event.target.value;
        this.handleDispatchEvent();
    }
    handleFASEHNo(event){
        this.jobRequestRecordCopy.GTS_FASEH_Request_No__c =  event.target.value;
        this.handleDispatchEvent();
    }
    handleFDINo(event){
        this.jobRequestRecordCopy.GTS_FDI_No__c =  event.target.value;
        this.handleDispatchEvent();
    }
    handleIDFNo(event){
        this.jobRequestRecordCopy.GTS_IDF_No__c =  event.target.value;
        this.handleDispatchEvent();
    }
    handleImportLicenceNo(event){
        this.jobRequestRecordCopy.GTS_Import_Licence_No__c =  event.target.value;
        this.handleDispatchEvent();
    }
    handleImporterCode(event){
        this.jobRequestRecordCopy.GTS_Importer_Code__c = event.target.value;
        this.handleDispatchEvent();
    }
    handleICENo(event){
        this.jobRequestRecordCopy.GTS_ICE_No__c = event.target.value;
        this.handleDispatchEvent();
    }
    handleLCNo(event){
        this.jobRequestRecordCopy.GTS_LC_No__c = event.target.value;
        this.handleDispatchEvent();
    }
    handleLCDate(event){
        this.jobRequestRecordCopy.GTS_LC_Date__c = event.target.value;
        this.handleDispatchEvent();
    }
    handleExporterNo(event){
        this.jobRequestRecordCopy.GTS_No_of_Exporter__c = event.target.value;
        this.handleDispatchEvent();
    }
    handleImporterNo(event){
        this.jobRequestRecordCopy.GTS_No_of_Importer__c = event.target.value;
        this.handleDispatchEvent();
    }
    handlePRNo(event){
        this.jobRequestRecordCopy.GTS_PR_No__c = event.target.value;
        this.handleDispatchEvent();
    }
    handleProformaNo(event){
        this.jobRequestRecordCopy.GTS_Invoice_No__c = event.target.value;
        this.handleDispatchEvent();
    }
    handleProformaDATE(event){
        this.jobRequestRecordCopy.GTS_Invoice_Date__c = event.target.value;
        this.handleDispatchEvent();
    }
    handleUESWDATE(event){
        this.jobRequestRecordCopy.GTS_UESW_Application_No__c = event.target.value;
        this.handleDispatchEvent();
    }
    handleURCNo(event){
        this.jobRequestRecordCopy.GTS_UCR_No__c = event.target.value;
        this.handleDispatchEvent();
    }
    handleOtherNo(event){
        this.jobRequestRecordCopy.GTS_Other_No_please_specify__c = event.target.value;
        this.handleDispatchEvent();
    }

    handleDispatchEvent(){
        const shipmentDocumentChanged = new CustomEvent("shipmentdocumentchange", {
            detail : {
                jobRequestRecord : this.jobRequestRecordCopy
            }
        });
        this.dispatchEvent(shipmentDocumentChanged);
    }

    @track showACID = false;
    @track showAWB = false;
    @track showBL = false;
    @track showCertNo = false;
    @track showCustDealerNo = false;
    @track showDocument = false;
    @track showFaseh = false;
    @track showFDI = false;
    @track showIDF = false;
    @track showImpLicense = false;
    @track showImpConde = false;
    @track showICE = false;
    @track showLC = false;
    @track showEpNo = false;
    @track showImpNo = false;
    @track showPRNo = false;
    @track showProforma = false;
    @track showUESW = false;
    @track showURC = false;

 @wire(getMandatoryFieldsFromProgramName, { programName : "$jobRequestRecord.ProgramName"})
    wiredDisplayFields({ error, data }) {
        if (data) {
            this.dataLoaded = true;
            this.showACID = data.includes('GTS_ACID_No__c'.toLowerCase());
            this.showAWB = data.includes('GTS_AWB_No__c'.toLowerCase());
            this.showBL = data.includes('GTS_BL_No__c'.toLowerCase());
            this.showCertNo = data.includes('GTS_Certificate_Origin_No__c'.toLowerCase());
            this.showCustDealerNo = data.includes('GTS_Customer_Dealer_No__c'.toLowerCase());
            this.showDocument = data.includes('GTS_Transport_Document_No__c'.toLowerCase());
            this.showFaseh = data.includes('GTS_FASEH_Request_No__c'.toLowerCase());
            this.showFDI = data.includes('GTS_FDI_No__c'.toLowerCase());
            this.showIDF = data.includes('GTS_IDF_No__c'.toLowerCase());
            this.showImpLicense = data.includes('GTS_Import_Licence_No__c'.toLowerCase());
            this.showImpConde = data.includes('GTS_Importer_Code__c'.toLowerCase());
            this.showICE = data.includes('GTS_ICE_No__c'.toLowerCase());
            this.showLC = data.includes('GTS_LC_No__c'.toLowerCase());
            this.showEpNo = data.includes('GTS_No_of_Exporter__c'.toLowerCase());
            this.showImpNo = data.includes('GTS_No_of_Importer__c'.toLowerCase());
            this.showPRNo = data.includes('GTS_PR_No__c'.toLowerCase());
            this.showProforma = data.includes('GTS_Invoice_No__c'.toLowerCase());
            this.showUESW = data.includes('GTS_UESW_Application_No__c'.toLowerCase());
            this.showURC = data.includes('GTS_UCR_No__c'.toLowerCase());
            this.showOther = data.includes('GTS_Other_No_please_specify__c'.toLowerCase());
        } else if (error) {
            this.dataLoaded = true;
            this.error = error;
            this.data = undefined;
        }
    }
    programName;
       connectedCallback() {
        this.jobRequestRecordCopy = { ...this.jobRequestRecord };
        this.programName = this.jobRequestRecord.ProgramName;

       }

       get showSpinner(){
           return !this.dataLoaded;
       }

       get showFields(){
           return this.showACID || this.showAWB || this.showBL || this.showCertNo || this.showCustDealerNo || this.showDocument
           || this.showFaseh || this.showFDI || this.showIDF || this.showImpLicense || this.showImpConde || this.showICE
           || this.showLC || this.showEpNo || this.showImpNo || this.showPRNo || this.showProforma || this.showUESW || this.showURC
       }
}