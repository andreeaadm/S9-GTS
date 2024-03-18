import { LightningElement, api } from "lwc";
import { label } from "c/labelService";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getDataForDownload from "@salesforce/apex/TC_DownloadInventoryController.getDataForDownload";

export default class TcDownloadInventory extends LightningElement {
  headerString =
    "Name, Inventory Name, Inventory Date, Type, Chemical Product, Chemical Product Name, Formulator Name, Other Name, Substrate, Other Certifications, ZDHC MRSL Level, ZDHC MRSL Vesrion, Conformant, Product ID, Product GUID, Unit, Stock take - month begin, Delivered stock this month, Stock take - month end, Calculated usage, Calculated weight (kg), Delivered Stock History, Storage Location, Lot Number, Expiry Date, CAS Number, Supplier Reference Number, Supplier Reference Name, Product Name (Local Langauge), Formulator Name (Local Langauge), Inditex Classification For Babies, Inditex Classification For ChildAdult, Commodity Chemical Standard Name, Type of Chemicals";
  columnKeys = [
    "name",
    "inventoryName",
    "inventoryDate",
    "type",
    "chemicalProduct",
    "chemicalProductName",
    "formulatorName",
    "otherName",
    "substrate",
    "otherCertifications",
    "zdhcMRSL",
    "zdhcMRSLVersion",
    "conformant",
    "productId",
    "productGUID",
    "unit",
    "stockTakeMonthBegin",
    "deliveredStock",
    "stockTakeMonthEnd",
    "calculatedUsage",
    "calculatedWeight",
    "deliveredStockHistory",
    "storageLocation",
    "lotNumber",
    "expiryDate",
    "CASNumber",
    "SupplierReferenceNumber",
    "SupplierReferenceName",
    "ProductName_LocalLangauge",
    "FormulatorName_LocalLangauge",
    "InditexClassificationForBabies",
    "InditexClassificationForChildAdult",
    "CommodityChemicalStandardName",
    "TypeofChemicals"
  ];
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
          this.createCsvFile();
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

  createCsvFile() {
    let rowEnd = "\n";
    let separator = ",";
    let csvString = this.headerString + rowEnd;

    this.data.lineItems.forEach((row) => {
      let colValue = 0;

      this.columnKeys.forEach((key) => {
        if (colValue !== 0) {
          csvString += separator;
        }

        let value =
          row[key] === undefined ? "" : row[key].replace(/(<([^>]+)>)/gi, " ");
        csvString += value;
        colValue++;
      });
      csvString += rowEnd;
    });

    let downloadElement = document.createElement("a");
    downloadElement.href =
      "data:text/csv;charset=utf-8," + encodeURIComponent(csvString);
    downloadElement.target = "_self";
    downloadElement.download = this.fileName;
    document.body.appendChild(downloadElement);
    downloadElement.click();
  }
}