import { LightningElement, api } from 'lwc';
import TIMESTAMP_COLUMN_LABEL from '@salesforce/label/c.GMA_Timestamp';
import getRecords from '@salesforce/apex/GMAHLSLCasesListviewController.getCaseRecords';
import { NavigationMixin } from 'lightning/navigation';

const columns = [
    {label: 'Case Number', fieldName: 'caseNumber', type: 'button', typeAttributes: {label: {fieldName: 'caseNumber'}, tooltip: {fieldName: 'caseNumber'}, variant: 'base'}, sortable : true , wrapText: true},
    {label: 'Subject', fieldName: 'subject', type: 'text', sortable : true , wrapText: true},
    {label: 'Case Type', fieldName: 'type', type: 'text', sortable : true , wrapText: true},
    {label: 'Status', fieldName: 'status', type: 'text', sortable : true , wrapText: true},
    {label: TIMESTAMP_COLUMN_LABEL, fieldName: 'timestamp', type: 'text', sortable : true , wrapText: true}
];

export default class GmaCasesListview extends NavigationMixin(LightningElement) {    
    @api ListViewOne;
    @api ListViewOneDaysCount;
    @api ListViewTwo;
    @api ListViewTwoDaysCount;
    @api ListViewThree;
    @api ListViewThreeDaysCount;
    @api ListViewFour;
    @api ListViewFourDaysCount;
    @api ListViewFive;
    @api ListViewFiveDaysCount;
    listViewOptions = [];
    currentFilter;
    daysCount;
    isExpanded = false;
    isLoaded = false;
    columns = columns;
    itemsForCurrentView = [];
    sortBy;
    sortDirection;

    connectedCallback(){
        if (this.ListViewOne.length>0) {
            this.listViewOptions.push(this.ListViewOne);
        }
        if (this.ListViewTwo.length>0) {
            this.listViewOptions.push(this.ListViewTwo);
        }
        if (this.ListViewThree.length>0) {
            this.listViewOptions.push(this.ListViewThree);
        }
        if (this.ListViewFour.length>0) {
            this.listViewOptions.push(this.ListViewFour);
        }
        if (this.ListViewFive.length>0) {
            this.listViewOptions.push(this.ListViewFive);
        }

        this.currentFilter = (this.listViewOptions.length>0 ? this.listViewOptions[0]: '');
        this.getRecords();
    }

    renderedCallback() {
        this.isLoaded = true;
    }

    doSorting(event) {
        this.sortBy = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;
        this.sortData(this.sortBy, this.sortDirection);
    }

    sortData(fieldname, direction) {
        let parseData = JSON.parse(JSON.stringify(this.itemsForCurrentView));
        let keyValue = (a) => {
            return a[fieldname];
        };
        let isReverse = direction === 'asc' ? 1: -1;
        parseData.sort((x, y) => {
            x = keyValue(x) ? keyValue(x) : ''; 
            y = keyValue(y) ? keyValue(y) : '';
            return isReverse * ((x > y) - (y > x));
        });
        this.itemsForCurrentView = parseData;
    }  

    get dropdownTriggerClass() {
        if (this.isExpanded) {
            return 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click custom_list_view slds-is-open'
        } else {
            return 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click custom_list_view'
        }
    }

    handleClickExtend() {
        this.isExpanded = !this.isExpanded;
    }

    handleFilterChangeButton(event) {
        this.isLoaded = false;
        let filter = event.target.dataset.filter;
        this.isExpanded = !this.isExpanded;
        if (filter !== this.currentFilter) {
            this.itemsForCurrentView = [];
            this.currentFilter = event.target.dataset.filter;
            this.getRecords();
        } else {
            this.isLoaded = true;
        }
    }
    
    async getRecords(){
        switch (this.currentFilter) {
            case this.ListViewOne:
                this.daysCount = this.ListViewOneDaysCount;
                break;
            case this.ListViewTwo:
                this.daysCount = this.ListViewTwoDaysCount;
                break;
            case this.ListViewThree:
                this.daysCount = this.ListViewThreeDaysCount;
                break;
            case this.ListViewFour:
                this.daysCount = this.ListViewFourDaysCount;
                break;
            case this.ListViewFive:
                this.daysCount = this.ListViewFiveDaysCount;
                break;
        }
        await getRecords({daysCount:this.daysCount })
            .then((result) => {
                this.itemsForCurrentView = result;
                this.isLoaded = true;
            })
            .catch(error => {
                console.log('error', error);
            });
    }

    viewRecord(event) {
        this[NavigationMixin.Navigate]({
            type: "standard__recordPage",
            attributes: {
              recordId: event.detail.row.key,
              objectApiName: "Case",
              actionName: "view"
            }
        });
    }
}