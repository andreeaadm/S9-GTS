import { LightningElement, api } from 'lwc';
import { utilFunctions } from "c/gmaelAccessPassportUtils";

export default class GmaelAPMultiSelectList extends LightningElement {
    
    @api reportData;
    options = [];
    _selected = [];

    labels = utilFunctions.labels;

    connectedCallback() {

        let records = [];
        
        this.reportData?.approvedCountries.forEach(record => {
        
            let pc = {};
            pc['value'] = record.Id;
            pc['label'] = record.Name;
            records.push(pc);
        });
        
        this.options = records;

        if (this.reportData?.isReportObject && this.reportData?.reportId
            && this.reportData?.reportRecordData?.GAMEL_Filter_JSON__c) {

            let reportFilter = JSON.parse(this.reportData?.reportRecordData?.GAMEL_Filter_JSON__c);
            this._selected = reportFilter.countries;
            utilFunctions.fireCustomEvent(this, 'countryselect', this._selected);
        }
    }

    get selected() {
 
        return this._selected.length ? this._selected : 'none';
    }

    handleChange(e) {
 
        this._selected = e.detail.value;

        if (window.localStorage) {

            window.localStorage.setItem(
                'selected-regions',
                JSON.stringify(this._selected)
            );
        }

        utilFunctions.fireCustomEvent(this, 'countryselect', this._selected);
    }

    @api resetCountryListView(event) {

        this._selected = [];
    }
}