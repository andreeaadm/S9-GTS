import { LightningElement, api, track, wire } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import deleteJobRequest from "@salesforce/apex/Icare_SubmitTestRequestController.deleteJobRequest";
import LightningConfirm from "lightning/confirm";

import getJobRequestList from "@salesforce/apex/Icare_SubmitTestRequestController.getJobRequestList";
import getNext from "@salesforce/apex/Icare_SubmitTestRequestController.getNext";
import getPrevious from "@salesforce/apex/Icare_SubmitTestRequestController.getPrevious";
import TotalRecords from "@salesforce/apex/Icare_SubmitTestRequestController.totalRecords";

import SUBMIT_A_TEST_REQUEST_LABEL from "@salesforce/label/c.Submit_a_test_request";
import FAVOURITES_LABEL from "@salesforce/label/c.iCare_Portal_Favourites";
import SAVED_DRAFTS_LABEL from "@salesforce/label/c.iCare_Portal_Saved_Drafts";

import VIEW_ALL from "@salesforce/label/c.iCare_Portal_View_all";
import SAVED_DRAFTS from "@salesforce/label/c.iCare_Saved_Drafts";
import SAVED from "@salesforce/label/c.iCare_Saved";
import SAMPLE_DESCRIPTION from "@salesforce/label/c.iCare_Sample_Description";
import DELETE from "@salesforce/label/c.iCare_Portal_Delete";
import NAME from "@salesforce/label/c.iCare_Portal_Name";

import CONFIRM_DELETE_HEADER from "@salesforce/label/c.iCare_Confirm_Delete_Header";
import CONFIRM_DELETE_MESSAGE from "@salesforce/label/c.iCare_Confirm_Delete_Message";
import RECORD_DELETED_HEADER from "@salesforce/label/c.iCare_Record_Deleted_Header";
import RECORD_DELETED_MESSAGE from "@salesforce/label/c.iCare_Record_Deleted_Message";

import TIMEZONE from "@salesforce/i18n/timeZone";

