public with sharing class GTS_JobRequestQueueable extends icare_QueueableVirtual implements Queueable, Database.AllowsCallouts {
  private Map<String, String> gtsRFCTypes = this.getGTSrfcType();
  private static String OPSSYSTEM = 'ASTRA';

  public GTS_JobRequestQueueable() {
    super();
  }

  public GTS_JobRequestQueueable(
    List<icare_Job_Request__c> jobRequestList,
    List<icare_Job_Request__c> jobRequestUpdateList,
    List<iCare_Integration_Audit_Log__c> auditLogList
  ) {
    super(jobRequestList, jobRequestUpdateList, auditLogList);
  }

  public override icare_Job_Request__c getJobRequest() {
    if (jobRequestList != null && jobRequestList.size() > 0) {
      return [
        SELECT
          Id,
          Name,
          GTS_Client_Reference__c,
          GTS_Applicant_Type__c,
          iCare_Applicant_Company__r.iCare_Supplier_Unique_ID__c,
		  iCare_Applicant_Company__r.GTS_Account_ID__c,
          iCare_Applicant_Company__r.GTS_Account_Type__c,
          iCare_Applicant_Company__r.Name,
          iCare_Applicant_Company__r.GTS_Commercial_Registration_No_TIN__c,
          iCare_Applicant_Company__r.BillingCity,
          iCare_Applicant_Company__r.BillingStreet,
          iCare_Applicant_Company__r.BillingStateCode,
          iCare_Applicant_Company__r.BillingCountryCode,
          iCare_Applicant_Company__r.BillingPostalCode,
          GTS_Program__r.Name,
          GTS_Program__r.GTS_Program_Unique_Code__c,
          GTS_Program__r.GTS_Program_Country__c,
          GTS_Program__r.GTS_Programme_Id__c,
          GTS_Importer_Company_Name__r.name,
          GTS_Importer_Company_Name__r.iCare_Supplier_Unique_ID__c,
		  GTS_Importer_Company_Name__r.GTS_Account_ID__c,
          GTS_Importer_Company_Name__r.GTS_Applicant_Type__c,
		  GTS_Importer_Company_Name__r.GTS_Account_Type__c,
          GTS_Importer_Company_Name__r.GTS_Commercial_Registration_No_TIN__c,
          GTS_Inspection_Location_Company_Name__r.name,
          GTS_Inspection_Location_Company_Name__r.iCare_Supplier_Unique_ID__c,
		  GTS_Inspection_Location_Company_Name__r.GTS_Account_ID__c,
          GTS_Inspection_Location_Company_Name__r.GTS_Applicant_Type__c,
		  GTS_Inspection_Location_Company_Name__r.GTS_Account_Type__c,
          GTS_Inspection_Location_Company_Name__r.GTS_Commercial_Registration_No_TIN__c,
          GTS_Payer_Company_Name__r.name,
          GTS_Payer_Company_Name__r.iCare_Supplier_Unique_ID__c,
		  GTS_Payer_Company_Name__r.GTS_Account_ID__c,
          GTS_Payer_Company_Name__r.GTS_Applicant_Type__c,
		  GTS_Payer_Company_Name__r.GTS_Account_Type__c,
          GTS_Applicant_Contact_Person__r.FirstName,
          GTS_Applicant_Contact_Person__r.LastName,
          GTS_Applicant_Contact_Number__c,
          iCare_Applicant_Fax__c,
          iCare_Applicant_Email__c,
          GTS_Importer_Contact_Person__r.FirstName,
          GTS_Importer_Contact_Person__r.LastName,
          GTS_Importer_Contact_Number__c,
          GTS_Importer_Email__c,
          GTS_Inspection_Location_Contact_Person__r.FirstName,
          GTS_Inspection_Location_Contact_Person__r.LastName,
          GTS_Inspection_Location_Contact_Number__c,
          GTS_Inspection_Location_Email__c,
          GTS_Payer_Contact_Person__r.FirstName,
          GTS_Payer_Contact_Person__r.LastName,
          GTS_Payer_Contact_Number__c,
          GTS_Payer_Email__c,
          iCare_Applicant_Address__City__s,
          iCare_Applicant_Address__CountryCode__s,
          iCare_Applicant_Address__PostalCode__s,
          iCare_Applicant_Address__StateCode__s,
          iCare_Applicant_Address__Street__s,
          GTS_Importer_Company_Address__City__s,
          GTS_Importer_Company_Address__CountryCode__s,
          GTS_Importer_Company_Address__PostalCode__s,
          GTS_Importer_Company_Address__StateCode__s,
          GTS_Importer_Company_Address__Street__s,
          GTS_Inspection_Location_Company_Address__City__s,
          GTS_Inspection_Location_Company_Address__CountryCode__s,
          GTS_Inspection_Location_Company_Address__PostalCode__s,
          GTS_Inspection_Location_Company_Address__StateCode__s,
          GTS_Inspection_Location_Company_Address__Street__s,
          GTS_Payer_Company_Address__City__s,
          GTS_Payer_Company_Address__CountryCode__s,
          GTS_Payer_Company_Address__PostalCode__s,
          GTS_Payer_Company_Address__StateCode__s,
          GTS_Payer_Company_Address__Street__s,
          RecordType.DeveloperName,
          GTS_Purchase_Order_Number__c,
          CreatedDate,
          GTS_Goods_Available_Date__c,
          GTS_Proposed_Inspection_Date__c,
          GTS_Shipment_Mode__c,
          GTS_Shipment_Type__c,
          GTS_Specify_Number_of_FCLs__c,
          GTS_Importer_Company_Name_Text__c,
          GTS_Importer_Company_Name__c,
          GTS_Inspection_Location_Company_Name__c,
          GTS_Inspection_Location_Company_Text__c,
          GTS_Payer_Company_Name__c,
          GTS_Payer_Company_Name_Text__c,
          GTS_Importer_Contact_Person_Name_Text__c,
          GTS_Importer_Contact_Person__c,
          GTS_Inspection_Loc_Contact_Name_Text__c,
          GTS_Inspection_Location_Contact_Person__c,
          GTS_Payer_Contact_Person__c,
          GTS_Payer_Contact_Person_Text__c
        FROM icare_Job_Request__c
        WHERE Id = :jobRequestList[0].Id
      ];
    }
    return null;
  }

  public void execute(QueueableContext context) {
    try {
      this.jobReq = this.getJobRequest();
      // headers
      if (this.jobReq != null) {
        this.setHeaders('Create_Job_GTS');
        if (!Test.isRunningTest() && !this.integrationDetails.Is_Active__c) {
          return;
        }
        headersMap.put('testingLocationCode', OPSSYSTEM);

        GTS_JobRequestWrapper wrapper = new GTS_JobRequestWrapper();
        GTS_JobRequestWrapper.JobRequestHeader jobRequestHeader = new GTS_JobRequestWrapper.JobRequestHeader();
        GTS_JobRequestWrapper.Programme shipmentCertificateProgramme = new GTS_JobRequestWrapper.Programme();
        GTS_JobRequestWrapper.JobDetails jobDetails = new GTS_JobRequestWrapper.JobDetails();

        // Job field mapping
        jobRequestHeader.rfcType = this.gtsRFCTypes.get(
          jobReq.RecordType.DeveloperName
        );
        jobRequestHeader.jobRequestRecordId = jobReq.Id;
        shipmentCertificateProgramme.programmeCode = jobReq.GTS_Program__r.GTS_Program_Unique_Code__c;
        shipmentCertificateProgramme.programmeName = jobReq.GTS_Program__r.Name;
        shipmentCertificateProgramme.country = jobReq.GTS_Program__r.GTS_Program_Country__c;
        shipmentCertificateProgramme.programmeId = jobReq.GTS_Program__r.GTS_Programme_Id__c;
        jobRequestHeader.shipmentCertificateProgramme = shipmentCertificateProgramme;
        jobRequestHeader.exporterReference = jobReq.GTS_Client_Reference__c;

        //exporter
        GTS_JobRequestWrapper.CompanyInformation exporter = new GTS_JobRequestWrapper.CompanyInformation();
        GTS_JobRequestWrapper.Account exporterAccount = new GTS_JobRequestWrapper.Account();
        exporterAccount.opsSystemAccountNumber = jobReq.iCare_Applicant_Company__r.GTS_Account_ID__c;
        exporterAccount.opsSystem = OPSSYSTEM;
        //exporterAccount.opsSystemAccountType = jobReq.GTS_Applicant_Type__c;
		exporterAccount.opsSystemAccountType = jobReq.iCare_Applicant_Company__r.GTS_Account_Type__c;
        exporterAccount.accountName = jobReq.iCare_Applicant_Company__r.Name;

        GTS_JobRequestWrapper.Contact exporterContact = new GTS_JobRequestWrapper.Contact();
        exporterContact.contactFirstName = jobReq.GTS_Applicant_Contact_Person__r.FirstName;
        exporterContact.contactLastName = jobReq.GTS_Applicant_Contact_Person__r.LastName;
        exporterContact.contactPhone = jobReq.GTS_Applicant_Contact_Number__c;
        exporterContact.contactFax = jobReq.iCare_Applicant_Fax__c;
        exporterContact.contactEmail = jobReq.iCare_Applicant_Email__c;

        GTS_JobRequestWrapper.Address exporterAddress = new GTS_JobRequestWrapper.Address();
        exporterAddress.street = jobReq.iCare_Applicant_Address__Street__s;
        exporterAddress.city = jobReq.iCare_Applicant_Address__City__s;
        exporterAddress.stateCode = jobReq.iCare_Applicant_Address__StateCode__s;
        exporterAddress.countryCode = jobReq.iCare_Applicant_Address__CountryCode__s;
        exporterAddress.postalCode = jobReq.iCare_Applicant_Address__PostalCode__s;
        exporterAccount.address = exporterAddress;
        exporter.account = exporterAccount;
        exporter.contact = exporterContact;
        exporter.taxNumber = jobReq.iCare_Applicant_Company__r.GTS_Commercial_Registration_No_TIN__c;
        GTS_JobRequestWrapper.Address billingAddress = new GTS_JobRequestWrapper.Address();
        billingAddress.street = jobReq.iCare_Applicant_Company__r.BillingStreet;
        billingAddress.city = jobReq.iCare_Applicant_Company__r.BillingCity;
        billingAddress.stateCode = jobReq.iCare_Applicant_Company__r.BillingStateCode;
        billingAddress.countryCode = jobReq.iCare_Applicant_Company__r.BillingCountryCode;
        billingAddress.postalCode = jobReq.iCare_Applicant_Company__r.BillingPostalCode;
        exporter.address = billingAddress;
        jobRequestHeader.exporter = exporter;
        //importer
        GTS_JobRequestWrapper.CompanyInformation importer = new GTS_JobRequestWrapper.CompanyInformation();
        GTS_JobRequestWrapper.Address importerAddress = new GTS_JobRequestWrapper.Address();
        importerAddress.street = jobReq.GTS_Importer_Company_Address__Street__s;
        importerAddress.city = jobReq.GTS_Importer_Company_Address__City__s;
        importerAddress.stateCode = jobReq.GTS_Importer_Company_Address__StateCode__s;
        importerAddress.countryCode = jobReq.GTS_Importer_Company_Address__CountryCode__s;
        importerAddress.postalCode = jobReq.GTS_Importer_Company_Address__PostalCode__s;

        if (jobReq.GTS_Importer_Company_Name__c != null) {
          GTS_JobRequestWrapper.Account importerAccount = new GTS_JobRequestWrapper.Account();
          importerAccount.opsSystemAccountNumber = jobReq.GTS_Importer_Company_Name__r.GTS_Account_ID__c;
          importerAccount.opsSystem = OPSSYSTEM;
          //importerAccount.opsSystemAccountType = jobReq.GTS_Importer_Company_Name__r.GTS_Applicant_Type__c;
		  importerAccount.opsSystemAccountType = jobReq.GTS_Importer_Company_Name__r.GTS_Account_Type__c;
          importerAccount.accountName = jobReq.GTS_Importer_Company_Name_Text__c;
          importerAccount.address = importerAddress;
          importer.account = importerAccount;
          importer.taxNumber = jobReq.GTS_Importer_Company_Name__r.GTS_Commercial_Registration_No_TIN__c;
        } else {
          importer.companyName = jobReq.GTS_Importer_Company_Name_Text__c;
          importer.address = importerAddress;
        }
        GTS_JobRequestWrapper.Contact importerContact = new GTS_JobRequestWrapper.Contact();
        if (jobReq.GTS_Importer_Contact_Person__c != null) {
          importerContact.contactFirstName = jobReq.GTS_Importer_Contact_Person__r.FirstName;
          importerContact.contactLastName = jobReq.GTS_Importer_Contact_Person__r.LastName;
        } else {
          importerContact.contactFirstName = jobReq.GTS_Importer_Contact_Person_Name_Text__c;
          //TODO: needs a schema fix
          importerContact.contactLastName = jobReq.GTS_Importer_Contact_Person_Name_Text__c;
        }
        importerContact.contactPhone = jobReq.GTS_Importer_Contact_Number__c;
        importerContact.contactEmail = jobReq.GTS_Importer_Email__c;
        importer.contact = importerContact;

        //jobRequestHeader.importer = importer;
		//Conditional Node assignment
		if (jobReq.GTS_Importer_Company_Name__c != null ||
			(jobReq.GTS_Importer_Company_Name_Text__c!=null && jobReq.GTS_Importer_Company_Name_Text__c.length()>0)) {
			jobRequestHeader.importer = importer;
		}

        //inspectionLocation
        GTS_JobRequestWrapper.CompanyInformation inspectionLocation = new GTS_JobRequestWrapper.CompanyInformation();
        GTS_JobRequestWrapper.Account inspectionLocationAccountInfo = new GTS_JobRequestWrapper.Account();
        GTS_JobRequestWrapper.Address inspectionLocationAddress = new GTS_JobRequestWrapper.Address();
        inspectionLocationAddress.street = jobReq.GTS_Inspection_Location_Company_Address__Street__s;
        inspectionLocationAddress.city = jobReq.GTS_Inspection_Location_Company_Address__City__s;
        inspectionLocationAddress.stateCode = jobReq.GTS_Inspection_Location_Company_Address__StateCode__s;
        inspectionLocationAddress.countryCode = jobReq.GTS_Inspection_Location_Company_Address__CountryCode__s;
        inspectionLocationAddress.postalCode = jobReq.GTS_Inspection_Location_Company_Address__PostalCode__s;
        if (jobReq.GTS_Inspection_Location_Company_Name__c != null) {
          inspectionLocationAccountInfo.opsSystemAccountNumber = jobReq.GTS_Inspection_Location_Company_Name__r.GTS_Account_ID__c;
          inspectionLocationAccountInfo.opsSystem = OPSSYSTEM;
          //inspectionLocationAccountInfo.opsSystemAccountType = jobReq.GTS_Inspection_Location_Company_Name__r.GTS_Applicant_Type__c;
		  inspectionLocationAccountInfo.opsSystemAccountType = jobReq.GTS_Inspection_Location_Company_Name__r.GTS_Account_Type__c;
          inspectionLocationAccountInfo.accountName = jobReq.GTS_Inspection_Location_Company_Name__r.name;
          inspectionLocationAccountInfo.address = inspectionLocationAddress;
          inspectionLocation.account = inspectionLocationAccountInfo;
          inspectionLocation.taxNumber = jobReq.GTS_Inspection_Location_Company_Name__r.GTS_Commercial_Registration_No_TIN__c;
        } else {
          inspectionLocation.companyName = jobReq.GTS_Inspection_Location_Company_Text__c;
          inspectionLocation.address = inspectionLocationAddress;
        }
        GTS_JobRequestWrapper.Contact inspectionLocationContact = new GTS_JobRequestWrapper.Contact();
        if (jobReq.GTS_Inspection_Location_Contact_Person__c != null) {
          inspectionLocationContact.contactFirstName = jobReq.GTS_Inspection_Location_Contact_Person__r.FirstName;
          inspectionLocationContact.contactLastName = jobReq.GTS_Inspection_Location_Contact_Person__r.LastName;
        } else {
          inspectionLocationContact.contactFirstName = jobReq.GTS_Inspection_Loc_Contact_Name_Text__c;
          //TODO: needs a schema fix
          inspectionLocationContact.contactLastName = jobReq.GTS_Inspection_Loc_Contact_Name_Text__c;
        }

        inspectionLocationContact.contactPhone = jobReq.GTS_Inspection_Location_Contact_Number__c;
        inspectionLocationContact.contactEmail = jobReq.GTS_Inspection_Location_Email__c;
        inspectionLocation.contact = inspectionLocationContact;
        String formattedDate = '';
        if (jobReq.GTS_Goods_Available_Date__c != null) {
          formattedDate =
            String.valueOf(jobReq.GTS_Goods_Available_Date__c.year()) +
            '-' +
            String.valueOf(jobReq.GTS_Goods_Available_Date__c.month())
              .leftPad(2, '0') +
            '-' +
            String.valueOf(jobReq.GTS_Goods_Available_Date__c.day())
              .leftPad(2, '0');
          inspectionLocation.goodsAvailableDate = formattedDate;
        }
        if (jobReq.GTS_Proposed_Inspection_Date__c != null) {
          formattedDate =
            String.valueOf(jobReq.GTS_Proposed_Inspection_Date__c.year()) +
            '-' +
            String.valueOf(jobReq.GTS_Proposed_Inspection_Date__c.month())
              .leftPad(2, '0') +
            '-' +
            String.valueOf(jobReq.GTS_Proposed_Inspection_Date__c.day())
              .leftPad(2, '0');
          inspectionLocation.proposedInspectionDate = formattedDate;
        }
        inspectionLocation.shipmentMode = jobReq.GTS_Shipment_Mode__c;
        inspectionLocation.shipmentType = jobReq.GTS_Shipment_Type__c;
        if (jobReq.GTS_Specify_Number_of_FCLs__c != null) {
          inspectionLocation.numberOfFCL = Integer.valueOf(
            jobReq.GTS_Specify_Number_of_FCLs__c
          );
        }
        
		//Conditional Node assignment: inspectionLocation
		if (jobReq.GTS_Inspection_Location_Company_Name__c != null ||
			(jobReq.GTS_Inspection_Location_Company_Text__c!=null && jobReq.GTS_Inspection_Location_Company_Text__c.length()>0)) {
            System.debug('------------ADDINg NODE----------');
			jobRequestHeader.inspectionLocation = inspectionLocation;
		}
        
		
		//payer
        GTS_JobRequestWrapper.CompanyInformation payer = new GTS_JobRequestWrapper.CompanyInformation();
        GTS_JobRequestWrapper.Account payerAccountInfo = new GTS_JobRequestWrapper.Account();
        GTS_JobRequestWrapper.Address payerAddress = new GTS_JobRequestWrapper.Address();
        payerAddress.street = jobReq.GTS_Payer_Company_Address__Street__s;
        payerAddress.city = jobReq.GTS_Payer_Company_Address__City__s;
        payerAddress.stateCode = jobReq.GTS_Payer_Company_Address__StateCode__s;
        payerAddress.countryCode = jobReq.GTS_Payer_Company_Address__CountryCode__s;
        payerAddress.postalCode = jobReq.GTS_Payer_Company_Address__PostalCode__s;

        if (jobReq.GTS_Payer_Company_Name__c != null) {
          payerAccountInfo.opsSystemAccountNumber = jobReq.GTS_Payer_Company_Name__r.GTS_Account_ID__c;
          payerAccountInfo.opsSystem = OPSSYSTEM;
          //payerAccountInfo.opsSystemAccountType = jobReq.GTS_Payer_Company_Name__r.GTS_Applicant_Type__c;
		  payerAccountInfo.opsSystemAccountType = jobReq.GTS_Payer_Company_Name__r.GTS_Account_Type__c;
          payerAccountInfo.accountName = jobReq.GTS_Payer_Company_Name__r.name;
          payerAccountInfo.address = payerAddress;
          payer.account = payerAccountInfo;
        } else {
          payer.companyName = jobReq.GTS_Payer_Company_Name_Text__c;
          payer.address = payerAddress;
        }

        GTS_JobRequestWrapper.Contact payerContact = new GTS_JobRequestWrapper.Contact();
        if (jobReq.GTS_Payer_Contact_Person__c != null) {
          payerContact.contactFirstName = jobReq.GTS_Payer_Contact_Person__r.FirstName;
          payerContact.contactLastName = jobReq.GTS_Payer_Contact_Person__r.LastName;
        } else {
          payerContact.contactFirstName = jobReq.GTS_Payer_Contact_Person_Text__c;
          //TODO: needs a schema fix
          payerContact.contactLastName = jobReq.GTS_Payer_Contact_Person_Text__c;
        }
        payerContact.contactPhone = jobReq.GTS_Payer_Contact_Number__c;
        payerContact.contactEmail = jobReq.GTS_Payer_Email__c;
        payer.contact = payerContact;

        payer.purchaseOrderNumber = jobReq.GTS_Purchase_Order_Number__c + '';
		
        //jobRequestHeader.payer = payer;
		//Conditional Node assignment
		if (jobReq.GTS_Payer_Company_Name__c != null ||
			(jobReq.GTS_Payer_Company_Name_Text__c!=null && jobReq.GTS_Payer_Company_Name_Text__c.length()>0)) {
			jobRequestHeader.payer = payer;
		}
		
        wrapper.jobRequestHeader = jobRequestHeader;

        jobDetails.previousReportNumber = '';
        jobDetails.formCompletionDate = jobReq.CreatedDate.format(
          'yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\''
        );

        wrapper.jobDetails = jobDetails;

        String payload = JSON.serialize(wrapper, true);

        // basic Callout
        String response = this.callOut(payload);
        Integer intStatusCode = this.statusCode();

        // to insert the logs
        auditLogList.add(
          new iCare_Integration_Audit_Log__c(
            iCare_Request_Payload__c = payload,
            iCare_Response_Payload__c = response.substringAfter(
                ':responseBody:'
              )
              .left(32768),
            iCare_Integration_Reference__c = 'Astra',
            GTS_Job_Request__c = jobRequestList[0].Id,
            iCare_Sync_Status__c = intStatusCode == 200 ? 'Success' : 'Failure'
          )
        );

        // process the next record by calling Queuable constructor
        if (!jobRequestList.isEmpty() && jobRequestList.size() > 1) {
          jobRequestList.remove(0);
          new GTS_QueueJob().excuteClass(jobRequestList, auditLogList, context);
        } else {
          insert auditLogList;
        }
      } else {
        throw new GTS_JobException('The job has no any ETRF associated');
      }
    } catch (Exception ex) {
      // to insert the logs
      insert new iCare_Integration_Audit_Log__c(
        iCare_Response_Payload__c = ex.getStackTraceString() +
          ' : ' +
          ex.getMessage(),
        iCare_Integration_Reference__c = Label.iCare_Job_Request_IntegRef,
        GTS_Job_Request__c = jobRequestList[0].Id,
        iCare_Sync_Status__c = 'Failure'
      );
    }
  }

  public class GTS_JobException extends Exception {
  }
}