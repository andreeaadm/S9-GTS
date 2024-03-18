import { LightningElement, api, wire, track } from "lwc";
import { getRecord, updateRecord, getFieldValue } from "lightning/uiRecordApi";
import makeCallout from "@salesforce/apex/ZDHCGatewayService.makeCallout";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { label, format } from "c/labelService";
import userId from "@salesforce/user/Id";
import USER_ACCESS_KEY_FIELD from "@salesforce/schema/User.ZDHC_User_Access_Key__c";
import toxLogo from "@salesforce/resourceUrl/toxLogo";
export default class ZdhcManageFormulator extends LightningElement {
  //PUBLIC PROPERTIES
  @api recordId;

  //INTERNAL PROPERTIES
  @track record;
  userId = userId;
  user;
  @track showConfirmModal = false;

  //TEMPLATE PROPERTIES
  labels = label;
  toxLogo = toxLogo;

  @track selector = {
    show: false,
    search: "",
    loading: false,
    searched: false,
    empty: true,
    more: true,
    columns: [
      {
        label: "Name",
        fieldName: "organizationName",
        hideDefaultActions: true
      },
      {
        label: "Address",
        fieldName: "address",
        hideDefaultActions: true
      },
      {
        label: "Supplier AID",
        fieldName: "supplierAID",
        hideDefaultActions: true
      },
      {
        label: "Action",
        fieldName: "formulatorGUID",
        type: "button",
        variant: "brand",
        initialWidth: 90,
        typeAttributes: {
          label: this.labels.LINK,
          variant: "brand",
          title: this.labels.TC_RELATE_ZDHC_FORMULATOR_LINK_TO_THIS_ACTION,
          disabled: false
        }
      }
    ],
    rows: []
  };

  get userAccessKey() {
    return getFieldValue(this.user?.data, USER_ACCESS_KEY_FIELD);
  }
  get haveUserAccessKey() {
    return this.userAccessKey?.length && this.userAccessKey?.length > 0;
  }
  get haveFormulatorGUID() {
    // GUIDs are atleast 32 characters in length, formatted with dashes a
    // GUID length is 36.
    return this.record?.fields?.ZDHC_Formulator_GUID__c?.value?.length >= 32;
  }
  get showLinkAction() {
    // Show the Link action when there is a userAccessKey to use, but
    // ZDHC_Formulator_GUID__c is null.
    return this.haveUserAccessKey && !this.haveFormulatorGUID;
  }
  get showUnlinkAction() {
    // Unlinking can occur when there is a GUID, without using the userAccessKey.
    return this.haveFormulatorGUID;
  }

  get notSearchable() {
    return !(this.selector?.search?.length > 0);
  }

  get noResults() {
    return this.selector.searched && this.selector.empty;
  }

  /**
   * retrieve relevant fields from the Formulator in scope
   */
  @wire(getRecord, {
    recordId: "$recordId",
    fields: [
      "Formulator__c.Id",
      "Formulator__c.Name",
      "Formulator__c.ZDHC_Formulator_GUID__c",
      "Formulator__c.Phone__c",
      "Formulator__c.Address__c",
      "Formulator__c.City_Town__c",
      "Formulator__c.State_Province__c",
      "Formulator__c.Country__c",
      "Formulator__c.Zip_Postal_Code__c",
      "Formulator__c.Contact_Name__c",
      "Formulator__c.Contact_Email__c",
    ]
  })
  wiredFormulator({ error, data }) {
    if (data) {
      this.record = data;
    } else if (error) {
      console.error(error);
      this._handleError(
        this.labels.TC_RELATE_ZDHC_FORMULATOR_RETRIEVAL_ERROR,
        false
      );
    }
  }

  @wire(getRecord, { recordId: "$userId", fields: [USER_ACCESS_KEY_FIELD] })
  userInfo(response) {
    this.user = response;
  }

  //EVENT HANDLERS
  /**
   * handles the user clicking the UI button to unlink the formulator from the ZDHC formulator
   */
  handleUnlinkFromZdhc() {
    this._updateFormulatorRecordFromRow(
      {
        formulatorGUID: null,
        address: null,
        supplierAID: null,
        phone: null,
        origin: null
      },
      this.labels.TC_RELATE_ZDHC_FORMULATOR_UNLINKED_SUCCESS
    );
  }

  /**
   * handles the user clicking the UI button to link the formulator to the ZDHC formulator
   */
  handleLinkToZdhc() {
    this.handleSearchReset();
    this.selector.search = this.record.fields.Name.value;
    this.selector.show = true;
    this.handleSearch();
  }

  /**
   * handles the user changing the Formulator Name search field.
   */
  handleSearchChange(event) {
    this.selector.search = event.detail.value;
  }

  /**
   * handles the user clicking the search button to get matching formulators from ZDHC gateway.
   */
  handleSearch() {
    if (this.selector.search && this.selector.search.length > 0) {
      this.selector.searched = false;
      this.selector.empty = true;
      this.selector.rows = [];
      this.selector.loading = true;
      this.selector.more = true;
      this._zdhcGetFormulators();
    }
  }

  /**
   * Resets the form to begin a new search.
   */
  handleSearchReset() {
    this.selector.searched = false;
    this.selector.search = "";
    this.selector.empty = true;
    this.selector.rows = [];
  }

  /**
   * handles an error from a child component
   * @param {object} event - error custom event
   */
  handleError(event) {
    this._handleError(event.detail, true);
  }

  /**
   * handles the user cancelling the action - closes the action modal
   */
  handleCancel() {
    this.selector.show = this.selector.loading = false;
  }

  /**
   * handles the user selecting one of the zdhc formulators to link to the formulator
   * @param {object} event - onrowaction lightning event
   */
  handleRowAction(event) {
    this._updateFormulatorRecordFromRow(
      event.detail.row,
      this.labels.TC_RELATE_ZDHC_FORMULATOR_LINKED_SUCCESS
    );
  }

