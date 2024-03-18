import { LightningElement,wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import setTitleUserPhoto from '@salesforce/apex/iCare_TitleUserProfileController.setTitleUserPhoto';
import USER_ID from '@salesforce/user/Id';
import COMMUNITY_ID from '@salesforce/community/Id';

// Custom Labels
import USER_PROFILE_LABEL from '@salesforce/label/c.iCare_Portal_User_Profile';
import USER_PROFILE_DETAILS_LABEL from '@salesforce/label/c.iCare_Portal_Update_Profile_Details';

export default class ICareTitleUserProfile extends LightningElement {
    labels = {
        USER_PROFILE_LABEL,
        USER_PROFILE_DETAILS_LABEL
    }

    photo;

    get acceptedFormats() {
        return ['.jpg', '.png'];
    }

    @wire(getRecord,
            { recordId: USER_ID,
                fields: ['User.MediumPhotoUrl'] })
    wiredUser({ error, data }) {
        if (data) {
            this.photo = data.fields.MediumPhotoUrl.value;
        } else if (error) {
            console.error(error);
        }
    }

    get currentPhotoUrl() {
        return this.photo;
    }

    handleUploadFinished(event){
        const uploadedFiles = event.detail.files;
        const image = uploadedFiles[0];
        setTitleUserPhoto({ contentDocumentId : image.documentId,
                                 communityId : COMMUNITY_ID,
                                 userId : USER_ID })
        location.reload();
    }
}