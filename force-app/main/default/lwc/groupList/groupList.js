import { LightningElement, track, api, wire } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getTableData from "@salesforce/apex/GroupListController.getTableData";
import getAccountOptions from "@salesforce/apex/GroupListController.getAccountOptions";
import checkForDupeGroup from "@salesforce/apex/GroupListController.checkForDupeGroup";
import insertGroup from "@salesforce/apex/GroupListController.insertGroup";
import deleteGroups from "@salesforce/apex/GroupListController.deleteGroups";
import csvExport from "@salesforce/apex/GroupListController.exportAsCSV";
import restoreGroups from "@salesforce/apex/GroupListController.restoreGroups";

import { label } from "c/labelService";
export default class GroupList extends LightningElement {
  /*** Vars common to all list pages ***/
  labels = label;
  @api scrollAfterXPixels;
  @track tableData = { columns: [], rows: [] };
  @track rowLimit = 6;
  @track selectedRowIds = [];
  @track orderBy = "CreatedDate DESC";
  @track isLoading = true;
  @track isWorking = false;
  @track loadMoreMessage;
  @track allShown;
  // The list of actions is a list of objects, each with a label attribute
  // The list of actions might be different if one table row is selected vs. many table rows selected
  // @track actions = [
  //   {
  //     label: "Delete"
  //   }
  // ];
  @track newGroup = {};
  @track filterTimeout;
  @track groupNameTimeout;
  @track groupAccountTimeout;
  @track error;
  @track selectedRowCount = 0;

  /*** Vars specific to this implementation of objectHome ***/
  @track filterGroupName = "";
  @track addGroupName;
  @track addGroupAccount;
  @track filterStatus = "";

  @track showAddGroupModal = false;
  @track showDeleteModal = false;
  @track showRestoreModal = false;
  @track validGroupName = true;

  @track defaultAccountWhenOnlyOne;
  @track accountOptions = {};

  @api showExportButton;

  get conditionalExport() {
    return this.showExportButton ? this.labels.EXPORT : null;
  }

  get actions() {
    if (this.filterStatus === "Inactive") {
      return [{ label: "Restore" }];
    }
    return [{ label: "Deactivate" }];
  }

  filterStatusOptions = [
    {
      value: "Active",
      label: this.labels.ACTIVE
    },
    {
      value: "Inactive",
      label: this.labels.INACTIVE
    }
  ];

  connectedCallback() {
    this.getData();
  }

