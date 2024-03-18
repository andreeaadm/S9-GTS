import { LightningElement, api } from 'lwc';

export default class GmaelCardNumber extends LightningElement {
    
    @api question;
    @api phone;
    @api paragraph;
    @api button;

    clientBrowserGeoCountry;
    clientBrowserGeoCountryPhone;
    
    geolocationVFURL = '/gmael/apex/GMAEL_GelocationPhoneNumber';

    connectedCallback() {
        window.addEventListener("message", (message) => {
            //handle the message
            if (message.data.name == "EmbedVflwc") {
                this.clientBrowserGeoCountryPhone = message.data.countryPhone;
                this.clientBrowserGeoCountry = message.data.countryName;
            }
        });
    }
    get telephone() {
        return `tel:${this.clientBrowserGeoCountryPhone}`;
    }
    handleSendRequest() {
        this.refs.sendARequestModel.handleShowModel();
    }
}