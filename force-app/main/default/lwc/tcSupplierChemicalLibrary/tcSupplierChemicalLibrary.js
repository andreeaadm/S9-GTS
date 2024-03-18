import { LightningElement, track, api, wire } from "lwc";
import { label } from "c/labelService";
import getSuppliersFacilityList from "@salesforce/apex/ChemicalLibraryController.getSuppliersFacilityList";
import getChemicalProducts from "@salesforce/apex/ChemicalLibraryController.getChemicalProducts";
import getConformantChemicalProducts from "@salesforce/apex/ChemicalLibraryController.getConformantChemicalProducts";
import getSDSChemicalProducts from "@salesforce/apex/ChemicalLibraryController.getSDSChemicalProducts";
import getMrslChemicalProducts from "@salesforce/apex/ChemicalLibraryController.getMrslChemicalProducts";
import getLoggedInUserInfo from "@salesforce/apex/ChemicalLibraryController.getLoggedInUserInfo";
import getSuppliersForBrand from "@salesforce/apex/ChemicalLibraryController.getSuppliersForBrand";
import getFacilityListBySelectedSupplier from "@salesforce/apex/ChemicalLibraryController.getFacilityListBySelectedSupplier";

const isObject = (obj) => {
    return Object.prototype.toString.call(obj) === "[object Object]";
  };

export default class ReportList extends LightningElement {
  labels = label;
  showNoActiveFaciltiesBanner = true;
  @track selectedFacility = "";
  @track selectedSupplier = "";
  @track filterSearch = "";
  @track filterConformant = false;
  @track filterSafetyDataSheet = false;
  @track filterMRSLCert = false;
  @track chemicalProductData;
  @track allChemicalProductsShown = false;
  @track selectFacilityNone = false;
  @track selectFacility = false;
  @track noDataFoundForFacility = false;
  @track isLoading = false;
  @track isViewMore = false;
  @track chemicalProductDataWithViewMore;
  @track isConformantChanged = false;
  @track isSdsChanged = false;
  @track isMrslChanged = false;
  @track isCellClicked = false;
  @track selectedRowId = '';
  @track isBackToLibrary = false;
  @track isBrandUser = false;
  
  _recordCount = 50;
  _offset = 0;
  
  
  connectedCallback() {
    this.selectFacilityNone = true;
    this._getSuppliersActiveFacilitiesListhandler();
    this._getLoggedInUserInfohandler();
    this._getSuppliersForBrandListhandler();
  }

  @track _facilities = [];
  @api
  get facilities(){
    this._facilities;
  }
  set facilities(v){
    const data = v ? (isObject(v) ? v : JSON.parse(v)) : null;
      this._facilities = data.facilities;
  }

  @track _suppliers = [];
  @api
  get suppliers(){
    this._suppliers;
  }
  set suppliers(v){
    const data = v ? (isObject(v) ? v : JSON.parse(v)) : null;
      this._suppliers = data.suppliers;
  }

  // call the apex method to get suppliers active facilities from the server
  _getSuppliersActiveFacilitiesListhandler() {
    getSuppliersFacilityList()
      .then((result) => {
        if(result == 'No Active Facilities are present'){
        }
        else if(result !== 'No Active Facilities are present'){
          this.facilities = result;
        }
      })
      .catch((error) => {
        this.errorCallback(error.body.message);
      });
  }

  // call the apex method to get suppliers from the server
  _getSuppliersForBrandListhandler() {
    getSuppliersForBrand()
      .then((result) => {
        if(result == 'No Active Suppliers are present'){
        }
        else if(result !== 'No Active Suppliers are present'){
          this.suppliers = result;
        }
      })
      .catch((error) => {
        this.errorCallback(error.body.message);
      });
  }

  // call the apex method to get logged-in user info from the server
  _getLoggedInUserInfohandler() {
    getLoggedInUserInfo()
      .then((result) => {
        this.isBrandUser = result;
      })
      .catch((error) => {
        this.errorCallback(error.body.message);
      });
  }

  handleSupplierChange(event) {
    this.selectedSupplier = event.detail.value;
    if(this.selectedSupplier !== 'None') {
      this._getFacilityListBySelectedSupplierHandler(this.selectedSupplier);
      }
      
    else if(this.selectedFacility == 'None') {
      this._getSuppliersActiveFacilitiesListhandler();
      this.selectFacilityNone = true;
      this.selectFacility = false;
      this.noDataFoundForFacility = false;
      this.resetFilters();
    }
  }

  handleFacilityChange(event) {
    this.selectedFacility = event.detail.value;
    if(this.selectedFacility == 'None'){
      this.selectFacilityNone = true;
      this.selectFacility = false;
      this.noDataFoundForFacility = false;
      this.resetFilters();
    }
    else if(this.selectedFacility !== 'None'){
      this.resetFilters();
      this.selectFacilityNone = false;
      this._getChecmialProductsData();
    } 
  }

  handleSearchChange(event) {
    this.filterSearch = event.detail.value;
    this._getChecmialProductsData();
  }

  resetFilters() {
    this.filterSearch = "";
    this.filterConformant = false;
    this.filterSafetyDataSheet = false;
    this.filterMRSLCert = false;
  }

  resetAllFilters() {
    this.filterSearch = "";
    this.filterConformant = false;
    this.filterSafetyDataSheet = false;
    this.filterMRSLCert = false;
    this._getChecmialProductsData();
  }

  handleConformantChange(event){
    this.isConformantChanged = true;
    this.filterConformant = event.detail.value;
    this._getConformantChecmialProductsData();
  }

  handleSafetyDataSheetChange(event){
    this.isSdsChanged = true;
    this.filterSafetyDataSheet = event.detail.value;
    this._getSDSChecmialProductsData();
  }

