import { LightningElement, api } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { loadStyle } from "lightning/platformResourceLoader";
import oegenResources from "@salesforce/resourceUrl/oegenResources";
import getTemplateColumns from "@salesforce/apex/CSVImportController.getTemplateColumns";
import doImport from "@salesforce/apex/CSVImportController.doImport";
export default class CsvImport extends LightningElement {
  @api recordId;
  @api settingName;
  @api title;
  @api downloadCSVLabel = "Download Template CSV";
  @api downloadCSVErrorTitle = "Error downloading template CSV";
  @api importErrorTitle = "Error importing CSV";
  @api readyToImportTitle = "Ready to import";
  @api readyToImportMessage = "CSV ready to import. Click Import to continue.";
  @api importSuccessTitle = "Success";
  @api importSuccessMessage = "CSV imported";
  @api importLabel = "Import";
  @api templateFileName = "CSV_Upload_Template";
  @api hideTemplateButton = false;
  @api hideImportButton = false;
  @api disableToasts = false;
  @api importAction;
  fileData;
  disableImport = true;
  isLoading = false;

  get acceptedFormats() {
    return ".csv";
  }

  connectedCallback() {
    this.importAction = this.importAction ? this.importAction : doImport;
    loadStyle(
      this,
      oegenResources + "/css/baseComponentOverrides/csvFileImport.css"
    );
  }

  downloadTemplateCSV() {
    if (this.settingName) {
      this.isLoading = true;
      getTemplateColumns({ settingName: this.settingName })
        .then((result) => {
          let csvContent =
            "data:text/csv;charset=utf-8," + result.join(",") + "\r\n";
          var encodedUri = encodeURI(csvContent);
          let a = document.createElement("a");
          a.href = encodedUri;
          a.download = this.templateFileName + ".csv";
          document.body.appendChild(a); // Required for FF
          a.click(); // This will download the data file.
          this.isLoading = false;
        })
        .catch((error) => {
          this.showNotification(
            this.downloadCSVErrorTitle,
            JSON.stringify(error),
            "error"
          );
          this.isLoading = false;
        });
    }
  }

  handleFileChange(evt) {
    this.isLoading = true;
    var reader = new FileReader();
    reader.onload = () => {
      this.fileData = reader.result.split(",")[1];
      this.isLoading = false;
      this.disableImport = false;
      this.showNotification(
        this.readyToImportTitle,
        this.readyToImportMessage,
        "success",
        "dismissible"
      );
      this.dispatchEvent(new CustomEvent("filechange"));
    };
    reader.readAsDataURL(evt.detail.files[0]);
  }

  showNotification(title, message, variant, mode) {
    if (!this.disableToasts) {
      this.dispatchEvent(
        new ShowToastEvent({
          title: title,
          message: message,
          variant: variant ? variant : "error",
          mode: mode ? mode : "sticky"
        })
      );
    }
  }

  @api
  doImport() {
    this.isLoading = true;
    if (this.settingName) {
      this.importAction({
        settingName: this.settingName,
        base64: this.fileData,
        parentId: this.recordId
      })
        .then((result) => {
          if (!result.messages || result.messages.length === 0) {
            this.disableImport = true;
            this.showNotification(
              this.importSuccessTitle,
              this.importSuccessMessage,
              "success",
              "dismissible"
            );
            this.dispatchEvent(new CustomEvent("importsuccess"));
          } else {
            this.disableImport = true;
            let error = "";
            result.messages.forEach((e) => (error += e + "\n"));
            this.showNotification(this.importErrorTitle, error, "error");
            this.dispatchEvent(new CustomEvent("importerror"));
          }
          this.isLoading = false;
        })
        .catch((error) => {
          this.disableImport = true;
          this.isLoading = false;
          this.showNotification(
            this.importErrorTitle,
            JSON.stringify(error),
            "error"
          );
        });
    }
  }
}