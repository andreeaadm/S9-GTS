/*******************************************************************************************
 * @Name         iCare_JobUtil
 * @Test Class : iCare_JobTriggerHandlerTest
 * @Author       Laura Fretter
 * @Description  This acts as a utility class to the iCare_JobTriggerHandler handler for TIPS records
 *******************************************************************************************/
public without sharing class iCare_JobUtil extends iCare_CountryMetadata_Factory implements iCare_JobId_Interface {
  private Map<String, iCare_Country_specific_information__mdt> countrySpecificInformation = iCare_Country_specific_information__mdt.getAll();
  private final String NAME_FOR_PORTAL_URL = 'iCare';
  private String currentYearValue = String.valueOf(System.today().year())
    .substring(2);

  public void setJobIds(List<iCare_Job__c> jobRecords) {
    List<iCare_Job_Identifier__c> jobIdRecordsToUpsert = new List<iCare_Job_Identifier__c>();
    List<String> processedJobIds = new List<String>();

    Map<String, List<iCare_Job__c>> jobIdWithJobs = groupJobsByIds(jobRecords);
      System.debug('jobIdWithJobs'+jobIdWithJobs);
    List<iCare_Job_Identifier__c> jobIdRecords = getJobIdentifierRecords(
      jobIdWithJobs
    );

    if (jobIdRecords.size() > 0) {
      for (iCare_Job_Identifier__c jobIdRecord : jobIdRecords) {
        List<String> formattedSections = jobIdRecord.iCare_Job_ID_Formatted__c.split(
          '-'
        );
        String formattedId =
          formattedSections[0] +
          '-' +
          formattedSections[1] +
          '-' +
          currentYearValue;
        if (jobIdWithJobs.containsKey(formattedId)) {
          jobIdRecordsToUpsert.add(
            updateJobIdInformation(
              formattedId,
              jobIdRecord,
              jobIdWithJobs.get(formattedId)
            )
          );
          processedJobIds.add(formattedId);
        }
      }
      if (processedJobIds.size() != jobIdRecordsToUpsert.size()) {
        for (String fomattedJobId : jobIdWithJobs.keySet()) {
          if (!processedJobIds.contains(fomattedJobId)) {
            Map<String, List<iCare_Job__c>> singleJobIdWithJobs = new Map<String, List<iCare_Job__c>>{
              fomattedJobId => jobIdWithJobs.get(fomattedJobId)
            };
            jobIdRecordsToUpsert.add(
              createNewJobIdRecords(singleJobIdWithJobs)[0]
            );
          }
        }
      }
    } else {
      jobIdRecordsToUpsert = createNewJobIdRecords(jobIdWithJobs);
    }
    if (
      Schema.sObjectType.iCare_Job_Identifier__c.fields.iCare_Country__c.isCreateable() &&
      Schema.sObjectType.iCare_Job_Identifier__c.fields.iCare_Lab_Country_Code__c.isCreateable() &&
      Schema.sObjectType.iCare_Job_Identifier__c.fields.iCare_Country__c.isCreateable() &&
      Schema.sObjectType.iCare_Job_Identifier__c.fields.iCare_ID_Number__c.isCreateable() &&
      Schema.sObjectType.iCare_Job_Identifier__c.fields.iCare_Timezone__c.isCreateable() &&
      Schema.sObjectType.iCare_Job_Identifier__c.fields.iCare_Year__c.isCreateable() &&
      Schema.sObjectType.iCare_Job_Identifier__c.fields.iCare_Country__c.isUpdateable() &&
      Schema.sObjectType.iCare_Job_Identifier__c.fields.iCare_Lab_Country_Code__c.isUpdateable() &&
      Schema.sObjectType.iCare_Job_Identifier__c.fields.iCare_Country__c.isUpdateable() &&
      Schema.sObjectType.iCare_Job_Identifier__c.fields.iCare_ID_Number__c.isUpdateable() &&
      Schema.sObjectType.iCare_Job_Identifier__c.fields.iCare_Timezone__c.isUpdateable() &&
      Schema.sObjectType.iCare_Job_Identifier__c.fields.iCare_Year__c.isUpdateable()
    ) {
      upsert jobIdRecordsToUpsert;
    }
  }

  private Map<String, List<iCare_Job__c>> groupJobsByIds(
    List<iCare_Job__c> jobRecords
  ) {
    Map<String, List<iCare_Job__c>> jobIdWithJobs = new Map<String, List<iCare_Job__c>>();
    Set<Id> accountIds = new Set<Id>();
    Set<Id> labIds = new Set<Id>();
    for (iCare_Job__c jobRecord : jobRecords) {
      accountIds.add(jobRecord.iCare_Supplier__c);
      labIds.add(jobRecord.iCare_Testing_Location__c);
    }

    Map<Id, Account> accounts = getAccounts(accountIds);
    Map<Id, Testing_Location__c> test = getTestingLocations(labIds);

    for (iCare_Job__c jobRecord : jobRecords) {
      String siteCode = '';
      if (
        test != null &&
        jobRecord.iCare_Testing_Location__c != null &&
        test.get(jobRecord.iCare_Testing_Location__c) != null
      ) {
        if (
          jobRecord.iCare_Ops_System_Merge_Number__c != null &&
          jobRecord.iCare_Ops_System_Merge_Number__c.contains('nirvana')
        ) {
            system.debug('IST');
          siteCode = 'IST';
        } else {
            system.debug('testing');
          siteCode = test.get(jobRecord.iCare_Testing_Location__c)
            .iCare_Laboratory_Site_Code__c;
             system.debug('testing s' + siteCode);
        }
      }
      String countryCode = '';
        system.debug('accounts' + accounts);
        system.debug('jobRecord.iCare_Supplier__c' + jobRecord.iCare_Supplier__c);
        system.debug('countrySpecificInformation' + countrySpecificInformation);
        system.debug('accounts.get(jobRecord.iCare_Supplier__c).BillingCountryCode' + accounts.get(jobRecord.iCare_Supplier__c).BillingCountryCode);
      if (
        accounts != null &&
        jobRecord.iCare_Supplier__c != null &&
        accounts.size() > 0 &&
        accounts.get(jobRecord.iCare_Supplier__c) != null &&
        countrySpecificInformation.get(
          accounts.get(jobRecord.iCare_Supplier__c).BillingCountryCode
        ) != null
      ) {
        if (
          jobRecord.iCare_Ops_System_Merge_Number__c != null &&
          jobRecord.iCare_Ops_System_Merge_Number__c.contains('nirvana')
        ) {
            System.debug('countryCode tur');
          countryCode = 'TUR';
        } else {
          countryCode = countrySpecificInformation.get(
              accounts.get(jobRecord.iCare_Supplier__c).BillingCountryCode
            )
            .iCare_Three_Letter_Country_Code__c;
            System.debug('countryCode account'+countryCode);
        }
      }
      if (String.isBlank(siteCode) || String.isBlank(countryCode)) {
        continue;
      }

      //Example: TUR-IST-23
      String formattedJobId =
        countryCode +
        '-' +
        siteCode +
        '-' +
        currentYearValue;

      if (jobIdWithJobs.containsKey(formattedJobId)) {
        jobIdWithJobs.get(formattedJobId).add(jobRecord);
      } else {
        jobIdWithJobs.put(formattedJobId, new List<iCare_Job__c>{ jobRecord });
      }
    }
    return jobIdWithJobs;
  }

  private Map<Id, Account> getAccounts(Set<Id> accountIds) {
    Map<Id, Account> accounts = new Map<Id, Account>(
      [SELECT Id, BillingCountryCode FROM Account WHERE Id IN :accountIds with system_mode]
    );
    return accounts;
  }

  private Map<Id, User> getOwners(Set<Id> ownerIds) {
    Map<Id, User> owners = new Map<Id, User>(
      [SELECT Id, LanguageLocaleKey FROM User WHERE Id IN :ownerIds]
    );
    return owners;
  }

  private Map<Id, Testing_Location__c> getTestingLocations(Set<Id> labIds) {
    Map<Id, Testing_Location__c> testingLocations = new Map<Id, Testing_Location__c>(
      [
        SELECT Id, iCare_Laboratory_Site_Code__c
        FROM Testing_Location__c
        WHERE Id IN :labIds
      ]
    );
    return testingLocations;
  }

  private List<iCare_Job_Identifier__c> getJobIdentifierRecords(
    Map<String, List<iCare_Job__c>> jobIdWithJobs
  ) {
    Set<String> fomattedJobIds = new Set<String>();
    for (String fomattedJobId : jobIdWithJobs.keySet()) {
      fomattedJobId += '%';
      fomattedJobIds.add(fomattedJobId);
      fomattedJobId = fomattedJobId.substring(0, fomattedJobId.length() - 1);
    }

    List<iCare_Job_Identifier__c> jobIdRecords = [
      SELECT iCare_Job_ID_Formatted__c, iCare_ID_Number__c
      FROM iCare_Job_Identifier__c
      WHERE iCare_Job_ID_Formatted__c LIKE :fomattedJobIds
      WITH SECURITY_ENFORCED
    ];

    return jobIdRecords;
  }

  private iCare_Job_Identifier__c updateJobIdInformation(
    String formattedId,
    iCare_Job_Identifier__c jobIdRecord,
    List<iCare_Job__c> jobs
  ) {
    Integer currentNumber = Integer.valueOf(
      jobIdRecord.iCare_ID_Number__c.removeStart('0')
    );
    Integer nextNumber = currentNumber + 1;

    for (Integer i = nextNumber; i < nextNumber + jobs.size(); i++) {
      jobs[i - nextNumber].iCare_Job_ID__c = formattedId;

      Integer numberOfZeros = 7 - String.valueOf(i).length();
      for (Integer j = 0; j < numberOfZeros; j++) {
        jobs[i - nextNumber].iCare_Job_ID__c += '0';
      }
      jobs[i - nextNumber].iCare_Job_ID__c += String.valueOf(i);
    }

    currentNumber += jobs.size();
    //Add leading zeroes
    Integer numberOfZeros = 7 - String.valueOf(currentNumber).length();
    jobIdRecord.iCare_ID_Number__c = '';
    for (Integer i = 0; i < numberOfZeros; i++) {
      jobIdRecord.iCare_ID_Number__c += '0';
    }
    jobIdRecord.iCare_ID_Number__c += String.valueOf(currentNumber);
    return jobIdRecord;
  }

  private List<iCare_Job_Identifier__c> createNewJobIdRecords(
    Map<String, List<iCare_Job__c>> jobIdWithJobs
  ) {
    List<iCare_Job_Identifier__c> newJobIdRecords = new List<iCare_Job_Identifier__c>();
    for (String formattedJobId : jobIdWithJobs.keySet()) {
      iCare_Job_Identifier__c jobIdRecord = new iCare_Job_Identifier__c();
      List<String> jobIdSections = formattedJobId.split('-');
      List<iCare_Job__c> relatedJobs = jobIdWithJobs.get(formattedJobId);

      jobIdRecord.iCare_Country__c = jobIdSections[0];
      jobIdRecord.iCare_Lab_Country_Code__c = jobIdSections[1];
      jobIdRecord.iCare_ID_Number__c = generateJobNumber(relatedJobs.size());
      jobIdRecord.iCare_Timezone__c = this.getCountryTimeZone()
        .get(jobIdSections[0]);
      jobIdRecord.iCare_Year__c = Integer.valueOf(jobIdSections[2]);

      newJobIdRecords.add(jobIdRecord);

      for (Integer i = 0; i < relatedJobs.size(); i++) {
        String newJobId = formattedJobId;
        Integer numberOfZeros = 7 - String.valueOf(i).length();
        for (Integer j = 0; j < numberOfZeros; j++) {
          newJobId += '0';
        }
        newJobId += String.valueOf(i + 1);
        relatedJobs[i].iCare_Job_ID__c = newJobId;
      }
    }
    return newJobIdRecords;
  }

  public String generateJobNumber(Integer totalJobCount) {
    String jobNumber = '';

    String jobCount = String.valueOf(totalJobCount);
    Integer numberOfZeros = 7 - jobCount.length();
    for (Integer i = 0; i < numberOfZeros; i++) {
      jobNumber += '0';
    }
    jobNumber += jobCount;
    return jobNumber;
  }

  public void setiCarePortalURL(List<iCare_Job__c> jobs) {
    GTS_Portal portal = new GTS_Portal(NAME_FOR_PORTAL_URL);
    String portalUrl = portal.getiCarePortalBaseUrl();
    for (iCare_Job__c job : jobs) {
      job.iCare_Portal_URL__c = portalUrl;
    }
  }

  public void updatePortalStatusValues(
    List<iCare_Job__c> newJobs,
    Map<Id, iCare_Job__c> oldJobs
  ) {
    for (iCare_Job__c newJob : newJobs) {
      if (
        newJob.iCare_Job_Status__c == 'Job Submitted (iCare)' ||
        newJob.iCare_Job_Status__c == 'Job Submitted (Ops System)'
      ) {
        newJob.iCare_Job_Status_Portal__c = 'Job Submitted';
      } else if (
        oldJobs != null &&
        newJob != null &&
        oldJobs.get(newJob.Id) != null &&
        newJob.iCare_Job_Status__c !=
        oldJobs.get(newJob.Id)?.iCare_Job_Status__c
      ) {
        newJob.iCare_Job_Status_Portal__c = newJob.iCare_Job_Status__c;
      }

      if (
        oldJobs != null &&
        newJob != null &&
        oldJobs.get(newJob.Id) != null &&
        newJob.iCare_Job_Pending__c == true &&
        oldJobs.get(newJob.Id)?.iCare_Job_Pending__c != true
      ) {
        newJob.iCare_Subject_for_Email_Notifications__c =
          translateLabelValue(
            'iCare_Job_Pending_Email_Subject',
            newJob.iCare_Owner_Language__c
          ) +
          ' ' +
          newJob.iCare_Job_ID__c;
      }

      if (
        oldJobs != null &&
        newJob != null &&
        oldJobs.get(newJob.Id) != null &&
        newJob.iCare_Job_Pending__c == true &&
        oldJobs.get(newJob.Id)?.iCare_Job_Pending__c != true
      ) {
        newJob.iCare_Subject_for_Email_Notifications__c =
          translateLabelValue(
            'iCare_Job_Pending_Email_Subject',
            newJob.iCare_Owner_Language__c
          ) +
          ' ' +
          newJob.iCare_Job_ID__c;
      }
    }
  }
  public string translateLabelValue(
    String labelToTranslate,
    String languageToTranslateTo
  ) {
    String translatedLabel = System.Label.get(
      '',
      labelToTranslate,
      languageToTranslateTo
    );
    return translatedLabel;
  }

  /**
   * History:
   * 04-01-2024   IB-22    kamlesh.kahar   Generating different possible format to search on global search (workaround)
   */
  public static void generateSearchableJobIds(Set<Id> jobIds) {
    List<iCare_Job__c> jobs = [
      SELECT Id, iCare_Job_ID__c
      FROM iCare_Job__c
      WHERE Id IN :jobIds AND iCare_Job_ID__c != NULL
    ];

    List<Integer> patterns = new List<Integer>{ 2, 3, 4, 5, 6, 7, 8 };

    for (iCare_Job__c job : jobs) {
      job.iCare_Job_ID_TF__c = patternGenerator(
        job.iCare_Job_ID__c.substringAfterLast('-'),
        patterns,
        '-'
      );
    }

    if (!jobs.isEmpty()) {
      update jobs;
    }
  }

  @Future
  public static void generateSearchableJobIdsFuture(Set<Id> jobIds) {
    generateSearchableJobIds(jobIds);
  }

  /**
   * History:
   * 04-01-2024   IB-22    kamlesh.kahar   Generic pattern generator utility class.
   */
  public static String patternGenerator(
    String input,
    List<Integer> patterns,
    String separator
  ) {
    Integer length = input.length();
    Set<String> result = new Set<String>();
    for (Integer p : patterns) {
      for (Integer i = 0; i < length; i++) {
        if ((i + p) > length) {
          break;
        }
        result.add(input.substring(i, i + p));
      }
    }

    return String.join(result, separator);
  }
}