import { LightningElement, api, track, wire } from "lwc";
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { NavigationMixin } from "lightning/navigation";
import { label } from "c/labelService";

import getTableData from "@salesforce/apex/ReportDeliverableListController.getTableData";
// import downloadDeliverable from "@salesforce/apex/ReportDeliverableListController.downloadDeliverable";
import downloadDeliverable from "@salesforce/apex/ReportDeliverableListController.getDocDownloadEphemeralURL";

import NAME_FIELD from "@salesforce/schema/Asset.Name";
import assetExpiryBanner from "@salesforce/apex/AssetExpiryBannerController.assetExpirystatus"; /*Prateek*/


export default class ReportDeliverablesTile extends NavigationMixin(
  LightningElement
) {
  labels = label; 
  @api recordId;
  @api additionalClasses = "greytile";
  @track isLoading = true;
  @track hasLoaded = false;
  @track isEmpty = true;
  @api booleanExpiry; //Prateek

  @track tableData = { columns: [], rows: [] };

  @track isWorking = false;
  @track reportName = "";
  error;

  connectedCallback() {
    this.getData();
  }

  @wire(getRecord, { recordId: "$recordId", fields: [NAME_FIELD] })
  wiredAsset({ error, data }) {
    if (data) {
      this.reportName = getFieldValue(data, NAME_FIELD);
    }
  }
  /*Prateek*/
  
  @wire(assetExpiryBanner, { recordId: "$recordId"})
  wiredExpiryStatus({ error, data }) {
    if (data) {
      console.log('Report debug',data);
      this.booleanExpiry = data;
    }
  }
  

  getData() {
    this.isLoading = true;
    getTableData({
      rowLimit: 40,
      orderBy: "Name DESC",
      selectedRowIds: [],
      reportId: this.recordId
    })
      .then((response) => {
        if (response.table) {
          this.tableData = response.table;
          this.isEmpty = !(
            response.table.rows.length && response.table.rows.length > 0
          );
          this.error = undefined;
          this.hasLoaded = true;
          this.isLoading = false;
        } else if (error) {
          this.error = error;
          this.tableData = { columns: [], rows: [] };
          this.isEmpty = true;
          this.hasLoaded = true;
        }
      })
      .catch((error) => {
        if (error) {
          this.error = error;
          this.tableData = { columns: [], rows: [] };
          this.isLoading = false;
        }
      });
  }

  handleActionClick(evt) {
    // depending on the action, launch the appropriate modal
    switch (evt.detail.value) {
      case "Download":
        this.getDeliverable(evt.detail.rowId);
        break;
    }
  }
  getDeliverable(pDeliverableId) {
    downloadDeliverable({
      reportId: this.recordId,
      deliverableId: pDeliverableId
    })
      .then((urlResponse) => {
        fetch(urlResponse).then((response) => {
          if (response.ok && response.status == 200) {
            this.error = undefined;
            let filename = this.getFileNameFromContentDispostionHeader(
              response.headers.get("content-disposition")
            );
            response.blob().then((blob) => {
              var dynElt = document.createElement("a");
              const objUrl = window.URL.createObjectURL(blob);
              dynElt.setAttribute("href", objUrl);
              dynElt.setAttribute("download", filename);
              dynElt.style.display = "none";
              document.body.appendChild(dynElt);
              dynElt.click();
              document.body.removeChild(dynElt);
            });
          } else {
            this.dispatchEvent(
              new ShowToastEvent({
                title: this.labels.ERROR,
                message: this.labels.DOWNLOAD_ERROR,
                variant: "error"
              })
            );
            this.error = this.labels.DOWNLOAD_ERROR;
          }
        });
      })
      .catch((error) => {
        new ShowToastEvent({
          title: this.labels.ERROR,
          message: this.labels.DOWNLOAD_ERROR,
          variant: "error"
        });
        this.error = this.labels.DOWNLOAD_ERROR;
      });
  }

  getFileNameFromContentDispostionHeader = function (header) {
    let contentDispostion = header.split(";");
    const fileNameToken = `filename=`;

    let fileName = "downloaded.pdf";
    for (let thisValue of contentDispostion) {
      if (thisValue.trim().indexOf(fileNameToken) === 0) {
        fileName = decodeURIComponent(
          thisValue.trim().replace(fileNameToken, "").replaceAll('"', "")
        );
        break;
      }
    }

    return fileName;
  };
}