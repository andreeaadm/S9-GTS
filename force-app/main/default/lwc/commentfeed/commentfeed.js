import { LightningElement, api, wire } from 'lwc';
import USER_ID from '@salesforce/user/Id';
import NAME_FIELD from '@salesforce/schema/User.Name';
import { getRecord } from 'lightning/uiRecordApi';

export default class Commentfeed extends LightningElement {
    /*
     Each comment in comments should have the following signature...
     {
        comment: the body of the comment
        userClass: "currentuser" if the current user created the comment or "otheruser" if not
        createdByDate: datetime the comment was created
        createdByName: name of the user who created the comment
        recordId (optional): a record Id that could be used when marking comments as read in the database
     }
     */
    @api comments;
    @api readOnly = false;
    @api reverseFeed = false;
    currentUserName;
    
    get hasComments() {
        return this.comments && this.comments.length > 0;
    }

    get allowNewComments() {
        return !this.readOnly && !this.reverseFeed;
    }

    get allowNewCommentsReverse() {
        return !this.readOnly && this.reverseFeed;
    }

    get commentsClass() {
        return this.reverseFeed ? "comments-posts reverse" : "comments-posts";
    }

    renderedCallback() {
        this.reverseFeed ? this.scrollToTopComment() : this.scrollToBottomComment();
    }

    @wire(getRecord, { recordId: USER_ID, fields: [NAME_FIELD] })
    wireUser({ error, data }) {
        if (data) {
            this.currentUserName = data.fields.Name.value;
        }
    }

    handleBlur(evt) {
        evt.stopPropagation();
        this.dispatchEvent(new CustomEvent('blur', { detail: evt}));
    }

    addComment(evt) {
        let newComment = this.template.querySelector('textarea').value;
        if (newComment) {
            this.dispatchEvent(new CustomEvent('newcomment', { detail: newComment }));
			let newCommentObj = { comment: newComment, userClass: 'currentuser', createdByName: this.currentUserName ? this.currentUserName : "Guest", createdByDate: new Date().toISOString() };
            this.reverseFeed ? this.comments = [newCommentObj, ...this.comments] : this.comments = [...this.comments, newCommentObj];
            this.template.querySelector('textarea').value = '';
		}
    }

    @api scrollToBottomComment() {
        let scrollDiv = this.template.querySelector('.comments-posts');
        if (scrollDiv) {
            scrollDiv.scrollTop = scrollDiv.scrollHeight;
        }
    }

    @api scrollToTopComment() {
        let scrollDiv = this.template.querySelector('.comments-posts');
        if (scrollDiv) {
            scrollDiv.scrollTop = 0;
        }
    }
}