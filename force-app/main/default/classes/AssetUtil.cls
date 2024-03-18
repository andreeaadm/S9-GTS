public with sharing class AssetUtil {
    public static final Integer DEFAULT_TEMP_USER_EXPIRY = 30;
    public static SchemaUtil.RecordType reportRT {
        get {
            if (reportRT == null) {
                reportRT = SchemaUtil.getRecordType('Asset', 'MTC_Report');
            }
            return reportRT;
        }
        private set;
    }
    public static SchemaUtil.RecordType deliverableRT {
        get {
            if (deliverableRT == null) {
                deliverableRT = SchemaUtil.getRecordType('Asset', 'MTC_Deliverable');
            }
            return deliverableRT;
        }
        private set;
    }
    
    public static List<Asset> filterReportWithAccountChange(
        List<Asset> assets,
        Map<Id, Asset> oldAssets
    ) {
        List<Asset> reportsWithAccountChange = new List<Asset>();
        for (Asset report : assets) {
            if (
                report.RecordTypeId == reportRT.recordId &&
                report.AccountId != oldAssets.get(report.Id).AccountId
            ) {
                reportsWithAccountChange.add(report);
            }
        }
        return reportsWithAccountChange;
    }
    
    public static void cleanupRefsAfterTransfer(List<Asset> reportsToProcess) {
        Set<Id> contactIds = new Set<Id>();
        for (Asset report : reportsToProcess) {
            if (report.ContactId != null) {
                contactIds.add(report.ContactId);
            }
        }
        
        Map<Id, Contact> contacts = new Map<Id, Contact>(
            [SELECT Name, Email FROM Contact WHERE Id IN :contactIds]
        );
        
        Map<Id, Asset> reportsToUpdate = new Map<Id, Asset>();
        for (Asset report : reportsToProcess) {
            String priorContact = '';
            if (report.ContactId != null && contacts.containsKey(report.ContactId)) {
                Contact con = contacts.get(report.ContactId);
                priorContact = con.Name + ' (' + con.Email + ')';
            }
            reportsToUpdate.put(
                report.Id,
                new Asset(
                    Id = report.Id,
                    ContactId = null,
                    Prior_ReportContact__c = priorContact
                )
            );
        }
        List<Access__c> accessesToDelete = [
            SELECT Id
            FROM Access__c
            WHERE Report_Asset__c IN :reportsToUpdate.keySet()
        ];
        
        update reportsToUpdate.values();
        delete accessesToDelete;
    }
    
    public static List<Asset> filterReports(List<Asset> assets) {
        List<Asset> result = new List<Asset>();
        for (Asset asset : assets) {
            if (asset.RecordTypeId == reportRT.recordId) {
                result.add(asset);
            }
        }
        return result;
    }
    public static List<Asset> filterDeliverables(List<Asset> assets) {
        List<Asset> result = new List<Asset>();
        for (Asset asset : assets) {
            if (asset.RecordTypeId == deliverableRT.recordId) {
                result.add(asset);
            }
        }
        return result;
    }
    
    public static List<Asset> filterContactless(List<Asset> assets) {
        List<Asset> withContacts = new List<Asset>();
        for (Asset asset : assets) {
            if (asset.ContactId != null) {
                withContacts.add(asset);
            }
        }
        return withContacts;
    }
    public static List<Asset> filterDateless(List<Asset> assets) {
        List<Asset> withDates = new List<Asset>();
        for (Asset asset : assets) {
            if (asset.Date_Issued__c != null || asset.Date_Revised__c != null) {
                withDates.add(asset);
            }
        }
        return withDates;
    }
    
    public static List<Asset> getReportsWithActiveAccessesFromAccountIds(
        Set<Id> accountIds
    ) {
        if (accountIds.isEmpty()) {
            return new List<Asset>();
        }
        List<Asset> reports = [
            SELECT
            Id,
            AccountId,
            Name,
            Type__c,
            (
                SELECT Id, Contact_Group__r.Expiry__c
                FROM Report_Accesses__r
                WHERE
                Contact_Group__r.Expiry__c = NULL
                OR Contact_Group__r.Expiry__c >= TODAY
            )
            FROM Asset
            WHERE AccountId IN :accountIds AND RecordTypeId = :reportRT.recordId
        ];
        return reports;
    }
    
    public static Map<Id, Asset> getReportsWithDeliverables(Set<Id> reportIds) {
        if (reportIds.isEmpty()) {
            return new Map<Id, Asset>();
        }
        Map<Id, Asset> reportsWithDeliverables = new Map<Id, Asset>(
            [
                SELECT
                Id,
                AccountId,
                RecordTypeId,
                Name,
                Type__c,
                (
                    SELECT Id, AccountId, RecordTypeId, Name, Type__c
                    FROM ChildAssets
                    WHERE RecordTypeId = :deliverableRT.recordId
                )
                FROM Asset
                WHERE Id IN :reportIds AND RecordTypeId = :reportRT.recordId
            ]
        );
        return reportsWithDeliverables;
    }
    public static Set<Id> getReportIdsFromAccountIds(Set<Id> accountIds) {
        if (accountIds.isEmpty()) {
            return new Set<Id>();
        }
        Set<Id> reportIds = (new Map<Id, Asset>(
            [
                SELECT Id
                FROM Asset
                WHERE AccountId IN :accountIds AND RecordTypeId = :reportRT.recordId
            ]
        ))
            .keySet();
        
        return reportIds;
    }
    // when deliverable(asset) created/updated set contactId to parent's contactId
    public static void alignContactIdWithParentContactId(
        List<Asset> assets,
        Map<Id, Asset> oldAssets
    ) {
        Map<Id, Asset> deliverables = new Map<Id, Asset>();
        Map<Id, Asset> reports = new Map<Id, Asset>();
        Set<Id> parentIds = new Set<Id>();
        for (Asset a : assets) {
            if (a.RecordTypeId == deliverableRT.recordId && a.ParentId != null) {
                deliverables.put(a.Id, a);
                parentIds.add(a.ParentId);
            }
            if (a.RecordTypeId == reportRT.recordId) {
                reports.put(a.Id, a);
            }
        }
        if (!deliverables.isEmpty()) {
            updateDeliverablesContactId(deliverables, parentIds);
        }
        if (!reports.isEmpty()) {
            alignChildContactIdWithContactId(reports, oldAssets);
        }
    }
    static void updateDeliverablesContactId(
        Map<Id, Asset> deliverables,
        Set<Id> parentIds
    ) {
        if (parentIds.isEmpty()) {
            return;
        }
        Map<Id, Asset> parents = new Map<Id, Asset>(
            [SELECT Id, ContactId FROM Asset WHERE Id IN :parentIds]
        );
        if (parents.isEmpty()) {
            return;
        }
        
        List<Asset> delivsToUpdate = new List<Asset>();
        for (Asset a : deliverables.values()) {
            if (!parents.containsKey(a.ParentId)) {
                continue;
            }
            if (a.ContactId != parents.get(a.ParentId).ContactId) {
                delivsToUpdate.add(
                    new Asset(Id = a.Id, ContactId = parents.get(a.ParentId).ContactId)
                );
            }
        }
        update delivsToUpdate;
    }
    
    public static void alignChildContactIdWithContactId(
        Map<Id, Asset> reports,
        Map<Id, Asset> oldAssets
    ) {
        if (reports.isEmpty()) {
            return;
        }
        List<Asset> deliverables = [
            SELECT ContactId, ParentId
            FROM Asset
            WHERE ParentId IN :reports.keySet()
        ];
        
        List<Asset> delivsToUpdate = new List<Asset>();
        for (Asset a : deliverables) {
            if (a.ContactId != reports.get(a.ParentId).ContactId) {
                delivsToUpdate.add(
                    new Asset(Id = a.Id, ContactId = reports.get(a.ParentId).ContactId)
                );
            }
        }
        update delivsToUpdate;
    }
    
    public static void updateTokenizedProdCoveredNoDML(
        List<Asset> newAssets,
        Map<Id, Asset> oldAssets
    ) {
        for (Asset a : newAssets) {
            if (String.isEmpty(a.Products_Covered__c)) {
                continue;
            }
            if (a.Products_Covered__c.length() <= 255) {
                a.Tokenized_Products_Covered__c = a.Products_Covered__c;
            } else {
                String oldValue = '';
                if (
                    oldAssets != null &&
                    oldAssets.containsKey(a.Id) &&
                    !String.isEmpty(oldAssets.get(a.Id).Products_Covered__c)
                ) {
                    oldValue = oldAssets.get(a.Id).Products_Covered__c;
                }
                if (!oldValue.equalsIgnoreCase(a.Products_Covered__c)) {
                    a.Tokenized_Products_Covered__c = StringUtil.tokenize(
                        a.Products_Covered__c,
                        '[,\\s\n]'
                    );
                }
            }
        }
    }
    
    public static void updateLastActivityDateWhenNewAsset(List<Asset> reports) {
      List<Asset> assetsToBeUpdatedWithLastActivityDate = new List<Asset>(); 
      List<Asset> assetsFromTriggerNew = new List<Asset>();
        Set<Id> assetId = new Set<Id>();
        for(Asset ast : reports){
            assetId.add(ast.Id);
        }
        assetsFromTriggerNew = [Select Id,Date_Issued__c,Date_Revised__c,Last_Activity_Date__c From Asset Where ID IN:assetId];
        for(Asset a : assetsFromTriggerNew){
            if(a.Date_Issued__c != null){
                a.Last_Activity_Date__c = a.Date_Issued__c;
                assetsToBeUpdatedWithLastActivityDate.add(a);
            }
            else if(a.Date_Revised__c != null){
                a.Last_Activity_Date__c = a.Date_Revised__c;
                assetsToBeUpdatedWithLastActivityDate.add(a);
            }
            else if(a.Date_Issued__c != null && a.Date_Revised__c != null){
                    if(a.Date_Issued__c > a.Date_Revised__c){
                        a.Last_Activity_Date__c = a.Date_Issued__c; 
                    }
                    else if(a.Date_Revised__c > a.Date_Issued__c){
                        a.Last_Activity_Date__c = a.Date_Revised__c;  
                    }
                    else if(a.Date_Revised__c == a.Date_Issued__c){
                        a.Last_Activity_Date__c = a.Date_Revised__c; 
                    }  
                }
                assetsToBeUpdatedWithLastActivityDate.add(a);
            }
        Map<Id,Asset> astMap = new Map<Id,Asset>();
        astMap.putAll(assetsToBeUpdatedWithLastActivityDate);
        if(astMap.size() > 0) {
           update astMap.values(); 
        }
    }
    
    public static void updateLastActivityDate(List<Asset> reportsWithDateChanges,Map<Id,Asset> oldAssets)
    {
        List<Asset> assetsToBeUpdatedWithLastActivityDate = new List<Asset>();
        List<Asset> assetsFromTriggerNew = new List<Asset>();
        Set<Id> assetId = new Set<Id>();
        for(Asset ast : reportsWithDateChanges){
            assetId.add(ast.Id);
        }
        assetsFromTriggerNew = [Select Id,Date_Issued__c,Date_Revised__c,Last_Activity_Date__c From Asset Where ID IN:assetId];
        for(Asset a : assetsFromTriggerNew){
            if(a.Date_Issued__c != oldAssets.get(a.Id).Date_Issued__c && a.Date_Issued__c != null){
                a.Last_Activity_Date__c = a.Date_Issued__c;
                assetsToBeUpdatedWithLastActivityDate.add(a);
            }
            else if(a.Date_Revised__c != oldAssets.get(a.Id).Date_Revised__c && a.Date_Revised__c != null){
                a.Last_Activity_Date__c = a.Date_Revised__c;
                assetsToBeUpdatedWithLastActivityDate.add(a);
            }
            else if(a.Date_Issued__c != oldAssets.get(a.Id).Date_Issued__c && a.Date_Revised__c != oldAssets.get(a.Id).Date_Revised__c){
                if(a.Date_Issued__c != null && a.Date_Revised__c != null){
                    if(a.Date_Issued__c > a.Date_Revised__c){
                        a.Last_Activity_Date__c = a.Date_Issued__c; 
                    }
                    else if(a.Date_Revised__c > a.Date_Issued__c){
                        a.Last_Activity_Date__c = a.Date_Revised__c;  
                    }
                    else if(a.Date_Revised__c == a.Date_Issued__c){
                        a.Last_Activity_Date__c = a.Date_Revised__c; 
                    }  
                }
                assetsToBeUpdatedWithLastActivityDate.add(a);
            }
        }
        update assetsToBeUpdatedWithLastActivityDate;
    }  
    
    public static List<Asset> filterReportWithDateChange(
        List<Asset> newAssets,
        Map<Id, Asset> oldAssets)
    {
        List<Asset> reportsWithDateChanges = new List<Asset>();
        for (Asset report : newAssets) {
            if (
                report.RecordTypeId == reportRT.recordId &&
                report.Date_Issued__c != oldAssets.get(report.Id).Date_Issued__c
            ) {
                reportsWithDateChanges.add(report);
            }
            else if(
                report.RecordTypeId == reportRT.recordId &&
                report.Date_Revised__c != oldAssets.get(report.Id).Date_Revised__c
            ){
                reportsWithDateChanges.add(report); 
            }
            else if
                (
                    report.RecordTypeId == reportRT.recordId &&
                    report.Date_Revised__c != oldAssets.get(report.Id).Date_Revised__c && report.Date_Issued__c != oldAssets.get(report.Id).Date_Issued__c  
                ){
                    reportsWithDateChanges.add(report);
                }
        }
        return reportsWithDateChanges;
    }
    //Prateek 
    public static void updateAssetSyncDate(List<Asset> newAssets, Map<Id, Asset> oldAssets){
        List<Asset_Contact_Relationship__c > newACRToInsert = new List<Asset_Contact_Relationship__c>(); 
        List<AccountContactRelation> accR = new list<AccountContactRelation>();
        set<Id> contactIdset = new set<Id>();
        if(oldAssets==null){
            for (Asset report : newAssets) {
                if(report.AccountId != null && report.ContactId != null){
                    accR = [Select Id,MTC_Role__c, ContactId, AccountId from AccountContactRelation where ContactId =: report.ContactId and AccountID =: report.AccountId limit 1];
                }
                if(accR != null && accR.size() > 0){
                    Asset_Contact_Relationship__c  acr=new Asset_Contact_Relationship__c();
                    acr.Asset__c= report.Id;
                    acr.Contact__c=report.ContactId;
                    acr.Asset_Synced_Date__c=System.today();
                    if(accR[0].MTC_Role__c == 'Restricted'){
                        acr.Restricted_Role__c = true;
                        contactIdset.add(report.ContactId);
                    }
                    newACRToInsert.add(acr);
                   
                } 
            }
            
        }
        else{
            for (Asset report : newAssets) {
                if (report.ContactId!=oldAssets.get(report.Id).ContactId && report.AccountId != null) {
                    accR = [Select Id,MTC_Role__c, ContactId, AccountId from AccountContactRelation where ContactId =: report.ContactId and AccountID =: report.AccountId limit 1];
                }
                if(accR != null && accR.size() > 0){
                    Asset_Contact_Relationship__c  acr=new Asset_Contact_Relationship__c();
                    acr.Asset__c= report.Id;
                    acr.Contact__c=report.ContactId;
                    acr.Asset_Synced_Date__c=System.today();
                    if(accR[0].MTC_Role__c == 'Restricted'){
                        acr.Restricted_Role__c = true;
                        contactIdset.add(report.ContactId);
                    }
                    newACRToInsert.add(acr);
                    
                } 
            }
        }
        if(!newACRToInsert.isempty()){
            insert newACRToInsert; } 
        List<User> usertoUpdate = new List<User>();
        if(!contactIdset.isEmpty()){
            for(User us : [Select id,ContactId,Date_Expires__c from User where ContactId IN:contactIdset ]){
                us.Date_Expires__c = System.today().addDays(30);
                usertoUpdate.add(us);
            }
        }
        if(!usertoUpdate.isempty()){
            update usertoUpdate; } 
    }   
}