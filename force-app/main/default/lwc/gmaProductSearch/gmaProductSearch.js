import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

//STATIC RESOURCES
import gapAnalysisOrderGenerateLabel from '@salesforce/label/c.GMA_GapAnalysis_Order_Generate_Label';
import readMore from '@salesforce/label/c.GMA_Read_More';
import loginMessage from '@salesforce/label/c.GMA_Login_Message';
import insufficientTokenMessage from '@salesforce/label/c.GMA_Insufficient_Token_Message';
import singleTokenMessage from '@salesforce/label/c.GMA_Single_Token_Message';
import noRegulationMessage from '@salesforce/label/c.GMA_No_Regulation_Message';
import productPicklistLabel from '@salesforce/label/c.GMA_Product_Picklist_Label';
import marketPicklistLabel from '@salesforce/label/c.GMA_Market_Picklist_Label';
import materialPicklistLabel from '@salesforce/label/c.GMA_Material_Picklist_Label';
import ageGroupPicklistLabel from '@salesforce/label/c.GMA_Age_Group_Picklist_Label';
import riskTypeLabel from '@salesforce/label/c.GMA_Risk_Type_Picklist_Label';
import currentMarketPicklistLabel from '@salesforce/label/c.GMA_Current_Market_Picklist_Label';
import targetMarketPicklistLabel from '@salesforce/label/c.GMA_Target_Market_Picklist_Label';
import runSearchAgainLabel from '@salesforce/label/c.GMA_Run_Search_Again_Label';
import recallSummarySearchMessage from '@salesforce/label/c.GMA_Recall_Summary_Search_Message';
import noRecallMessage from '@salesforce/label/c.GMA_No_Recall_Message';
import multipleTokenMessage from '@salesforce/label/c.GMA_Multiple_Token_Message';
import generateRecallSummaryLabel from '@salesforce/label/c.GMA_Generate_Recall_Summary_Label';
import gapAnalysisSearchMessage from '@salesforce/label/c.GMA_GapAnalysis_Search_Message';
import noGapMessage from '@salesforce/label/c.GMA_No_Gap_Message';
import generateGapAnalysisLabel from '@salesforce/label/c.GMA_Generate_Gap_Analysis_Label';
import generateReportMessage from '@salesforce/label/c.GMA_Generate_Report_Message';
import downloadReportMessage from '@salesforce/label/c.GMA_Download_Report_Message';
import downloadLinkMessage1 from '@salesforce/label/c.GMA_Download_Link_Message_1';
import downloadLinkMessage2 from '@salesforce/label/c.GMA_Download_Link_Message_2';
import intertekAdminEmail from '@salesforce/label/c.GMA_Portal_Admin_Email';
import generateRecallReportMessage from '@salesforce/label/c.GMA_Generate_Recall_Report_Message';
import generateTestPlanReportMessage from '@salesforce/label/c.GMA_Generate_Test_Plan_Report_Message';
import downloadRegulatoryReportMessage from '@salesforce/label/c.GMA_Download_Regulatory_Report_Message';
import downloadTestPlanReportMessage from '@salesforce/label/c.GMA_Download_Test_Plan_Report_Message';
import downloadRecallReportMessage from '@salesforce/label/c.GMA_Download_Recall_Report_Message';
import mandatoryFieldExplanationLabel from '@salesforce/label/c.GMA_MandatoryField_Label_Search';
import myOrdersText from '@salesforce/label/c.GMA_View_Orders_text';
import myOrdersButton from '@salesforce/label/c.GMA_View_Orders_Button';
import downloadButtonText from '@salesforce/label/c.GMA_Download_Report_button';
import gapAnalysisConfirmationMessage from '@salesforce/label/c.GMA_GapAnalysis_ConfirmOrder_Label';
import gmaRequiredFields from '@salesforce/label/c.GMA_Required_Fields';

//EXTENDED LWC STANDARD FUNCTIONALITY
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { getFieldValue } from "lightning/uiRecordApi";
import CONTACT_ID from "@salesforce/schema/User.ContactId";
import USER_ID from "@salesforce/user/Id";
import { publish, subscribe, unsubscribe, MessageContext } from "lightning/messageService";
import msgChannel from "@salesforce/messageChannel/GMAPortalMessageChannel__c";

