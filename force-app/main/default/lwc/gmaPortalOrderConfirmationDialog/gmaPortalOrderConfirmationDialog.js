import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { publish, MessageContext } from "lightning/messageService";
import msgChannel from "@salesforce/messageChannel/GMAPortalMessageChannel__c";
import getCurrentUser from '@salesforce/apex/GmaPortalHelper.getCurrentUser';
import tokenDeductionMessage from '@salesforce/label/c.Token_Deduction_Message';
import tokenNotAvailableMessage from '@salesforce/label/c.Token_Deduction_Message_Insufficient';
import authFailedMessage from '@salesforce/label/c.GMA_User_Authentication_Error';

const REPORT_COST_TOKEN_PLACEHOLDER = '[[tokenCount]]';
const AVAILABLE_TOKEN_PLACEHOLDER = '[[tokensAvailable]]';

export default class GmaPortalOrderConfirmationDialog extends LightningElement {
    @api showModal = false;
    @api sucessMessageType;
    @api abortMessageType;
    @api tokensRequired;
    tokensAvailable = 0;

    @wire(MessageContext)
    messageContext;

    label = {
        tokenDeductionMessage,
        tokenNotAvailableMessage
    };

    @api hasLoaded = false;
    dialogIsShown = false;

    loadDialog() {
        if (this.showModal && !this.dialogIsShown) {
            this.dialogIsShown = true;
            this.hasLoaded = false;
            getCurrentUser({})
            .then((result) => {
                if (result.Contact !== undefined && result.Contact !== null) {
                    this.tokensAvailable = result.Contact.Account.GMA_Available_Tokens__c;
                    this.hasLoaded = true;
                    this.updateLabelsForMessages();
                } else {
                    //user not logged in or not community user; set pause (to avoid rapid flickering) to hide dialog and show error
                    this.dialogIsShown = false;
                    setTimeout(function() {
                        this.dispatchEvent(
                            new ShowToastEvent({
                                message: authFailedMessage,
                                variant: "error"
                            })
                        );
                        publish(this.messageContext, msgChannel, {
                            messageType: this.abortMessageType
                        });
                      }.bind(this), 2000);
                }
            })
            .catch((error) => {
                this.hasLoaded = true;
                this.dispatchEvent(
                    new ShowToastEvent({
                        message: error.body.message,
                        variant: "error"
                    })
                );
            });
        }
    }

    updateLabelsForMessages() {
        this.label.tokenDeductionMessage = this.label.tokenDeductionMessage.replace(REPORT_COST_TOKEN_PLACEHOLDER, this.tokensRequired).replace(AVAILABLE_TOKEN_PLACEHOLDER, this.tokensAvailable);
        this.label.tokenNotAvailableMessage = this.label.tokenNotAvailableMessage.replace(REPORT_COST_TOKEN_PLACEHOLDER, this.tokensRequired).replace(AVAILABLE_TOKEN_PLACEHOLDER, this.tokensAvailable);
    }

    renderedCallback() {
        this.loadDialog();
    }

    checkEnoughTokens() {
        return (this.tokensAvailable >= this.tokensRequired);
    }

    handleOkClick(event) {
        if (this.checkEnoughTokens()) {
            publish(this.messageContext, msgChannel, {
                messageType: this.sucessMessageType
            });
        }
        this.dialogIsShown = false;
    }

    handleCancelClick(event) {       
        publish(this.messageContext, msgChannel, {
            messageType: this.abortMessageType
        });
        this.dialogIsShown = false;
        //this.showModal = false; //recipient of the message should decide to close modal or not
    }

    get proceedButtonUnavailable() {
        return !this.checkEnoughTokens(); 
    }
}