  handleMRSLCertChange(event){
    this.isMrslChanged = true;
    this.filterMRSLCert = event.detail.value;
    this._getMrslChecmialProductsData();
  }

  // call the apex method to get facilities of selected supplier
  _getFacilityListBySelectedSupplierHandler(selectedSupplierId){
    this.isLoading = true;
    getFacilityListBySelectedSupplier({
    selectedSupplierId : selectedSupplierId
  })
    .then((result) => {
        if(result){
          if(result == 'No Active Facilities are present'){
          }
          else if(result !== 'No Active Facilities are present'){
            this.facilities = result;
          }
        }
    })
    .catch((error) => {
        console.error(error);
      });
  }

  // call the apex method to get chemical products for selected facility
  _getChecmialProductsData(){
    this.isLoading = true;
    getChemicalProducts({
    facilityId : this.selectedFacility,
    Productname : this.filterSearch,
    recordCount: this._recordCount,
    offset: this._offset
  })
    .then((result) => {
        if(result){
          this.noDataFoundForFacility = false;
          this.selectFacility = true;
          if(this.isViewMore == true){
            this._processProductResponse(result);
            this.isViewMore = false;
          }
          else {
            this.chemicalProductData = result.table;
            this.allChemicalProductsShown = result.table.rows.length < this._recordCount;
          }
        }
        else {
          this.noDataFoundForFacility = true;
          this.selectFacility = false;
        }
        this.isLoading = false;
        
    })
    .catch((error) => {
        console.error(error);
      });
  }

  // call the apex method to get chemical products filtered by Conformant
  _getConformantChecmialProductsData(){
    this.isLoading = true;
    getConformantChemicalProducts({
    facilityId : this.selectedFacility,
    Productname : this.filterSearch,
    conformant : this.filterConformant,
    recordCount: this._recordCount,
    offset: this._offset
  })
    .then((result) => {
        if(result){
          this.noDataFoundForFacility = false;
          this.selectFacility = true;
          if(this.isViewMore == true){
            this._processProductResponse(result);
            this.isViewMore = false;
          }
          else {
            this.chemicalProductData = result.table;
            this.allChemicalProductsShown = result.table.rows.length < this._recordCount;
          }
        }
        else {
          this.noDataFoundForFacility = true;
          this.selectFacility = false;
        }
        this.isLoading = false;
        
    })
    .catch((error) => {
        console.error(error);
      });
  }

  // call the apex method to get chemical products filtered by Safety Data Sheet
  _getSDSChecmialProductsData(){
    this.isLoading = true;
    getSDSChemicalProducts({
    facilityId : this.selectedFacility,
    Productname : this.filterSearch,
    safetyDataSheet : this.filterSafetyDataSheet,
    recordCount: this._recordCount,
    offset: this._offset
  })
    .then((result) => {
        if(result){
          this.noDataFoundForFacility = false;
          this.selectFacility = true;
          if(this.isViewMore == true){
            this._processProductResponse(result);
            this.isViewMore = false;
          }
          else {
            this.chemicalProductData = result.table;
            this.allChemicalProductsShown = result.table.rows.length < this._recordCount;
          }
        }
        else {
          this.noDataFoundForFacility = true;
          this.selectFacility = false;
        }
        this.isLoading = false;
        
    })
    .catch((error) => {
        console.error(error);
      });
  }

  // call the apex method to get chemical products filtered by MRSL Certificates
  _getMrslChecmialProductsData(){
    this.isLoading = true;
    getMrslChemicalProducts({
    facilityId : this.selectedFacility,
    Productname : this.filterSearch,
    MRSLCert : this.filterMRSLCert,
    recordCount: this._recordCount,
    offset: this._offset
  })
    .then((result) => {
        if(result){
          this.noDataFoundForFacility = false;
          this.selectFacility = true;
          if(this.isViewMore == true){
            this._processProductResponse(result);
            this.isViewMore = false;
          }
          else {
            this.chemicalProductData = result.table;
            this.allChemicalProductsShown = result.table.rows.length < this._recordCount;
          }
        }
        else {
          this.noDataFoundForFacility = true;
          this.selectFacility = false;
        }
        this.isLoading = false;
        
    })
    .catch((error) => {
        console.error(error);
      });
  }



  /**
   * processes the response from the server
   * @param {object} result - object containing chemical product data structured for c-datatable
   */
  _processProductResponse(result) {
    if (result) {
      if (this.chemicalProductData && this.chemicalProductData.rows) {
        this.chemicalProductData.rows.push(...result.table.rows);
      } else {
        this.chemicalProductData = result.table;
      }
      this.allChemicalProductsShown = result.table.rows.length < this._recordCount;
      if(this.allChemicalProductsShown){
        this._offset = 0;
      }
    } else if (!result && this.chemicalProductData) {
      this.allChemicalProductsShown = true;
    } else {
      this.noDataFoundForFacility = true;
    }
  }
  
//handles the user requesting more records
handleViewMore() {
  this._processViewMore();
}

// processes the user's request for more records
_processViewMore() {
  this.isViewMore = true;
  this._offset = this.chemicalProductData.rows.length;
  if(this.isConformantChanged == true){
    this._getConformantChecmialProductsData();
  }
  else if(this.isSdsChanged == true) {
    this._getSDSChecmialProductsData();
  }
  else if(this.isMrslChanged == true){
    this._getMrslChecmialProductsData();
  }
  else {
    this._getChecmialProductsData();
  }
}

onCellClick(event) {
  this.selectedRowId = event.detail.rowId;
  if(this.selectedRowId) {
    this.isCellClicked = true;
  }
}

onBackToLibrary(event) {
  this.isCellClicked = event.detail.isBackToLibrary;
}
}