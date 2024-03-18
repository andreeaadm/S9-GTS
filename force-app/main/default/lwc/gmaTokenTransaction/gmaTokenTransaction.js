import { LightningElement, api } from 'lwc';
import TIMESTAMP_COLUMN_LABEL from '@salesforce/label/c.GMA_Timestamp';
import getTokenTransactions from '@salesforce/apex/GMAHLSLTokenTransactionController.getTokenTransaction';
const columns = [
    {label: 'Transaction Number', fieldName: 'name', type: 'text', sortable : true , wrapText: true},
    {label: TIMESTAMP_COLUMN_LABEL, fieldName: 'timestamp', type: 'text', sortable : true , wrapText: true},
    {label: 'Addition / Deduction of Tokens', fieldName: 'recordType', type: 'text', sortable : true , wrapText: true},
    {label: 'Number of Tokens', fieldName: 'amount', type: 'Number', sortable : true , wrapText: true},
    {label: 'Transaction By', fieldName: 'ownerName', type: 'text', sortable : true , wrapText: true}
];

export default class GmaTokenTransaction extends LightningElement {    
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
        this.getTokenTransaction();
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
            this.getTokenTransaction();
        } else {
            this.isLoaded = true;
        }
    }
    
    async getTokenTransaction(){
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
        await getTokenTransactions({daysCount:this.daysCount })
            .then((result) => {
                this.itemsForCurrentView = result;
                this.isLoaded = true;
            })
            .catch(error => {
            });
    }

}