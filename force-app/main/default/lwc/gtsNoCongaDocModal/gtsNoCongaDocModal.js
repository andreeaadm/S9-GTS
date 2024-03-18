import { LightningElement } from 'lwc';
import LightningModal from 'lightning/modal';
import NO_DOC from "@salesforce/label/c.GTS_No_PDF_Conga_Doc";

export default class GtsNoCongaDocModal extends LightningModal {
    labels = {NO_DOC}
}