//CUSTOM APEX METHODS
import searchProducts from '@salesforce/apex/GMAHLSLProductSearchController.productSearch';
import searchRecall from '@salesforce/apex/GMAHLSLProductSearchController.recallSearch';
import searchGap from '@salesforce/apex/GMAHLSLProductSearchController.gapSearch';
import createRegulatorySheetOrder from '@salesforce/apex/GMAHLSLProductSearchController.createRegulatorySheetOrder';
import createRecallSummaryOrder from '@salesforce/apex/GMAHLSLProductSearchController.createRecallSummaryOrder';
import createSearchRecord from '@salesforce/apex/GMAHLSLProductSearchController.createSearchRecord';
import createGapAnalysisOrder from '@salesforce/apex/GMAHLSLProductSearchController.createGapAnalysisOrder';
import getSearchTokenCost from '@salesforce/apex/GMAHLSLProductSearchController.getSearchTokenCost';
import getMaxWaitSecondsForDownloads from '@salesforce/apex/GMAHLSLProductSearchController.getMaxWaitSecondsForDownloads';
import getUserData from '@salesforce/apex/GMAHLSLProductSearchController.getUserData';
import retrieveOrderDocument from '@salesforce/apex/GMAHLSLProductSearchController.retrieveOrderDocument';
import publishPlatformEvent from '@salesforce/apex/GMAHLSLProductSearchController.publishPlatformEvent';

//VARIABLES
const MESSAGE_TYPE_ABORT_LOGIN = 'loginAbort'; // (did not log in)
const MESSAGE_TYPE_OK_LOGIN = 'loginOk'; // (logged in ok)
const MESSAGE_TYPE_CANCEL_ORDER = 'orderConfirmCancel'; // (logged in, not proceeding)
const MESSAGE_TYPE_OK_ORDER = 'orderConfirmOk'; // (logged in, proceeding)
const REFRESH_HISTORY_MESSAGE = 'historyRefresh';
const LOADING_HISTORY_MESSAGE = 'historyLoading';
const SESSION_STORAGE_KEY_ORDER_DATA = 'orderData';
const SESSION_STORAGE_KEY_LOGIN_OK = 'loginComplete';
const SESSION_STORAGE_KEY_TASK_LOGGED = 'tLog';
const SESSION_STORAGE_KEY_HISTORY_RERUN = 'rerunSearch';
const PLATFORM_EVENT_MESSAGE_ORDER_PROCEED = 'ORDER_PROCEED'; //platform event message to publish if user intends to proceed with order
                                                            // user is logged in, clicks Generate report button - at this point may or may not have sufficient fund
const ORDER_TYPE_REGULATORY = 'Regulatory Sheet';
const ORDER_TYPE_TESTPLAN = 'Test Plan';
const ORDER_TYPE_RECALL = 'Recall Summary';
const ORDER_TYPE_GAPANALYSIS = 'Gap Analysis';
const GENERATE_REGULATORY_TYPE_SHEET = 'Generate Regulatory Sheet';
const GENERATE_TEST_PLAN= 'Generate Test Plan';
const GAPANALYSIS_CONFIRM_TOKEN_PLACEHOLDER = '[[tokenCount]]';
const ALL_VALUES = 'ALL';

export default class GMA_ProductSearch extends NavigationMixin(LightningElement) {
    showRegulatory = false;
    showRecall = false;
    showRegulatorySheet = false;
    @api orderType;
    showGapAnalysis = false;
    showGapAnalysisReport = false;
    gapCount;
    showLoginMessage;
    showRecallSummary = false;
    showOrderGeneratedPage = false;
    showGapAnalysisOrderGeneratedPage = false;
    selectedCurrentMarketValues = [];
    selectedTargetMarketValues = [];
    gapAnalysisCheckbox = false;
    showCheckbox = false;
    selectedMarketValues = [];
    selectedProductValues = [];
    selectedMaterialValues = [];
    selectedAgeRangeValues = [];
    selectedRiskTypeValues =[];
    gapRecordId = [];
    existingRecordId = [];
    matchedRecordId = [];
    parentRecordId = [];
    testSize = 0;
    regulatoryResultsCount;
    recallCount;
    fromDate = null;
    toDate = null;
    titleOneSmall;
    titleTwoSmall;
    titleColor = 'titleColor';
    showSearchResults;
    searchButtonLabels;

    label = {
        gapAnalysisOrderGenerateLabel,
        readMore,
        loginMessage,
        insufficientTokenMessage,
        singleTokenMessage,
        multipleTokenMessage,
        noRegulationMessage,
        productPicklistLabel,
        marketPicklistLabel,
        materialPicklistLabel,
        ageGroupPicklistLabel,
        riskTypeLabel,
        currentMarketPicklistLabel,
        targetMarketPicklistLabel,
        runSearchAgainLabel,
        recallSummarySearchMessage,
        noRecallMessage,
        generateRecallSummaryLabel,
        gapAnalysisSearchMessage,
        noGapMessage,
        generateGapAnalysisLabel,
        generateReportMessage,
        downloadReportMessage,
        downloadLinkMessage1,
        downloadLinkMessage2,
        intertekAdminEmail,
        generateRecallReportMessage,
        generateTestPlanReportMessage,
        downloadRegulatoryReportMessage,
        downloadTestPlanReportMessage,
        downloadRecallReportMessage,
        mandatoryFieldExplanationLabel,
        myOrdersText,
        myOrdersButton,
        downloadButtonText
    };

