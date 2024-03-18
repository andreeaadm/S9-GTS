import { LightningElement, api } from 'lwc';
import FORM_FACTOR from '@salesforce/client/formFactor';
import getCurrentUser from '@salesforce/apex/GmaPortalHelper.getCurrentUser';

//STATIC RESOURCES
import regulatorySheetLogo from '@salesforce/contentAssetUrl/GMA_Icon_Regulatory_Sheet'; 
import testPlanLogo from '@salesforce/contentAssetUrl/GMA_Icon_Test_Plan'; 
import gapAnalysisLogo from '@salesforce/contentAssetUrl/GMA_Icon_Gap_Analysis'; 
import recallSummaryLogo from '@salesforce/contentAssetUrl/GMA_Icon_Recall_Summary'; 
import regulatorySheetLabel from '@salesforce/label/c.GMA_RegulatorySheetLabel';
import testPlanLabel from '@salesforce/label/c.GMA_TestPlanLabel';
import gapAnalysisLabel from '@salesforce/label/c.GMA_GapAnalysisLabel';
import recallSummaryLabel from '@salesforce/label/c.GMA_RecallSummaryLabel';
import introductionMessage1 from '@salesforce/label/c.GMA_Introduction_Message1';
import introductionMessage2 from '@salesforce/label/c.GMA_Introduction_Message2';


export default class GmaEservicesSelector extends LightningElement {
    @api regulatoryForUser;
    @api regulatoryForGuest;

    @api testplanForUser;
    @api testplanForGuest;

    @api recallForUser;
    @api recallForGuest;

    @api gapanalysisForUser;
    @api gapanalysisForGuest;

    parentWrapperClass = "";
    columnWrapperClass = "";
    imageWrapperClass = "";

    logo = {
        regulatorySheetLogo,
        testPlanLogo,
        gapAnalysisLogo,
        recallSummaryLogo
    };
    label = {
        regulatorySheetLabel,
        testPlanLabel,
        gapAnalysisLabel,
        recallSummaryLabel,
        introductionMessage1,
        introductionMessage2
    };

    isLoggedInUser = false;

    connectedCallback(){
        getCurrentUser({})
        .then((result) => {
            if (result.Contact !== undefined && result.Contact !== null) {
                this.isLoggedInUser = true;
            }
        })
        .catch((error) => {

        });
        
        if(FORM_FACTOR && FORM_FACTOR=="Small"){
            this.parentWrapperClass = "slds-grid slds-grid_vertical slds-p-top_small";
            this.columnWrapperClass = "slds-col slds-p-bottom_xx-large";
            this.imageWrapperClass = "slds-media__figure regulatoryImageWrapper hyperlinkedImage slds-p-horizontal_xx-large";
        }else{
            this.parentWrapperClass = "slds-grid slds-wrap slds-p-top_small";
            this.columnWrapperClass = "slds-col slds-size_1-of-4 slds-p-horizontal_medium";    
            this.imageWrapperClass = "slds-media__figure regulatoryImageWrapper hyperlinkedImage";
        }
    }

    openRegulatoryPage(event) {
        const pageToShow = (this.isLoggedInUser ? this.regulatoryForUser : this.regulatoryForGuest);
        window.open(pageToShow, '_self');
    }

    openTestPlanPage(event) {
        const pageToShow = (this.isLoggedInUser ? this.testplanForUser : this.testplanForGuest);
        window.open(pageToShow, '_self');
    }

    openRecallPage(event) {
        const pageToShow = (this.isLoggedInUser ? this.recallForUser : this.recallForGuest);
        window.open(pageToShow, '_self');
    }

    openGapAnalysisPage(event) {
        const pageToShow = (this.isLoggedInUser ? this.gapanalysisForUser : this.gapanalysisForGuest);
        window.open(pageToShow, '_self');
    }
}