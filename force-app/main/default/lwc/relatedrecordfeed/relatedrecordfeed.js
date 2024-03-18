import { LightningElement, api, track, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getRelatedRecords from '@salesforce/apex/RelatedRecordFeedController.getRelatedRecords';
import markAsRead from '@salesforce/apex/RelatedRecordFeedController.markAsRead';
import createRecord from '@salesforce/apex/RelatedRecordFeedController.createRecord';

export default class Relatedrecordfeed extends LightningElement {
    @api recordId = "";
    @api childObjectType = "";
    @api relationshipFieldName = "";
    @api commentFieldName = "";
    @api markAsReadFieldName = "";
    @api presetFields;
    @api popupMode;
    @api readOnly;
    @api get reverseFeed() {
        return this._reverseFeed;
    }
    set reverseFeed(value) {
        this._reverseFeed = value;
        refreshApex(this.wiredRecords);
    }
    @track relatedRecords;
    @track hasUnread;
    @track wiredRecords;
    _reverseFeed = false;

    @wire(getRelatedRecords, { recordId: '$recordId', childObjectType: '$childObjectType', relationshipFieldName: '$relationshipFieldName',
                                commentFieldName: '$commentFieldName', markAsReadFieldName: '$markAsReadFieldName', reverseFeed: '$reverseFeed' })
    recordList(result) {
        this.wiredRecords = result;
        if(result.data) {
            this.relatedRecords = result.data.comments;
            this.hasUnread = result.data.hasUnread;
        } else if (result.error) {
            console.error(result.error);
        }
    }

    handleReadRecords() {
        if(this.markAsReadFieldName && this.relatedRecords) {
            markAsRead(
                {
                    recordString: JSON.stringify(this.relatedRecords),
                    markAsReadFieldName: this.markAsReadFieldName
                }
                ).then((result) => {
                    if(result) {
                        this.hasUnread = false;
                    } else {
                        console.error("There was a problem marking the records as read");
                    }
                })
                .catch((error) => {
                    console.error("There was a problem marking the records as read: " + error.body);
                });
        }
    }

    handleNewComment(evt) {
        if(evt.detail) {
            createRecord(
                { 
                    recordId: this.recordId,
                    childObjectType: this.childObjectType,
                    relationshipFieldName: this.relationshipFieldName,
                    commentFieldName: this.commentFieldName,
                    markAsReadFieldName: this.markAsReadFieldName ? this.markAsReadFieldName : null,
                    newComment: evt.detail,
                    presetFields: this.presetFields
                }
                )
                .then((result) => {
                    if(result) {
                        // success
                    } else {
                        console.error("There was a problem creating a new record");
                    }
                })
                .catch((error) => {
                    console.error("There was a problem creating a new record: " + error.body.stackTrace + " | " + error.body.message);
                });
        }
    }
}