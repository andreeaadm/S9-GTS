import { LightningElement, api } from "lwc";
import { label } from "c/labelService";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getDataForDownload from "@salesforce/apex/TCBrandDownloadInventoryController.getDataForDownload";

export default class TcBrandDownloadInventory extends LightningElement {

  labels = label;
  data;
  fileName;

  @api handleDownload(inventoryId) {
    getDataForDownload({ inventoryId: inventoryId })
      .then((response) => {
        this.data = response;
        if (
          this.data.supplierName &&
          this.data.facilityName &&
          this.data.inventoryName
        ) {
          this.fileName = this.data.supplierName.concat(
            " - ",
            this.data.facilityName,
            " - ",
            this.data.inventoryName,
            ".csv"
          );
          this.downloadCsvFile(this.data.csvFile);
        } else {
          this.dispatchEvent(
            new ShowToastEvent({
              title: this.labels.ERROR,
              message: this.labels.TC_DOWNLOAD_ERROR_NO_ITEMS,
              variant: "error"
            })
          );
        }
      })
      .catch((error) => {
        this.dispatchEvent(
          new ShowToastEvent({
            title: this.labels.ERROR,
            message: error?.body?.message
              ? error.body.message
              : this.labels.TC_DOWNLOAD_INVENTORY_ERROR,
            variant: "error"
          })
        );
        this.data = undefined;
      });
  }

  downloadCsvFile(csvString) {
    let downloadElement = document.createElement("a");
    downloadElement.href =
      "data:text/csv;charset=utf-8," + encodeURIComponent(csvString);
    downloadElement.target = "_self";
    downloadElement.download = this.fileName;
    document.body.appendChild(downloadElement);
    downloadElement.click();
  }


}