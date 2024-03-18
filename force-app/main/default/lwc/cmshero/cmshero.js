import { LightningElement, api, track, wire } from 'lwc';
import getSingleItem from '@salesforce/apex/CMSController.getSingleItem';

export default class Cmshero extends LightningElement {
    @api managedContentType = 'Hero';
    @api contentKey;
    @api titleColour = 'rgb(47, 46, 46)';
    @api subTitleColour = 'rgb(47, 46, 46)';
    @api bodyColour = 'rgb(47, 46, 46)';
    @api buttonLabelColour = 'rgb(47, 46, 46)';
    @api buttonBorderColour = 'rgb(47, 46, 46)';
    @api buttonVariant = 'btn1';
    @api backgroundOverlayColour = "rgb(32, 165, 199)";
    @api backgroundColour = "rgba(255, 255, 255, 0)";
    @api backgroundColourContent = "rgb(32, 165, 199)";
    @api bgSize = "100% auto";
    @api heroContentWidth = "1180px";
    @api heroMinHeight = "380px";
    @api colOrRowContents = "row";
    @api alignContentsV = false;
    @api alignContentsH = false;
    @api reverseContents = false;
    @api additionalClasses = "hero bg-v title-separator";
    @api disableLinkify = false;
    @api showTitle;
    @track data;
    @track error;

    @wire(getSingleItem, { contentKey : '$contentKey', managedContentType : '$managedContentType' })
    wiredContent({ error, data }) {
        if (data) {
            let tempData = JSON.parse(JSON.stringify(data.items[0]));
            if(!tempData.contentNodes.Image) {
                tempData.contentNodes.Image = { 'url' : '' };
            }
            if(!tempData.contentNodes.Icon) {
                tempData.contentNodes.Icon = { 'url' : '' };
            }
            if(!tempData.contentNodes.Additional_Icon_1) {
                tempData.contentNodes.Additional_Icon_1 = { 'url' : '' };
            }
            if(!tempData.contentNodes.Additional_Icon_2) {
                tempData.contentNodes.Additional_Icon_2 = { 'url' : '' };
            }
            if(!tempData.contentNodes.Button_Label) {
                tempData.contentNodes.Button_Label = { 'value' : '' };
            }
            if(!tempData.contentNodes.Button_Action) {
                tempData.contentNodes.Button_Action = { 'value' : '' };
            }
            if(!tempData.contentNodes.Body) {
                tempData.contentNodes.Body = { 'value' : '' };
            } else if(tempData.contentNodes.Body?.value) {
                tempData.contentNodes.Body.value = tempData.contentNodes.Body.value.replaceAll('&lt;', '<').replaceAll('&gt;', '>');
            }
            if(!tempData.contentNodes.Subtitle) {
                tempData.contentNodes.Subtitle = { 'value' : '' };
            } else if(tempData.contentNodes.Subtitle?.value) {
                tempData.contentNodes.Subtitle.value = tempData.contentNodes.Subtitle.value.replaceAll('&lt;', '<').replaceAll('&gt;', '>');
            }
            if(!this.showTitle) {
                tempData.contentNodes.Title.value = '';
            }

            this.data = tempData;
            this.error = undefined;
            
        } else if (error) {
            this.error = error;
            this.data = undefined;
        }
    }
}