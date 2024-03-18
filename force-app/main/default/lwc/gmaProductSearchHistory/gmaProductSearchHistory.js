import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from "lightning/navigation";
import { subscribe, unsubscribe, MessageContext } from "lightning/messageService";
import msgChannel from "@salesforce/messageChannel/GMAPortalMessageChannel__c";
import TIMESTAMP_COLUMN_LABEL from '@salesforce/label/c.GMA_Timestamp';

import getPastSearches from '@salesforce/apex/GMAHLSLProductSearchController.getPastSearches';

const ORDER_TYPE_REGULATORY = 'Regulatory Sheet';
const ORDER_TYPE_TESTPLAN = 'Test Plan';
const ORDER_TYPE_RECALL = 'Recall Summary';
const ORDER_TYPE_GAPANALYSIS = 'Gap Analysis';
const SESSION_STORAGE_KEY_ORDER_DATA = 'orderData';
const SESSION_STORAGE_KEY_HISTORY_RERUN = 'rerunSearch';
const ALL_VALUES = 'ALL';
const LOADING_HISTORY_MESSAGE = 'historyLoading';
const REFRESH_HISTORY_MESSAGE = 'historyRefresh';

export default class GmaProductSearchHistory extends NavigationMixin(LightningElement) {
    subscription = null;
    @wire(MessageContext)
    messageContext;

    @api orderType;
    pastSearches = [];
    loading = true;

    connectedCallback() {
        this.subscribeToMessageChannel();
        this.loadPastSearches();
    }

    disconnectedCallback() {
        this.unsubscribeToMessageChannel();
    }

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

    handleMessage(message) {
        if (message.messageType===REFRESH_HISTORY_MESSAGE) {
            this.loading = true;
            this.loadPastSearches();
        } else if (message.messageType===LOADING_HISTORY_MESSAGE) {
            this.loading = true;
        }
    }

    async loadPastSearches() {
        await  getPastSearches({orderType : this.orderType})
        .then((result) => {    
            this.pastSearches = result;
            this.loading = false;
        })
        .catch(error => {
            console.log(error);
        });
    }

    rerunSearch(event) {
        this.loading = true;
        let whichPage = (this.isTestPlan() ? '/test-plan' : '');
        whichPage = (this.isRegulatory() ? '/regulatory-sheet' : whichPage);
        whichPage = (this.isRecall() ? '/recall-summary' : whichPage);
        whichPage = (this.isGapAnalysis() ? '/gap-analysis-report' : whichPage);

        let searchId = event.currentTarget.dataset.id;
        let searchData = this.pastSearches.find(x => x.key === searchId);

        let orderData = {
            selectedCurrentMarketValues : (this.isGapAnalysis() ? searchData.marketList : []),
            selectedTargetMarketValues : (this.isGapAnalysis() ? searchData.targetMarketList : []),
            fromDate: (this.isRecall() ? searchData.fromDate : ''),
            toDate: (this.isRecall() ? searchData.toDate : ''),
            selectedRiskTypeValues: (this.isRecall() ? searchData.riskTypeList : []),
            orderType: this.orderType,
            selectedMarketValues: (!this.isGapAnalysis() ? searchData.marketList : []),
            selectedProductValues: searchData.productList,
            selectedMaterialValues: (!this.isRecall() ? searchData.materialList : []),
            selectedAgeRangeValues: (!this.isRecall() ? searchData.ageRangeList : [])
        };

        orderData.selectedRiskTypeValues = (orderData.selectedRiskTypeValues.length==1 && orderData.selectedRiskTypeValues[0]===ALL_VALUES ? [] : orderData.selectedRiskTypeValues);
        orderData.selectedMaterialValues = (orderData.selectedMaterialValues.length==1 && orderData.selectedMaterialValues[0]===ALL_VALUES ? [] : orderData.selectedMaterialValues);

        sessionStorage.setItem(SESSION_STORAGE_KEY_ORDER_DATA, JSON.stringify(orderData));
        sessionStorage.setItem(SESSION_STORAGE_KEY_HISTORY_RERUN, true);

        this[NavigationMixin.Navigate]({
            type: "standard__webPage",
            attributes: {
                url: whichPage
            }
        });
    }

    isRegulatory() {
        return this.orderType == ORDER_TYPE_REGULATORY;
    }

    isRecall() {
        return this.orderType == ORDER_TYPE_RECALL;
    }

    isTestPlan() {
        return this.orderType == ORDER_TYPE_TESTPLAN;
    }

    isGapAnalysis() {
        return this.orderType == ORDER_TYPE_GAPANALYSIS;
    }

    get hasPastSearches() {
        return this.pastSearches.length>0;
    }

    get renderRegulatoryReportView() {
        return this.isRegulatory();
    }

    get renderTestPlanView() {
        return this.isTestPlan();
    }

    get renderRecallReportView() {
        return this.isRecall();
    }

    get renderGapAnalysisView() {
        return this.isGapAnalysis();
    }

    get timestampColumnNme() {
        return TIMESTAMP_COLUMN_LABEL;
    }
}