  handleLoadMore(event) {
    event.target.enableInfiniteLoading = this.selector.more;
    if (this.selector.more) {
      this.selector.loading = true;
      this._zdhcGetFormulators();
    }
  }

  // INTERNAL METHODS
  /**
   * Callout to ZDHC Gateway Service to Get list of Formulators.
   */
  _zdhcGetFormulators() {
    makeCallout({
      zdhcRequest: {
        method: "GET",
        apiName: "formulators",
        userAccessKey: this.userAccessKey,
        queryParams: {
          search: this.selector.search,
          startIndex: this.selector?.rows ? this.selector.rows.length : 0,
          recordLimit: 50
        }
      }
    })
      .then((response) => {
        this.selector.loading = false;
        this.selector.searched = true;
        this.selector.more = false;
        if (response.isSuccess && response.response.result.success) {
          const currentData = this.selector.rows;
          const newData = currentData.concat(response.response.data);
          this.selector.rows = newData;
          this.selector.empty = this.selector.rows.length === 0;
          this.selector.more =
            response.response.totalResults > this.selector.rows.length;
        } else if (
          (!response.isSuccess || !response.response.result.success) &&
          response.response?.result?.errorMessage !== "No results found."
        ) {
          this._handleError(
            format(
              label.TC_ZDHC_CALLOUT_ERROR,
              response.response?.result?.errorMessage
            ),
            false
          );
        }
      })
      .catch((error) => {
        this._handleError(
          format(
            label.TC_ZDHC_CALLOUT_ERROR,
            Array.isArray(error.message) ? error.message[0] : error.message
          ),
          false
        );
      });
  }

  /**
   * updates the Formulator sObject with the selected row data
   * @param {object} row - selected row data from the org list table
   */
  _updateFormulatorRecordFromRow(row, successMessage) {
    const recordInput = {
      fields: {
        Id: this.recordId,
        Name: row.organizationName,
        ZDHC_Formulator_GUID__c: row.formulatorGUID,
        ZDHC_Supplier_AID__c: row.supplierAID,
        Address_from_ZDHC__c: row.address,
        Phone__c: row.phone,
        Origin__c: row.origin === null ? row.origin : "ZDHC Gateway"
      }
    };
    updateRecord(recordInput)
      .then(() => {
        this._showToastNotification(
          this.labels.SUCCESS,
          successMessage,
          "success"
        );
        this.selector.show = false;
      })
      .catch((error) => {
        console.error(error);
        this._handleError(
          this.labels.TC_RELATE_ZDHC_FORMULATOR_UPDATE_ERROR,
          true
        );
      });
  }

  /**
   * standard handling of an error throughout the process
   * @param {string} message - message to display to the user when an error occurs
   * @param {boolean} close - if true close the modal
   */
  _handleError(message, close) {
    this._showToastNotification(this.labels.ERROR, message, "error");
    if (close) {
      this.selector.show = false;
    }
    this.selector.loading = false;
    this.selector.more = false;
  }

  /**
   * displays a toast notification to the user
   * @param {string} title - title for the notification
   * @param {string} message - core message of the notification
   * @param {string} variant - type of message shown (success / info / warning / error)
   */
  _showToastNotification(title, message, variant) {
    this.dispatchEvent(
      new ShowToastEvent({
        title,
        message,
        variant
      })
    );
  }

  confirmAdd() {
    this.selector.show = false;
    this.showConfirmModal = true;
  }

  handleReturnToSearch() {
    this.showConfirmModal = false;
    this.selector.show = true;
  }

  handleAddToZdhc() {
    if(this.record.fields.Name.value && this.record.fields.Country__c.value) {
      makeCallout({
        zdhcRequest: {
          method: "POST",
          apiName: "formulators",
          userAccessKey: this.userAccessKey,
          requestBody: {
            name: this.record.fields.Name.value,
            phone: this.record.fields.Phone__c.value,
            address: this.record.fields.Address__c.value,
            cityTown: this.record.fields.City_Town__c.value,
            stateProvince: this.record.fields.State_Province__c.value,
            country: this.record.fields.Country__c.value,
            postalCode: this.record.fields.Zip_Postal_Code__c.value,
            contactName: this.record.fields.Contact_Name__c.value,
            contactEmail: this.record.fields.Contact_Email__c.value
          }
        }
      })
      .then((response) => {
        if (response.isSuccess && response.response.result.success) {
          const recordInput = {
            fields: {
              Id: this.recordId,
              ZDHC_Formulator_GUID__c: response.response.formulatorGUID,
              Origin__c: "Intertek"
            }
          };
          updateRecord(recordInput)
            .then(() => {
              this._showToastNotification(
                this.labels.SUCCESS,
                this.labels.TC_ZDHC_CREATE_FORMULATOR_SUCCESS,
                "success"
              );
              this.showConfirmModal = false;
            })
            .catch((error) => {
              console.error(error);
              this._handleError(
                this.labels.TC_RELATE_ZDHC_FORMULATOR_UPDATE_ERROR,
                true
              );
            });
        } else {
          this._handleError(
            format(
              label.TC_ZDHC_CALLOUT_ERROR,
              response.errors.length > 0 ? response.errors[0] : ''
            ),
            false
          );
        }
      })
      .catch((error) => {
        this._handleError(
          format(
            label.TC_ZDHC_CALLOUT_ERROR,
            Array.isArray(error.message) ? error.message[0] : error.message
          ),
          false
        );
      });
    } else {
      this._handleError(
        label.TC_ZDHC_ADD_FORMULATOR_REQUIRED_ERROR,
        false
      );
    }
  }
}