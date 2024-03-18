/*******************************************************************************************
 * @Name         iCare_ExpertQueryQueuable
 * @Test Class :  iCare_ExpertQueryTriggerHandlerTest
 * @Author       Praveen Kumar R
 * @Description  This acts as the queuable class to ExpertQueryTrigger trigger.
 *******************************************************************************************/
public class iCare_ExpertQueryQueuable extends icare_QueueableVirtual implements Queueable, Database.AllowsCallouts {
  public iCare_ExpertQueryQueuable() {
  }

  public iCare_ExpertQueryQueuable(
    List<iCare_Expert_Query__c> expQueryList,
    List<iCare_Expert_Query__c> expQueryUpdateList,
    List<iCare_Integration_Audit_Log__c> auditLogList
  ) {
    this.expQueryList.addAll(expQueryList);
    this.expQueryUpdateList.addAll(expQueryUpdateList);
    this.auditLogList.addAll(auditLogList);
  }

  public void execute(QueueableContext context) {
    // variables
    Map<String, String> headersMap = new Map<String, String>();
    // get the integration details from the metadata
    this.setHeaders('Create_Lead_iConnect');

    if (Test.isRunningTest() || this.integrationDetails.Is_Active__c) {
      iCare_Expert_Query__c expQuery = [
        SELECT
          Id,
          iCare_Subject__c,
          iCare_Account__c,
          iCare_Account__r.Name,
          iCare_User__c,
          iCare_User__r.Title,
          iCare_User__r.CountryCode,
          iCare_User__r.City,
          iCare_User__r.Email,
          iCare_User__r.Phone,
          iCare_User__r.LastName,
          iCare_User__r.FirstName,
          iCare_Expert__r.iCare_Country__c,
          iCare_Expert__r.GTS_iConnect_Campaign_ID__c
        FROM iCare_Expert_Query__c
        WHERE Id = :expQueryList[0].Id
      ];

      String campaignID = iCare_Country_specific_information__mdt.getInstance(
          expQuery.iCare_Expert__r.iCare_Country__c
        )
        ?.iCare_Campaign_Id__c;

      if (campaignID == null || (campaignID != null && campaignID == '')) {
        campaignID = expQuery.iCare_Expert__r.GTS_iConnect_Campaign_ID__c;
      }

      ExpertQueryWrapper wrapper = new ExpertQueryWrapper();
      // field mapping
      wrapper.subject = expQueryList[0].iCare_Subject__c;
      wrapper.campaignCode = Test.isRunningTest()
        ? iCare_CallOutUtilityClass.CAMPAIGN_ID
        : campaignID;
      wrapper.source = expQueryList[0].iCare_Source__c;
      wrapper.description = expQueryList[0].iCare_Your_Query__c;
      wrapper.externalSystem = expQueryList[0].iCare_Source_Application_Name__c;
      wrapper.externalSystemId = expQueryList[0].Id;

      wrapper.jobTitle = expQuery.iCare_User__r?.Title;
      wrapper.companyName = expQuery.iCare_Account__r?.Name;
      wrapper.countryCode = expQuery.iCare_User__r?.CountryCode;
      wrapper.city = expQuery.iCare_User__r?.City;
      wrapper.email = expQuery.iCare_User__r?.Email;
      wrapper.businessPhone = expQuery.iCare_User__r?.Phone;
      wrapper.lastName = expQuery.iCare_User__r?.LastName;
      wrapper.firstName = expQuery.iCare_User__r?.FirstName;

      String payload = JSON.serialize(wrapper, true);

      // basic Callout
      String response = this.callOut(payload);
      Integer intStatusCode = this.statusCode();

      // to update Sync Status
      expQueryUpdateList.add(
        new iCare_Expert_Query__c(
          Id = expQueryList[0].Id,
          iCare_iConnect_Sync_Status__c = intStatusCode == 200
            ? 'Success'
            : 'Failure'
        )
      );

      // to insert the logs
      auditLogList.add(
        new iCare_Integration_Audit_Log__c(
          iCare_Request_Payload__c = payload,
          iCare_Response_Payload__c = response.substringAfter(':responseBody:'),
          iCare_Integration_Reference__c = Label.iCare_Customer_Data_Integ_Ref,
          iCare_Expert_Query__c = expQueryList[0].Id,
          iCare_Sync_Status__c = intStatusCode == 200 ? 'Success' : 'Failure'
        )
      );

      // process the next record by calling Queuable constructor
      if (!expQueryList.isEmpty() && expQueryList.size() > 1) {
        expQueryList.remove(0);
        GTS_QueueJob queue = new GTS_QueueJob(new iCare_ExpertQueryQueuable());
        queue.excuteClass(
          expQueryList,
          auditLogList,
          expQueryUpdateList,
          context
        );
      } else {
        update expQueryUpdateList;
        insert auditLogList;
      }
    }
  }

  public class ExpertQueryWrapper {
    public String businessPhone;
    public String city;
    public String companyName;
    public String countryCode;
    public String description;
    public String email;
    public String externalSystem;
    public String externalSystemId;
    public String firstName;
    public String jobTitle;
    public String lastName;
    public String campaignCode;
    public String source;
    public String subject;
  }
}