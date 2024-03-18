import { LightningElement, wire, api, track } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

import getNext from "@salesforce/apex/iCare_TrackJobsController.getNext";
import getPrevious from "@salesforce/apex/iCare_TrackJobsController.getPrevious";
import TotalRecords from "@salesforce/apex/iCare_TrackJobsController.totalRecords";
import getJobTestReport from "@salesforce/apex/iCare_JobTestReport.getJobTestReport";

import DATE_TIME_FIELD from "@salesforce/schema/iCare_Job__c.iCare_Date_Time__c";

import ALL_LABEL from "@salesforce/label/c.iCare_Portal_All";
import SAMPLE_RECEIVED_LABEL from "@salesforce/label/c.iCare_Portal_Sample_Received";
import COMPLETED_LABEL from "@salesforce/label/c.iCare_Portal_Completed";
import IN_PROGRESS_LABEL from "@salesforce/label/c.iCare_Portal_In_Progress";
import PENDING_LABEL from "@salesforce/label/c.iCare_Portal_Pending";
import CANCELLED_LABEL from "@salesforce/label/c.iCare_Portal_Cancelled";
import ENTER_LABEL from "@salesforce/label/c.iCare_Portal_Enter_JobId_or_Key";
import ACTION_LABEL from "@salesforce/label/c.iCare_Action";
import DOWNLOAD_LABEL from "@salesforce/label/c.iCare_Portal_Download";
import TRACK_JOBS_LABEL from "@salesforce/label/c.iCare_Portal_Track_Jobs";
import VIEW_ALL_LABEL from "@salesforce/label/c.iCare_Portal_View_all";

import getTableData from "@salesforce/apex/iCare_TrackJobsController.getTableData";
import checkRelatedCertificates from "@salesforce/apex/iCare_TrackJobsController.checkRelatedCertificates";

import iCarePortalTableMC from "@salesforce/messageChannel/iCarePortalTablesMessageChannel__c";

import TOTAL_NUMBER_LABEL from "@salesforce/label/c.iCare_Portal_TotalNumber";
import { publish, MessageContext } from "lightning/messageService";
import ALL_BUYERS_LABEL from "@salesforce/label/c.iCare_Portal_All_Buyers";