    tokenCost;
    searchCost;

    subscription = null;
    @api showLoginModal = false;
    @api showOrderConfirmationModal = false;
    @wire(MessageContext)
    messageContext;
    availableToken = null;
    user = null;

    pastSearches = [];

    @wire(getMaxWaitSecondsForDownloads, {})
    maxWaitTime;

    orderId;
    @api downloadInProgress;
    @api downloadLink;
    searchId;

    @api pageHasLoaded = false;

    subscribeToMessageChannel() {
        if (!this.subscription) {
            this.subscription = subscribe(
                this.messageContext,
                msgChannel,
                (message) => this.handleMessage(message)
            );
        }
    }

    unsubscribeToMessageChannel() {
        unsubscribe(this.subscription);
        this.subscription = null;
    }

    async getUserData(userId){
        await  getUserData({userId:userId})
            .then((result) => {    
                this.user = result;
                this.availableToken = result.Contact.Account.GMA_Available_Tokens__c;
            })
            .catch(error => {
            });
    }

    renderSearchPage() {
        if (this.orderType!==null && this.orderType!==undefined && this.orderType.length>0) {
            if (this.orderType===ORDER_TYPE_REGULATORY) {
                this.openRegulatoryPage();
            } else if(this.orderType===ORDER_TYPE_TESTPLAN) {
                this.openTestPlanPage();
            } else if(this.orderType===ORDER_TYPE_RECALL) {
                this.openRecallPage();
            } else if(this.orderType===ORDER_TYPE_GAPANALYSIS) { 
                this.openGapAnalysisPage();
            }
        }

        if (sessionStorage.getItem(SESSION_STORAGE_KEY_HISTORY_RERUN)) {
            sessionStorage.removeItem(SESSION_STORAGE_KEY_HISTORY_RERUN);
            sessionStorage.removeItem(SESSION_STORAGE_KEY_ORDER_DATA);
        }
    }

    connectedCallback(){
        let currentOrderType = this.orderType;

        this.getSessionStorage();
        if (currentOrderType !=this.orderType) {
            //session storage is old, destroy it (it has data from different e-service search)
            this.resetPageVariables();
            this.orderType = currentOrderType;
            sessionStorage.removeItem(SESSION_STORAGE_KEY_ORDER_DATA);
            sessionStorage.removeItem(SESSION_STORAGE_KEY_TASK_LOGGED);
        }

        if (sessionStorage.getItem(SESSION_STORAGE_KEY_ORDER_DATA) && sessionStorage.getItem(SESSION_STORAGE_KEY_HISTORY_RERUN)) {
            this.renderSearchPage();
        } else if (!sessionStorage.getItem(SESSION_STORAGE_KEY_ORDER_DATA)) {
            this.renderSearchPage();
        }

        if(this.user == null ){
            this.getUserData(USER_ID);
        }
        
        this.subscribeToMessageChannel();
    }

    disconnectedCallback() {
        this.unsubscribeToMessageChannel();
    }

    openRegulatoryPage(event){
        this.showRegulatory = true;
        this.titleOneSmall = 'Regulatory';
        this.titleTwoSmall = 'Sheet';
        this.orderType = ORDER_TYPE_REGULATORY;
        this.searchButtonLabels = GENERATE_REGULATORY_TYPE_SHEET;
        if(this.user == null ){
            this.getUserData(USER_ID);
        }
    }

    openTestPlanPage(event){
        this.showRegulatory = true;
        this.titleOneSmall = 'Test';
        this.titleTwoSmall = 'Plan';
        this.orderType = ORDER_TYPE_TESTPLAN;          
        this.searchButtonLabels = GENERATE_TEST_PLAN;
        if(this.user == null ){
            this.getUserData(USER_ID);
        }
    }

    openRecallPage(){
        this.showRecall = true;
        this.orderType = ORDER_TYPE_RECALL;
        if(this.user == null ){
            this.getUserData(USER_ID);
        }
    }

    async openGapAnalysisPage(){
        this.orderType = ORDER_TYPE_GAPANALYSIS;
        this.showLoginMessage = false;
        if(this.user == null ){
            await this.getUserData(USER_ID);
        }
        if (!this.userIsLoggedIn()) {
            this.showLoginMessage = true;
        }else{
            this.showGapAnalysis = true;
            this.checkTokensAvailableToRunSearch();
        }
    }

    async getPastSearches() {
        this.orderType
    }

    userLogin(){
        this.showLoginModal = true;
    }

    handleMarketChange(event){
        this.selectedMarketValues = event.detail;
    }

