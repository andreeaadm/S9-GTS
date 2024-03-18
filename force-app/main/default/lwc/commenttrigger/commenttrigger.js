import { LightningElement, api, track } from 'lwc';

export default class Commenttrigger extends LightningElement {
    /*
     Each comment in comments should have the following signature...
     {
        comment: the body of the comment
        userClass: "currentuser" if the current user created the comment or "otheruser" if not
        createdByDate: datetime the comment was created
        createdByName: name of the user who created the comment
        recordId (optional): a record Id that could be used when marking comments as read in a parent component
     }
     */
    @api comments;
    @api hasUnread = false;
    @api readOnly = false;
    @api reverseFeed = false;
    @track popupClass = 'popup';
    
    get hasComments() {
        return this.comments && this.comments.length > 0;
    }

    openPopup() {
        this.popupClass = 'popup active';
        this.reverseFeed ? this.template.querySelector('c-commentfeed').scrollToTopComment() : this.template.querySelector('c-commentfeed').scrollToBottomComment();
        this.setFocusOnPopup();
        this.hasUnread = false;
        // mark comments as read in a parent component if needed, or do other things
        this.dispatchEvent(
            new CustomEvent("readcomments", { detail: { comments: this.comments }})
        );
    }

    setFocusOnPopup() {
        let focusDiv = this.template.querySelector('.popup');
        if (focusDiv) {
            focusDiv.focus();
        }
    }

    handleBlur(evt) {
        try {
            let focusDiv = JSON.parse(JSON.stringify(this.template.querySelector('.popup')));
            let event = evt.detail ? evt.detail : evt;
            if (!event.relatedTarget || (focusDiv != JSON.parse(JSON.stringify(event.relatedTarget)) && !focusDiv.contains(JSON.parse(JSON.stringify((event.relatedTarget)))))) {
                this.closePopup();
            }
        } catch (e) {}
    }

    closePopup() {
        this.popupClass = 'popup';
    }

    handleNewComment(evt) {
        this.dispatchEvent( new CustomEvent("newcomment", { detail: evt.detail }));
    }
}