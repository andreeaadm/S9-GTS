public class AssetExpiryBannerController {
    
    @AuraEnabled
    public static APIResponse userRequestsFullMTCAccess() {
        try {
            List<User> users = MTCUserUtil.getUsersWithContact(
                new Set<Id>{ UserInfo.getUserId() }
            );
            if (!users.isEmpty()) {
                Contact thisContact = users[0].Contact;
                if (
                    thisContact.Approval_Status__c != Label.MTC_Approval_RequestedStatus
                ) {
                    WithoutSharing.updateRecord(
                        new Contact(
                            Id = thisContact.Id,
                            Approval_Status__c = Label.MTC_Approval_RequestedStatus
                        )
                    );
                }
                return new APIResponse('OK', 200);
            } else {
                return new APIResponse('Bad Request', 400, 'Invalid User for Request');
            }
        } catch (Exception e) {
            return new APIResponse('Bad Request', 400, e.getMessage());
        }
    }
    
    @AuraEnabled
    public static User getUserDetails(Id userId) {
        return UserUtil.getUserDetails(userId);
    }
    @AuraEnabled(cacheable=true)
    public static User getUserDetailsWired(Id userId) {
        return UserUtil.getUserDetails(userId);
    }
    
    @AuraEnabled
    public static APIResponse resetUsersPassword(List<String> selectedUserIds) {
        try {
            // Ensure access to records
            Set<Id> userIdsPermitted = MTCUserUtil.filterPermittedUsers(
                (List<Id>) selectedUserIds
            );
            if (userIdsPermitted.isEmpty()) {
                return new APIResponse(
                    'Bad Request',
                    400,
                    'You are not allowed to reset passwords'
                );
            }
            for (Id userId : userIdsPermitted) {
                System.resetPasswordWithEmailTemplate(
                    userId,
                    true,
                    'Custom_Experience_Cloud_Changed_Password_Email'
                );
            }
            return new APIResponse('OK', 200);
        } catch (Exception e) {
            return new APIResponse('Bad Request', 400, e.getMessage());
        }
    }
    
    @AuraEnabled
    public static APIResponse addOrRemoveUsersFromGroups(
        List<String> selectedUserIds,
        List<String> selectedGroupIds,
        Boolean applyAddAction
    ) {
        try {
            Set<Id> selectedUsersContactIds = new Set<Id>();
            
            Id accountID;
            for (User u : [
                SELECT ContactID, Contact.AccountId
                FROM User
                WHERE ID IN :selectedUserIds
            ]) {
                selectedUsersContactIds.add(u.ContactID);
                accountID = u.Contact.AccountId; // the acc is the same for all users selected from the logged in user.
            }
            // Block any CGA's being added to a Group if a CGA on the same account.
            for (AccountContactRelation accRel : [
                SELECT ContactID
                FROM AccountContactRelation
                WHERE
                AccountId = :accountID
                AND ContactID IN :selectedUsersContactIds
                AND MTC_Role__c = 'CGA'
            ]) {
                selectedUsersContactIds.remove(accRel.ContactID);
            }
            //Check if the contact is a CGA User and filter out if s.
            if (applyAddAction) {
                ContactGroupUtil.linkContactsToGroups(
                    selectedUsersContactIds,
                    selectedGroupIds,
                    true
                );
            } else {
                ContactGroupUtil.unlinkContactsFromGroups(
                    selectedUsersContactIds,
                    selectedGroupIds
                );
            }
            return new APIResponse('OK', 200);
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, e.getMessage());
            return new APIResponse('Bad Request', 400, e.getMessage());
        }
    }
    
    /*┌────────────────────────────────────────────────────────────────┐
* Enable a user if 'active' parameter is set to true.
* Disable users if 'active' is set to false.
*└────────────────────────────────────────────────────────────┄┄┄┄┘
*/
    @AuraEnabled
    public static APIResponse enableDisableUser(
        List<String> selectedUserIds,
        Boolean activateYN
    ) {
        try {
            Set<Id> manageableUserIds = MTCUserUtil.filterPermittedUsers(
                (List<Id>) selectedUserIds
            );
            Set<Id> deactivatableUserIds = MTCUserUtil.filterUsersUserCanDeactivate(
                manageableUserIds
            );
            
            Set<Id> accountIdsAdminFor = AccountRelationUtil.getRelatedMTCAccountIdsforContactWhenAdmin();
            List<User> usersToUpdate = new List<User>();
            
            if (activateYN) {
                for (Id userId : manageableUserIds) {
                    usersToUpdate.add(new user(id = userId, isactive = true));
                }
                WithoutSharing.updateRecords((List<SObject>) usersToUpdate);
            } else {
                List<AccountContactRelation> acrsToUpdate = new List<AccountContactRelation>();
                for (AccountContactRelation acr : [
                    SELECT AccountId, MTC_Role__c
                    FROM AccountContactRelation
                    WHERE
                    ContactId IN (
                        SELECT ContactId
                        FROM User
                        WHERE Id IN :manageableUserIds
                    )
                ]) {
                    if (accountIdsAdminFor.contains(acr.AccountId)) {
                        acrsToUpdate.add(
                            new AccountContactRelation(Id = acr.Id, MTC_Role__c = 'no-access')
                        );
                    }
                }
                
                WithoutSharing.updateRecords(acrsToUpdate);
                
                for (Id userId : manageableUserIds) {
                    if (deactivatableUserIds.contains(userId)) {
                        usersToUpdate.add(new user(id = userId, isactive = false));
                    }
                }
                if (acrsToUpdate.isEmpty()) {
                    // no risk of MIXED DML here
                    WithoutSharing.updateRecords((List<SObject>) usersToUpdate);
                } else if (!usersToUpdate.isEmpty()) {
                    // Users update must be futured in this case
                    WithoutSharing.updateRecordsFuture((List<SObject>) usersToUpdate);
                }
            }
        } catch (Exception e) {
            String enableDisable = activateYN ? 'Enable' : 'Disable';
            return new APIResponse(
                'FAILURE',
                400,
                enableDisable +
                ' user failure\n' +
                e.getMessage()
            );
        }
        return new APIResponse('OK', 200);
    }
    
    @AuraEnabled
    public static APIResponse approveDeclineAccessForUser(
        Id userId,
        String decision
    ) {
        try {
            Set<Id> userIdsPermitted = MTCUserUtil.filterPermittedUsers(
                new List<Id>{ userId }
            );
            if (userIdsPermitted.isEmpty()) {
                return new APIResponse(
                    'Bad Request',
                    400,
                    'You are not allowed to approve access to MTC'
                );
            }
            
            List<User> users = MTCUserUtil.getUsersWithContact(new Set<Id>{ userId });
            if (users.isempty()) {
                return new APIResponse('FAILURE', 400, 'User not found');
            }
            Contact con = users[0].Contact;
            List<AccountContactRelation> acrs = AccountRelationUtil.getMTCACRsForContact(
                con.Id
            );
            
            List<AccountContactRelation> acrsToUpdate = new List<AccountContactRelation>();
            if (decision == 'approve') {
                WithoutSharing.updateUser(userId, true, true);
                con.Approval_Status__c = Label.MTC_Approval_ApprovedStatus;
                for (AccountContactRelation acr : acrs) {
                    if (acr.MTC_Role__c == 'pending approval') {
                        acrsToUpdate.add(
                            new AccountContactRelation(Id = acr.Id, MTC_Role__c = 'Read-Only')
                        );
                    }
                }
            } else if (decision == 'decline') {
                WithoutSharing.updateUser(userId, false, false);
                con.Approval_Status__c = Label.MTC_Approval_DeclinedStatus;
                for (AccountContactRelation acr : acrs) {
                    if (acr.MTC_Role__c == 'pending approval') {
                        acrsToUpdate.add(
                            new AccountContactRelation(Id = acr.Id, MTC_Role__c = 'Rejected')
                        );
                    }
                }
            }
            update con;
            update acrsToUpdate;
        } catch (Exception e) {
            return new APIResponse(
                'FAILURE',
                400,
                'It was not possible to perform your request.'
            );
        }
        return new APIResponse('OK', 200);
    }
    public class UserWithContact {
        @AuraEnabled
        public Boolean isActive;
        @AuraEnabled
        public String approvalStatus;
        @AuraEnabled
        public String username;
        
        public UserWithContact(User usr) {
            username = usr.Username;
            isActive = usr.IsActive;
            approvalStatus = usr.Contact.Approval_Status__c;
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static UserWithContact getUserWithContact(Id userId) {
        Set<Id> userIdsPermitted = MTCUserUtil.filterPermittedUsers(
            new List<Id>{ userId }
        );
        if (userIdsPermitted.isEmpty()) {
            throw new AuraHandledException(
                'You are not allowed to manage this user.'
            );
        }
        List<User> users = MTCUserUtil.getUsersWithContact(new Set<Id>{ userId });
        if (users.isEmpty()) {
            throw new AuraHandledException(
                'You are not allowed to manage this user.'
            );
        } else {
            return new UserWithContact(users[0]);
        }
    }
    //Prateek
    @AuraEnabled(cacheable=true)
    public static Integer assetExpiryBanner(Id recordId){
       Integer No_Of_Days;
        List<Asset_Contact_Relationship__c> acr= [Select Id, Asset_Synced_Date__c,Expiry_Date__c,Asset__c, Asset__r.Id,Expired__c,Contact__c,Restricted_Role__c from Asset_Contact_Relationship__c where Asset__c = :recordId  order By CreatedDate desc limit 1];
        if(!acr.isEmpty()){
            No_Of_Days = (system.today()).daysBetween(Date.valueOf(acr[0].Expiry_Date__c));
            system.debug('No_Of_Days' + No_Of_Days);
            //return No_Of_Days;
        }
        return No_Of_Days;
    } 
    //Prateek
    @AuraEnabled(cacheable=true)
    public static boolean assetExpirystatus(Id recordId){
        String loggedUserId = UserInfo.getUserId();
        User us = [Select id,Name, ContactID from User where Id =: loggedUserId];
        String contactIds = us.ContactId;
        boolean expiryStatus = false;
        
        List<Asset_Contact_Relationship__c> acr= [Select Id, Asset_Synced_Date__c,Expiry_Date__c,Asset__c, Asset__r.Id,Expired__c,Contact__c,Restricted_Role__c,Asset__r.AccountId from Asset_Contact_Relationship__c where Asset__c = :recordId order By CreatedDate desc limit 1];
        if(!acr.isEmpty() && acr[0].Contact__c == contactIds){
            if(acr[0].Restricted_Role__c == true){
                expiryStatus =  acr[0].Expired__c;    //MBS-298
            }else{
                expiryStatus = false;
            }
        }else{
            List<Asset> assetList = [Select id,AccountID,ContactID from Asset where ID =: recordId limit 1];
        	List<AccountContactRelation> orgACR = [Select id, ContactId,AccountId,MTC_Role__c From AccountContactRelation where ContactId =: contactIds and AccountId =: assetList[0].AccountId limit 1];
            if(!orgACR.isEmpty() && orgACR[0].MTC_Role__c == 'Restricted'){
                expiryStatus =  true;
            }else{
                expiryStatus = false;
            }
        } 
        return expiryStatus;
    }
    
   @AuraEnabled(cacheable=true)
    public static boolean assetExpirystatusCheckforBanner(Id recordId){
       String loggedUserIds = UserInfo.getUserId();
       User us = [Select id,Name, ContactID from User where Id =: loggedUserIds];
       String contactIds = us.ContactId;
        boolean expiryStatus = false;
        
        List<Asset_Contact_Relationship__c> acr= [Select Id, Asset_Synced_Date__c,Expiry_Date__c,Asset__c, Asset__r.Id,Expired__c,Contact__c,Restricted_Role__c,Asset__r.AccountId from Asset_Contact_Relationship__c where Asset__c = :recordId order By CreatedDate desc limit 1];
        if(!acr.isEmpty() && acr[0].Contact__c == contactIds){
            if(acr[0].Restricted_Role__c == true){
                expiryStatus =  true;
            }else{
                expiryStatus = false;
            }
        }else{
            List<Asset> assetList = [Select id,AccountID,ContactID from Asset where ID =: recordId limit 1];
        	List<AccountContactRelation> orgACR = [Select id, ContactId,AccountId,MTC_Role__c From AccountContactRelation where ContactId =: contactIds and AccountId =: assetList[0].AccountId limit 1];
            if(!orgACR.isEmpty() && orgACR[0].MTC_Role__c == 'Restricted'){
                expiryStatus =  true;
            }else{
                expiryStatus = false;
            }
        } 
        
        
        return expiryStatus;
    } 
      
}