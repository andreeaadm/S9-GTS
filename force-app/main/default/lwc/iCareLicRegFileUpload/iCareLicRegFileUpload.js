import { LightningElement, api } from 'lwc';
import VehicleDetails from '@salesforce/resourceUrl/VehicleDetails';
import CosmeticsAndPerfumeryProductDetails from '@salesforce/resourceUrl/CosmeticsAndPerfumeryProductDetails';
import GeneralAndFoodProductDetails from '@salesforce/resourceUrl/GeneralAndFoodProductDetails';
import VehicleDetails_LicReg from '@salesforce/resourceUrl/VehicleDetails_LicReg';
import GeneralProductDetails_LicReg from '@salesforce/resourceUrl/GeneralProductDetails_LicReg';
import Product_Details_Title from '@salesforce/label/c.Product_Details_Title';
import Product_Details_Sub_Title from '@salesforce/label/c.Product_Details_Sub_Title';

import GTS_GeneralAndFoodProductDetailsLabel from '@salesforce/label/c.GTS_GeneralAndFoodProductDetailsLabel';
import GTS_CosmeticsAndPerfumeryProductDetailsLabel from '@salesforce/label/c.GTS_CosmeticsAndPerfumeryProductDetailsLabel';
import GTS_VehicleDetailsLabel from '@salesforce/label/c.GTS_VehicleDetailsLabel';
import GTS_VehicleDetails_LicRegLabel from '@salesforce/label/c.GTS_VehicleDetails_LicRegLabel';
import GTS_GeneralProductDetails_LicRegLabel from '@salesforce/label/c.GTS_GeneralProductDetails_LicRegLabel';

export default class ICareLicRegFileUpload extends LightningElement {
    @api formName = "REGISTRATION";
    @api isReadOnly = false;
    isCOCForm = false;
    @api contentVersionIds;

    vehicleDetailsSheet = VehicleDetails;
    cosmeticsAndPerfumeryProductDetailsSheet = CosmeticsAndPerfumeryProductDetails;
    generalAndFoodProductDetailsSheet = GeneralAndFoodProductDetails;
    GeneralProductDetails_LicRegSheet = GeneralProductDetails_LicReg;
    VehicleDetails_LicRegSheet = VehicleDetails_LicReg;

    labels = {  Product_Details_Title, 
                Product_Details_Sub_Title, 
                GTS_GeneralAndFoodProductDetailsLabel, 
                GTS_CosmeticsAndPerfumeryProductDetailsLabel,
                GTS_VehicleDetailsLabel,
                GTS_VehicleDetails_LicRegLabel,
                GTS_GeneralProductDetails_LicRegLabel
            };

    connectedCallback(){
        if(this.formName === "COC"){
            this.isCOCForm = true;
        }else{
            this.isCOCForm = false;
        }
    }

    handleDocumentUpload(event){
        console.log('documentUpload : ',event.detail);
        this.dispatchEvent(new CustomEvent('documentupload', {detail : event.detail}));
    }
}