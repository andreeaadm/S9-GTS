import { LightningElement, api, wire } from "lwc";
import getUserAccessKey from "@salesforce/apex/ZDHCGatewayService.getUserAccessKey";
import searchProducts from "@salesforce/apex/TC_AddProducts.searchProducts";
import Id from "@salesforce/user/Id";

export default class TcAddProductsSearch extends LightningElement {
  //PUBLIC PROPERTIES
  @api isInternalSalesforce;

  //TEMPLATE PROPERTIES
  showResultsLoader;

  //INTERNAL PROPERTIES
  _userId = Id;

  //GETTERS & SETTERS
  @api
  set searchParams(value) {
    this._processSearch(value);
  }
  get searchParams() {}

  /**
   * call this public method to reset state.
   */
  @api reset() {
    this.template.querySelector("c-tc-add-products-search-results").reset();
  }

  //LIGHTNING WIRE SERVICE
  /**
   * retrieve the UserAccessKey for the current user
   */
  @wire(getUserAccessKey, {
    recordId: "$_userId"
  })
  _userAccessKey;

  //INTERNAL FUNCTIONS
  /**
   * calls the server to get products from ZDHC and the master chemical list (Salesforce)
   * @param {object} queryParams - params used on the ZDHC API to filter the results
   */
  _processSearch(queryParams) {
    if (this._userAccessKey?.data) {
      this.showResultsLoader = true;
      searchProducts({
        userAccessKey: this._userAccessKey.data,
        queryParams: queryParams
      })
        .then((response) => {
          this._processSearchResponse(response);
        })
        .catch((error) => {
          console.error(error);
          this.dispatchEvent(
            new CustomEvent("searcherror", {
              detail: error
            })
          );
        });
    }
  }

  /**
   * processes the response from the server
   * @param {object} response - ListResponse for c-datatable if successfuly or a gateway service response if not
   */
  _processSearchResponse(response) {
    const resultsCmp = this.template.querySelector(
      "c-tc-add-products-search-results"
    );
    resultsCmp.productData = [];
    if (response.isSuccess && response.combinedProducts?.length > 0) {
      resultsCmp.productData = response.combinedProducts;
    } else {
      resultsCmp.noSearchResults = true;
      if (!response.errors?.[0] === "No results found.") {
        this._showToastNotification(
          this.labels.ERROR,
          this.labels.TC_SEARCHING_PRODUCTS_ERROR,
          "error"
        );
      }
    }
    resultsCmp.showLoader = this.showResultsLoader = false;
  }
}