export default class ICareTrackJobsTable extends NavigationMixin(
  LightningElement
) {
  @api isReportToBeShown = false;
  @api numberOfRecords = 5;
  @api pagination = false;
  @api tableName;
  statusFilter = "All";
  @api daysToSearch;
  endDate;
  startDate;
  @api viewAll = false;

  @track v_Offset = 0;
  @track v_TotalRecords;
  @track page_size = 5;
  @api recordTypeId;
  isGtsTrackJobTable = false;

  searchBoxRecords;
  @track buyerOptions = [{ label: "All", value: "All" }];

  downloadColumn = {
    label: ACTION_LABEL,
    type: "button",
    initialWidth: 100,
    typeAttributes: {
      class: "datatable-action-button",
      label: DOWNLOAD_LABEL,
      name: "download",
      variant: "base" /*, style:'color:red'*/
    }
  };

  label = {
    ALL_LABEL,
    SAMPLE_RECEIVED_LABEL,
    COMPLETED_LABEL,
    IN_PROGRESS_LABEL,
    PENDING_LABEL,
    CANCELLED_LABEL,
    ENTER_LABEL,
    VIEW_ALL_LABEL
  };

  tableHeaderLabel = TRACK_JOBS_LABEL;
  availableJobs;
  error;
  columns;

  sortFieldName;
  sortDirection;
  buyerPicklistValue = "All";

  totalRecsLabel;

  @wire(MessageContext)
  messageContext;

  connectedCallback() {
    if (this.pagination) {
      this.getTotalRecords();
    }
    /*if (FORM_FACTOR === 'Small') {
            //Hide tables
        }*/

    if (this.tableName && this.tableName.includes("GTS Track Jobs")) {
      this.isGtsTrackJobTable = true;
      this.page_size = 25;
    } else {
      this.isGtsTrackJobTable = false;
      this.page_size = 5;
    }

    this.loadJobs();

    this.handleResetSort();
  }

  loadJobs() {
    var jobWrapper = {
      tableName: this.tableName,
      isReport: this.isReportToBeShown,
      recordLimit: this.numberOfRecords,
      daysToSearch: this.daysToSearch,
      startDate: this.startDate,
      endDate: this.endDate,
      vOffset: this.v_Offset,
      vPagesize: this.page_size,
      pagination: this.pagination,
      recordTypeId: this.recordTypeId
    };

    getTableData({ request: jobWrapper })
      .then((result) => {
        this.availableJobs = result.lstJobRecords;
        this.processData(this.availableJobs);
        this.columns = result.lstDataTableColumns;
        this.processColumns(this.columns);

        this.initialApexJobs = this.availableJobs;

        this.applyTabFilter();
      })
      .catch((error) => {
        console.log("generate data error ****");
        console.log("result error: " + error);
        console.log(error);
        this.error = error;
      });
  }

  //todo make this work for paginattion
  getTotalRecords() {
    var jobWrapper = {
      tableName: this.tableName,
      isReport: this.isReportToBeShown,
      recordLimit: this.numberOfRecords,
      daysToSearch: this.daysToSearch,
      pagination: this.pagination
    };

    TotalRecords({ request: jobWrapper })
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
        console.log("totalRecords error: " + error);

        console.log("error in totalrecords **** ", JSON.stringify(error));
      });
  }

  processData(result) {
    if (result) {
      let tempRecs = [];

      result.forEach((record) => {
        let tempRec = Object.assign({}, record);

        if (this.tableName.includes("GTS")) {
          tempRec.LinkLabel = tempRec.GTS_RFI_Number__c.substring(
            tempRec.GTS_RFI_Number__c.indexOf(">", 5) + 1,
            tempRec.GTS_RFI_Number__c.indexOf("<", 5)
          );
          tempRec.LinkUrl = tempRec.GTS_RFI_Number__c.substring(
            tempRec.GTS_RFI_Number__c.indexOf("href") + 6,
            tempRec.GTS_RFI_Number__c.indexOf("target") - 2
          );
        } else {
          tempRec.LinkLabel = tempRec.iCare_Job_Hyperlink__c.substring(
            tempRec.iCare_Job_Hyperlink__c.indexOf(">", 5) + 1,
            tempRec.iCare_Job_Hyperlink__c.indexOf("<", 5)
          );
          tempRec.LinkUrl = tempRec.iCare_Job_Hyperlink__c.substring(
            tempRec.iCare_Job_Hyperlink__c.indexOf("href") + 6,
            tempRec.iCare_Job_Hyperlink__c.indexOf("target") - 2
          );
        }
        if (tempRec.Job_Timestamps__r) {
          tempRec.iCare_Job_Timestamp__c =
            tempRec.Job_Timestamps__r[0].iCare_Job_Timestamp__c;
        }
        if (tempRec.iCare_Testing_Location__c) {
          tempRec.LabName = tempRec.iCare_Testing_Location__r.Name;
        }

        tempRecs.push(tempRec);
      });

      this.availableJobs = tempRecs;
      this.error = undefined;
    }
  }

  processColumns(result) {
    if (result) {
      let tempRecs = [];

      result.forEach((record) => {
        let tempRec = Object.assign({}, record);
        tempRecs.push(tempRec);
      });
      if (this.isReportToBeShown) {
        tempRecs.push(this.downloadColumn);
      }

      this.columns = tempRecs;
      this.error = undefined;
    }
  }

  updateColumnSorting(event) {
    this.sortFieldName = event.detail.fieldName;
    this.sortDirection = event.detail.sortDirection;
    this.sortData(this.sortFieldName, this.sortDirection);
  }

  sortData(fieldname, direction) {
    let parseData = JSON.parse(JSON.stringify(this.availableJobs));
    // Return the value stored in the field
    let keyValue = (a) => {
      return a[fieldname];
    };
    // cheking reverse direction
    let isReverse = direction === "asc" ? 1 : -1;
    // sorting data
    parseData.sort((x, y) => {
      x = keyValue(x) ? keyValue(x) : ""; // handling null values
      y = keyValue(y) ? keyValue(y) : "";
      // sorting values based on direction
      return isReverse * ((x > y) - (y > x));
    });
    this.availableJobs = parseData;
  }

  handleResetSort() {
    //Reset sorting values
    this.sortFieldName = DATE_TIME_FIELD.fieldApiName;
    this.sortDirection = "desc";
  }

  handleRowAction(event) {
    const actionName = event.detail.action.name;
    const row = event.detail.row;

    this.handleClick(row.Id);
  }

  handleClick(jobId) {
    getJobTestReport({ jobId: jobId })
      .then((result) => {
        window.open(result);
      })
      .catch((error) => {
        let errorData = JSON.parse(error.body.message);
        this.showToast(errorData.name, errorData.message, "error");
      });
  }

  showToast(title, message, variant) {
    const event = new ShowToastEvent({
      title: title,
      message: message,
      variant: variant
    });
    this.dispatchEvent(event);
  }

  handleListViewNavigation() {
    if (this.tableName && this.tableName.includes("GTS")) {
      window.open(
        "/iCareGTS/s/view-all-page?ir=" +
          this.isReportToBeShown +
          "&tb=" +
          this.tableName,
        "_top"
      );
    } else {
      window.open(
        "/iCare/s/view-all-page?ir=" +
          this.isReportToBeShown +
          "&tb=" +
          this.tableName,
        "_top"
      );
    }
  }

  previousHandler() {
    getPrevious({ v_Offset: this.v_Offset, v_pagesize: this.page_size })
      .then((result) => {
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
        this.loadJobs();
      })
      .catch((error) => {
        console.log("error in previousHandler: ", error);
      });
  }

  nextHandler() {
    getNext({ v_Offset: this.v_Offset, v_pagesize: this.page_size })
      .then((result) => {
        this.v_Offset = result;
        let addtion = this.v_Offset * 1 + this.page_size * 1;

        if (addtion > this.v_TotalRecords) {
          this.template
            .querySelector("c-i-care-paginator")
            .changeView("truenext");
          this.template
            .querySelector("c-i-care-paginator")
            .changeView("trueLastPage");
        } else if (addtion < this.v_TotalRecords) {
          //this.template.querySelector('c-i-care-paginator').changeView('falseprevious');
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
        this.loadJobs();
      })
      .catch((error) => {
        console.log("error in nextHandler2**" + JSON.stringify(error));
      });
  }

  changeHandler(event) {
    this.v_Offset = 0;
    let det = event.detail;
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
    this.loadJobs();
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
    this.loadJobs();
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
    this.loadJobs();
  }

  showError() {
    const error = {
      title: "Error",
      message: this.error,
      variant: "error"
    };
    const event = new ShowToastEvent(error);
    this.dispatchEvent(event);
  }

  loadBuyerOptions() {
    this.buyerOptions = [{ label: ALL_BUYERS_LABEL, value: "All" }];
    let uniqueBuyers = [];
    this.availableJobs.forEach((job) => {
      if (!uniqueBuyers.includes(job.iCare_Buyer_Program_formula__c)) {
        this.buyerOptions.push({
          label: job.iCare_Buyer_Program_formula__c,
          value: job.iCare_Buyer_Program_formula__c
        });
        uniqueBuyers.push(job.iCare_Buyer_Program_formula__c);
      }
    });
    //this.sendBuyerMessage();
  }

  @api handleBuyerChange(buyer) {
    this.buyerPicklistValue = buyer;
    this.applyBuyerFilter();
  }

  applyBuyerFilter() {
    let searchRecords = [];
    if (this.buyerPicklistValue !== "All" && this.buyerPicklistValue != null) {
      for (let record of this.initialApexJobs) {
        if (record.iCare_Buyer_Program_formula__c === this.buyerPicklistValue) {
          searchRecords.push(record);
        }
      }
      this.availableJobs = searchRecords;
    } else {
      this.availableJobs = this.initialApexJobs;
    }
    //this.applyTabFilter();
    this.searchBoxRecords = this.availableJobs;
    this.calculateTotalRecords();
    this.sendMessage();
  }

  @api handleTabChanges(x) {
    this.statusFilter = x;
    this.applyTabFilter();
    //this.sendMessage();
  }

  @api handleGtsTabChanges(gtsTableName, recordTypeId) {
    this.tableName = gtsTableName;
    this.recordTypeId = recordTypeId;

    console.log("gtsTableName : ", gtsTableName);

    this.loadJobs();
    this.handleResetSort();
  }

  @api handleStatusChanges(status) {
    this.statusFilter = status;
    console.log("handleStatusChanges invoked : ", this.statusFilter);
    this.applyTabFilter();
  }

  @api handleShipmentCheckboxChange(checkedValue) {
    if (checkedValue) {
      let jobIds = [];
      let lstJobRecords = [];

      for (let rec of this.initialApexJobs) {
        jobIds.push(rec.Id);
      }

      checkRelatedCertificates({ jobIds: jobIds })
        .then((result) => {
          let lstJobIds = result;
          if (lstJobIds.length > 0) {
            for (let record of this.availableJobs) {
              if (lstJobIds.includes(record.Id)) {
                lstJobRecords.push(record);
              }
            }
            this.availableJobs = lstJobRecords;
          } else {
            this.availableJobs = lstJobRecords;
          }
          this.calculateTotalRecords();
          this.sendMessage();
        })
        .catch((error) => {
          console.log(error);
        });
    } else {
      this.applyTabFilter();
    }
  }

  /**
        Method to apply the Tab (Status) filter
    */

  applyTabFilter() {
    this.availableJobs = this.initialApexJobs; //Reset to initial list of Jobs

    let searchRecords = [];
    if (this.tableName === "Track Jobs") {
      if (this.statusFilter !== "All" && this.statusFilter != null) {
        for (let record of this.initialApexJobs) {
          if (this.statusFilter === "Pending") {
            if (record.iCare_Job_Pending__c) {
              searchRecords.push(record);
            }
          } else {
            if (record.iCare_Job_Status_Portal__c === this.statusFilter) {
              searchRecords.push(record);
            }
          }
        }
        this.availableJobs = searchRecords;
      }
    } else if (this.tableName.includes("GTS Track Jobs")) {
      if (this.statusFilter !== "All" && this.statusFilter != null) {
        for (let record of this.initialApexJobs) {
          if (this.statusFilter === "Pending") {
            if (record.iCare_Job_Pending__c) {
              searchRecords.push(record);
            }
          } else {
            if (record.iCare_Job_Status__c === this.statusFilter) {
              searchRecords.push(record);
            }
          }
        }
        this.availableJobs = searchRecords;
      }
    } else {
      if (this.statusFilter !== "All" && this.statusFilter != null) {
        for (let record of this.initialApexJobs) {
          if (record.iCare_Job_Outcome__c === this.statusFilter) {
            searchRecords.push(record);
          }
        }
        this.availableJobs = searchRecords;
      }
    }

    this.loadBuyerOptions();

    this.searchBoxRecords = this.availableJobs;

    this.calculateTotalRecords();
    this.sendMessage();
  }

  /**
        Method to apply the Search keyword filter
    */
  @api handleSearchBoxChange(searchKey) {
    //Search keyword,  apply search keyword filter
    this.availableJobs = this.searchBoxRecords;

    if (searchKey) {
      if (this.availableJobs) {
        let searchRecords = [];
        for (let record of this.availableJobs) {
          let valuesArray = Object.values(record);
          for (let val of valuesArray) {
            let strVal = String(val);
            if (strVal) {
              if (strVal.toLowerCase().includes(searchKey.toLowerCase())) {
                searchRecords.push(record);
                break;
              }
            }
          }
        }
        this.availableJobs = searchRecords;
      }
    }
    this.calculateTotalRecords();
    this.sendMessage();
  }

  /**
        Method to apply dates filter
    */
  @api handleDateChange(startDate, endDate, daysToSearch) {
    this.startDate = startDate;
    this.endDate = endDate;
    this.daysToSearch = daysToSearch;
    this.loadJobs();
  }

  calculateTotalRecords() {
    if (this.availableJobs) {
      this.totalRecsLabel =
        TOTAL_NUMBER_LABEL + " " + this.availableJobs.length;
    } else {
      this.totalRecsLabel = TOTAL_NUMBER_LABEL + " 0";
    }
  }

  /**
        Sync Chart component with reports data - via message
    */
  sendMessage() {
    if (this.tableName.includes("Track Jobs")) {
      const payload = {
        buyerFilterValues: JSON.stringify(this.buyerOptions),
        availableJobs: JSON.stringify(this.availableJobs),
        statusFilter: JSON.stringify(this.statusFilter)
      };
      try {
        publish(this.messageContext, iCarePortalTableMC, payload);
      } catch (error) {
        console.log("Error sending message: " + error);
      }
    } else if (this.tableName === "View Reports") {
      const payload = {
        buyerFilterValues: JSON.stringify(this.buyerOptions),
        availableJobs: JSON.stringify(this.availableJobs),
        statusFilter: JSON.stringify(this.statusFilter)
      };
      try {
        publish(this.messageContext, iCarePortalTableMC, payload);
      } catch (error) {
        console.log("Error sending report message: " + error);
      }
    }
  }
}