import { LightningElement, api } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import apexGetShipments from "@salesforce/apex/GTSShipmentTableController.getShipments";

export default class GTSShipmentTable extends LightningElement {
  sortDirection = 'desc';
  sortedBy;

  @api recordId;
  records;

  connectedCallback() {
    apexGetShipments({
      recordId: this.recordId
    })
      .then((response) => {
        this.records = JSON.parse(response);
        console.log(JSON.stringify(this.records));
      })
      .catch((error) => {
        const evt = new ShowToastEvent({
          title: "Error",
          message: "There was an Error retrieving Shipment Information.",
          variant: "error"
        });
        this.dispatchEvent(evt);
      });
  }
     // Used to sort the 'Age' column
     sortBy(field, reverse, primer) {
         const key = primer
             ? function (x) {
                   return primer(x[field]);
               }
             : function (x) {
                   return x[field];
               };

         return function (a, b) {
             a = key(a);
             b = key(b);
             return reverse * ((a > b) - (b > a));
         };
     }

     onHandleSort(event) {
         const { fieldName: sortedBy, sortDirection } = event.detail;
         const cloneData = [...this.records];

         cloneData.sort(this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));
         this.records = cloneData;
         this.sortDirection = sortDirection;
         this.sortedBy = sortedBy;
     }

     handleSortRecords(event){
         let sortDirection = event.detail.sortDirection;

         let sortedBy = 'GTS_Date_Issued__c';

         const cloneData = [...this.records];
         cloneData.sort(this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));
         this.records = cloneData;
         this.sortDirection = sortDirection;
         this.sortedBy = sortedBy;
     }


 }