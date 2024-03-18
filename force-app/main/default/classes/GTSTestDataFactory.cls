/*******************************************************************************************
 * @author       Globant
 * @description  Test data factory for GTS Records
 * @date         8-March-2024
 *******************************************************************************************/
@IsTest
public class GTSTestDataFactory {
  private static final Id GTS_ACCOUNT_RECORD_ID = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
    .get('GTS_Customer')
    .getRecordTypeId();
  /**
   * @description Create Account record
   * @param accountName
   * @param doInsert
   *
   * @return
   */
  public static Account createAccount(String accountName, Boolean doInsert) {
    Account customerAccount = new Account(
      Name = accountName,
      RecordTypeId = GTS_ACCOUNT_RECORD_ID
    );
    if (doInsert) {
      insert customerAccount;
    }
    return customerAccount;
  }
  /**
   * @description Create Contact record
   * @param contactName
   * @param customerAccountId
   * @param doInsert
   *
   * @return
   */
  public static Contact createContact(
    String contactName,
    Id customerAccountId,
    Boolean doInsert
  ) {
    Contact customerContact = new Contact(
      AccountId = customerAccountId,
      LastName = contactName,
      FirstName = contactName,
      Phone = StringUtil.random(12, '0123456789'),
      Email = contactName + '@email.com'
    );
    if (doInsert) {
      insert customerContact;
    }
    return customerContact;
  }

  /**
   * @description Create User record
   * @param userName
   * @param customerProfileId
   * @param customerContactId
   * @param doInsert
   *
   * @return
   */
  public static User createUser(
    String userName,
    Id customerProfileId,
    Id customerContactId,
    Boolean doInsert
  ) {
    User customerUser = new User(
      LastName = userName,
      FirstName = userName,
      Alias = userName.substring(2, 7),
      Username = userName + '@email.com',
      ProfileId = customerProfileId,
      TimeZoneSidKey = 'GMT',
      LanguageLocaleKey = 'en_US',
      EmailEncodingKey = 'UTF-8',
      LocaleSidKey = 'en_US',
      ContactId = customerContactId,
      Email = 'j.doe@email.com',
      Street = '10 Downing Street',
      City = 'London',
      PostalCode = 'SW1A 2AB',
      isActive = true,
      Source__c = 'Self-Registration'
    );
    if (doInsert) {
      insert customerUser;
    }
    return customerUser;
  }
  /**
   * @description Create iCare_Job__c record
   * @param recordTypeId
   * @param supplierId
   * @param doInsert
   *
   * @return
   */
  public static iCare_Job__c createJob(
    Id recordTypeId,
    Id supplierId,
    Boolean doInsert
  ) {
    iCare_Job__c job = new iCare_Job__c(
      RecordTypeId = recordTypeId,
      iCare_Supplier__c = supplierId
    );
    if (doInsert) {
      insert job;
    }
    return job;
  }
  /**
   * @description Create ContentVersion record
   * @param fileName
   * @param doInsert
   *
   * @return
   */
  public static ContentVersion createContentVersion(
    String fileName,
    Boolean doInsert
  ) {
    ContentVersion cv = new ContentVersion();
    cv.ContentLocation = 'S';
    cv.Title = fileName;
    cv.PathOnClient = 'PathFileDownloadTest.pdf';
    cv.VersionData = Blob.valueOf('Test PDF File Content');
    cv.GTS_Document_Type__c = 'Type1';
    cv.GTS_Document_Super_Type__c = 'Certificate';
    if (doInsert) {
      insert cv;
    }
    return cv;
  }
  /**
   * @description Create ContentDocumentLink record
   * @param parentRecordId
   * @param contentDocumentId
   * @param doInsert
   *
   * @return
   */
  public static ContentDocumentLink createContentDocumentLink(
    Id parentRecordId,
    Id contentDocumentId,
    Boolean doInsert
  ) {
    ContentDocumentLink cdl = new ContentDocumentLink();
    cdl.LinkedEntityId = parentRecordId;
    cdl.ContentDocumentId = contentDocumentId;
    cdl.shareType = 'V';
    if (doInsert) {
      insert cdl;
    }
    return cdl;
  }
}