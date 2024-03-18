import { LightningElement, track, api, wire } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { CurrentPageReference } from "lightning/navigation";
import getTableData from "@salesforce/apex/UserListController.getTableData";
import enableDisableUser from "@salesforce/apex/ManageUserController.enableDisableUser";
import resetUsersPassword from "@salesforce/apex/ManageUserController.resetUsersPassword";
import csvExport from "@salesforce/apex/UserListController.exportAsCSV";

import { label } from "c/labelService";
export default class UserList extends LightningElement {
  /*** Vars common to all list pages ***/
  labels = label;
  @api scrollAfterXPixels;
  @track tableData = { columns: [], rows: [] };
  @track selectedRowCount = 0;
  @track rowLimit = 6;
  @track selectedRowIds = [];
  @track orderBy = "LastLoginDate DESC";
  @track isLoading = true;
  @track isWorking = false;
  @track loadMoreMessage;
  @track allShown;

  @api showExportButton;
  get conditionalExport() {
    return this.showExportButton ? this.labels.EXPORT : null;
  }

  // The list of actions is a list of objects, each with a label attribute
  // The list of actions might be different if one table row is selected vs. many table rows selected
  actions = [
    {
      label: this.labels.ENABLE
    },
    {
      label: this.labels.DISABLE
    },
    {
      label: this.labels.USER_GROUP_MGMT_ACTION_ADD_TO_GROUP
    },
    {
      label: this.labels.USER_GROUP_MGMT_ACTION_REMOVE_FROM_GROUP
    },
    {
      label: this.labels.USER_MGMT_RESET_PASSWORD
    }
  ];
  filterTimeout;
  error;

  /*** Vars specific to userList ***/
  @track filterStatus = "";
  @track filterSearch = "";
  @track filterDateFrom = "";
  @track filterDateTo = "";
  @track filterUnassignedOnly = false;
  @track showEnableUserModal = false;
  @track showResetPwdModal = false;
  @track showDisableUserModal = false;
  @track showManageModal = false;
  @track manageMode = "assign";
  @track showAddUserModal = false;

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

  // Use @wire to get data and store in tableData variable
  // below is just temporary stubbed data
  //we shoudl remove if not used

  navMixinPageRef = {
    type: "standard__namedPage",
    attributes: {
      pageName: "home"
    }
  };

  connectedCallback() {
    this.getData();
  }

  @wire(CurrentPageReference)
  getStateParameters(currentPageReference) {
    if (currentPageReference) {
      if (currentPageReference.state.unassigned) {
        this.filterUnassignedOnly = true;
      }
    }
  }

