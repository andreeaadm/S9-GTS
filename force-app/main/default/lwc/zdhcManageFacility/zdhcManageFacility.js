import { LightningElement, api, wire } from "lwc";
import { getRecord, updateRecord } from "lightning/uiRecordApi";
import { getObjectInfo } from "lightning/uiObjectInfoApi";
import makeCallout from "@salesforce/apex/ZDHCGatewayService.makeCallout";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { label } from "c/labelService";
import toxLogo from "@salesforce/resourceUrl/toxLogo";
import tcZDHCPurchaseIncheck from "@salesforce/label/c.ZDHC_Purchase_Incheck_Callout_Error";

export default class ZdhcManageFacility extends LightningElement {
  //PUBLIC PROPERTIES
  @api recordId;

  //TEMPLATE PROPERTIES
  labels = label;
  tcZDHCPurchaseIncheck = tcZDHCPurchaseIncheck;
  toxLogo = toxLogo;
  showLoader;
  showModal;
  showOrgLinkAction;
  showPurchaseAction;
  purchaseActionLabel = 'Purchase InCheck Subscription';
  showSubscriptionStatus;
  showComponentStatus;
  componentStatus;
  componentStatusLabel;
  tableCols = [
    {
      label: this.labels.TC_ORGANISATION_GUID,
      fieldName: "OrgGUID",
      hideDefaultActions: true
    },
    {
      label: this.labels.TC_ORGANISATION_GUID_NAME,
      fieldName: "Name",
      hideDefaultActions: true
    },
    {
      label: this.labels.TC_SUPPLIER_AID,
      fieldName: "SupplierAID",
      hideDefaultActions: true
    },
    { label: "Type", fieldName: "Type", hideDefaultActions: true },
    {
      label: this.labels.ACTION,
      fieldName: "OrgGUID",
      type: "button",
      variant: "brand",
      initialWidth: 90,
      typeAttributes: {
        label: this.labels.LINK,
        variant: "brand",
        disabled: false
      }
    }
  ];
  tableRows;
  userAccessKey;
  subscriptionStatus;

  //INTERNAL PROPERTIES
  _accountRecord;

  //LIGHTNING DATA SERVICE
  /**
   * retrieve metadata info for the Account sObject
   */
  @wire(getObjectInfo, { objectApiName: "Account" })
  accountObjectInfo;

  /**
   * retrieve relevant fields from the Account in scope
   */
  @wire(getRecord, {
    recordId: "$recordId",
    fields: [
      "Account.ZDHC_Organisation_GUID__c",
      "Account.ZDHC_Organisation_Name__c",
      "Account.InCheck_Subscription_Expiration_Date__c",
      "Account.InCheck_Subscription_Purchase_Date__c",
      "Account.InCheck_Subscription_Start_Date__c",
      "Account.InCheck_Status__c",
      "Account.Supplier_AID__c"
    ]
  })
  wiredAccount({ error, data }) {
    if (data) {
      this._accountRecord = data;
    } else if (error) {
      console.error(error);
      this._handleError(this.labels.UPDATE_SUBSCRIPTION_STATUS_ERROR, false);
    }
  }

  //GETTERS & SETTERS
  /**
   * @returns the icon name to display in the component status
   */
  get statusIcon() {
    return this.componentStatus === "success"
      ? "utility:success"
      : "utility:error";
  }

  /**
   * @returns the sObject fields needed by the facility manager check cmp to query the UserAccessKey
   */
  get recordFields() {
    return "Account.Facility_Manager__c";
  }

  //EVENT HANDLERS
  /**
   * handles the user cancelling the action - closes the action modal
   */
  handleCancel() {
    this.showModal = false;
  }

  /**
   * handles a child component instructing to stop showing the loader / spinner cmp
   */
  handleStopLoader() {
    this.showLoader = false;
  }

  /**
   * handles a request from the manager checks component to reset properties
   * this will be called if there is a change to the Account record data outside of the cmp lifecycle
   */
  handleResetCmp() {
    this.userAccessKey =
      this.showSubscriptionStatus =
      this.subscriptionStatus =
      this.showOrgLinkAction =
      this.showPurchaseAction =
      this.showComponentStatus =
      this.componentStatus =
      this.componentStatusLabel =
        null;
  }

