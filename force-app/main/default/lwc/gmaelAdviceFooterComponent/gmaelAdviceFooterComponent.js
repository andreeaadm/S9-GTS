import { LightningElement, api } from 'lwc';
import IntertekGmaelImages from '@salesforce/resourceUrl/intertek_gmael_images';
import PARAGRAPH from '@salesforce/label/c.GMAEL_Footer_Grey_Component_Text';


export default class GmaelAdviceFooterComponent extends LightningElement {

    customLabel = {
        PARAGRAPH,
    };

    IntertekRoundelOrange = IntertekGmaelImages + '/IntertekRoundelOrange.png';
    AdviceFooterImg = IntertekGmaelImages + '/adviceFooterImg.png';
    IntertekStrap = IntertekGmaelImages + '/IntertekStrapImg.svg';
    clientBrowserGeoCountry;
    clientBrowserGeoCountryPhone;

    geolocationVFURL = '/gmael/apex/GMAEL_GelocationPhoneNumber';

    @api link1;
    @api link2;
    @api link3;
    @api link4;
    @api link5;

    connectedCallback() {

//         var openModalBtn = document.querySelector('#openModalBtn');
//         var closeModalBtn = document.querySelector('#closeModalBtn');
//         var modalContainer = document.querySelector('#modalContainer');

//         // Abrir el modal
//         openModalBtn.addEventListener('click', function () {
// /*             modalContainer.style.display = 'block'; */
//             alert("holaaaa");
//         });

//         // Cerrar el modal
//         closeModalBtn.addEventListener('click', function () {
//             modalContainer.style.display = 'none';
//         });

// /*         // Cerrar el modal si se hace clic fuera de él
//         window.addEventListener('click', function (event) {
//             if (event.target === modalContainer) {
//             modalContainer.style.display = 'none';
//             }
//         }); */

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