    handleProductChange (event){
        this.selectedProductValues = event.detail;
    }

    handleMaterialChange (event){
        this.selectedMaterialValues = event.detail;
    }

    handleAgeRangeChange (event){   
        this.selectedAgeRangeValues = event.detail;
    }

    handleRiskTypeChange(event){
        this.selectedRiskTypeValues = event.detail;
    }

    handleCurrentMarketChange(event){
        this.selectedCurrentMarketValues = event.detail;
    }

    handleTargetMarketChange(event){
        this.gapAnalysisCheckbox = false;
        this.template.querySelector('[data-id="gapAnalysisCheckbox"]').checked = this.gapAnalysisCheckbox;
        this.selectedTargetMarketValues = event.detail;
        this.checkTokensAvailableToRunSearch();
    }

    handleDateChange(event){
        if(event.target.name =='From date'){
            this.fromDate = event.target.value;
        }
        if(event.target.name =='To date'){
            this.toDate = event.target.value;
        }
    }

    handleGapAnalysisCheckbox(event){
        if(event.target.checked){
            this.gapAnalysisCheckbox = true;
        }else{
            this.gapAnalysisCheckbox = false;
        }
    }
    inputNullCheck(){
        if(this.orderType == ORDER_TYPE_REGULATORY || this.orderType == ORDER_TYPE_TESTPLAN){
            if(this.selectedProductValues.length == 0 || this.selectedMarketValues.length == 0 || this.selectedAgeRangeValues.length == 0 ){
                this.dispatchEvent(
                    new ShowToastEvent({
                        message: gmaRequiredFields,
                        variant: "error"
                    })
                );
                return false;
            }else{
                if(this.selectedMaterialValues.length == 0){
                    this.selectedMaterialValues.push(ALL_VALUES);
                } 
                return true;
            }
        }
        if(this.orderType == ORDER_TYPE_RECALL){
            if(this.selectedProductValues.length == 0 || this.selectedMarketValues.length == 0 || this.toDate == null || this.fromDate == null){
                this.dispatchEvent(
                    new ShowToastEvent({
                        message: gmaRequiredFields,
                        variant: "error"
                    })
                );
                return false;
            }else{
                if(this.selectedRiskTypeValues.length == 0){
                    this.selectedRiskTypeValues.push(ALL_VALUES);
                } 
                return true;
            }
        }
        if(this.orderType == ORDER_TYPE_GAPANALYSIS){
            if(this.selectedProductValues.length == 0 || this.selectedAgeRangeValues.length == 0 
                || this.selectedCurrentMarketValues.length == 0 || this.selectedTargetMarketValues.length == 0 ){
                this.dispatchEvent(
                    new ShowToastEvent({
                        message: gmaRequiredFields,
                        variant: "error"
                    })
                );
                return false;
            }else{
                if(this.selectedMaterialValues.length == 0){
                    this.selectedMaterialValues.push(ALL_VALUES);
                } 
                return true;
            }
        }
    }

    forceSearchHistoryShowAsLoading() {
        publish(this.messageContext, msgChannel, {
            messageType: LOADING_HISTORY_MESSAGE
        });
    }

    forceSearchHistoryRefresh() {
        publish(this.messageContext, msgChannel, {
            messageType: REFRESH_HISTORY_MESSAGE
        });
    }

