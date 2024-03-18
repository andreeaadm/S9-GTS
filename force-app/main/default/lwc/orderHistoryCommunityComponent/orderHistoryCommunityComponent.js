import { LightningElement, api } from 'lwc';
import getOrderHistory from '@salesforce/apex/OrderHistoryCommunityComponentController.getOrderHistory';
import getDownloadLink from '@salesforce/apex/OrderHistoryCommunityComponentController.getDownloadLink';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import timestamp from '@salesforce/label/c.GMA_Timestamp';
import solution from '@salesforce/label/c.GMA_Solution';
import token from '@salesforce/label/c.GMA_Token';
import generatedBy from '@salesforce/label/c.GMA_Generated_By';
import download from '@salesforce/label/c.GMA_Download';
import product from '@salesforce/label/c.GMA_Product';
import market from '@salesforce/label/c.GMA_Market';

export default class OrderHistoryCommunityComponent extends LightningElement {
    totalRecords = [];
    selectedRecords = [];
    pageNo = '1';
    pageNoOptions = [
        { label: '1', value: '1' }
    ];
    @api rowsPerTable;

    label = {
        timestamp,
        solution,
        token,
        generatedBy,
        download,
        product,
        market
    };

    connectedCallback() {
        getOrderHistory()
        .then((result) => {
            this.totalRecords = result;
            if(result && result.length!=0){
                this.rowsPerTable = (!this.rowsPerTable || this.rowsPerTable==0) ? 5 : this.rowsPerTable;
                var quo = Math.floor(result.length/this.rowsPerTable);
                var rem = result.length%this.rowsPerTable;
                if(quo>0){
                    this.pageNoOptions = [];
                    for(var i=1;i<=(rem==0 ? quo : (quo+1));i++){
                        this.pageNoOptions.push({label: (''+i), value: (''+i)});
                    }
                }
                this.setSelectedRecords();
            }
        })
        .catch((error) => {
            this.fireToastEvent("Error!","Unable to fetch records.","error");
            console.error(error);
        });
    }

    setSelectedRecords(){
        if(this.totalRecords.length!=0){
            this.selectedRecords = [];
            for(var i=(this.rowsPerTable * (parseInt(this.pageNo)-1));i<(this.rowsPerTable * parseInt(this.pageNo));i++){
                if(this.totalRecords[i])this.selectedRecords.push(this.totalRecords[i]);
                else break;
            }
        }
    }

    generateDownloadLink(event){
        getDownloadLink({ recordId: event.currentTarget.dataset.id })
        .then((result) => {
            if(result){
                //window.open(result,"_self");
                window.location.href = result; //GSBS-17 changes
            }
        })
        .catch((error) => {
            this.fireToastEvent("Error!","Unable create download link.","error");
            console.error(error);
        });
    }

    handlePageChange(event) {
        this.pageNo = event.detail.value;
        this.setSelectedRecords();
    }

    fireToastEvent(title,message,variant){
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }
}