  // Use @wire to get group data and store in tableData variable
  // should contain columns and rows lists
  getData() {
    let filterStatus = this.filterStatus;
    if (this.filterStatus == "" || this.filterStatus == "Active") {
      filterStatus = "False";
    } else if (this.filterStatus == "Inactive") {
      filterStatus = "True";
    }

    this.tableData = { columns: [], rows: [] };
    getTableData({
      rowLimit: this.rowLimit,
      orderBy: this.orderBy,
      selectedRowIds: this.selectedRowIds,
      filterGroupName: this.filterGroupName,
      filterStatus: filterStatus
    })
      .then((response) => {
        if (response.table) {
          this.tableData = response.table;
          this.allShown =
            response.table.rows.length &&
            response.table.rows.length == response.totalRows;
          this.loadMoreMessage =
            "Showing " +
            response.table.rows.length +
            " of " +
            response.totalRows +
            " results";
          this.error = undefined;
          this.isLoading = false;
        } else if (response && response.error) {
          this.error = response.error;
          this.tableData = { columns: [], rows: [] };
          this.isLoading = false;
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

  @wire(getAccountOptions)
  wiredAccountOptions(response) {
    if (response && response.data) {
      this.accountOptions = response.data;
      if (this.accountOptions.length == 1) {
        this.newGroup.Account__c = this.accountOptions[0].value;
        this.defaultAccountWhenOnlyOne = this.accountOptions[0].value;
        this.addGroupAccount = this.accountOptions[0].value;
      }
    }
  }

  handleFilterChange(evt) {
    if (evt.detail.value == "Active" || evt.detail.value == "Inactive") {
      this.filterStatus = evt.detail.value;
    }

    // After a short delay, update the group name filter
    window.clearTimeout(this.filterTimeout);
    this.filterTimeout = setTimeout(
      function () {
        // make sure the filter input's fieldId attribute exactly matches the filter variable name up above ^^^
        this[evt.detail.fieldId] = evt.detail.value;
        this.isLoading = true;
        this.getData();
      }.bind(this),
      500
    );
  }

  handleViewMore() {
    this.rowLimit = this.rowLimit + 6;
    this.isLoading = true;
    this.getData();
  }

  handleOrderBy(evt) {
    // make sure we pass in orderBy AND tableData.columns. orderBy will contain the newly requested sort and tableData.tableCols will contain any previous sorts, allowing us to overlay the two
    this.orderBy = evt.detail;
    this.isLoading = true;
    this.getData();
  }

  handleActionClick(evt) {
    // depending on the action, launch the appropriate modal
    switch (evt.detail.label) {
      case "Deactivate":
        this.showDeleteModal = true;
        break;
      case "Restore":
        this.showRestoreModal = true;
    }
  }

  handleSelectedRowsChange(evt) {
    this.selectedRowIds = evt.detail.selectedRowIds;
    this.selectedRowCount = this.selectedRowIds.length;
  }

  handleAddGroupInputChange(evt) {
    // update newGroup, plus also check for duplicate group names, live as the user types (after a short pause)
    let newGroup = JSON.parse(JSON.stringify(this.newGroup));
    newGroup[evt.detail.fieldId] = evt.detail.value;
    this.newGroup = newGroup;
    console.log(newGroup);
    if (evt.detail.fieldId == "Group_Name__c") {
      this.isWorking = true;
      window.clearTimeout(this.groupNameTimeout);
      this.groupNameTimeout = setTimeout(
        function () {
          this.addGroupName = evt.detail.value;
          console("in groupname timeout");
        }.bind(this),
        500
      );
    }
    if (evt.detail.fieldId == "Account__c") {
      this.isWorking = true;
      window.clearTimeout(this.groupAccountTimeout);
      this.groupAccountTimeout = setTimeout(
        function () {
          this.addGroupAccount = evt.detail.value;
        }.bind(this),
        500
      );
    }
  }

  @wire(checkForDupeGroup, {
    groupName: "$addGroupName",
    accountId: "$addGroupAccount"
  })
  wiredDupeData({ error, data }) {
    if (data) {
      if (data == "true") {
        this.template
          .querySelector("c-input[data-id='GroupName']")
          .toggleCustomError(true);
        this.validGroupName = false;
      } else {
        this.template
          .querySelector("c-input[data-id='GroupName']")
          .toggleCustomError(false);
        this.validGroupName = true;
      }
    } else if (error) {
      this.error = error;
    }
    this.isWorking = false;
  }

  async handleConfirmAddGroup() {
    this.isWorking = true;
    if (!this.validateAddGroupInputs() || !this.validGroupName) {
      // Do nothing, let inputs display their own inline error messages
    } else {
      // send the data off to Apex which tries to create a new Contact Group
      // if a duplicate group name is found, display error toast
      let response = await insertGroup({ newGroup: this.newGroup });
      this.getData();

      if (response.status == "OK") {
        this.dispatchEvent(
          new ShowToastEvent({
            title: "Group added",
            message: "Successfully added a new group",
            variant: "Success"
          })
        );
        this.handleCancelModal();
      } else {
        this.dispatchEvent(
          new ShowToastEvent({
            title: "Error",
            message: response.messages[0],
            variant: "Error"
          })
        );
      }
    }
    this.isWorking = false;
  }

  validateAddGroupInputs() {
    let isValid = true;
    this.template.querySelectorAll("c-modal c-input").forEach((input) => {
      if (!input.validate().isValid) {
        isValid = false;
      }
    });
    // Workaround: make sure we re-set the error state where group name is a duplicate
    if (!this.validGroupName) {
      this.template
        .querySelector("c-input[data-id='GroupName']")
        .toggleCustomError(true);
    }
    return isValid;
  }

  handleBtnClick(evt) {
    switch (evt.detail.label) {
      case "ADD GROUP":
        // launch add group modal
        this.showAddGroupModal = true;
        break;
      case this.labels.EXPORT:
        this.handleExport();
        break;
    }
  }

  async handleExport() {
    let whatExport = "Groups";
    this.dispatchEvent(
      new ShowToastEvent({
        title: "Downloading " + whatExport + "...",
        message: "",
        variant: "info"
      })
    );

    let response = await csvExport();

    var hiddenElement = document.createElement("a");
    hiddenElement.href =
      "data:text/csv;charset=utf-8," + encodeURIComponent(response);
    hiddenElement.target = "_blank";
    let time = new Date().getTime();
    hiddenElement.download = whatExport + "_" + time + ".csv";
    hiddenElement.click();
  }

  async handleConfirmDeactivate() {
    // Deactivate the selected groups and update this.tableData
    this.isWorking = true;
    // send the data off to Apex which tries to create a new Contact Group
    // if a duplicate group name is found, display error toast
    let response = await deleteGroups({ selectedRowIds: this.selectedRowIds });

    if (response.status == "OK") {
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Groups Deactivated",
          message: "Successfully deactivated the selected group(s)",
          variant: "Success"
        })
      );
      this.getData();
      this.handleCancelModal();
    } else if (response.status == "Already Inactive") {
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Already Inactive",
          message: response.messages[0],
          variant: "warning"
        })
      );
    } else {
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Error",
          message: response.messages[0],
          variant: "Error"
        })
      );
    }
    this.isWorking = false;
    this.handleCancelModal();
  }

  async handleConfirmRestore() {
    this.isWorking = true;
    let response = await restoreGroups({ selectedRowIds: this.selectedRowIds });

    if (response.status == "OK") {
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Groups Restored",
          message: "Successfully restored the selected group(s)",
          variant: "Success"
        })
      );
      this.getData();
    } else {
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Error",
          message: response.messages[0],
          variant: "Error"
        })
      );
    }
    this.isWorking = false;
    this.handleCancelModal();
  }

  handleCancelModal() {
    this.showDeleteModal =
      this.showAddGroupModal =
      this.showRestoreModal =
        false;
  }
}