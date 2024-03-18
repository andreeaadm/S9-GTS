import { LightningElement, wire } from "lwc";
import getInventories from "@salesforce/apex/TC_BrandInventoryListController.getInventoriesListTableData";
import getFilterLists from "@salesforce/apex/TC_BrandInventoryListController.getFilterLists";
import { label } from "c/labelService";

export default class TcBrandInventoryList extends LightningElement {
  selectedSupplierType = null;
  selectedSupplier = null;
  selectedFacility = null;
  selectedFacilityFromPageRef = null;
  selectedInventory = null;
  supplierTypeList = [];
  supplierList = [];
  facilityList = [];
  inventoryList = [];
  supplierIdsToConnectionIds = {};
  validFacilityIds = [];
  noData;
  isLoading = true;
  tableData = { columns: [], rows: [] };
  labels = label;
  rowLimit = 50;
  allShown = false;

  @wire(getFilterLists)
  processFilterLists(response) {
    if (response && response.data) {
      let result = JSON.parse(response.data);
      this.supplierTypeList = result.supplierTypes;
      this.supplierList = result.suppliers;
      this.facilityList = result.facilities;
      this.inventoryList = result.inventories;
      this.supplierIdsToConnectionIds = result.supplierIdsToConnectionIds;
      this.validFacilityIds = result.validFacilityIds;
      this.setFacilityBasedOnPageRef();
      this.getData();
    } else {
      this.tableData = { columns: [], rows: [] };
      this.noData = true;
      this.isLoading = false;
    }
  }

  getData() {
    if (
      this.supplierIdsToConnectionIds &&
      this.validFacilityIds &&
      this.validFacilityIds.length > 0
    ) {
      getInventories({
        supplierType: this.selectedSupplierType,
        supplierId: this.selectedSupplier,
        facilityId: this.selectedFacility,
        inventoryName: this.selectedInventory,
        supplierIdsToConnectionIds: this.supplierIdsToConnectionIds,
        validFacilityIds: this.validFacilityIds
      })
        .then((response) => {
          this.tableData = response.table;
          this.noData = response.totalRows === 0 ? true : false;
          this.isLoading = false;
        })
        .catch((error) => {
          this.tableData = { columns: [], rows: [] };
          this.noData = true;
          this.isLoading = false;
        });
    }
  }

  handleSupplierTypeChange(evt) {
    this.selectedSupplierType = evt.detail.value;
    this.getData();
  }

  handleSupplierChange(evt) {
    this.selectedSupplier = evt.detail.value;
    this.getData();
  }

  handleFacilityChange(evt) {
    this.selectedFacility = evt.detail.value;
    this.getData();
  }

  handleInventoryChange(evt) {
    this.selectedInventory = evt.detail.value;
    this.getData();
  }

  handleReset() {
    this.selectedSupplier = null;
    this.selectedFacility = null;
    this.selectedInventory = null;
    this.selectedSupplierType = null;
    this.getData();
  }

  get currentRows() {
    this.allShown = this.tableData.rows.length <= this.rowLimit;
    return this.tableData.rows.slice(0, this.rowLimit);
  }

  handleViewMore() {
    this.rowLimit += 50;
  }

  handleRetrievedState(event) {
    if (event?.detail?.facilityId) {
      this.selectedFacilityFromPageRef = event.detail.facilityId;
      this.setFacilityBasedOnPageRef();
    }
  }

  setFacilityBasedOnPageRef() {
    let elem = this.template.querySelector("c-input.facilitySelect");
    if (
      this.facilityList &&
      this.facilityList.length > 0 &&
      this.selectedFacilityFromPageRef &&
      elem
    ) {
      this.facilityList.forEach((facility) => {
        if (facility.value === this.selectedFacilityFromPageRef) {
          elem.value = this.selectedFacilityFromPageRef;
          this.selectedFacility = this.selectedFacilityFromPageRef;
          this.getData();
        }
      });
    }
  }

  handleCellClick(evt) {
    if (evt.detail.value === this.labels.TC_VIEW_INCHECK_REPORT) {
      this.template
        .querySelector("c-zdhc-get-in-check-report")
        .getInCheckReport(evt.detail.rowId);
    } else if (evt.detail.value === this.labels.TC_DOWNLOAD_INVENTORY) {
      this.template
        .querySelector("c-tc-download-inventory")
        .handleDownload(evt.detail.rowId);
    }
  }
}