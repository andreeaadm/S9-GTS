import { LightningElement, api, track, wire } from 'lwc';
import getCommunityNotices from '@salesforce/apex/CommunityNoticeLwcController.getCommunityNotices';

export default class CommunityNoticeLwc extends LightningElement {
    @api communityName;
    @api bgColor;
    @track messages;

    connectedCallback(){
      if(this.bgColor){
        this.template.host.style.setProperty( '--bgColor', this.bgColor);
      }
    }

    @wire(getCommunityNotices, {communityName: '$communityName'})
    communityNotices({ error, data }) {
      if (data) {
        this.messages = data;
      } else if (error) {
         console.error('Error:', error);
      }
    }
}