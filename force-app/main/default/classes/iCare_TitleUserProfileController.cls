/********************************************************************************************
* @Name         iCare_TitleUserProfileController
* @Author       Regan Smiith
* @Description  This class is used by the iCare Title User Profile LWC 
*               and sets the users profile picture using the file uploaded
*********************************************************************************************/
public with sharing class iCare_TitleUserProfileController {
    @AuraEnabled
    public static void setTitleUserPhoto(String contentDocumentId, String communityId, String userId){
        ContentVersion contentVersion =[SELECT Id, VersionData, FileType, Title
                                        FROM ContentVersion
                                        WHERE ContentDocumentId =:contentDocumentId
                                        LIMIT 1];
        
        String lowerCaseFileType = contentVersion.FileType.toLowerCase();
        
		ConnectApi.BinaryInput binaryInput = new ConnectApi.BinaryInput(contentVersion.VersionData, 
																		'image/' + lowerCaseFileType, 
                                            							contentVersion.Title + '.' + lowerCaseFileType);
        ConnectApi.UserProfiles.setPhoto(communityId, userId, binaryInput);
    }
}