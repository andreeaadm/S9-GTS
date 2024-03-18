public with sharing class EmailRequestUtil {
    static final String MTC_CASE_QUEUE = Label.MTC_System_Case_Queue;
    
    public static void newEmailRequests(List<Email_Request__e> newEmailRequests) {
        List<Email_Request__e> accessEmailRequests = new List<Email_Request__e>();
        List<Email_Request__e> accountEmailRequests = new List<Email_Request__e>();
        List<Email_Request__e> acrEmailRequests = new List<Email_Request__e>();
        List<Email_Request__e> assetEmailRequests = new List<Email_Request__e>();
        List<Email_Request__e> caseEmailRequests = new List<Email_Request__e>();
        List<Email_Request__e> groupMemberEmailRequests = new List<Email_Request__e>();
        List<Email_Request__e> userEmailRequests = new List<Email_Request__e>();
        List<Email_Request__e> contactEmailRequests = new List<Email_Request__e>();
        List<Email_Request__e> bscEmailRequests = new List<Email_Request__e>();
        List<Email_Request__e> bulletinEmailRequests = new List<Email_Request__e>();
        List<Email_Request__e> inventoryEmailRequests = new List<Email_Request__e>();
        
        for (Email_Request__e request : newEmailRequests) {
            if (request.RecordId__c == null || request.RecordId__c == '')
                continue;
            switch on
                String.valueOf(Id.valueOf(request.RecordId__c).getSObjectType()) {
                    when 'Access__c' {
                        accessEmailRequests.add(request);
                    }
                    when 'Account' {
                        accountEmailRequests.add(request);
                    }
                    when 'AccountContactRelation' {
                        acrEmailRequests.add(request);
                    }
                    when 'Asset' {
                        assetEmailRequests.add(request);
                    }
                    when 'Case' {
                        caseEmailRequests.add(request);
                    }
                    when 'Group_Membership__c' {
                        groupMemberEmailRequests.add(request);
                    }
                    when 'User' {
                        userEmailRequests.add(request);
                    }
                    when 'Contact' {
                        contactEmailRequests.add(request);
                    }
                    when 'Brand_Supplier_Connection__c' {
                        bscEmailRequests.add(request);
                    }
                    when 'Bulletin__c' {
                        bulletinEmailRequests.add(request);
                    }
                    when 'Inventory__c' {
                        inventoryEmailRequests.add(request);
                    }
                    when else {
                        System.debug(
                            LoggingLevel.ERROR,
                            'Unsupported RecordId__c on Email_Request__c'
                        );
                    }
                }
        }
        
        if (!accessEmailRequests.isEmpty())
            handleAccessEmails(accessEmailRequests);
        if (!accountEmailRequests.isEmpty())
            handleAccountEmails(accountEmailRequests);
        if (!acrEmailRequests.isEmpty())
            handleACREmails(acrEmailRequests);
        if (!assetEmailRequests.isEmpty())
            handleAssetEmails(assetEmailRequests);
        if (!caseEmailRequests.isEmpty())
            handleCaseEmails(caseEmailRequests);
        if (!groupMemberEmailRequests.isEmpty())
            handleGroupMembershipEmails(groupMemberEmailRequests);
        if (!userEmailRequests.isEmpty())
            handleUserEmails(userEmailRequests);
        if (!contactEmailRequests.isEmpty())
            handleContactEmails(contactEmailRequests);
        if (!bscEmailRequests.isEmpty())
            handleBSCEmails(bscEmailRequests);
        if (!bulletinEmailRequests.isEmpty())
            handleBulletinEmails(bulletinEmailRequests);
        if (!inventoryEmailRequests.isEmpty())
            handleInventoryEmails(inventoryEmailRequests);
    }
    
    private static Map<Id,User> emailOptOutForUser(Map<Id,User> contactIdToUserMap){
        Map<Id,User> filteredContactIdToUserMap =new Map<Id,User>(); 
        Set<Id> userId= new Set<Id>();
        for (Id conId : contactIdToUserMap.keyset()){
            if (contactIdToUserMap.get(conId) != null) { 
                userId.add(contactIdToUserMap.get(conId).Id) ;
            }
        }
        List<User> filteredUserList =[select id,contactId,email_opt_out__c from User where id in : userId and email_opt_out__c = false] ;
        if(!filteredUserList.isEmpty()){
            for(User u:filteredUserList){
                filteredContactIdToUserMap.put(u.ContactId, u);
            }
        }
        return filteredContactIdToUserMap;
    }
    private static void handleAccessEmails(List<Email_Request__e> requests) {
        List<EmailUtil.Email> emails = new List<EmailUtil.Email>();
        Map<Id, Set<Id>> recordIdToContactIdsMap = new Map<Id, Set<Id>>();
        Map<String, Set<Id>> strategyToRecordIdsMap = new Map<String, Set<Id>>();
        for (Email_Request__e e : requests) {
            if (strategyToRecordIdsMap.get(e.Strategy__c) != null) {
                strategyToRecordIdsMap.get(e.Strategy__c).add(e.RecordId__c);
            } else {
                strategyToRecordIdsMap.put(e.Strategy__c, new Set<Id>{ e.RecordId__c });
            }
        }
        if (strategyToRecordIdsMap.get('Group') != null) {
            Set<Id> recordIds = strategyToRecordIdsMap.get('Group');
            Map<Id, Id> contactGroupIdToAssetIds = new Map<Id, Id>();
            for (Access__c a : [
                SELECT Id, Contact_Group__c
                FROM Access__c
                WHERE Id IN :recordIds
            ]) {
                contactGroupIdToAssetIds.put(a.Contact_Group__c, a.Id);
            }
            for (
                Contact_Group__c cg : ContactGroupUtil.getGroupMembershipsForContactGroups(
                    contactGroupIdToAssetIds.keySet()
                )
            ) {
                for (Group_Membership__c gm : cg.Group_Memberships__r) {
                    if (
                        recordIdToContactIdsMap.get(contactGroupIdToAssetIds.get(cg.Id)) !=
                        null
                    ) {
                        recordIdToContactIdsMap.get(contactGroupIdToAssetIds.get(cg.Id))
                            .add(gm.Contact__c);
                    } else {
                        recordIdToContactIdsMap.put(
                            contactGroupIdToAssetIds.get(cg.Id),
                            new Set<Id>{ gm.Contact__c }
                        );
                    }
                }
            }
            Map<Id, User> contactIdToUserMap = getContactIdToUserMap(
                recordIdToContactIdsMap.values()
            );
            Map<Id,User> filteredContactIdToUserMap= EmailRequestUtil.emailOptOutForUser(contactIdToUserMap);
            for (Email_Request__e e : requests) {
                List<User> recipients = new List<User>();
                for (Id i : recordIdToContactIdsMap.get(e.RecordId__c)) {
                    if (filteredContactIdToUserMap.get(i) != null) {
                        recipients.add(filteredContactIdToUserMap.get(i));
                    }
                }
                emails.add(
                    new EmailUtil.Email(
                        recipients,
                        e.RecordId__c,
                        e.Email_Template_Name__c,
                        e.Organization_Wide_Address__c
                    )
                );
            }
        }
        EmailUtil.sendEmails(emails);
    }
    
    private static void handleAccountEmails(List<Email_Request__e> requests) {
        List<EmailUtil.Email> emails = new List<EmailUtil.Email>();
        Set<Id> recordIds = new Set<Id>();
        Map<Id, Set<Id>> recordIdToContactIdsMap = new Map<Id, Set<Id>>();
        
        for (Email_Request__e e : requests) {
            recordIds.add(e.RecordId__c);
        }
        
        for (AccountContactRelation acr : [
            SELECT Id, ContactId, AccountId
            FROM AccountContactRelation
            WHERE
            AccountId IN :recordIds
            AND MTC_Role__c IN ('Read-Only', 'Admin', 'CGA')
        ]) {
            if (recordIdToContactIdsMap.get(acr.AccountId) != null) {
                recordIdToContactIdsMap.get(acr.AccountId).add(acr.ContactId);
            } else {
                recordIdToContactIdsMap.put(
                    acr.AccountId,
                    new Set<Id>{ acr.ContactId }
                );
            }
        }
        Map<Id, User> contactIdToUserMap = getContactIdToUserMap(
            recordIdToContactIdsMap.values()
        );
        for (Email_Request__e e : requests) {
            List<User> recipients = new List<User>();
            if (
                recordIdToContactIdsMap != null &&
                !recordIdToContactIdsMap.isEmpty() &&
                e.RecordId__c != null
            ) {
                for (Id i : recordIdToContactIdsMap.get(e.RecordId__c)) {
                    if (contactIdToUserMap.get(i) != null) {
                        recipients.add(contactIdToUserMap.get(i));
                    }
                }
                emails.add(
                    new EmailUtil.Email(
                        recipients,
                        e.RecordId__c,
                        e.Email_Template_Name__c,
                        e.Organization_Wide_Address__c
                    )
                );
            }
        }
        
        EmailUtil.sendEmails(emails);
    }
    
    private static void handleACREmails(List<Email_Request__e> requests) {
        List<EmailUtil.Email> emails = new List<EmailUtil.Email>();
        Map<Id, Set<Id>> recordIdToContactIdsMap = new Map<Id, Set<Id>>();
        Set<Id> recordIds = new Set<Id>();
        for (Email_Request__e e : requests) {
            recordIds.add(e.RecordId__c);
        }
        for (AccountContactRelation acr : [
            SELECT Id, ContactId
            FROM AccountContactRelation
            WHERE Id IN :recordIds
        ]) {
            if (recordIdToContactIdsMap.get(acr.Id) != null) {
                recordIdToContactIdsMap.get(acr.Id).add(acr.ContactId);
            } else {
                recordIdToContactIdsMap.put(acr.Id, new Set<Id>{ acr.ContactId });
            }
        }
        Map<Id, User> contactIdToUserMap = getContactIdToUserMap(
            recordIdToContactIdsMap.values()
        );
        for (Email_Request__e e : requests) {
            List<User> recipients = new List<User>();
            for (Id i : recordIdToContactIdsMap.get(e.RecordId__c)) {
                if (contactIdToUserMap.get(i) != null) {
                    recipients.add(contactIdToUserMap.get(i));
                }
            }
            emails.add(
                new EmailUtil.Email(
                    recipients,
                    e.RecordId__c,
                    e.Email_Template_Name__c,
                    e.Organization_Wide_Address__c
                )
            );
        }
        EmailUtil.sendEmails(emails);
    }
    /***
     * History:
     *         25-07-2023   Kamlesh.kahar    MBS-301    Added logic to send email to admins for new reports.
    ***/
    private static void handleAssetEmails(List<Email_Request__e> requests) {
        List<EmailUtil.Email> emails = new List<EmailUtil.Email>();
        Map<Id, Set<Id>> recordIdToContactIdsMap = new Map<Id, Set<Id>>();
        Map<Id, Set<User>> recordIdToRecipientsMap = new Map<Id, Set<User>>();
        Map<String, Set<Id>> strategyToRecordIdsMap = new Map<String, Set<Id>>();
        for (Email_Request__e e : requests) {
            String strategy = 'Group';
            if (!String.isBlank(e.Strategy__c)) {
                strategy = e.Strategy__c;
            }
            Set<Id> records4ForStrategy = strategyToRecordIdsMap.get(strategy);
            if (records4ForStrategy == null) {
                strategyToRecordIdsMap.put(strategy, new Set<Id>{ e.RecordId__c });
            } else {
                records4ForStrategy.add(e.RecordId__c);
            }
        }
        if (strategyToRecordIdsMap.get('ACR') != null) {
            Set<Id> recordIds = strategyToRecordIdsMap.get('ACR');
            Map<Id, Set<Id>> accountIdToRecordIdsMap = new Map<Id, Set<Id>>();
            for (Asset a : [
                SELECT Id, AccountId, Account.CGA_Id__c
                FROM Asset
                WHERE Id IN :recordIds
            ]) {
                if (accountIdToRecordIdsMap.get(a.AccountId) != null) {
                    accountIdToRecordIdsMap.get(a.AccountId).add(a.Id);
                } else {
                    accountIdToRecordIdsMap.put(a.AccountId, new Set<Id>{ a.Id });
                }
            }
            for (User u : [
                SELECT Id, ContactId, Contact.AccountId
                FROM User
                WHERE
                ContactId IN (
                    SELECT ContactId
                    FROM AccountContactRelation
                    WHERE
                    MTC_Role__c IN ('Read-Only', 'Admin', 'CGA')
                    AND MTC_Role__c != 'No-Access' 
                    AND AccountId IN :accountIdToRecordIdsMap.keyset()
                )
                AND isActive = TRUE
            ]) {
                for (Id i : accountIdToRecordIdsMap.get(u.Contact.AccountId)) {
                    if (recordIdToRecipientsMap.get(i) != null) {
                        recordIdToRecipientsMap.get(i).add(u);
                    } else {
                        recordIdToRecipientsMap.put(i, new Set<User>{ u });
                    }
                }
            }
            List<User> finalRecipients = new List<User> ();
            for (Email_Request__e e : requests) {
                List<User> recipients = new List<User>(
                    recordIdToRecipientsMap.get(e.RecordId__c)
                );
                for(User u :recipients)
                {
                    if(u.Email_Opt_Out__c== true){
                        continue;
                    }else{
                        finalRecipients.add(u);
                    }
                }
                emails.add(
                    new EmailUtil.Email(
                        finalRecipients,
                        e.RecordId__c,
                        e.Email_Template_Name__c,
                        e.Organization_Wide_Address__c
                    )
                );
            }
        }
        if (strategyToRecordIdsMap.get('Group') != null) {
            Map<Id, Asset> recordIdToRecordMap = new Map<Id, Asset>();
            Set<Id> recordIds = strategyToRecordIdsMap.get('Group');
            Map<Id, Set<Id>> contactGroupIdToAssetIds = new Map<Id, Set<Id>>();
            Map<Id, Set<Id>> accountIdVsAssetIds = new Map<Id, Set<Id>>();
            for (Asset asset : [
                SELECT
                Id,
                AccountId,
                ContactId,
                Account.CGA_Id__c,
                (SELECT Id, Contact_Group__c FROM Report_Accesses__r)
                FROM Asset
                WHERE Id IN :recordIds
            ]) {
                recordIdToRecordMap.put(asset.Id, asset);
                if(!accountIdVsAssetIds.containsKey(asset.AccountId)){
                    accountIdVsAssetIds.put(asset.AccountId, new Set<Id>());
                }
                accountIdVsAssetIds.get(asset.AccountId).add(asset.Id);

                if (asset.ContactId != null) {
                    recordIdToContactIdsMap.put(asset.Id, new Set<Id>{ asset.ContactId });
                }
                
                for (Access__c access : asset.Report_Accesses__r) {
                    Set<Id> accessesForReport = contactGroupIdToAssetIds.get(
                        access.Contact_Group__c
                    );
                    if (accessesForReport == null) {
                        contactGroupIdToAssetIds.put(
                            access.Contact_Group__c,
                            new Set<Id>{ asset.Id }
                        );
                    } else {
                        accessesForReport.add(asset.Id);
                    }
                }
            }

            //Always notify CGA and Admin irrespective of group memberships.
            List<AccountContactRelation> adminAndCGA_ACRs = [SELECT AccountId,ContactId,MTC_Role__c 
                                                    FROM AccountContactRelation 
                                                    WHERE MTC_Role__c IN ('CGA', 'Admin')
                                                    AND AccountId IN :accountIdVsAssetIds.keySet()];

            for(AccountContactRelation relation :adminAndCGA_ACRs){
                if(accountIdVsAssetIds.containsKey(relation.AccountId)){
                    for(Id assetId :accountIdVsAssetIds.get(relation.AccountId)){
                        if(!recordIdToContactIdsMap.containsKey(assetId)){
                            recordIdToContactIdsMap.put(assetId, new Set<Id>());
                        }
                        recordIdToContactIdsMap.get(assetId).add(relation.ContactId);
                    }
                }
            }
            
            for (
                Contact_Group__c cg : ContactGroupUtil.getGroupMembershipsForContactGroups(
                    contactGroupIdToAssetIds.keySet()
                )
            ) {
                for (Group_Membership__c gm : cg.Group_Memberships__r) {
                    Set<Id> reportsForCG = contactGroupIdToAssetIds.get(cg.Id);
                    
                    for (Id reportForCG : reportsForCG) {
                        Set<Id> contacts = recordIdToContactIdsMap.get(reportForCG);
                        
                        if (contacts == null) {
                            recordIdToContactIdsMap.put(
                                reportForCG,
                                new Set<Id>{ gm.Contact__c }
                            );
                        } else {
                            recordIdToContactIdsMap.get(reportForCG).add(gm.Contact__c);
                        }
                    }
                }
            }
            
            Set<Id> allContactIds = new Set<Id>();
            for (Set<Id> i : recordIdToContactIdsMap.values()) {
                allContactIds.addAll(i);
            }
            Map<Id, Set<Id>> recordIdToContactIdsMapNew = new Map<Id, Set<Id>>();
            
            List<AccountContactRelation> acrList = [SELECT AccountId,ContactId,MTC_Role__c FROM AccountContactRelation WHERE ContactId IN :allContactIds AND AccountId IN :accountIdVsAssetIds.keySet()];
            Map<Id,AccountContactRelation> contactIdToACRMap = new Map<Id,AccountContactRelation>();
            for(AccountContactRelation acr : acrList){
                contactIdToACRMap.put(acr.ContactId, acr);
            }
            
            for(Id ast : recordIdToContactIdsMap.KeySet()){
                for(Id i : recordIdToContactIdsMap.get(ast)){
                    if(contactIdToACRMap.containsKey(i)) {
                        if(contactIdToACRMap.get(i).MTC_Role__c != 'No-Access') {
                            if(!recordIdToContactIdsMapNew.containsKey(ast)) {
                                recordIdToContactIdsMapNew.put(ast,new Set<Id>{i});
                            }
                            else {
                                recordIdToContactIdsMapNew.get(ast).add(i);
                            }  
                        }
                    }
                }
            }
             
            system.debug(json.serialize(recordIdToContactIdsMapNew));
            Map<Id, User> contactIdToUserMap = getContactIdToUserMap(
                recordIdToContactIdsMapNew.values()
            );
            system.debug(json.serialize(contactIdToUserMap));
            Map<Id,User> filteredContactIdToUserMap= EmailRequestUtil.emailOptOutForUser(contactIdToUserMap);
            for (Email_Request__e e : requests) {
                List<User> recipients = new List<User>();
                if (recordIdToContactIdsMapNew.get(e.RecordId__c) != null) {
                    for (Id i : recordIdToContactIdsMapNew.get(e.RecordId__c)) {
                        if (filteredContactIdToUserMap.get(i) != null) {
                            recipients.add(filteredContactIdToUserMap.get(i));
                        }
                    }
                }
                system.debug(json.serialize(recipients));

                emails.add(
                    new EmailUtil.Email(
                        recipients,
                        e.RecordId__c,
                        e.Email_Template_Name__c,
                        e.Organization_Wide_Address__c
                    )
                );
            }
        }
        if (strategyToRecordIdsMap.get('Admin') != null) {
            Map<Id,Id> assetVsAccountId = new Map<Id,Id>();
            Map<Id,List<User>> accountVsRecepients = new Map<Id,List<User>>();
            Set<Id> recordIds = strategyToRecordIdsMap.get('Admin');
            for(Asset asset :[SELECT Id, AccountId FROM Asset WHERE Id IN :recordIds]){
                assetVsAccountId.put(asset.Id, asset.AccountId);
            }
            List<User> users = [SELECT Id, Contact.AccountId FROM User 
                                WHERE ContactId IN (SELECT ContactId FROM AccountContactRelation 
                                WHERE AccountId IN :assetVsAccountId.values() 
                                AND MTC_Role__c IN ('CGA', 'Admin'))
                                AND isActive = true
                                AND Email_Opt_Out__c = false];

            for(User user :users){
                if(!accountVsRecepients.containsKey(user.Contact.AccountId)){
                    accountVsRecepients.put(user.Contact.AccountId, new List<User>{user});
                }
                accountVsRecepients.get(user.Contact.AccountId).add(user);
            }

            for(Email_Request__e request :requests){
                Id accountId = assetVsAccountId.get(request.RecordId__c);
                if(assetVsAccountId.containsKey(request.RecordId__c) && accountVsRecepients.containsKey(accountId)){
                    emails.add(
                        new EmailUtil.Email(
                            accountVsRecepients.get(accountId),
                            request.RecordId__c,
                            request.Email_Template_Name__c,
                            request.Organization_Wide_Address__c
                        )
                    );
                }
            }
        }
        EmailUtil.sendEmails(emails);
    }
    
    private static void handleCaseEmails(List<Email_Request__e> requests) {
        List<EmailUtil.Email> emails = new List<EmailUtil.Email>();
        Map<Id, Set<Id>> recordIdToUserIdsMap = new Map<Id, Set<Id>>();
        Set<Id> recordIds = new Set<Id>();
        Boolean includesInternalStrategy = false;
        for (Email_Request__e e : requests) {
            recordIds.add(e.RecordId__c);
            if (e.Strategy__c == 'Internal') {
                includesInternalStrategy = true;
            }
        }
        Set<Id> queueUserIds = new Set<Id>();
        List<User> activeQueueUsers = new List<User>();
        // if none of the request included an Internal strategy, we can save some SOQL queries. Yippee!
        if (includesInternalStrategy) {
            // In this release we support only queues with users and queues with roles. Queues with groups, nested groups, or roles and subordinates, are not supported.
            Set<Id> groupIds = new Set<Id>();
            for (GroupMember gm : [
                SELECT UserOrGroupId
                FROM GroupMember
                WHERE Group.DeveloperName = :MTC_CASE_QUEUE
            ]) {
                if (String.valueOf(gm.UserOrGroupId.getSObjectType()) == 'User') {
                    queueUserIds.add(gm.UserOrGroupId);
                } else {
                    groupIds.add(gm.UserOrGroupId);
                }
            }
            Set<Id> roleIds = new Set<Id>();
            for (Group g : [
                SELECT Id, Type, RelatedId
                FROM Group
                WHERE Id IN :groupIds AND Type = 'Role'
            ]) {
                roleIds.add(g.RelatedId);
            }
            activeQueueUsers.addAll(
                [
                    SELECT Id
                    FROM User
                    WHERE
                    (UserRoleId IN :roleIds
                     OR Id IN :queueUserIds)
                    AND isActive = TRUE
                ]
            );
        }
        Map<Id, Case> caseIdToCaseMap = new Map<Id, Case>(
            [SELECT Id, CreatedById FROM Case WHERE Id IN :recordIds]
        );
        for (Email_Request__e e : requests) {
            List<User> recipients = new List<User>();
            Case c = caseIdToCaseMap.get(e.RecordId__c);
            if (e.Strategy__c == 'Internal') {
                for (User u : activeQueueUsers) {
                    recipients.add(new User(Id = u.Id));
                }
            } else {
                recipients.add(new User(Id = c.CreatedById));
            }
            emails.add(
                new EmailUtil.Email(
                    recipients,
                    e.RecordId__c,
                    e.Email_Template_Name__c,
                    e.Organization_Wide_Address__c
                )
            );
        }
        EmailUtil.sendEmails(
            emails
            //WithoutSharing.handleCaseEmailsAsCustomer(requests, MTC_CASE_QUEUE)
        );
    }
    
    private static void handleGroupMembershipEmails(
        List<Email_Request__e> requests
    ) {
        List<EmailUtil.Email> emails = new List<EmailUtil.Email>();
        Map<Id, Set<Id>> recordIdToContactIdsMap = new Map<Id, Set<Id>>();
        Set<Id> recordIds = new Set<Id>();
        for (Email_Request__e e : requests) {
            recordIds.add(e.RecordId__c);
        }
        for (Group_Membership__c gm : [
            SELECT Id, Contact__c
            FROM Group_Membership__c
            WHERE Id IN :recordIds
        ]) {
            if (recordIdToContactIdsMap.get(gm.Id) != null) {
                recordIdToContactIdsMap.get(gm.Id).add(gm.Contact__c);
            } else {
                recordIdToContactIdsMap.put(gm.Id, new Set<Id>{ gm.Contact__c });
            }
        }
        Map<Id, User> contactIdToUserMap = getContactIdToUserMap(
            recordIdToContactIdsMap.values()
        );
        for (Email_Request__e e : requests) {
            List<User> recipients = new List<User>();
            for (Id i : recordIdToContactIdsMap.get(e.RecordId__c)) {
                if (contactIdToUserMap.get(i) != null) {
                    recipients.add(contactIdToUserMap.get(i));
                }
            }
            emails.add(
                new EmailUtil.Email(
                    recipients,
                    e.RecordId__c,
                    e.Email_Template_Name__c,
                    e.Organization_Wide_Address__c
                )
            );
        }
        EmailUtil.sendEmails(emails);
    }
    
    private static void handleUserEmails(List<Email_Request__e> requests) {
        List<EmailUtil.Email> emails = new List<EmailUtil.Email>();
        for (Email_Request__e e : requests) {
            emails.add(
                new EmailUtil.Email(
                    new List<User>{ new User(Id = e.RecordId__c) },
                    e.RecordId__c,
                    e.Email_Template_Name__c,
                    e.Organization_Wide_Address__c
                )
            );
        }
        EmailUtil.sendEmails(emails);
    }
    private static void handleContactEmails(List<Email_Request__e> requests) {
        List<EmailUtil.Email> emails = new List<EmailUtil.Email>();
        Set<Id> contactIdsCGARequired = new Set<Id>();
        Set<Id> contactIds = new Set<Id>();
        // Set<Id> accountIds = new Set<Id>();
        for (Email_Request__e e : requests) {
            contactIds.add(e.RecordId__c);
            if (e.Strategy__c == 'cga') {
                contactIdsCGARequired.add(e.RecordId__c);
            }
            // else if (e.Strategy__c == 'contact') {}
        }
        Map<Id, Contact> contacts = new Map<Id, Contact>(
            [SELECT Id, Account.CGA_Id__c FROM Contact WHERE Id IN :contactIds]
        );
        List<User> cgas = new List<User>();
        if (!contactIdsCGARequired.isEmpty()) {
            Set<Id> cgaContactIds = new Set<Id>();
            for (Contact con : contacts.values()) {
                if (contactIdsCGARequired.contains(con.Id)) {
                    cgaContactIds.add(con.Account.CGA_Id__c);
                }
            }
            if (!cgaContactIds.isEmpty()) {
                cgas = [
                    SELECT Id, AccountId
                    FROM User
                    WHERE ContactId IN :cgaContactIds
                ];
            }
        }
        Map<Id, User> accountId2CGA = new Map<Id, User>();
        for (User cga : cgas) {
            accountId2CGA.put(cga.AccountId, cga);
        }
        
        for (Email_Request__e e : requests) {
            Contact thisCon = contacts.get(e.RecordId__c);
            if (e.Strategy__c == 'cga') {
                User cgaUser = accountId2CGA.get(thisCon.AccountId);
                emails.add(
                    new EmailUtil.Email(
                        new List<User>{ cgaUser },
                        e.RecordId__c,
                        e.Email_Template_Name__c,
                        e.Organization_Wide_Address__c
                    )
                );
            } else if (e.Strategy__c == 'contact') {
                emails.add(
                    new EmailUtil.Email(
                        new List<Contact>{ thisCon },
                        e.RecordId__c,
                        e.Email_Template_Name__c,
                        e.Organization_Wide_Address__c
                    )
                );
            }
        }
        EmailUtil.sendEmails(emails);
    }
    
    private static void handleBSCEmails(List<Email_Request__e> requests) {
        List<EmailUtil.Email> emails = new List<EmailUtil.Email>();
        Map<Id, Set<User>> recordIdToRecipientsMap = new Map<Id, Set<User>>();
        Map<Id, Set<Id>> accountIdToRecordIdsMap = new Map<Id, Set<Id>>();
        Map<String, Set<Id>> templateToRecordIdsMap = new Map<String, Set<Id>>();
        Set<Id> allRecordIds = new Set<Id>();
        Map<Id, Brand_Supplier_Connection__c> connectionIdToConnectionMap = new Map<Id, Brand_Supplier_Connection__c>();
        for (Email_Request__e e : requests) {
            allRecordIds.add(e.RecordId__c);
            if (templateToRecordIdsMap.containsKey(e.Email_Template_Name__c)) {
                templateToRecordIdsMap.get(e.Email_Template_Name__c).add(e.RecordId__c);
            } else {
                templateToRecordIdsMap.put(
                    e.Email_Template_Name__c,
                    new Set<Id>{ e.RecordId__c }
                );
            }
        }
        for (Brand_Supplier_Connection__c bsc : [
            SELECT
            Id,
            Brand_Account__c,
            Supplier_Account__c,
            Requestor_Contact__c,
            Disconnected_By__r.ToxClear_Account_Type__c
            FROM Brand_Supplier_Connection__c
            WHERE Id IN :allRecordIds
        ]) {
            connectionIdToConnectionMap.put(bsc.Id, bsc);
        }
        
        // Work through new connection request emails
        if (
            templateToRecordIdsMap.get(
                'ToxClear_Community_Supplier_Connection_Request'
            ) != null
        ) {
            // Sending to Brand Admins
            Set<Id> recordIds = templateToRecordIdsMap.get(
                'ToxClear_Community_Supplier_Connection_Request'
            );
            // Get all brand accounts to send to
            for (Id i : recordIds) {
                Brand_Supplier_Connection__c bsc = connectionIdToConnectionMap.get(i);
                if (accountIdToRecordIdsMap.containsKey(bsc.Brand_Account__c)) {
                    accountIdToRecordIdsMap.get(bsc.Brand_Account__c).add(bsc.Id);
                } else {
                    accountIdToRecordIdsMap.put(
                        bsc.Brand_Account__c,
                        new Set<Id>{ bsc.Id }
                    );
                }
            }
        }
        if (
            templateToRecordIdsMap.get(
                'ToxClear_Community_Brand_Connection_Request'
            ) != null
        ) {
            // Sending to Supplier Admins
            Set<Id> recordIds = templateToRecordIdsMap.get(
                'ToxClear_Community_Brand_Connection_Request'
            );
            // Get all supplier accounts to send to
            for (Id i : recordIds) {
                Brand_Supplier_Connection__c bsc = connectionIdToConnectionMap.get(i);
                if (accountIdToRecordIdsMap.containsKey(bsc.Supplier_Account__c)) {
                    accountIdToRecordIdsMap.get(bsc.Supplier_Account__c).add(bsc.Id);
                } else {
                    accountIdToRecordIdsMap.put(
                        bsc.Supplier_Account__c,
                        new Set<Id>{ bsc.Id }
                    );
                }
            }
        }
        for (User u : [
            SELECT Id, ContactId, Contact.AccountId
            FROM User
            WHERE
            Contact.AccountId IN :accountIdToRecordIdsMap.keySet()
            AND Contact.ToxClear_User_Type__c = 'ToxClear Administrator'
            AND isActive = TRUE
        ]) {
            for (Id i : accountIdToRecordIdsMap.get(u.Contact.AccountId)) {
                if (recordIdToRecipientsMap.containsKey(i)) {
                    recordIdToRecipientsMap.get(i).add(u);
                } else {
                    recordIdToRecipientsMap.put(i, new Set<User>{ u });
                }
            }
        }
        
        // Now work through any Approvals, Rejections, and Disconnections
        // Approvals first
        if (templateToRecordIdsMap.get('ToxClear_Approve_Connection') != null) {
            Set<Id> recordIds = templateToRecordIdsMap.get(
                'ToxClear_Approve_Connection'
            );
            Map<Id, User> contactIdToUserMap = new Map<Id, User>();
            // Get all Requester users to send to
            for (User u : [
                SELECT Id, ContactId
                FROM User
                WHERE
                IsActive = TRUE
                AND Connection_Request_Notifications__c = TRUE
                AND ContactId IN (
                    SELECT Requestor_Contact__c
                    FROM Brand_Supplier_Connection__c
                    WHERE Id IN :recordIds
                )
            ]) {
                contactIdToUserMap.put(u.ContactId, u);
            }
            for (Id i : recordIds) {
                if (connectionIdToConnectionMap.containsKey(i)) {
                    Brand_Supplier_Connection__c bsc = connectionIdToConnectionMap.get(i);
                    if (recordIdToRecipientsMap.containsKey(i)) {
                        recordIdToRecipientsMap.get(i)
                            .add(contactIdToUserMap.get(bsc.Requestor_Contact__c));
                    } else {
                        recordIdToRecipientsMap.put(
                            i,
                            new Set<User>{ contactIdToUserMap.get(bsc.Requestor_Contact__c) }
                        );
                    }
                }
            }
        }
        // Now rejections
        if (templateToRecordIdsMap.get('ToxClear_Reject_Connection') != null) {
            Set<Id> recordIds = templateToRecordIdsMap.get(
                'ToxClear_Reject_Connection'
            );
            Map<Id, User> contactIdToUserMap = new Map<Id, User>();
            // Get all Requester users to send to
            for (User u : [
                SELECT Id, ContactId
                FROM User
                WHERE
                IsActive = TRUE
                AND Connection_Request_Notifications__c = TRUE
                AND ContactId IN (
                    SELECT Requestor_Contact__c
                    FROM Brand_Supplier_Connection__c
                    WHERE Id IN :recordIds
                )
            ]) {
                contactIdToUserMap.put(u.ContactId, u);
            }
            for (Id i : recordIds) {
                if (connectionIdToConnectionMap.containsKey(i)) {
                    Brand_Supplier_Connection__c bsc = connectionIdToConnectionMap.get(i);
                    if (recordIdToRecipientsMap.containsKey(i)) {
                        recordIdToRecipientsMap.get(i)
                            .add(contactIdToUserMap.get(bsc.Requestor_Contact__c));
                    } else {
                        recordIdToRecipientsMap.put(
                            i,
                            new Set<User>{ contactIdToUserMap.get(bsc.Requestor_Contact__c) }
                        );
                    }
                }
            }
        }
        // Finally, disconnections
        if (templateToRecordIdsMap.get('ToxClear_Disconnect_Connection') != null) {
            Map<Id, Id> recordIdToSupplierAccountIdMap = new Map<Id, Id>();
            Map<Id, Id> recordIdToBrandAccountIdMap = new Map<Id, Id>();
            Set<Id> recordIds = templateToRecordIdsMap.get(
                'ToxClear_Disconnect_Connection'
            );
            // Build a map from connection Id to Supplier or Brand account Id, depending on who disconnected the connection
            for (Id i : recordIds) {
                if (connectionIdToConnectionMap.containsKey(i)) {
                    Brand_Supplier_Connection__c bsc = connectionIdToConnectionMap.get(i);
                    if (bsc.Disconnected_By__r.ToxClear_Account_Type__c == 'Brand') {
                        recordIdToSupplierAccountIdMap.put(bsc.Id, bsc.Supplier_Account__c);
                    } else if (
                        bsc.Disconnected_By__r.ToxClear_Account_Type__c == 'Supplier'
                    ) {
                        recordIdToBrandAccountIdMap.put(bsc.Id, bsc.Brand_Account__c);
                    }
                }
            }
            // Build a map from account Id to a set of (supplier/brand) admin users
            Map<Id, Set<User>> accountIdToUserListMap = new Map<Id, Set<User>>();
            for (User u : [
                SELECT Id, Contact.AccountId
                FROM User
                WHERE
                IsActive = TRUE
                AND Connection_Request_Notifications__c = TRUE
                AND Id IN (
                    SELECT AssigneeId
                    FROM PermissionSetAssignment
                    WHERE
                    PermissionSetGroup.DeveloperName = 'ToxClear_Supplier_Administrator'
                    OR PermissionSetGroup.DeveloperName = 'ToxClear_Brand_Administrator'
                )
                AND (Contact.AccountId IN :recordIdToSupplierAccountIdMap.values()
                     OR Contact.AccountId IN :recordIdToBrandAccountIdMap.values())
            ]) {
                if (accountIdToUserListMap.containsKey(u.Contact.AccountId)) {
                    accountIdToUserListMap.get(u.Contact.AccountId).add(u);
                } else {
                    accountIdToUserListMap.put(u.Contact.AccountId, new Set<User>{ u });
                }
            }
            // Build a map from connection Id to a set of Users (recipients) for each email
            for (Id i : recordIds) {
                Brand_Supplier_Connection__c bsc = connectionIdToConnectionMap.get(i);
                Set<User> users = new Set<User>();
                if (bsc.Disconnected_By__r.ToxClear_Account_Type__c == 'Brand') {
                    if (
                        recordIdToSupplierAccountIdMap.containsKey(bsc.Id) &&
                        accountIdToUserListMap.containsKey(
                            recordIdToSupplierAccountIdMap.get(bsc.Id)
                        )
                    ) {
                        users = accountIdToUserListMap.get(
                            recordIdToSupplierAccountIdMap.get(bsc.Id)
                        );
                    }
                } else if (
                    bsc.Disconnected_By__r.ToxClear_Account_Type__c == 'Supplier'
                ) {
                    if (
                        recordIdToBrandAccountIdMap.containsKey(bsc.Id) &&
                        accountIdToUserListMap.containsKey(
                            recordIdToBrandAccountIdMap.get(bsc.Id)
                        )
                    ) {
                        users = accountIdToUserListMap.get(
                            recordIdToBrandAccountIdMap.get(bsc.Id)
                        );
                    }
                }
                if (recordIdToRecipientsMap.get(i) != null) {
                    recordIdToRecipientsMap.get(i).addAll(users);
                } else {
                    recordIdToRecipientsMap.put(i, users);
                }
            }
        }
        // Build and send the emails
        for (Email_Request__e e : requests) {
            List<User> recipients = new List<User>(
                recordIdToRecipientsMap.get(e.RecordId__c)
            );
            emails.add(
                new EmailUtil.Email(
                    recipients,
                    e.RecordId__c,
                    e.Email_Template_Name__c,
                    e.Organization_Wide_Address__c
                )
            );
        }
        EmailUtil.sendEmails(emails);
    }
    
    private static void handleBulletinEmails(List<Email_Request__e> requests) {
        List<EmailUtil.Email> emails = new List<EmailUtil.Email>();
        Set<Id> recordIds = new Set<Id>();
        Map<String, List<Email_Request__e>> recipientGroupingToEmailRequestsMap = new Map<String, List<Email_Request__e>>{
            'brands' => new List<Email_Request__e>(),
                'suppliersFromBrand' => new List<Email_Request__e>(),
                'suppliersFromIntertek' => new List<Email_Request__e>(),
                'intertek' => new List<Email_Request__e>()
                };
                    for (Email_Request__e e : requests) {
                        recordIds.add(e.RecordId__c);
                    }
        Map<Id, Bulletin__c> recordIdToRecordMap = new Map<Id, Bulletin__c>(
            [
                SELECT
                Id,
                Target_Audience__c,
                Sent_From_Owner_Account__c,
                Sent_From_Owner_Account__r.ToxClear_Account_Type__c,
                Sent_by_Intertek__c
                FROM Bulletin__c
                WHERE
                Active__c = TRUE
                AND Id IN :recordIds
                AND Target_Audience__c != NULL
            ]
        );
        for (Email_Request__e e : requests) {
            if (recordIdToRecordMap.containsKey(e.RecordId__c)) {
                Bulletin__c b = recordIdToRecordMap.get(e.RecordId__c);
                // Target audience contains 'Brands'
                if (e.Strategy__c.contains('Brands')) {
                    recipientGroupingToEmailRequestsMap.get('brands').add(e);
                }
                // Target audience contains 'Suppliers' and send from is a Brand Account
                if (
                    e.Strategy__c.contains('Suppliers') &&
                    b.Sent_From_Owner_Account__r.ToxClear_Account_Type__c == 'Brand'
                ) {
                    recipientGroupingToEmailRequestsMap.get('suppliersFromBrand').add(e);
                }
                // Target audience contains 'Suppliers' and 'Sent by Intertek' is TRUE
                if (e.Strategy__c.contains('Suppliers') && b.Sent_by_Intertek__c) {
                    recipientGroupingToEmailRequestsMap.get('suppliersFromIntertek')
                        .add(e);
                }
                // Target audience contains 'Intertek'
                if (e.Strategy__c.contains('Intertek')) {
                    recipientGroupingToEmailRequestsMap.get('intertek').add(e);
                }
            }
        }
        
        // Get the recipients for the 'brands' recipient grouping
        if (recipientGroupingToEmailRequestsMap.get('brands').size() > 0) {
            List<User> recipients = new List<User>(
                [
                    SELECT Id
                    FROM User
                    WHERE
                    IsActive = TRUE
                    AND Bulletin_Notifications__c = TRUE
                    AND Id IN (
                        SELECT AssigneeId
                        FROM PermissionSetAssignment
                        WHERE
                        PermissionSetGroup.DeveloperName = 'ToxClear_Brand_Standard_User'
                        OR PermissionSetGroup.DeveloperName = 'ToxClear_Brand_Administrator'
                    )
                ]
            );
            for (
                Email_Request__e e : recipientGroupingToEmailRequestsMap.get('brands')
            ) {
                emails.add(
                    new EmailUtil.Email(
                        recipients,
                        e.RecordId__c,
                        e.Email_Template_Name__c,
                        e.Organization_Wide_Address__c
                    )
                );
            }
        }
        
        // Get the recipients for the 'suppliersFromBrand' recipient grouping
        if (
            recipientGroupingToEmailRequestsMap.get('suppliersFromBrand').size() > 0
        ) {
            Set<Id> sentFromAccountIds = new Set<Id>();
            for (
                Email_Request__e e : recipientGroupingToEmailRequestsMap.get(
                    'suppliersFromBrand'
                )
            ) {
                Bulletin__c b = recordIdToRecordMap.get(e.RecordId__c);
                sentFromAccountIds.add(b.Sent_From_Owner_Account__c);
            }
            
            Map<Id, Set<Id>> brandIdToSupplierIdsMap = new Map<Id, Set<Id>>();
            for (Brand_Supplier_Connection__c bsc : [
                SELECT Supplier_Account__c, Brand_Account__c
                FROM Brand_Supplier_Connection__c
                WHERE Status__c = 'Approved' AND Brand_Account__c IN :sentFromAccountIds
            ]) {
                if (brandIdToSupplierIdsMap.containsKey(bsc.Brand_Account__c)) {
                    brandIdToSupplierIdsMap.get(bsc.Brand_Account__c)
                        .add(bsc.Supplier_Account__c);
                } else {
                    brandIdToSupplierIdsMap.put(
                        bsc.Brand_Account__c,
                        new Set<Id>{ bsc.Supplier_Account__c }
                    );
                }
            }
            Set<Id> allSupplierIds = new Set<Id>();
            for (Set<Id> idSet : brandIdToSupplierIdsMap.values()) {
                allSupplierIds.addAll(idSet);
            }
            
            Map<Id, List<User>> supplierIdToRecipientsMap = new Map<Id, List<User>>();
            for (User u : [
                SELECT Id, Contact.AccountId, Contact.Account.ParentId
                FROM User
                WHERE
                IsActive = TRUE
                AND Bulletin_Notifications__c = TRUE
                AND Id IN (
                    SELECT AssigneeId
                    FROM PermissionSetAssignment
                    WHERE
                    PermissionSetGroup.DeveloperName = 'ToxClear_Supplier_Standard_User'
                    OR PermissionSetGroup.DeveloperName = 'ToxClear_Supplier_Administrator'
                )
                AND (Contact.AccountId IN :allSupplierIds
                     OR Contact.Account.ParentId IN :allSupplierIds)
            ]) {
                if (u.Contact.Account.ParentId != null) {
                    if (
                        supplierIdToRecipientsMap.containsKey(u.Contact.Account.ParentId)
                    ) {
                        supplierIdToRecipientsMap.get(u.Contact.Account.ParentId).add(u);
                    } else {
                        supplierIdToRecipientsMap.put(
                            u.Contact.Account.ParentId,
                            new List<User>{ u }
                        );
                    }
                } else {
                    if (supplierIdToRecipientsMap.containsKey(u.Contact.AccountId)) {
                        supplierIdToRecipientsMap.get(u.Contact.AccountId).add(u);
                    } else {
                        supplierIdToRecipientsMap.put(
                            u.Contact.AccountId,
                            new List<User>{ u }
                        );
                    }
                }
            }
            
            for (
                Email_Request__e e : recipientGroupingToEmailRequestsMap.get(
                    'suppliersFromBrand'
                )
            ) {
                List<User> recipients = new List<User>();
                Bulletin__c b = recordIdToRecordMap.get(e.RecordId__c);
                for (
                    Id supplierId : brandIdToSupplierIdsMap.get(
                        b.Sent_From_Owner_Account__c
                    )
                ) {
                    for (User u : supplierIdToRecipientsMap.get(supplierId)) {
                        recipients.add(u);
                    }
                }
                emails.add(
                    new EmailUtil.Email(
                        recipients,
                        e.RecordId__c,
                        e.Email_Template_Name__c,
                        e.Organization_Wide_Address__c
                    )
                );
            }
        }
        
        // Get the recipients for the 'suppliersFromIntertek' recipient grouping
        if (
            recipientGroupingToEmailRequestsMap.get('suppliersFromIntertek').size() >
            0
        ) {
            List<User> recipients = new List<User>(
                [
                    SELECT Id
                    FROM User
                    WHERE
                    IsActive = TRUE
                    AND Bulletin_Notifications__c = TRUE
                    AND Id IN (
                        SELECT AssigneeId
                        FROM PermissionSetAssignment
                        WHERE
                        PermissionSetGroup.DeveloperName = 'ToxClear_Supplier_Standard_User'
                        OR PermissionSetGroup.DeveloperName = 'ToxClear_Supplier_Administrator'
                    )
                ]
            );
            for (
                Email_Request__e e : recipientGroupingToEmailRequestsMap.get(
                    'suppliersFromIntertek'
                )
            ) {
                emails.add(
                    new EmailUtil.Email(
                        recipients,
                        e.RecordId__c,
                        e.Email_Template_Name__c,
                        e.Organization_Wide_Address__c
                    )
                );
            }
        }
        
        // Get the recipients for the 'intertek' recipient grouping
        if (recipientGroupingToEmailRequestsMap.get('intertek').size() > 0) {
            List<User> recipients = new List<User>(
                [
                    SELECT Id
                    FROM User
                    WHERE
                    IsActive = TRUE
                    AND Bulletin_Notifications__c = TRUE
                    AND Id IN (
                        SELECT AssigneeId
                        FROM PermissionSetAssignment
                        WHERE
                        PermissionSetGroup.DeveloperName = 'ToxClear_Intertek_Back_Office_Administrator'
                        OR PermissionSetGroup.DeveloperName = 'ToxClear_Customer_Services_Representatives'
                        OR PermissionSetGroup.DeveloperName = 'ToxClear_Internal_Light_No_Case_Access'
                    )
                ]
            );
            for (
                Email_Request__e e : recipientGroupingToEmailRequestsMap.get('intertek')
            ) {
                emails.add(
                    new EmailUtil.Email(
                        recipients,
                        e.RecordId__c,
                        e.Email_Template_Name__c,
                        e.Organization_Wide_Address__c
                    )
                );
            }
        }
        EmailUtil.sendEmails(emails);
    }
    
    private static void handleInventoryEmails(List<Email_Request__e> requests) {
        List<EmailUtil.Email> emails = new List<EmailUtil.Email>();
        Map<Id, Set<User>> recordIdToRecipientsMap = new Map<Id, Set<User>>();
        Map<Id, Set<Id>> accountIdToRecordIdsMap = new Map<Id, Set<Id>>();
        Set<Id> recordIds = new Set<Id>();
        for (Email_Request__e e : requests) {
            recordIds.add(e.RecordId__c);
        }
        
        for (Inventory__c i : [
            SELECT Id, Facility__c
            FROM Inventory__c
            WHERE Id IN :recordIds
        ]) {
            if (accountIdToRecordIdsMap.get(i.Facility__c) != null) {
                accountIdToRecordIdsMap.get(i.Facility__c).add(i.Id);
            } else {
                accountIdToRecordIdsMap.put(i.Facility__c, new Set<Id>{ i.Id });
            }
        }
        
        for (User u : [
            SELECT Id, ContactId, Contact.Main_Facility__c
            FROM User
            WHERE
            Contact.Main_Facility__c IN :accountIdToRecordIdsMap.keySet()
            AND Inventory_Report_Reminder_Notifications__c = TRUE
            AND isActive = TRUE
        ]) {
            for (Id i : accountIdToRecordIdsMap.get(u.Contact.Main_Facility__c)) {
                if (recordIdToRecipientsMap.get(i) != null) {
                    recordIdToRecipientsMap.get(i).add(u);
                } else {
                    recordIdToRecipientsMap.put(i, new Set<User>{ u });
                }
            }
        }
        
        for (Email_Request__e e : requests) {
            List<User> recipients = new List<User>(
                recordIdToRecipientsMap.get(e.RecordId__c)
            );
            emails.add(
                new EmailUtil.Email(
                    recipients,
                    e.RecordId__c,
                    e.Email_Template_Name__c,
                    e.Organization_Wide_Address__c
                )
            );
        }
        EmailUtil.sendEmails(emails);
    }
    
    private static Map<Id, User> getContactIdToUserMap(
        List<Set<Id>> contactIdSets
    ) {
        Map<Id, User> contactIdToUserMap = new Map<Id, User>();
        Set<Id> allContactIds = new Set<Id>();
        for (Set<Id> i : contactIdSets) {
            allContactIds.addAll(i);
        }
        for (User u : [
            SELECT Id, ContactId
            FROM User
            WHERE ContactId IN :allContactIds AND isActive = TRUE
        ]) {
            contactIdToUserMap.put(u.ContactId, u);
        }
        return contactIdToUserMap;
    }
}