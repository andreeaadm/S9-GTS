public with sharing class GTSJobRequestController {
	private static Id cocRecTypeId = Schema.SObjectType.icare_Job_Request__c.getRecordTypeInfosByDeveloperName().get('GTS_Certificate_of_Conformity_Request').getRecordTypeId();
	private static Id licenseRecTypeId = Schema.SObjectType.icare_Job_Request__c.getRecordTypeInfosByDeveloperName().get('GTS_Registration_License_Product_Certificate_Request').getRecordTypeId();
	private static Id tradeableRecTypeId = Schema.SObjectType.icare_Job_Request__c.getRecordTypeInfosByDeveloperName().get('GTS_Commercial_Service_Request').getRecordTypeId();

	@AuraEnabled(cacheable=true)
	public static String getCertifications() {

		List<GTS_Certificate__c> certifications = [SELECT Id, Name FROM GTS_Certificate__c];
		return JSON.serialize(certifications);
	}

	@AuraEnabled
	public static List<Id> getContentDocumentVersion(String jobRequestId) {
		List<ContentDocumentLink> contentDocumentLinks = [Select id, ContentDocumentId from ContentDocumentLink where LinkedEntityId = :jobRequestId];
		List<Id> contentVersionIds = new List<Id>();

		if(contentDocumentLinks != null && !contentDocumentLinks.isEmpty()) {
			List<Id> docIds = new List<Id>();
			for (ContentDocumentLink contentDocLink : contentDocumentLinks) {
				docIds.add(contentDocLink.ContentDocumentId);
			}

			Map<Id, ContentVersion> contentVersion = new Map<Id, ContentVersion>([SELECT Id, ContentDocumentId FROM ContentVersion WHERE ContentDocumentId IN :docIds]);
			contentVersionIds.addAll(contentVersion.keySet());
		}
		return contentVersionIds;
	}

	@AuraEnabled
	public static icare_Job_Request__c createDraftJobRequest(icare_Job_Request__c jobRequest, String recordType) {
		jobRequest.RecordTypeId = Schema.SObjectType.icare_Job_Request__c.getRecordTypeInfosByDeveloperName().get(recordType).getRecordTypeId();
		insert jobRequest;
		return jobRequest;
	}
	@AuraEnabled
	public static String getRecordTypeByApiName(String recordTypeApiName) {
		Id recordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'icare_Job_Request__c' AND DeveloperName = :recordTypeApiName LIMIT 1].Id;
		return recordTypeId;
	}

	@AuraEnabled
	public static List<icare_Job_Request__c> getJobRequests() {
		try {

			List<Id> recordTypeIds = new List<Id>{
				cocRecTypeId,
				licenseRecTypeId,
				tradeableRecTypeId
			};

			List<icare_Job_Request__c> favouriteJobRecords = [
				SELECT Id, Name, LastModifiedDate, iCare_Sample_Description__c, iCare_Favourite_Name__c, RecordType.Name, iCare_Draft_ETRF__c
				FROM icare_Job_Request__c
				WHERE RecordTypeId IN :recordTypeIds
				AND iCare_Favourite_Name__c != NULL
				AND iCare_Draft_ETRF__c = FALSE
				AND OwnerId = :userinfo.getUserId()
				Order By LastModifiedDate desc
				LIMIT 5
			];
			List<icare_Job_Request__c> draftJobRecords =[
				SELECT Id, Name, LastModifiedDate, iCare_Sample_Description__c, iCare_Favourite_Name__c, RecordType.Name, iCare_Draft_ETRF__c
				FROM icare_Job_Request__c
				WHERE RecordTypeId IN :recordTypeIds
				AND iCare_Draft_ETRF__c = TRUE
				AND OwnerId = :userinfo.getUserId()
				Order By LastModifiedDate desc
				LIMIT 5
			];

			List<icare_Job_Request__c> jobRequestList = new List<icare_Job_Request__c>();
			if(!favouriteJobRecords.isEmpty()){
				jobRequestList.addAll(favouriteJobRecords);
			}

			if(!draftJobRecords.isEmpty()){
				jobRequestList.addAll(draftJobRecords);
			}
			return jobRequestList;

		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	@AuraEnabled(cacheable=true)
	public static List<String> getMandatoryFieldsFromProgramName(String programName) {
		String query = 'SELECT ';
		Map<String, Schema.SObjectField> fieldsMap = Schema.getGlobalDescribe().get('GTS_Program_Shipment_Document__mdt').getDescribe().fields.getMap();

		for (String fieldName : fieldsMap.keySet()) {
			query += fieldName + ',';
		}

		query = query.substring(0, query.length() - 1); // Remove the trailing comma
		query += ' FROM GTS_Program_Shipment_Document__mdt WHERE Program_Name__c = :programName LIMIT 1';

		// Execute the query
		GTS_Program_Shipment_Document__mdt programShipmentDocumentsMtd =(GTS_Program_Shipment_Document__mdt) Database.query(query);

		List<String> mandatoryFields = new List<String>();

		for (String fieldName : fieldsMap.keySet()) {
			if(Schema.getGlobalDescribe().get('GTS_Program_Shipment_Document__mdt').getDescribe().fields.getMap().get(fieldName).getDescribe().getType() ==  DisplayType.BOOLEAN){
				if(programShipmentDocumentsMtd.get(fieldName) == true){
					mandatoryFields.add(fieldName);
				}
			}
		}

		return mandatoryFields;
	}

	@AuraEnabled
	public static List<icare_Job_Request__c> getAllDraftJobRequests(Integer v_Offset, Integer v_pagesize){
		try {

			List<Id> recordTypeIds = new List<Id>{
				cocRecTypeId,
				licenseRecTypeId,
				tradeableRecTypeId
			};

			List<icare_Job_Request__c> draftJobRecords = [
				SELECT Id, Name, LastModifiedDate, iCare_Sample_Description__c, iCare_Favourite_Name__c, RecordType.Name, iCare_Draft_ETRF__c
				FROM icare_Job_Request__c
				WHERE RecordTypeId IN :recordTypeIds
				AND iCare_Draft_ETRF__c = TRUE
				Order By LastModifiedDate desc
				LIMIT :v_pagesize OFFSET :v_Offset
			];

			return draftJobRecords;

		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	@AuraEnabled
	public static List<icare_Job_Request__c> getAllFavJobRequests(Integer v_Offset, Integer v_pagesize) {
		try {

			List<Id> recordTypeIds = new List<Id>{
				cocRecTypeId,
				licenseRecTypeId,
				tradeableRecTypeId
			};

			List<icare_Job_Request__c> favouriteJobRecords = [
				SELECT Id, Name, LastModifiedDate, iCare_Sample_Description__c, iCare_Favourite_Name__c, RecordType.Name, iCare_Draft_ETRF__c
				FROM icare_Job_Request__c
				WHERE RecordTypeId IN :recordTypeIds
				AND iCare_Favourite_Name__c != NULL
				AND iCare_Draft_ETRF__c = FALSE
				Order By LastModifiedDate desc
				LIMIT :v_pagesize OFFSET :v_Offset
			];
			return favouriteJobRecords;

		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	@AuraEnabled
	public static icare_Job_Request__c getJobRequest(Id recordId) {

		String fields = getFields();
		// Build and execute SOQL query
		String queryString = 'SELECT ' + fields + ' FROM icare_Job_Request__c WHERE Id = :recordId LIMIT 1';
		List<icare_Job_Request__c> records = Database.query(queryString);
		System.debug(records[0].GTS_Program__r.Name);

		// Check if a record is found
		if (!records.isEmpty()) {
			return records[0];
		} else {
			return null;
		}
	}

	@AuraEnabled
	public static Integer totalRecords(Boolean isFavorite){
		List<Id> recordTypeIds = new List<Id>{
			cocRecTypeId,
			licenseRecTypeId,
			tradeableRecTypeId
		};
		if(isFavorite){
			List<icare_Job_Request__c> draftJobRecords = [
				SELECT Id, Name, LastModifiedDate, iCare_Sample_Description__c, iCare_Favourite_Name__c, RecordType.Name, iCare_Draft_ETRF__c
				FROM icare_Job_Request__c
				WHERE RecordTypeId IN :recordTypeIds
				AND iCare_Favourite_Name__c != null
				Order By LastModifiedDate desc
			];
			return draftJobRecords.size();
		}else {
			List<icare_Job_Request__c> draftJobRecords = [
				SELECT Id, Name, LastModifiedDate, iCare_Sample_Description__c, iCare_Favourite_Name__c, RecordType.Name, iCare_Draft_ETRF__c
				FROM icare_Job_Request__c
				WHERE RecordTypeId IN :recordTypeIds
				AND iCare_Draft_ETRF__c = TRUE
				Order By LastModifiedDate desc
			];
			return draftJobRecords.size();
		}
	}

	private static String getFields() {
		return
			'GTS_Applicant_Type__c,' +
				'GTS_Client_Reference__c,' +
				'GTS_CoC_Declaration_1__c,' +
				'GTS_CoC_Declaration_2__c,' +
				'GTS_CoC_Declaration_3__c,' +
				'iCare_Draft_ETRF__c,' +
				'iCare_Applicant_Company__c,' +
				'GTS_Applicant_Company_Name__c,' +
				'iCare_Applicant_Address__City__s,' +
				'iCare_Applicant_Address__CountryCode__s,' +
				'iCare_Applicant_Address__PostalCode__s,' +
				'iCare_Applicant_Address__Street__s,' +
				'iCare_Applicant_Address__StateCode__s,' +
				'GTS_Commercial_Registration_No_TIN__c,' +
				'GTS_Applicant_Contact_Person__c,' +
				'GTS_Applicant_Contact_Number__c,' +
				'iCare_Applicant_Contact_Person_Name__c,' +
				'iCare_Applicant_Email__c,' +
				'GTS_Importer_Company_Name__c,' +
				'GTS_Importer_Company_Name_Text__c,' +
				'GTS_Importer_Company_Address__City__s,' +
				'GTS_Importer_Company_Address__CountryCode__s,' +
				'GTS_Importer_Company_Address__PostalCode__s,' +
				'GTS_Importer_Company_Address__Street__s,' +
				'GTS_Importer_Company_Address__StateCode__s,' +
				'GTS_Importer_Contact_Person__c,' +
				'GTS_Importer_Contact_Person_Name_Text__c,' +
				'GTS_Importer_Email__c,' +
				'GTS_Importer_Contact_Number__c,' +
				'GTS_Importer_Commercial_Reg_No_TIN__c,' +
				'GTS_Inspection_Location_Company_Name__c,' +
				'GTS_Inspection_Location_Company_Address__City__s,' +
				'GTS_Inspection_Location_Company_Address__CountryCode__s,' +
				'GTS_Inspection_Location_Company_Address__PostalCode__s,' +
				'GTS_Inspection_Location_Company_Address__Street__s,' +
				'GTS_Inspection_Location_Company_Address__StateCode__s,' +
				'GTS_Inspection_Location_Contact_Number__c,' +
				'GTS_Inspection_Location_Contact_Person__c,' +
				'GTS_Inspection_Location_Email__c,' +
				'GTS_Inspection_Location_Company_Text__c,' +
				'GTS_Inspection_Loc_Contact_Name_Text__c,' +
				'GTS_Payer_Company_Name__c,' +
				'GTS_Payer_Company_Name_Text__c,' +
				'GTS_Payer_Company_Address__City__s,' +
				'GTS_Payer_Company_Address__CountryCode__s,' +
				'GTS_Payer_Company_Address__PostalCode__s,' +
				'GTS_Payer_Company_Address__Street__s,' +
				'GTS_Payer_Company_Address__StateCode__s,' +
				'GTS_Payer_Contact_Person__c,' +
				'GTS_Payer_Contact_Person_Text__c,' +
				'GTS_Payer_Email__c,' +
				'GTS_Payer_Contact_Number__c,' +
				'GTS_Purchase_Order_Number__c,' +
				'RecordTypeId,' +
				'RecordType.DeveloperName,' +
				'GTS_Program__c,' +
				'GTS_Program__r.Name,' +
				'GTS_ACID_No__c,' +
				'GTS_AWB_No__c,' +
				'GTS_BL_No__c,' +
				'GTS_Certificate_Origin_No__c,' +
				'GTS_Certificate_Origin_Date__c,' +
				'GTS_Customer_Dealer_No__c,' +
				'GTS_Transport_Document_No__c,' +
				'GTS_Transport_Document_Date__c,' +
				'GTS_FASEH_Request_No__c,' +
				'GTS_FDI_No__c,' +
				'GTS_IDF_No__c,' +
				'GTS_Import_Licence_No__c,' +
				'GTS_Importer_Code__c,' +
				'GTS_ICE_No__c,' +
				'GTS_LC_No__c,' +
				'GTS_LC_Date__c,' +
				'GTS_No_of_Exporter__c,' +
				'GTS_No_of_Importer__c,' +
				'GTS_PR_No__c,' +
				'GTS_Invoice_No__c,' +
				'GTS_Invoice_Date__c,' +
				'GTS_UESW_Application_No__c,' +
				'GTS_UCR_No__c,' +
				'iCare_Active_Favourite__c,' +
				'iCare_Favourite_Name__c,' +
				'GTS_Type_of_Application__c,' +
				'GTS_Other_No_please_specify__c,' +
				'GTS_LRF_Declaration_1__c,' +
				'GTS_LRF_Declaration_2__c,' +
				'GTS_LRF_Declaration_3__c,' +
				'GTS_ComSer_Declaration_1__c,' +
				'GTS_ComSer_Declaration_2__c,' +
				'GTS_ComServ_Declaration_3__c,' +
				'GTS_ComSer_Declaration_4__c,' +
				'GTS_Specify_Number_of_FCLs__c,' +
				'GTS_Shipment_Mode_Please_Specify__c,' +
				'GTS_Shipment_Mode__c,' +
				'GTS_Shipment_Type__c,' +
				'GTS_Goods_Condition__c,' +
				'GTS_Goods_Available_Date__c,' +
				'GTS_Proposed_Inspection_Date__c,' +
				'GTS_Statement_of_Work__c,' +
				'GTS_Inview_Requested__c,' +
				'GTS_Purchase_Order__c,' +
				'GTS_Final_Report_Required__c,' +
				'GTS_Renewal_Revision__c,' +
				'GTS_Existing_Number__c,' +
				'GTS_ComSer_Prog_Please_Specify__c';
	}
}