  /**
   * handles the facility manager child component finding the access key needed to perform the API call
   * @param {object} event - foundUserAccessKey custom event
   */
  handleFoundUserAccessKey(event) {
    this.userAccessKey = event.detail;
    this._checkComponentState();
  }

  /**
   * handles the user clicking the UI button to link the account to a ZDHC organisation
   */
  handleLinkToZdhc() {
    this.showModal = this.showLoader = true;
    this._getOrganisationData();
  }

  /**
   * handles the user clicking the UI button to Purchase the Incheck Subscription
   */
  handlePurchase() {
    this.showLoader = true;
    this._postPurchaseDetails();
    //alert('Successfully Clicked!!!');
  }

  /**
   * handles an error in a child component
   * @param {object} event - error custom event
   */
  handleError(event) {
    this._handleError(event.detail, true);
  }

  /**
   * handles the user selecting one of the orgs to link to the account
   * @param {object} event - onrowaction lightning event
   */
  handleRowAction(event) {
    this._updateaccountRecordFromRow(event.detail.row);
  }

  /**
   * handles the user clicking to update the subscription status details on the Account
   */
  handleUpdateSubscriptionStatus() {
    this.showLoader = true;
    this.showSubscriptionStatus = false;
    this._updateAccountSubscriptionStatus();
  }

  //INTERNAL FUNCTIONS
  /**
   * checks the state of the component and determines what action to display to the user
   */
  _checkComponentState() {
    if (this.subscriptionStatus == null) {
      if (
        this._accountRecord &&
        this._accountRecord.fields.ZDHC_Organisation_GUID__c.value != null &&
        this._accountRecord.fields.ZDHC_Organisation_Name__c.value != null &&  
        this._accountRecord.fields.InCheck_Subscription_Purchase_Date__c.value == null
      ) {
        this.showPurchaseAction = true;
        this.showOrgLinkAction = false;
      }
      else if (
        this._accountRecord &&
        this._accountRecord.fields.ZDHC_Organisation_GUID__c.value != null &&
        this._accountRecord.fields.InCheck_Subscription_Purchase_Date__c.value != null
      ) {
        this.showPurchaseAction = false;
        this.showLoader = true;
        //linked to ZDHC - get latest subscription status
        this._getSubscriptionStatus();
      } else {
        //need to link facility to ZDHC
        this.showOrgLinkAction = true;
      }
    }
  }

  /**
   * calls ZDHC Gateway Service to retrieve the subscription status for the facility
   */
  _getSubscriptionStatus() {
    makeCallout({
      zdhcRequest: {
        apiName: "inCheckSubscriptionStatus",
        method: "GET",
        userAccessKey: this.userAccessKey,
        queryParams: {
          organizationGUID:
            this._accountRecord.fields.ZDHC_Organisation_GUID__c.value
        }
      }
    })
      .then((response) => {
        if (response.isSuccess && response.response.result.success) {
          this.subscriptionStatus = new Map(
            [
              ["InCheckStatus",response.response.InCheckStatus],
              ["OrganisationAID",response.response.OrganisationAID],
              ["InCheckExpirationDate",response.response.InCheckExpirationDate],
              ["InCheckStartDate",response.response.InCheckStartDate]
            ]
            )
          this._processSubscriptionStatus();
        } else if (!response.isSuccess || !response.response.result.success) {
          this._handleError(
            this.labels.SUBSCRIPTION_STATUS_CALLOUT_ERROR,
            true
          );
        }
      })
      .catch((error) => {
        console.error(error);
        this._handleError(this.labels.SUBSCRIPTION_STATUS_CALLOUT_ERROR, true);
      });
  }

  /**
   * processes the subscription status response from the ZDHC Gateway
   */
  _processSubscriptionStatus() {
    let accountData = this._accountRecord.fields;
    if (
      accountData.InCheck_Status__c.value == null 
    ) {
      //proceed to update the account automatically
      this._updateAccountSubscriptionStatus();
    } else {
      //present options to the UI and let the user choose to update
      this.showLoader = false;
      this.showSubscriptionStatus = true;
    }
  }

