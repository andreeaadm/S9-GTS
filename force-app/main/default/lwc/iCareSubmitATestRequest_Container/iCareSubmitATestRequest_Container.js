import { LightningElement, wire, api } from "lwc";
import getJobRequests from "@salesforce/apex/Icare_SubmitTestRequestController.getJobRequests";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import deleteJobRequest from "@salesforce/apex/Icare_SubmitTestRequestController.deleteJobRequest";
import getAllJobRequests from "@salesforce/apex/Icare_SubmitTestRequestController.getAllJobRequests";
import LightningConfirm from "lightning/confirm";
import { NavigationMixin } from "lightning/navigation";

import TITLE from "@salesforce/label/c.iCare_Submit_Test_Homepage";
import TIP1 from "@salesforce/label/c.iCare_Submit_a_Test_Request_P1";
import TIP2 from "@salesforce/label/c.iCare_Submit_a_Test_Request_P2";
import SELF_REFERENCE_TEST from "@salesforce/label/c.iCare_Self_Reference_Test_Button";
import VIEW_ALL from "@salesforce/label/c.iCare_Portal_View_all";
import FAVOURITES from "@salesforce/label/c.iCare_Favourites";
import SAVED_DRAFTS from "@salesforce/label/c.iCare_Saved_Drafts";
import SAVED from "@salesforce/label/c.iCare_Saved";
import SAMPLE_DESCRIPTION from "@salesforce/label/c.iCare_Sample_Description";
import DELETE from "@salesforce/label/c.iCare_Portal_Delete";
import NAME from "@salesforce/label/c.iCare_Portal_Name";
import BUYER_PROGRAM from "@salesforce/label/c.iCare_Buyer_Program_Button";

import CONFIRM_DELETE_HEADER from "@salesforce/label/c.iCare_Confirm_Delete_Header";
import CONFIRM_DELETE_MESSAGE from "@salesforce/label/c.iCare_Confirm_Delete_Message";
import RECORD_DELETED_HEADER from "@salesforce/label/c.iCare_Record_Deleted_Header";
import RECORD_DELETED_MESSAGE from "@salesforce/label/c.iCare_Record_Deleted_Message";

import TIMEZONE from "@salesforce/i18n/timeZone";

const favouriteColumns = [
  {
    label: SAVED,
    fieldName: "CreatedDate",
    type: "date",
    hideDefaultActions: false,
    typeAttributes: {
      day: "2-digit",
      month: "2-digit",
      year: "numeric",
      hour: "2-digit",
      minute: "2-digit",
      timeZone: TIMEZONE
    }
  },
  {
    label: NAME,
    type: "button",
    initialWidth: 300,
    typeAttributes: {
      label: { fieldName: "favNameButton" },
      name: "openFavourite",
      variant: "base"
    }
  },
  {
    label: DELETE,
    type: "button",
    typeAttributes: {
      label: DELETE,
      name: "delete",
      title: "Delete",
      variant: "destructive-text"
    }
  }
];

const draftColumns = [
  {
    label: SAVED,
    fieldName: "CreatedDate",
    type: "date",
    hideDefaultActions: false,
    typeAttributes: {
      day: "2-digit",
      month: "2-digit",
      year: "numeric",
      hour: "2-digit",
      minute: "2-digit",
      timeZone: TIMEZONE
    }
  },
  {
    label: SAMPLE_DESCRIPTION,
    type: "button",
    initialWidth: 300,
    typeAttributes: {
      label: { fieldName: "iCare_Sample_Description__c" },
      name: "openDraft",
      variant: "base"
    }
  },
  {
    label: DELETE,
    type: "button",
    typeAttributes: {
      label: DELETE,
      name: "delete",
      title: "Delete",
      variant: "destructive-text"
    }
  }
];

