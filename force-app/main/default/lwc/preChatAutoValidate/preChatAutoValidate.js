import { LightningElement, api, track } from 'lwc';
import BasePrechat from 'lightningsnapin/basePrechat';
 

export default class PreChatAutoValidate extends BasePrechat {
    @api prechatFields; //Variable that automatically stores the info related to prechat fields.
    
    @track fields;
    /**
     * Method that runs when this prechat component is added to the DOM.
     */

    /* passesundefined?
    connectedCallback() {
       
        this.autostartChat();
    }
    */
    handleStartChat() {
        this.autostartChat();
    }
  
    /**
     * Method that checks if all the inputs are valid in prechat fields and autostarts the chat.
     */
    autostartChat() {

        if (this.validateFields(this.prechatFields).valid) {
            console.log('starting chat');
            console.log(this.prechatfields);
            this.startChat(this.prechatFields);

        } else {
            // Error handling if fields do not pass validation.
            HTMLFormControlsCollection.log('error');
        }

    }
}