    async searchProduct(){
        if(this.inputNullCheck()){
            this.forceSearchHistoryShowAsLoading();
            this.showRegulatorySheet = true;
            this.showRegulatory = false;
            this.testSize = 0;
            this.regulatoryResultsCount = 0;
            this.parentRecordId =[];
            this.downloadInProgress = true;
            if(this.orderType == ORDER_TYPE_REGULATORY){
                this.titleColor = 'titleColor regulatoryTitleMargin';
            }
            if(this.orderType == ORDER_TYPE_TESTPLAN){
                this.titleColor = 'titleColor';
            }
            await searchProducts({productList: this.selectedProductValues, 
                            marketList: this.selectedMarketValues,
                            materialList:this.selectedMaterialValues, 
                            ageRangeList: this.selectedAgeRangeValues,
                            orderType: this.orderType})
            .then((result) => {
                this.forceSearchHistoryRefresh();
                for(var key in result.recordsMatched){
                    this.parentRecordId.push(key);
                }
                this.regulatoryResultsCount = this.parentRecordId.length;
                this.tokenCost = result.tokenCost;
                if (result.searchId!==null && result.searchId!=undefined) {
                    this.searchId = result.searchId;
                }
                this.setSessionStorage();
                this.downloadInProgress = false;
            })
            .catch(error => {
                this.downloadInProgress = false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        message: this.parseErrorMessage(error),
                        variant: "error"
                    })
                );
            });
        }
    }

    async searchRecall(){
        if(this.inputNullCheck()){
            this.forceSearchHistoryShowAsLoading();
            this.showRecallSummary = true;
            this.showRecall = false;
            this.recallCount = 0;
            this.recallId =[];
            this.downloadInProgress = true;
            await searchRecall({productList: this.selectedProductValues, 
                        marketList: this.selectedMarketValues, 
                        riskTypeList:this.selectedRiskTypeValues, 
                        toDate: this.toDate,
                        fromDate: this.fromDate})
            .then((result) => {
                this.forceSearchHistoryRefresh();
                for(var key in result.recordsMatched){
                    this.recallId.push(key);
                }
                this.recallCount = this.recallId.length;
                this.tokenCost = result.tokenCost;
                if (result.searchId!==null) {
                    this.searchId = result.searchId;
                }
                this.setSessionStorage();
                this.downloadInProgress = false;
            })
            .catch(error => {
                this.downloadInProgress = false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        message: this.parseErrorMessage(error),
                        variant: "error"
                    })
                );
            });
        }
    }

    async searchGapAnalysis(){
        if(this.inputNullCheck()){
            this.forceSearchHistoryShowAsLoading();
            this.gapCount = 0;
            this.gapRecordId =[];
            this.existingRecordId =[];
            this.matchedRecordId =[];
            this.downloadInProgress = true;
            this.showGapAnalysis = false;
            this.showGapAnalysisReport = true;
            await searchGap({productList: this.selectedProductValues, 
                currentMarketList: this.selectedCurrentMarketValues,
                targetMarketList: this.selectedTargetMarketValues,
                materialList:this.selectedMaterialValues, 
                ageRangeList: this.selectedAgeRangeValues,
                orderType: this.orderType})
            .then((result) => {
                this.forceSearchHistoryRefresh();
                for(var key in result.gapRecords){
                    this.gapRecordId.push(key);
                }
                for(var key in result.existingRecords){
                    this.existingRecordId.push(key);
                }
                for(var key in result.recordsMatched){
                    this.matchedRecordId.push(key);
                }
                this.gapCount = this.gapRecordId.length;
                this.tokenCost = result.tokenCost;
                if (result.searchId!==null) {
                    this.searchId = result.searchId;
                }
                this.setSessionStorage();
                this.downloadInProgress = false;
            })
            .catch(error => {
                this.downloadInProgress = false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        message: this.parseErrorMessage(error),
                        variant: "error"
                    })
                );
            });
        }
    }

    checkTokensAvailableToRunSearch(){
        getSearchTokenCost({targetMarketValues: this.selectedTargetMarketValues})
        .then((result) => {
            if (result !== undefined && result !== null) {
                this.pageHasLoaded = true;
                this.searchCost = result;
                this.showCheckbox = false;
                if (this.availableToken >= this.searchCost){
                    this.showCheckbox = true;
                }
            }
        })
        .catch((error) => {
            this.dispatchEvent(
                new ShowToastEvent({
                    message: error.body.message,
                    variant: "error"
                })
            );
        });
    }

    getSessionStorage() {
        if(sessionStorage.getItem(SESSION_STORAGE_KEY_ORDER_DATA)){
            let orderData = JSON.parse(sessionStorage.getItem(SESSION_STORAGE_KEY_ORDER_DATA));

            this.selectedCurrentMarketValues = orderData.selectedCurrentMarketValues;
            this.selectedTargetMarketValues = orderData.selectedTargetMarketValues;
            this.showGapAnalysis = orderData.showGapAnalysis;
            this.showGapAnalysisReport = orderData.showGapAnalysisReport;
            this.gapRecordId = orderData.gapRecordId;
            this.matchedRecordId = orderData.matchedRecordId;
            this.gapCount = orderData.gapCount;
            this.existingRecordId = orderData.existingRecordId;
            this.fromDate = orderData.fromDate;
            this.toDate = orderData.toDate;
            this.showSearchResults = orderData.showSearchResults;
            this.searchButtonLabels = orderData.searchButtonLabels;
            this.showOrderGeneratedPage = orderData.showOrderGeneratedPage;
            this.showGapAnalysisOrderGeneratedPage = orderData.showGapAnalysisOrderGeneratedPage;
            this.selectedRiskTypeValues = orderData.selectedRiskTypeValues;
            this.showRegulatory = orderData.showRegulatory;
            this.showRecall = orderData.showRecall;
            this.recallCount = orderData.recallCount;
            this.recallId = orderData.recallId;
            this.showRegulatorySheet = orderData.showRegulatorySheet;
            this.showRecallSummary = orderData.showRecallSummary;
            this.orderType = orderData.orderType;
            this.selectedMarketValues = orderData.selectedMarketValues;
            this.selectedProductValues = orderData.selectedProductValues;
            this.selectedMaterialValues = orderData.selectedMaterialValues;
            this.selectedAgeRangeValues = orderData.selectedAgeRangeValues;
            this.parentRecordId = orderData.parentRecordId;
            this.regulatoryResultsCount = orderData.regulatoryResultsCount;
            this.tokenCost = orderData.tokenCost;
            this.searchId = orderData.searchId;

            if (sessionStorage.getItem(SESSION_STORAGE_KEY_LOGIN_OK)) {
                this.downloadInProgress = true;
                this.showOrderConfirmationModal = true;
                sessionStorage.removeItem(SESSION_STORAGE_KEY_LOGIN_OK);
                this.createSearchRecord();
            }
        } else {
            this.resetPageVariables();
        }
    }

    resetPageVariables() {
        this.showRegulatory = false;
        this.showRegulatorySheet = false;
        this.tokenCost = null;
        this.searchCost = null;
        this.showRecall = false; 
        this.showRecallSummary = false; 
        this.showOrderGeneratedPage = false;
        this.showGapAnalysisOrderGeneratedPage = false;
        this.showGapAnalysis = false;
        this.showLoginMessage = false;
        this.searchId = '';
        this.selectedMarketValues = [];
        this.selectedCurrentMarketValues = [];
        this.selectedTargetMarketValues = [];
        this.selectedProductValues = [];
        this.selectedMaterialValues = [];
        this.selectedAgeRangeValues = [];
        this.selectedRiskTypeValues = [];
        this.showGapAnalysisReport = false;
    }

    setSessionStorage() {
        let orderData = {
            showGapAnalysis: this.showGapAnalysis,
            showGapAnalysisReport: this.showGapAnalysisReport,
            selectedCurrentMarketValues : this.selectedCurrentMarketValues,
            selectedTargetMarketValues : this.selectedTargetMarketValues,
            gapRecordId : this.gapRecordId,
            existingRecordId : this.existingRecordId,
            matchedRecordId : this.matchedRecordId,
            gapCount: this.gapCount,
            fromDate: this.fromDate,
            toDate: this.toDate,
            showOrderGeneratedPage : this.showOrderGeneratedPage,
            showGapAnalysisOrderGeneratedPage: this.showGapAnalysisOrderGeneratedPage,
            showSearchResults : this.showSearchResults,
            searchButtonLabels : this.searchButtonLabels,
            showRegulatory: this.showRegulatory,
            showRecall: this.showRecall,
            recallCount: this.recallCount,
            recallId: this.recallId,
            selectedRiskTypeValues: this.selectedRiskTypeValues,
            showRegulatorySheet: this.showRegulatorySheet,
            showRecallSummary: this.showRecallSummary,
            orderType: this.orderType,
            selectedMarketValues: this.selectedMarketValues,
            selectedProductValues: this.selectedProductValues,
            selectedMaterialValues: this.selectedMaterialValues,
            selectedAgeRangeValues: this.selectedAgeRangeValues,
            parentRecordId: this.parentRecordId,
            regulatoryResultsCount: this.regulatoryResultsCount,
            tokenCost: this.tokenCost,
            searchId: this.searchId
        };
        sessionStorage.setItem(SESSION_STORAGE_KEY_ORDER_DATA, JSON.stringify(orderData));
    }

    handleConfirmButtonClick() {
        if (this.userIsLoggedIn() && sessionStorage.getItem(SESSION_STORAGE_KEY_ORDER_DATA)) {
            this.showOrderConfirmationModal = true;
            this.downloadInProgress = true;
            if (!sessionStorage.getItem(SESSION_STORAGE_KEY_TASK_LOGGED)) {
                this.publishPlatformEvent(this.searchId, PLATFORM_EVENT_MESSAGE_ORDER_PROCEED, this.tokenCost);
                sessionStorage.setItem(SESSION_STORAGE_KEY_TASK_LOGGED, 1); 
            }
        } else if (!this.userIsLoggedIn()) {
            this.showLoginModal = true;
            this.downloadInProgress = true;
        }
    }

    handleResetButtonClick() {
        sessionStorage.removeItem(SESSION_STORAGE_KEY_ORDER_DATA);
        sessionStorage.removeItem(SESSION_STORAGE_KEY_TASK_LOGGED);
        this.getSessionStorage();
        this.renderSearchPage();
    }

    async createSearchRecord() {
        //needed only if user just completed login flow (after searching)
        //if user was already logged in when doing search, search history would be logged already
        await createSearchRecord({parentRecordId: this.parentRecordId, orderType: this.orderType,
                                selectedMarketValues : this.selectedMarketValues,
                                selectedProductValues: this.selectedProductValues,
                                selectedMaterialValues: this.selectedMaterialValues,
                                selectedAgeRangeValues: this.selectedAgeRangeValues,
                                selectedRiskTypeValues: this.selectedRiskTypeValues,
                                fromDate: this.fromDate,
                                toDate: this.toDate})
        .then((result) => {
            this.searchId = result;
            if (!sessionStorage.getItem(SESSION_STORAGE_KEY_TASK_LOGGED)) {
                this.publishPlatformEvent(this.searchId, PLATFORM_EVENT_MESSAGE_ORDER_PROCEED, this.tokenCost);
                sessionStorage.setItem(SESSION_STORAGE_KEY_TASK_LOGGED, 1); 
            }
        })
        .catch(error => {
            this.dispatchEvent(
                new ShowToastEvent({
                    message: this.parseErrorMessage(error),
                    variant: "error"
                })
            );
        });
    }

	async createRegulatoryOrder(){
        await createRegulatorySheetOrder({parentRecordId: this.parentRecordId, orderType: this.orderType,
                            selectedMarketValues : this.selectedMarketValues,
                            selectedProductValues: this.selectedProductValues,
                            selectedMaterialValues: this.selectedMaterialValues,
                            selectedAgeRangeValues: this.selectedAgeRangeValues})
        .then((result) => {
            sessionStorage.removeItem(SESSION_STORAGE_KEY_ORDER_DATA);
            sessionStorage.removeItem(SESSION_STORAGE_KEY_TASK_LOGGED);
            this.showRegulatorySheet = false;
            this.showOrderGeneratedPage = true;
            this.orderId = result;
            this.startDownloadWait();
        })
        .catch(error => {
            this.dispatchEvent(
                new ShowToastEvent({
                    message: this.parseErrorMessage(error),
                    variant: "error"
                })
            );
        });
    }

    async createRecallOrder(){
        await createRecallSummaryOrder({recallIdValues: this.recallId, orderType: this.orderType,
                            selectedMarketValues : this.selectedMarketValues,
                            selectedProductValues: this.selectedProductValues,
                            riskTypeValues: this.selectedRiskTypeValues,
                            toDate: this.toDate,
                            fromDate: this.fromDate})
        .then((result) => {
            sessionStorage.removeItem(SESSION_STORAGE_KEY_ORDER_DATA);
            sessionStorage.removeItem(SESSION_STORAGE_KEY_TASK_LOGGED);
            this.showOrderGeneratedPage = true;
            this.showRecallSummary = false;
            this.orderId = result;
            this.startDownloadWait();
        })
        .catch(error => {
            this.dispatchEvent(
                new ShowToastEvent({
                    message: this.parseErrorMessage(error),
                    variant: "error"
                })
            );
        });
    }

    async createGapAnalysisOrder(){
        await createGapAnalysisOrder({existingRecordId: this.existingRecordId, 
                                    gapRecordId: this.gapRecordId,
                                    matchedRecordId: this.matchedRecordId,
                                    orderType: this.orderType,
                                    selectedcurrentMarketValues : this.selectedCurrentMarketValues,
                                    selectedTargetMarketValues : this.selectedTargetMarketValues,
                                    selectedProductValues: this.selectedProductValues,
                                    selectedMaterialValues: this.selectedMaterialValues,
                                    selectedAgeRangeValues: this.selectedAgeRangeValues})
        .then((result) => {
            sessionStorage.removeItem(SESSION_STORAGE_KEY_ORDER_DATA);
            sessionStorage.removeItem(SESSION_STORAGE_KEY_TASK_LOGGED);
            this.showGapAnalysisReport = false;
            this.showGapAnalysisOrderGeneratedPage = true;
            this.orderId = result;
            this.startDownloadWait();
        })
        .catch(error => {
            this.dispatchEvent(
                new ShowToastEvent({
                    message: this.parseErrorMessage(error),
                    variant: "error"
                })
            );
        });
    }

    async publishPlatformEvent(recordId, message, amount) {
        await publishPlatformEvent({recordId: recordId, message: message, amount: amount})
        .then((result) => {

        })
        .catch(error => {
            this.dispatchEvent(
                new ShowToastEvent({
                    message: this.parseErrorMessage(error),
                    variant: "error"
                })
            );
        });
    }

    handleMessage(message) {
        let isOrderActionFromModal = (message.messageType===MESSAGE_TYPE_CANCEL_ORDER || message.messageType===MESSAGE_TYPE_OK_ORDER);
        let isLoginActionFromModal = (message.messageType===MESSAGE_TYPE_ABORT_LOGIN || message.messageType===MESSAGE_TYPE_OK_LOGIN);
        if (isLoginActionFromModal) {
            this.showLoginModal = false;
            if (message.messageType===MESSAGE_TYPE_OK_LOGIN) {
                sessionStorage.setItem(SESSION_STORAGE_KEY_LOGIN_OK, true);
                window.location.replace(message.payload.redirectUrl); //redirecting to complete login procedure
            } else {
                this.downloadInProgress = false;
            }
        } else if (isOrderActionFromModal) {
            this.downloadInProgress = false;
            this.showOrderConfirmationModal = false;
            if (message.messageType===MESSAGE_TYPE_OK_ORDER) {
                if(this.orderType == ORDER_TYPE_REGULATORY || this.orderType == ORDER_TYPE_TESTPLAN){
                    this.createRegulatoryOrder();
                }
                if(this.orderType == ORDER_TYPE_RECALL){
                    this.createRecallOrder();
                }
                if(this.orderType == ORDER_TYPE_GAPANALYSIS){
                    this.createGapAnalysisOrder();
                }
            }
        }
    }

    startDownloadWait() {
        this.downloadInProgress = true;
        let interval = 3000;
        let counter = 0;
        let maxWaitTime = (this.maxWaitTime.data * 1000);
        let parent = this;
        let downloadIntervalInstance = setInterval(function() {
            retrieveOrderDocument({orderId: parent.orderId})
            .then((result) => {
                if (result!==null) {
                    parent.downloadInProgress = false;
                    parent.downloadLink = result;
                    clearInterval(downloadIntervalInstance);
                }
            });
            counter += interval;
            if (counter > maxWaitTime) {
                 parent.downloadInProgress = false;
                clearInterval(downloadIntervalInstance);
            }
        }, interval);
    }

    userIsLoggedIn() {
        return (getFieldValue(this.user, CONTACT_ID)!=undefined && getFieldValue(this.user, CONTACT_ID)!==null);
    }

    get loginAbortMessage() {
        return MESSAGE_TYPE_ABORT_LOGIN;
    }

    get loginOkMessage() {
        return MESSAGE_TYPE_OK_LOGIN;
    }

    get orderAbortMessage() {
        return MESSAGE_TYPE_CANCEL_ORDER;
    }

    get orderOkMessage() {
        return MESSAGE_TYPE_OK_ORDER;
    }

    get renderRegulatoryReportView() {
        return this.orderType == ORDER_TYPE_REGULATORY;
    }

    get renderTestPlanView() {
        return this.orderType == ORDER_TYPE_TESTPLAN;
    }

    get renderRecallReportView() {
        return this.orderType == ORDER_TYPE_RECALL;
    }

    get renderGapAnalysisView() {
        return this.orderType == ORDER_TYPE_GAPANALYSIS;
    }

    get noRegulationsFound() {
        return this.regulatoryResultsCount<1 || this.regulatoryResultsCount==null || this.tokenCost==null;
    }

    get noRecallsFound() {
        return this.recallCount<1 || this.recallCount==null || this.tokenCost==null;
    }

    get noGapsFound() {
        return this.gapCount<1 || this.gapCount==null || this.tokenCost==null;
    }

    get searchCostIsSingleToken() {
        return this.searchCost===1;
    }

    get gapAnalysisSearchConfirmationMessage() {
        let msg = gapAnalysisConfirmationMessage;
        let tokenCount = this.searchCost + ' token' + (this.searchCost===1 ? '' : 's');
        msg = msg.replace(GAPANALYSIS_CONFIRM_TOKEN_PLACEHOLDER, tokenCount);
        return msg;
    }

    get showSearchHistory() {
        return this.showRegulatory || this.showRecall || this.showGapAnalysis
             || this.showRegulatorySheet || this.showRecallSummary || this.showGapAnalysisReport;
    }

    parseErrorMessage (error) {
        console.log(JSON.stringify(error));
        if (typeof error === 'object') {
        //LWC and Apex errors are objects
            if ('body' in error) {
                if ('message' in error.body) {
                    //Apex errors follow this pattern
                    return error.body.message;
                } else if('pageErrors' in error.body) {
                    return error.body.pageErrors[0].message;
                } else {
                    return JSON.stringify(error.body);
                }
            } else if (error.constructor.name === 'ReferenceError') {
                //Javascript errors
                return error.message;
            } else {
                return JSON.stringify(error);
            }
        } else {
            return error;
        }
    }

    get todayDateForDatePicker() {
        let today = new Date();
        let monthNo = (today.getMonth()+1<10 ? '0' + (today.getMonth()+1) : today.getMonth()+1);
        let dayNo = (today.getDate()<10 ? '0' + today.getDate() : today.getDate());
        let todayAsString = today.getFullYear() + '-' + monthNo + '-' + dayNo + 'T00:00:00';
        return todayAsString;
    }

    get mailtoLinkForReportQueries() {
        return 'mailto:' + this.label.intertekAdminEmail;
    }

    openMyOrdersPage(event) {
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: 'my_orders__c',
            },
        });
    }
}