export default class SubmitATestRequest_Container extends NavigationMixin(
  LightningElement
) {
  customLabel = {
    TITLE,
    TIP1,
    TIP2,
    SELF_REFERENCE_TEST,
    VIEW_ALL,
    FAVOURITES,
    SAVED_DRAFTS,
    SAVED,
    SAMPLE_DESCRIPTION,
    DELETE,
    NAME,
    BUYER_PROGRAM,
    CONFIRM_DELETE_HEADER,
    CONFIRM_DELETE_MESSAGE,
    RECORD_DELETED_HEADER,
    RECORD_DELETED_MESSAGE
  };

  draftData = [];
  favouritesData = [];
  favouriteColumns = favouriteColumns;
  draftColumns = draftColumns;
  flowApiName = "iCare_eTRF_Form_Handler";
  launchFlow = false;
  allJobRequestData = [];
  viewAllJobRequests = false;
  selectedRecordTypeName = "";
  sumbitJobRequestPage = false;

  displaySubmitAJobByBuyerProgram = false;
  displaySearchedBuyer = false;
  selectedBuyer;
  selectedDraft;

  @api accountId;

  connectedCallback() {
    this.loadJobRequests();
  }

  loadJobRequests() {
    this.launchFlow = false;
    this.sumbitJobRequestPage = true;
    this.viewAllJobRequests = false;
    getJobRequests()
      .then((result) => {
        result = result.map((row) => {
          var favName =
            row.iCare_Favourite_Name__c != undefined
              ? row.iCare_Favourite_Name__c.slice(0, 50)
              : "";
          var draftName =
            row.iCare_Sample_Description__c != undefined
              ? row.iCare_Sample_Description__c.slice(0, 50)
              : "";
          return {
            ...row,
            favNameButton: favName,
            draftNameButton: draftName
          };
        });

        this.favouritesData = result.filter(
          (row) => row.RecordType.Name === "Favourite Job Request"
        );
        this.draftData = result.filter(
          (row) => row.RecordType.Name !== "Favourite Job Request"
        );
      })
      .catch((error) => {
        console.log("error >>" + JSON.stringify(error));
      });
  }

  async handleRowAction(event) {
    const actionName = event.detail.action.name;
    const row = event.detail.row;

    switch (actionName) {
      case "delete":
        const result = await LightningConfirm.open({
          message: CONFIRM_DELETE_MESSAGE,
          variant: "header",
          label: CONFIRM_DELETE_HEADER,
          theme: "success"
        }).then((result) => {
          if (result) {
            deleteJobRequest({ jobReqId: row.Id })
              .then((result) => {
                console.log("record deleted");
                this.showSuccessToast();
                this.loadJobRequests();
              })
              .catch((error) => {
                console.log("error in delete *** ", error);
              });
          }
        });
        break;
      case "openFavourite":
        this.selectedDraft = row.Id;
        this.launchFlow = true;
        this.viewAllJobRequests = false;
        this.sumbitJobRequestPage = false;
        break;
      case "openDraft":
        this.selectedDraft = row.Id;
        this.launchFlow = true;
        this.viewAllJobRequests = false;
        this.sumbitJobRequestPage = false;
        break;
      default:
        break;
    }
  }

  showSuccessToast() {
    const evt = new ShowToastEvent({
      title: RECORD_DELETED_HEADER,
      message: RECORD_DELETED_MESSAGE,
      variant: "success",
      mode: "dismissable"
    });
    this.dispatchEvent(evt);
  }

  viewAllRecords(event) {
    console.log("View All Records **");
    let selectedRecordType = event.target.name;
    this.selectedRecordTypeName = selectedRecordType;
    getAllJobRequests({ recTypeName: selectedRecordType })
      .then((result) => {
        this.allJobRequestData = result;
        this.launchFlow = false;
        this.viewAllJobRequests = true;
        this.sumbitJobRequestPage = false;
      })
      .catch((error) => {
        console.log("error --> " + JSON.stringify(error));
      });
  }

  handleFlowStatusChange(event) {
    if (event.detail.status === "FINISHED") {
      window.location.reload();
    }
  }

  refreshJobRequest(event) {
    console.log("View All Records **");
    getAllJobRequests({ recTypeName: this.selectedRecordTypeName })
      .then((result) => {
        this.allJobRequestData = result;
        this.launchFlow = false;
        this.viewAllJobRequests = true;
        this.sumbitJobRequestPage = false;
      })
      .catch((error) => {
        console.log("error --> " + JSON.stringify(error));
      });
  }

  launchSelfReferenceFlow() {
    this.selectedDraft = "";
    this.launchFlow = true;
    this.viewAllJobRequests = false;
    this.sumbitJobRequestPage = false;
  }

  handleViewAllLaunchFlow(event) {
    this.selectedDraft = event.detail;
    this.launchFlow = true;
    this.viewAllJobRequests = false;
    this.sumbitJobRequestPage = false;
  }

  handleBuyerProgramClick(event) {
    this.selectedDraft = "";
    this.displaySubmitAJobByBuyerProgram = true;
    this.sumbitJobRequestPage = false;
  }

  handleSearchClick(event) {
    this.displaySearchedBuyer = true;
    this.displaySubmitAJobByBuyerProgram = false;
    this.selectedBuyer = JSON.parse(event.detail);
  }

  handleGoBackClick(event) {
    this.displaySubmitAJobByBuyerProgram = false;
    this.sumbitJobRequestPage = true;
  }

  handleFrequentlyBuyerClick(event) {
    this.displaySearchedBuyer = true;
    this.displaySubmitAJobByBuyerProgram = false;
    this.selectedBuyer = JSON.parse(event.detail);
  }

  handleChangeBuyerClick(event) {
    this.displaySubmitAJobByBuyerProgram = true;
    this.displaySearchedBuyer = false;
  }

  handleSubmitTestRequestSelectedBuyer(event) {
    this.displaySearchedBuyer = false;
    this.launchFlow = true;
  }

  get inputVariables() {
    return [
      {
        name: "BuyerProgramId",
        type: "String",
        value: this.selectedBuyer != undefined ? this.selectedBuyer.id : ""
      },
      {
        name: "recordId",
        type: "String",
        value: this.selectedDraft != undefined ? this.selectedDraft : ""
      }
    ];
  }
}