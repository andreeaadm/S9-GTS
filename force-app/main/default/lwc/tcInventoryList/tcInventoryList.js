import { LightningElement, wire } from "lwc";
import { CurrentPageReference, NavigationMixin } from "lightning/navigation";
import getInventories from "@salesforce/apex/InventoryListController.getInventoriesListTableData";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { label } from "c/labelService";
import createNewInventory from "@salesforce/apex/InventoryListController.createNewInventory";
import { getPicklistValues } from "lightning/uiObjectInfoApi";
import TYPE_FIELD from "@salesforce/schema/Inventory__c.Type__c";

export default class TcInventoryList extends NavigationMixin(LightningElement) {
  facilityId;
  isLoading = true;
  tableData = { columns: [], rows: [] };
  labels = label;
  showNewButton = false;

  showNewModal = false;
  selectedType;
  typePicklist;
  selectedDate;
  monthOptions = [];
  showCloneOptions = false;
  cloneOptions = [];
  showCloneCheckbox = false;
  cloneOptionText;
  cloneName = null;
  usageCloneName = null;
  noData;

  months = [
    this.labels.JANUARY,
    this.labels.FEBRUARY,
    this.labels.MARCH,
    this.labels.APRIL,
    this.labels.MAY,
    this.labels.JUNE,
    this.labels.JULY,
    this.labels.AUGUST,
    this.labels.SEPTEMBER,
    this.labels.OCTOBER,
    this.labels.NOVEMBER,
    this.labels.DECEMBER
  ];

  fetchPageReferencedFacilityData() {
    if (this.currentPageReference && this.currentPageReference.state) {
      this.facilityId = this.currentPageReference.state.facilityId;
      this.fetchTableData();
    }
  }

  connectedCallback() {
    this.connected = true;
    if (this.initialActionOnConnect) {
      this.fetchPageReferencedFacilityData();
      this.initialAction();
    }
  }

  currentPageReference;
  @wire(CurrentPageReference)
  setCurrentPageReference(currentPageReference) {
    this.currentPageReference = currentPageReference;
    if (this.connected) {
      this.fetchPageReferencedFacilityData();
      this.initialAction();
    } else {
      // NavigationMixin doesn't work before connectedCallback.
      this.initialActionOnConnect = true;
    }
  }

  @wire(getPicklistValues, {
    recordTypeId: "012000000000000AAA",
    fieldApiName: TYPE_FIELD
  })
  processPicklist(response) {
    if (response && response.data) {
      this.typePicklist = response.data.values;
    }
  }

  fetchTableData() {
    getInventories({ facilityId: this.facilityId })
      .then((response) => {
        this.tableData = response.table;
        this.noData = response.totalRows === 0 ? true : false;
        this.calculateShowNewButton();
        this.isLoading = false;
      })
      .catch((error) => {
        this.tableData = { columns: [], rows: [] };
        this.noData = true;
        this.isLoading = false;
      });
  }

  formatDate(input){
    if(input.toString().length === 1){
      return '0'+input;
    }
    return input;
  }

  calculateShowNewButton() {
    this.showNewButton = false;
    let showMonths = [];
    let invDateMap = new Map();
    this.tableData.rows.forEach(row => {
      invDateMap.set(row.rowCells[1].value, row);
    });

    let currentDate = new Date();
    let currentMonth = new Date();
    currentMonth.setDate(1);
    for (let i = 0; i < 3 ; i++){
      let current = new Date();
      current.setDate(1);
      let monthValue = current.getMonth() - i;
      current.setMonth(monthValue);
      if(!invDateMap.has(current.getFullYear()+'-'+this.formatDate(current.getMonth()+1)+'-'+this.formatDate(current.getDate()))){
        let EndDateMonth = new Date(current.getFullYear(), current.getMonth() + 1, 0);
        let invCreationDate = new Date(EndDateMonth);
        invCreationDate.setDate(EndDateMonth.getDate() + parseInt(this.labels.TC_INVENTORY_CREATION_DAYS));
        if (invCreationDate >= currentDate){
          showMonths.push(current);
        }
      }
    }    
    this.showNewButton = (showMonths.length > 0);

    if (this.showNewButton) {
      this.populateCloneOptions();
      this.populateMonthPicklist(showMonths);
    }
  }

  initialAction() {
    // Check if there's an action expected.
    if (this.currentPageReference?.state?.action === "new") {
      // And remove it ready for returning back to this page.
      this[NavigationMixin.Navigate](
        this.getUpdatedPageReference({ action: undefined }),
        true
      );
      this.handleNewClick();
    }
  }