  /**
   * updates the Account record with ZDHC Subscription status data
   */
  _updateAccountSubscriptionStatus() {
      const recordInput = {
        fields: {
          Id: this.recordId,
          InCheck_Status__c: this.subscriptionStatus.get('InCheckStatus'),
          InCheck_Subscription_Expiration_Date__c:
            this.subscriptionStatus.get('InCheckExpirationDate') || null,
          InCheck_Subscription_Start_Date__c:
            this.subscriptionStatus.get('InCheckStartDate') || null
        }
      };    
    updateRecord(recordInput)
      .then(() => {
        this._showToastNotification(
          this.labels.SUCCESS,
          this.labels.SUBSCRIPTION_STATUS_ACCOUNT_UPDATE_SUCCESS,
          "success"
        );
        this.showLoader = false;
        this.showComponentStatus = true;
        this.componentStatus = "success";
        this.showSubscriptionStatus = true;
        this.componentStatusLabel =
          this.labels.UPDATE_SUBSCRIPTION_STATUS_SUCCESS;
      })
      .catch((error) => {
        console.error(error);
        this._handleError(this.labels.UPDATE_ACCOUNT_ERROR, true);
      });
  }

  /**
   * calls ZDHC Gateway Service to retrieve organisation data for the current user
   */
  _getOrganisationData() {
    makeCallout({
      zdhcRequest: {
        apiName: "userOrganizations",
        method: "GET",
        userAccessKey: this.userAccessKey
      }
    })
      .then((response) => {
        if (response.isSuccess && response.response.result.success) {
          this.tableRows = response.response.Organizations;
          this.showLoader = false;
        } else if (!response.isSuccess || !response.response.result.success) {
          this._handleError(this.labels.ORG_CALLOUT_ERROR, true);
        }
      })
      .catch((error) => {
        this._handleError(this.labels.ORG_CALLOUT_ERROR, true);
        console.error(error);
      });
  }

  /**
   * updates the Account sObject with the selected row data
   * @param {object} row - selected row data from the org list table
   */
  _updateaccountRecordFromRow(row) {
    const recordInput = {
      fields: {
        Id: this.recordId,
        ZDHC_Organisation_GUID__c: row.OrgGUID,
        ZDHC_Organisation_Name__c: row.Name,
        Supplier_AID__c : row.SupplierAID
      }
    };
    updateRecord(recordInput)
      .then(() => {
        this._showToastNotification(
          this.labels.SUCCESS,
          this.labels.ORG_SELECTOR_ACCOUNT_UPDATE_SUCCESS,
          "success"
        );
        this.showModal = false;
        this.showPurchaseAction = true;
      })
      .catch((error) => {
        console.error(error);
        this._handleError(this.labels.UPDATE_ACCOUNT_ERROR, true);
      });
  }

  /**
   * calls ZDHC Gateway Service to post purchase details to ZDHC
  */
  _postPurchaseDetails() {
    makeCallout({
      zdhcRequest: {
        apiName: "purchaseInCheckSubscription",
        method: "POST",
        userAccessKey: this.userAccessKey,
        queryParams: {
          OrgGUID:
            this._accountRecord.fields.ZDHC_Organisation_GUID__c.value,
          OrgName:
            this._accountRecord.fields.ZDHC_Organisation_Name__c.value
        }
      }
    })
      .then((response) => {
        if (response.isSuccess && response.response.result.success) {
          this.showLoader = false;
          this._updateAccountWithPurchsaeDate();
        } else if (!response.isSuccess || !response.response.result.success) {
          this._handleError(this.tcZDHCPurchaseIncheck, true);
        }
      })
      .catch((error) => {
        this._handleError(this.tcZDHCPurchaseIncheck, true);
        console.error(error);
      });
  }

  /**
   * updates the Account record with ZDHC InCheck Purchase Date
   */
  _updateAccountWithPurchsaeDate() {
    const recordInput = {
      fields: {
        Id: this.recordId,
        InCheck_Subscription_Purchase_Date__c:  new Date().toISOString().substring(0, 10)
      }
    };
    updateRecord(recordInput)
      .then(() => {
        this._showToastNotification(
          this.labels.SUCCESS,
          this.labels.SUBSCRIPTION_STATUS_ACCOUNT_UPDATE_SUCCESS,
          "success"
        );
        this.showLoader = false;
      })
      .catch((error) => {
        console.error(error);
        this._handleError(this.labels.UPDATE_ACCOUNT_ERROR, true);
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
      this.showModal = false;
    }
    this.showComponentStatus = true;
    this.componentStatus = "error";
    this.componentStatusLabel = message;
    this.showLoader = false;
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
}