  // Use an imperative method to get report data and store in tableData variable
  // We cannot use @wire because we can't stop it watching selectedRowIds, which causes us problems
  getData() {
    if(this.filterStatus == ""){
      this.filterStatus = "Active";
    }
    
    this.tableData = { columns: [], rows: [] };
    getTableData({
      rowLimit: this.rowLimit,
      orderBy: this.orderBy,
      selectedRowIds: this.selectedRowIds,
      filterStatus: this.filterStatus,
      filterSearch: this.filterSearch,
      filterDateFrom: this.filterDateFrom,
      filterDateTo: this.filterDateTo,
      filterUnassignedOnly: this.filterUnassignedOnly
    })
      .then((response) => {
        if (response.table) {
          this.tableData = response.table;
          this.allShown = response.table.rows.length == response.totalRows;
          this.loadMoreMessage =
            this.labels.DATA_TABLE_RESULTS_COUNT_INFO_PREFIX +
            " " +
            response.table.rows.length +
            " " +
            this.labels.OF +
            " " +
            response.totalRows +
            " " +
            this.labels.DATA_TABLE_RESULTS_COUNT_INFO_SUFFIX;
          this.error = undefined;
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

  handleViewMore() {
    this.rowLimit = this.rowLimit + 6;
    this.isLoading = true;
    this.getData();
  }

  handleOrderBy(evt) {
    // make sure we pass in orderBy AND tableData.data.tableCols. orderBy will contain the newly requested sort and tableData.data.tableCols will contain any previous sorts, allowing us to overlay the two
    this.orderBy = evt.detail;
    this.isLoading = true;
    this.getData();
  }

  handleBtnClick(evt) {
    switch (evt.detail.label) {
      case this.labels.USER_LIST_ADD_USER_BUTTON:
        // launch add user modal
        this.showAddUserModal = true;
        break;
      case this.labels.EXPORT:
        this.handleExport();
        break;
    }
  }

  async handleExport() {
    let whatExport = "Users";
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

  handleActionClick(evt) {
    // depending on the action, launch the appropriate modal
    switch (evt.detail.label) {
      case this.labels.ENABLE:
        this.showEnableUserModal = true;
        break;
      case this.labels.DISABLE:
        this.showDisableUserModal = true;
        break;
      case this.labels.USER_GROUP_MGMT_ACTION_ADD_TO_GROUP:
        this.manageMode = "assign";
        this.showManageModal = true;
        break;
      case this.labels.USER_GROUP_MGMT_ACTION_REMOVE_FROM_GROUP:
        this.manageMode = "retract";
        this.showManageModal = true;
        break;
      case this.labels.USER_MGMT_RESET_PASSWORD:
        this.showResetPwdModal = true;
        break;
    }
  }

  handleFilterChange(evt) {
    if(evt.detail.value == 'Active' || evt.detail.value == 'Inactive'){
      this.filterStatus = evt.detail.value;
    }
    // After a short delay, update the user name filter
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

  handleSelectedRowsChange(evt) {
    this.selectedRowIds = evt.detail.selectedRowIds;
    this.selectedRowCount = this.selectedRowIds.length;
  }

  handleUserCreationEvent(evt) {
    if (evt.detail.variant === "Success") {
      this.handleCancelModal();
    }
    const toast = new ShowToastEvent({
      title: evt.detail.title,
      message: evt.detail.message,
      variant: evt.detail.variant
    });
    this.dispatchEvent(toast);
    this.toggleIsWorking();
  }

  handleCancelModal() {
    this.showEnableUserModal =
      this.showDisableUserModal =
      this.showAddToGroupModal =
      this.showRemoveFromGroupModal =
      this.showAddUserModal =
      this.showManageModal =
      this.showResetPwdModal =
        false;
    this.getData(); //refresh datatable after action from modal
  }

  handleConfirmAddUser() {
    // create the selected users and refresh this.tableData
    let form = this.template.querySelector("c-user-detail-record");
    if (form) {
      form.handleSubmit();
    }
  }

  async handleConfirmEnable() {
    // enable the selected users and refresh this.tableData
    // disable the selected users and refresh this.tableData
    this.isLoading = true;
    // Call apex to either assign, or retract users to/from groups
    let response;

    response = await enableDisableUser({
      selectedUserIds: this.selectedRowIds,
      activateYN: true
    });
    // Display toast
    if (response.status == "OK") {
      this.dispatchEvent(
        new ShowToastEvent({
          title: this.labels.SUCCESS,
          message: this.labels.USER_ENABLED,
          variant: "success"
        })
      );
    } else {
      this.dispatchEvent(
        new ShowToastEvent({
          title: this.labels.ERROR,
          message: response.messages[0],
          variant: "error",
          mode: "sticky"
        })
      );
    }
    this.isLoading = false;
    // We need to freshen up the data in the table so that when we next open it, the correct data is shown.
    this.tableData = { columns: [], rows: [] };
    // Tell parent to hide me
    this.dispatchEvent(new CustomEvent("close"));

    this.getData();
    this.handleCancelModal();
  }

  async handleConfirmDisable() {
    // disable the selected users and refresh this.tableData
    this.isLoading = true;
    // Call apex to either assign, or retract users to/from groups
    let response;

    response = await enableDisableUser({
      selectedUserIds: this.selectedRowIds,
      activateYN: false
    });
    // Display toast
    if (response.status == "OK") {
      this.dispatchEvent(
        new ShowToastEvent({
          title: this.labels.SUCCESS,
          message: this.labels.USER_DISABLED,
          variant: this.labels.SUCCESS
        })
      );
    } else {
      this.dispatchEvent(
        new ShowToastEvent({
          title: this.labels.ERROR,
          message: response.messages[0],
          variant: this.labels.ERROR,
          mode: "sticky"
        })
      );
    }
    this.isLoading = false;
    // We need to freshen up the data in the table so that when we next open it, the correct data is shown.
    this.tableData = { columns: [], rows: [] };
    // Tell parent to hide me
    this.dispatchEvent(new CustomEvent("close"));

    this.getData();
    this.handleCancelModal();
  }

  async handleConfirmResetPassword() {
    // reset password for the selected users
    this.isLoading = true;
    // Call apex to either assign, or retract users to/from groups
    let response;

    response = await resetUsersPassword({
      selectedUserIds: this.selectedRowIds
    });
    // Display toast
    if (response.status == "OK") {
      this.dispatchEvent(
        new ShowToastEvent({
          title: this.labels.SUCCESS,
          message: this.labels.PASSWORD_RESET,
          variant: this.labels.SUCCESS
        })
      );
    } else {
      this.dispatchEvent(
        new ShowToastEvent({
          title: this.labels.ERROR,
          message: response.messages[0],
          variant: this.labels.ERROR,
          mode: "sticky"
        })
      );
    }
    this.isLoading = false;
    // Tell parent to hide me
    this.dispatchEvent(new CustomEvent("close"));

    this.handleCancelModal();
  }

  handleConfirmAddToGroup() {
    // add the selected users to the selected groups and refresh this.tableData
    this.getData();
    this.handleCancelModal();
  }

  handleConfirmRemoveFromGroup() {
    // remove the selected users from the selected groups and refresh this.tableData
    this.getData();
    this.handleCancelModal();
  }

  toggleIsWorking() {
    this.isWorking = !this.isWorking;
  }
}