  populateCloneOptions() {
    let maxPastDate = new Date();
    maxPastDate.setFullYear(maxPastDate.getFullYear() - 1);
    maxPastDate.setDate(1);
    this.cloneOptions = [{ label: this.labels.NONE, value: this.labels.NONE }];
    let maxCount =
      this.tableData.rows.length > 12 ? 12 : this.tableData.rows.length;

    for (let i = 0; i < maxCount; i++) {
      let currentRow = this.tableData.rows[i];
      if (currentRow && new Date(currentRow.rowCells[1].value) >= maxPastDate) {
        if (currentRow.rowCells[4].value === "Submitted") {
          this.cloneOptions = [
            ...this.cloneOptions,
            {
              label: currentRow.rowCells[0].value,
              value: currentRow.rowCells[0].value
            }
          ];
        }
      } else {
        break;
      }
    }
  }

  populateMonthPicklist(monthsToShow) {
    this.monthOptions = [];
    monthsToShow.forEach((month) => {
      this.monthOptions = [
        ...this.monthOptions,
        {
          label: this.months[month.getMonth()].concat(" ", month.getFullYear()),
          value: month.toString()
        }
      ];
    });
  }

  handleNewClick() {
    this.selectedDate = null;
    this.selectedType = null;
    this.showCloneOptions = false;
    this.showCloneCheckbox = false;
    this.showNewModal = true;
  }

  handleCancelClick() {
    this.showNewModal = false;
  }

  handleSaveClick() {
    if (this.validateInputs()) {
      this.showNewModal = false;
      this.showNewButton = false;
      createNewInventory({
        facilityId: this.facilityId,
        invType: this.selectedType,
        invDate: this.selectedDate,
        cloneName: this.cloneName
      })
        .then((result) => {
          if (result === "MissingLineItems") {
            this.dispatchEvent(
              new ShowToastEvent({
                title: this.labels.ERROR,
                message: this.labels.ERROR_MISSING_CHEMICAL_PRODUCTS,
                variant: "error"
              })
            );
          } else {
            this.dispatchEvent(
              new ShowToastEvent({
                title: this.labels.SUCCESS,
                message: this.labels.SUCCESS_NEW_INVENTORY,
                variant: "success"
              })
            );
          }
          this.fetchTableData();
        })
        .catch((error) => {
          this.dispatchEvent(
            new ShowToastEvent({
              title: this.labels.ERROR,
              message: this.labels.ERROR_GENERIC_NEW_INVENTORY,
              variant: "error"
            })
          );
          this.fetchTableData();
        });
    }
  }

  validateInputs() {
    let isValid = true;
    this.template.querySelectorAll("c-input").forEach((input) => {
      if (!input.validate().isValid) {
        isValid = false;
      }
    });
    return isValid;
  }

  handleInventoryMonthChange(event) {
    this.selectedDate = new Date(event.detail.value);
    this.showCloneCheckbox = false;
    this.showCloneOptions = false;
    this.cloneName = null;
    this.usageCloneName = null;

    this.calculateShowCloneFields();
  }

  calculateShowCloneFields() {
    if (
      typeof this.selectedType !== "undefined" &&
      this.selectedType &&
      typeof this.selectedDate !== "undefined" &&
      this.selectedDate
    ) {
      if (this.selectedType === "Delivery" && this.cloneOptions.length > 1) {
        this.showCloneOptions = true;
      } else if (this.selectedType === "Usage") {
        this.populateCloneCheckbox();
      }
    }
  }

  populateCloneCheckbox() {
    let lastMonth =
      this.selectedDate.getMonth() === 0
        ? 11
        : this.selectedDate.getMonth() - 1;

    for (let i = 0; i < 2; i++) {
      let rowDate = new Date(this.tableData.rows[i].rowCells[1].value);
      if (
        rowDate.getMonth() === lastMonth &&
        this.tableData.rows[i].rowCells[4].value === "Submitted"
      ) {
        this.usageCloneName = this.tableData.rows[i].rowCells[0].value;
        this.cloneOptionText = this.labels.INVENTORY_MODAL_CLONE.concat(
          " ",
          this.usageCloneName
        );
        this.showCloneCheckbox = true;
        break;
      }
    }
  }

  handleTypeChange(event) {
    this.selectedType = event.detail.value;
    this.showCloneCheckbox = false;
    this.showCloneOptions = false;
    this.cloneName = null;
    this.usageCloneName = null;

    this.calculateShowCloneFields();
  }

  handleCheckboxChange(event) {
    if (event.detail.value) {
      this.cloneName = this.usageCloneName;
    } else {
      this.cloneName = null;
    }
  }

  handleCloneMonthChange(event) {
    this.cloneName = event.detail.value;
  }

  // Utility function that returns a copy of the current page reference
  // after applying the stateChanges to the state on the new copy
  getUpdatedPageReference(stateChanges) {
    // The currentPageReference property is read-only.
    // To navigate to the same page with a modified state,
    // copy the currentPageReference and modify the copy.
    return Object.assign({}, this.currentPageReference, {
      // Copy the existing page state to preserve other parameters
      // If any property on stateChanges is present but has an undefined
      // value, that property in the page state is removed.
      state: Object.assign({}, this.currentPageReference.state, stateChanges)
    });
  }
}