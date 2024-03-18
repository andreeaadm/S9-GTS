@IsTest
private class GmaelDownloadReportFile_Test {
	@TestSetup
	static void setUp() {
		Id gmaelAccountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('GMA_Electrical_Customer').getRecordTypeId();
		Id gmaelContactRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('GMA_Electrical_Contact').getRecordTypeId();

		Account account = new Account(Name = 'Account', RecordTypeId = gmaelAccountRecordTypeId,
			BillingStreet = '1409 Sok. No:34 D:19 Buca Koop Mah.',
			BillingCity = 'London',
			BillingCountry = 'United Kingdom',
			BillingPostalCode = '35390'
		);
		insert account;

		Contact contact = new Contact(AccountId = account.Id, FirstName = 'Test', LastName = 'Contact', Email = 'test@test.com', RecordTypeId = gmaelContactRecordTypeId);
		insert contact;

	}

	@IsTest
	static void getDownloadLink_Approved(){
		Contact contact = [SELECT Id,AccountId FROM Contact LIMIT 1];
		GMAEL_TestDataFactory.createGmaelReport(1,contact.AccountId, contact.Id, 'Approved', true);

		GMAEL_Report__c report = [SELECT Name FROM GMAEL_Report__c LIMIT 1];

		String title = 'Report Name ' + report.Name + '.docx';

		ContentDocumentLink contentDocumentLink = createDocumentLink(title, report.Id);

		Test.startTest();
		String contentDocLinkResponse = GmaelDownloadReportFile.getDownloadLink(report.Id);
		Test.stopTest();

		List<ContentDocumentLink> cdl = [
			SELECT ContentDocument.Id,
				ContentDocument.FileExtension, ContentDocument.Title
			FROM ContentDocumentLink
			WHERE LinkedEntityId = :report.Id
		];

		System.assert(contentDocLinkResponse == contentDocumentLink.ContentDocumentId);
		GMAEL_Report__c updatedReport = [SELECT GMAEL_Generate_Report_File__c FROM GMAEL_Report__c WHERE Id = :report.Id LIMIT 1];
		System.assert(updatedReport.GMAEL_Generate_Report_File__c == true);
	}

	@IsTest
	static void getDownloadLink_Draft(){
		Contact contact = [SELECT Id,AccountId FROM Contact LIMIT 1];
		GMAEL_TestDataFactory.createGmaelReport(1,contact.AccountId, contact.Id, 'Draft', true);

		GMAEL_Report__c report = [SELECT Name FROM GMAEL_Report__c LIMIT 1];

		String title = 'Report Name ' + report.Name + 'Draft.docx';

		ContentDocumentLink contentDocumentLink = createDocumentLink(title, report.Id);

		Test.startTest();
		GmaelDownloadReportFile.getDownloadLink(report.Id);
		Test.stopTest();

		GMAEL_Report__c updatedReport = [SELECT GMAEL_Generate_Report_File__c FROM GMAEL_Report__c WHERE Id = :report.Id LIMIT 1];
		System.assert(updatedReport.GMAEL_Generate_Report_File__c == true);
	}

	@IsTest
	static void resetGenerateReportFileValue(){
		Contact contact = [SELECT Id,AccountId FROM Contact LIMIT 1];
		GMAEL_Report__c report = GMAEL_TestDataFactory.createGmaelReport(1,contact.AccountId, contact.Id, 'Draft', false)[0];
		report.GMAEL_Generate_Report_File__c = true;
		insert report;

		Test.startTest();
		GmaelDownloadReportFile.resetGenerateReportFileValue(report.Id);
		Test.stopTest();

		GMAEL_Report__c updatedReport = [SELECT GMAEL_Generate_Report_File__c FROM GMAEL_Report__c WHERE Id = :report.Id LIMIT 1];
		System.assert(updatedReport.GMAEL_Generate_Report_File__c == false);
	}


	static ContentDocumentLink createDocumentLink(String title,Id relatedRecord){
		ContentVersion cv = new ContentVersion();
		cv.Title = title;
		cv.VersionData = Blob.valueOf('content');
		cv.PathOnClient = title;

		insert cv;

		ContentDocument contentDocument = [SELECT Id, Title FROM ContentDocument WHERE Title = :cv.Title LIMIT 1];

		ContentDocumentLink contentDocumentLink = new ContentDocumentLink(LinkedEntityId = relatedRecord, ContentDocumentId = contentDocument.Id);
		insert contentDocumentLink;
		return contentDocumentLink;
	}


}