const draftColumns = [
  {
    label: SAVED,
    fieldName: "CreatedDate",
    type: "date",
    hideDefaultActions: "false",
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
    initialWidth: 400,
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

const favouriteColumns = [
  {
    label: SAVED,
    fieldName: "CreatedDate",
    type: "date",
    hideDefaultActions: "false",
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
    initialWidth: 400,
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

export default class ViewAllJobRequests extends LightningElement {
  label = {
    SUBMIT_A_TEST_REQUEST_LABEL,
    FAVOURITES_LABEL,
    SAVED_DRAFTS_LABEL,
    VIEW_ALL,
    SAVED_DRAFTS,
    SAVED,
    SAMPLE_DESCRIPTION,
    DELETE,
    NAME,
    CONFIRM_DELETE_HEADER,
    CONFIRM_DELETE_MESSAGE,
    RECORD_DELETED_HEADER,
    RECORD_DELETED_MESSAGE
  };

  @api allJobRequestData = [];
  @api selectedRecordType = "";
  tableData = [];
  favouriteTable = false;
  draftTable = false;
  favouriteColumns = favouriteColumns;
  draftColumns = draftColumns;
  selectedDraft;
  flowApiName = "iCare_eTRF_Form_Handler";
  launchFlow = false;

  jobRequestResults = [];
  @track v_Offset = 0;
  @track v_TotalRecords;
  @track page_size = 5;
  isLoading = false;

  connectedCallback() {
    if (this.selectedRecordType === "Favourite_Job_Request") {
      this.favouriteTable = true;
    } else {
      this.draftTable = true;
    }
    this.loadJobRequests();
    //this.loadJobRequestData();
  }

  @wire(getJobRequestList, {
    v_Offset: "$v_Offset",
    v_pagesize: "$page_size",
    recTypeName: "$selectedRecordType"
  })
  jobRequests(result) {
    this.jobRequestResults = result;
    if (result.data) {
      result.data = result.data.map((row) => {
        const favName =
          row.iCare_Favourite_Name__c != undefined
            ? row.iCare_Favourite_Name__c.slice(0, 50)
            : "";
        const draftName =
          row.iCare_Sample_Description__c != undefined
            ? row.iCare_Sample_Description__c.slice(0, 50)
            : "";
        return {
          ...row,
          favNameButton: favName,
          draftNameButton: draftName
        };
      });
      this.tableData = result.data;
    } else if (result.error) {
      console.log("data **", JSON.stringify(result.error));
    }
  }

  /*
    loadJobRequestData(){
        getJobRequestList({ v_Offset: this.v_Offset, v_pagesize: this.page_size, recTypeName: this.selectedRecordType })
        .then((result) => {
            result = result.map((row) => {
            const favName = row.iCare_Favourite_Name__c != undefined
            ? row.iCare_Favourite_Name__c.slice(0, 50)
            : '';
            const draftName = row.iCare_Sample_Description__c != undefined
            ? row.iCare_Sample_Description__c.slice(0, 50)
            : '';
            return {
                ...row,
                favNameButton: favName,
                draftNameButton: draftName,
            };
        });
            this.tableData = result;
        }).catch(error =>{
            console.log('error in loadJobRequestData**',error);
        }); 
    }
    */

  handleRowAction(event) {
    const actionName = event.detail.action.name;
    const row = event.detail.row;

    switch (actionName) {
      case "delete":
        this.confirmDelete(row.Id);
        break;
      case "openFavourite":
        this.selectedDraft = row.Id;
        this.launchSelfReferenceFlow();
        break;
      case "openDraft":
        this.selectedDraft = row.Id;
        this.launchSelfReferenceFlow();
        break;
      default:
        break;
    }
  }

  confirmDelete(recordId) {
    LightningConfirm.open({
      message: CONFIRM_DELETE_MESSAGE,
      variant: "header",
      label: CONFIRM_DELETE_HEADER,
      theme: "success"
    })
      .then((result) => {
        if (result) {
          this.deleteRecord(recordId);
          window.location.reload();
        }
      })
      .catch((error) => {
        console.log("error in delete *** ", error);
      });
  }

  deleteRecord(recordId) {
    deleteJobRequest({ jobReqId: recordId })
      .then(() => {
        console.log("record deleted");
        this.showSuccessToast();
        this.removeDeletedRecord(recordId);
      })
      .catch((error) => {
        console.log("error in delete *** ", error);
      });
  }

  removeDeletedRecord(recordId) {
    const updatedTableData = this.tableData.filter(
      (row) => row.Id !== recordId
    );
    this.tableData = updatedTableData;
  }

  launchSelfReferenceFlow() {
    const flowEvent = new CustomEvent("launchflow", {
      detail: this.selectedDraft,
      bubbles: true,
      composed: false
    });
    this.dispatchEvent(flowEvent);
  }

  loadJobRequests() {
    this.isLoading = true;
    TotalRecords({ selectedRecordTypeName: this.selectedRecordType })
      .then((result) => {
        this.v_TotalRecords = result;
        if (this.v_TotalRecords < this.page_size) {
          this.template
            .querySelector("c-i-care-paginator")
            .changeView("truenext");
          this.template
            .querySelector("c-i-care-paginator")
            .changeView("trueFirstPage");
          this.template
            .querySelector("c-i-care-paginator")
            .changeView("trueLastPage");
          this.template
            .querySelector("c-i-care-paginator")
            .changeView("trueprevious");
        }
      })
      .catch((error) => {
        console.log("error in totalrecords ***", JSON.stringify(error));
      })
      .finally(() => {
        this.isLoading = false;
      });
  }

  previousHandler() {
    getPrevious({ v_Offset: this.v_Offset, v_pagesize: this.page_size })
      .then((result) => {
        console.log("*** previousHandler ***", result);
        this.v_Offset = result;
        if (this.v_Offset <= 0) {
          this.template
            .querySelector("c-i-care-paginator")
            .changeView("trueprevious");
          this.template
            .querySelector("c-i-care-paginator")
            .changeView("trueFirstPage");
          this.template
            .querySelector("c-i-care-paginator")
            .changeView("falsenext");
          this.template
            .querySelector("c-i-care-paginator")
            .changeView("falseLastPage");
        } else {
          this.template
            .querySelector("c-i-care-paginator")
            .changeView("falsenext");
          this.template
            .querySelector("c-i-care-paginator")
            .changeView("falseLastPage");
        }
      })
      .catch((error) => {
        console.log("error in previousHandler2**", error);
      });
  }

  nextHandler() {
    getNext({ v_Offset: this.v_Offset, v_pagesize: this.page_size })
      .then((result) => {
        this.v_Offset = result;
        const addition = this.v_Offset * 1 + this.page_size * 1;

        if (addition > this.v_TotalRecords) {
          this.template
            .querySelector("c-i-care-paginator")
            .changeView("truenext");
          this.template
            .querySelector("c-i-care-paginator")
            .changeView("trueLastPage");
        } else if (addition < this.v_TotalRecords) {
          this.template
            .querySelector("c-i-care-paginator")
            .changeView("falsenext");
          this.template
            .querySelector("c-i-care-paginator")
            .changeView("falseLastPage");
        }
        this.template
          .querySelector("c-i-care-paginator")
          .changeView("falseprevious");
        this.template
          .querySelector("c-i-care-paginator")
          .changeView("falseFirstPage");
      })
      .catch((error) => {
        console.log("error in nextHandler2**", JSON.stringify(error));
      });
  }

  changeHandler(event) {
    this.v_Offset = 0;
    const det = event.detail;
    this.page_size = det;

    if (this.page_size < this.v_TotalRecords) {
      this.template
        .querySelector("c-i-care-paginator")
        .changeView("falseLastPage");
      this.template.querySelector("c-i-care-paginator").changeView("falsenext");
      this.template
        .querySelector("c-i-care-paginator")
        .changeView("trueprevious");
      this.template
        .querySelector("c-i-care-paginator")
        .changeView("trueFirstPage");
    } else if (this.page_size > this.v_TotalRecords) {
      this.template.querySelector("c-i-care-paginator").changeView("truenext");
    }
  }

  firstpagehandler() {
    this.v_Offset = 0;
    this.template
      .querySelector("c-i-care-paginator")
      .changeView("trueprevious");
    this.template.querySelector("c-i-care-paginator").changeView("falsenext");
    this.template
      .querySelector("c-i-care-paginator")
      .changeView("falseLastPage");
    this.template
      .querySelector("c-i-care-paginator")
      .changeView("trueFirstPage");
  }

  lastpagehandler() {
    this.v_Offset =
      this.v_TotalRecords - (this.v_TotalRecords % this.page_size);
    this.template
      .querySelector("c-i-care-paginator")
      .changeView("falseprevious");
    this.template.querySelector("c-i-care-paginator").changeView("truenext");
    this.template
      .querySelector("c-i-care-paginator")
      .changeView("trueLastPage");
    this.template
      .querySelector("c-i-care-paginator")
      .changeView("falseFirstPage");
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
}