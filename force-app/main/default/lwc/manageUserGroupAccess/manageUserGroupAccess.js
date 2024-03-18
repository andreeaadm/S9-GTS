import { LightningElement, track, api, wire } from "lwc";
import getTableData from "@salesforce/apex/ManageUserController.getTableData";
import addOrRemoveUsersFromGroups from "@salesforce/apex/ManageUserController.addOrRemoveUsersFromGroups";
import getUserDetails from "@salesforce/apex/ManageUserController.getUserDetails";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { label } from "c/labelService";

export default class ManageUserGroupAccess extends LightningElement {
  @track labels = label;
  @api mode = "assign"; // assign || retract
  @api selectedRowIds = [];
  @track tableData = { columns: [], rows: [] };
  @track loadMoreMessage = "";
  @track allShown = true;
  @track isLoading = true;
  @track rowLimit = 6;
  @track orderBy = "Group_Name__c DESC";
  @track selectedGroupIds = [];
  @track userDetailId;
  @track filterSearch = "";
  @track username;
  filterTimeout;

  get title() {
    return this.mode == "assign"
      ? this.labels.USER_GROUP_MGMT_TITLE_ADD_USERS
      : this.labels.USER_GROUP_MGMT_TITLE_REMOVE_USERS;
  }

  get action() {
    return this.mode == "assign" ? this.labels.ADD : this.labels.REMOVE;
  }

  get suffix() {
    return this.mode == "assign" ? this.labels.TO : this.labels.FROM;
  }

  get confirmButtonLabel() {
    return this.mode == "assign" ? this.labels.ADD + " +" : this.labels.REMOVE;
  }

  get selectedRowCount() {
    return this.selectedRowIds ? this.selectedRowIds.length : 0;
  }

  connectedCallback() {
    if (this.selectedRowIds && this.selectedRowIds.length == 1) {
      this.userDetailId = this.selectedRowIds[0];
      this.getUserData();
    } else {
      this.userDetailId = undefined;
    }

    this.getData();
  }

  getData() {
    this.tableData = { columns: [], rows: [] };
    getTableData({
      rowLimit: this.rowLimit,
      filterSearch: this.filterSearch,
      orderBy: this.orderBy,
      selectedRowIds: this.selectedRowIds,
      mode: this.mode
    })
      .then((response) => {
        if (response.table) {
          this.tableData = response.table;
          this.allShown =
            response.table.rows &&
            response.table.rows.length &&
            response.table.rows.length == response.totalRows;
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
          let tempSelectedGroupIds = [];
          for (let row of response.table.rows) {
            if (row.rowCells[0].value == "true") {
              tempSelectedGroupIds.push(row.rowId);
            }
          }
          this.selectedGroupIds = tempSelectedGroupIds;
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

  getUserData() {
    // Retrieving username via WireService requires User Managerment Settings changes.
    // Moved to Apex to retain preferred UM-Settings.
    getUserDetails({ userId: this.userDetailId })
      .then((response) => {
        this.username = response.Username;
      })
      .catch((error) => {
        console.log("error", error);
      });
  }

  handleFilterChange(evt) {
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
    // update this.rowLimit, which should be watched by the @wire service and cause the table data to refresh
    this.rowLimit = this.rowLimit + 6;
    this.isLoading = true;
    this.getData();
  }

  handleCheckboxChange(evt) {
    let tempSelectedGroupIds = JSON.parse(
      JSON.stringify(this.selectedGroupIds)
    );
    if (evt.detail.checked) {
      tempSelectedGroupIds.push(evt.detail.rowId);
      this.selectedGroupIds = tempSelectedGroupIds;
    } else {
      tempSelectedGroupIds = tempSelectedGroupIds.filter(function (
        value,
        index,
        arr
      ) {
        return value !== evt.detail.rowId;
      });
      this.selectedGroupIds = tempSelectedGroupIds;
    }
  }

  handleCancel() {
    this.dispatchEvent(new CustomEvent("close"));
  }

  async handleConfirm() {
    this.isLoading = true;
    // Call apex to either assign, or retract users to/from groups
    let response;
    let isAddAction = this.mode === "assign" ? true : false;

    response = await addOrRemoveUsersFromGroups({
      selectedUserIds: this.selectedRowIds,
      selectedGroupIds: this.selectedGroupIds,
      applyAddAction: isAddAction
    });
    // Display toast
    if (response.status == "OK") {
      this.dispatchEvent(
        new ShowToastEvent({
          title: this.labels.SUCCESS,
          message: "",
          variant: this.labels.SUCCESS
        })
      );
    } else {
      this.dispatchEvent(
        new ShowToastEvent({
          title: this.labels.ERROR,
          message: response.messages[0],
          variant: this.labels.ERROR
        })
      );
    }
    this.isLoading = false;
    // We need to freshen up the data in the table so that when we next open it, the correct checkboxes are selected
    this.tableData = { columns: [], rows: [] };
    // Tell parent to hide me
    this.dispatchEvent(new CustomEvent("close"));
  }

  handleSortClick(evt) {
    // update orderBy and then getData
    this.orderBy =
      evt.detail.colId +
      " " +
      (evt.detail.currentSortOrder == "DESC" ? "ASC" : "DESC");
    this.getData();
  }
}