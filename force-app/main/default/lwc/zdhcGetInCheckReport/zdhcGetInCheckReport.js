import { LightningElement, api } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { label, format } from "c/labelService";
import getInCheckReportForInventory from "@salesforce/apex/ZdhcGetInCheckReportController.getInCheckReportForInventory";

export default class zdhcGetInCheckReport extends LightningElement {
  @api getInCheckReport(inventoryId) {
    getInCheckReportForInventory({ inventoryId: inventoryId })
      .then((response) => {
        try {
          let result = JSON.parse(response);
          if (result.fileData && result.fileName) {
            this.downloadPdf(result.fileData, result.fileName);
          }
        } catch {
          dispatchEvent(
            new ShowToastEvent({
              title: label.ERROR,
              message: format(label.TC_ZDHC_CALLOUT_ERROR, response),
              variant: "error"
            })
          );
        }
      })
      .catch((error) => {
        dispatchEvent(
          new ShowToastEvent({
            title: label.ERROR,
            message: format(label.TC_ZDHC_CALLOUT_ERROR, error.body.message),
            variant: "error"
          })
        );
      });
  }

  downloadPdf(pdfString, fileName) {
    let headers = "data:application/pdf;base64,";
    let link = document.createElement("a");
    link.download = fileName;
    link.href = headers.concat(pdfString);
    document.body.appendChild(link);
    link.click();
  }
}