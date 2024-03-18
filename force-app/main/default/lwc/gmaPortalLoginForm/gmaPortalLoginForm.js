import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { publish, MessageContext } from "lightning/messageService";
import msgChannel from "@salesforce/messageChannel/GMAPortalMessageChannel__c";
import portalLogin from '@salesforce/apex/GmaPortalHelper.portalLogin';
import COMMUNITY_LOGO from '@salesforce/contentAssetUrl/LoginBanner';

export default class GmaPortalLoginForm extends LightningElement {
    username;
    password;

    communityLogo = COMMUNITY_LOGO;

    @api showModal = false;
    @api sucessMessageType;
    @api abortMessageType;
    
    @wire(MessageContext)
    messageContext;

    handleUserNameChange(event) {
        this.username = event.target.value;
    }

    handlePasswordChange(event) {
        this.password = event.target.value;
        //trigger login button click if Enter is pressed on password input
        if(event.keyCode === 13){
            this.handleLogin();
        }
    }

    handleLogin(event) {
        if(this.username && this.password){
    
            portalLogin({ username: this.username, password: this.password, retUrl: window.location.href })
            .then((result) => {
                const jsonMsg = {
                    redirectUrl: result
                };
                publish(this.messageContext, msgChannel, {
                    messageType: this.sucessMessageType,
                    payload: jsonMsg
                });
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
    }

    handleCancelClick(event) {       
        publish(this.messageContext, msgChannel, {
            messageType: this.abortMessageType
        });
         //this.showModal = false; //recipient of the message should decide to close modal or not
    }
}