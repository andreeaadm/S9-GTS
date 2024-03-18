import { LightningElement } from 'lwc';

export default class GstCustomLookupTest extends LightningElement {

    lookupRecord(event){
        console.log('Selected Record Value on Parent Component is ' +  JSON.stringify(event.detail.selectedRecord));
    }
}