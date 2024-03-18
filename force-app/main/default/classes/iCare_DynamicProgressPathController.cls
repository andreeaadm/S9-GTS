/*
* ________________________________________________________________________________________________
* Controller class for Dynamic Progress Path LWC component of iCare Portal
* Component to show the historical path of the Job status
* ________________________________________________________________________________________________
* @author       Andres Morales
* @created      2023-05-01
* ________________________________________________________________________________________________
* @changes

* ________________________________________________________________________________________________
*/
public with sharing class iCare_DynamicProgressPathController {
    static final String ST_JOB_SUBMITTED = 'Job Submitted';
    static final String ST_SAMPLE_RECEIVED = 'Sample Received';
    static final String ST_TEST_IN_PROGESS = 'Test in Progress';
    static final String ST_TEST_REPORT_ISSUED = 'Test Report Issued';
    static final String ST_CANCELLED = 'Cancelled';

    static final String jobSubmittedW = 'JobSubmittedYellow.svg';
    static final String jobSubmittedY = 'JobSubmittedYellow.svg';
    static final String samplesReceivedW = 'SamplesReceivedWhite.svg';
    static final String samplesReceivedY = 'SamplesReceivedYellow.svg';
    static final String testingProgresW = 'TestingProgresWhite.svg';
    static final String testingProgresY = 'TestingProgresYellow.svg';
    static final String reportIssuedW = 'ReportIssuedWhite.svg';
    static final String reportIssuedY = 'ReportIssuedYellow.svg';
    static final String cancelledJob = 'CancelledYellow.svg';

    static final String trackCenterBlank = 'TrackCenterBlank.svg';
    static final String trackCenterOk = 'TrackCenterOk.svg';
    static final String trackCenterX = 'TrackCenterX.svg';
    
    @AuraEnabled(cacheable=true)
    public static List<JobTimestampWrapper> getJobTimestampWithImages(Id jobId) {
        List<JobTimestampWrapper> lstJobTimestampsWithImages = new List<JobTimestampWrapper>();

        try{
            //Get Job Status Picklist Values
            Map<String, String> mapStatus = getJobStatusPickListValues();

            String iCareJobId = '';
            String lastStatus = ST_JOB_SUBMITTED;
            //String progressDate = null;

            Integer completeValue = 0;
            String labelTesting = System.Label.iCare_Portal_Testing;
            String labelComplete = System.Label.iCare_Portal_Complete;

            //List of all timestamps for Job
            List<icare_Job_Timestamp__c> lstJobTimestamps = [
                    SELECT iCare_Is_Current_State__c, iCare_Job_Pending__c, iCare_Job_Status__c, iCare_Job_Timestamp__c,
                        iCare_Job__r.iCare_Job_ID__c
                    FROM icare_Job_Timestamp__c
                    WHERE  iCare_Job__c = :jobId
                    ORDER BY iCare_Is_Current_State__c DESC, iCare_Job_Timestamp__c DESC
            ];

            List<iCare_Job__c> lstJobs = [SELECT iCare_Job_ID__c, iCare_Pecentage_Completion__c FROM iCare_Job__c WHERE Id = :jobId];

            //Note: If timestamp record does not exist, take the info (iCare_Pecentage_Completion__c) from Job
            if(lstJobs != null && !lstJobs.isEmpty()) {
                iCareJobId = lstJobs[0].iCare_Job_ID__c;
                completeValue = lstJobs[0].iCare_Pecentage_Completion__c != null ? lstJobs[0].iCare_Pecentage_Completion__c.intValue() : 0;
            }

            //Insert default status (Show 4 status on screen) assign labels
            lstJobTimestampsWithImages.add(new JobTimestampWrapper('1', mapStatus.get(ST_JOB_SUBMITTED), jobSubmittedW, trackCenterOk, null, iCareJobId, lastStatus));
            lstJobTimestampsWithImages.add(new JobTimestampWrapper('2', mapStatus.get(ST_SAMPLE_RECEIVED), samplesReceivedW, trackCenterBlank, null, iCareJobId, lastStatus));
            lstJobTimestampsWithImages.add(new JobTimestampWrapper('3', mapStatus.get(ST_TEST_IN_PROGESS), testingProgresW, trackCenterBlank, null, iCareJobId, lastStatus));
            lstJobTimestampsWithImages.add(new JobTimestampWrapper('4', mapStatus.get(ST_TEST_REPORT_ISSUED), reportIssuedW, trackCenterBlank, null, iCareJobId, lastStatus));

            Integer index = 0;
            for(icare_Job_Timestamp__c timestamp : lstJobTimestamps){
                index++;
                //Only for the fist record, assign current status
                if (index == 1) {
                    String currentStatus = timestamp.iCare_Job_Status__c;  //Current status from timestamp always in english
                    lastStatus = currentStatus;
                    //Special case Cancelled
                    if (currentStatus.equalsIgnoreCase(ST_CANCELLED)){
                        currentStatus = lstJobTimestamps[0].iCare_Job_Status__c;
                        lastStatus = ST_CANCELLED;
                        lstJobTimestampsWithImages[3].progressLabel = mapStatus.get(ST_CANCELLED);
                        lstJobTimestampsWithImages[3].progressImage = cancelledJob;
                        lstJobTimestampsWithImages[3].progressTrackImage = trackCenterX;
                    }

                    //Setup images depending current status
                    if (currentStatus.startsWithIgnoreCase(ST_JOB_SUBMITTED)) {  //Job Submitted
                        if (timestamp.iCare_Job_Pending__c) {
                            lstJobTimestampsWithImages[0].progressTrackImage = trackCenterX;
                        } else {
                            lstJobTimestampsWithImages[0].progressTrackImage = trackCenterOk;
                        }
                        lstJobTimestampsWithImages[0].progressImage = jobSubmittedY;
                    } else if (currentStatus.equalsIgnoreCase(ST_SAMPLE_RECEIVED)){  //Sample Received
                        if (timestamp.iCare_Job_Pending__c) {
                            lstJobTimestampsWithImages[1].progressTrackImage = trackCenterX;
                        } else {
                            lstJobTimestampsWithImages[1].progressTrackImage = trackCenterOk;
                        }
                        lstJobTimestampsWithImages[0].progressImage = jobSubmittedY;
                        lstJobTimestampsWithImages[1].progressImage = samplesReceivedY;
                        lstJobTimestampsWithImages[0].progressTrackImage = trackCenterOk;
                    } else if (currentStatus.equalsIgnoreCase(ST_TEST_IN_PROGESS)){  //Test in Progress
                        if (timestamp.iCare_Job_Pending__c) {
                            lstJobTimestampsWithImages[2].progressTrackImage = trackCenterX;
                        } else {
                            lstJobTimestampsWithImages[2].progressTrackImage = trackCenterOk;
                        }
                        lstJobTimestampsWithImages[0].progressImage = jobSubmittedY;
                        lstJobTimestampsWithImages[1].progressImage = samplesReceivedY;
                        lstJobTimestampsWithImages[2].progressImage = testingProgresY;
                        lstJobTimestampsWithImages[2].progressLabel = labelTesting + ' ' + completeValue + labelComplete;
                        lstJobTimestampsWithImages[0].progressTrackImage = trackCenterOk;
                        lstJobTimestampsWithImages[1].progressTrackImage = trackCenterOk;
                    }else if (currentStatus.equalsIgnoreCase(ST_TEST_REPORT_ISSUED)){  //Test Report Issued
                        if (timestamp.iCare_Job_Pending__c) {
                            lstJobTimestampsWithImages[3].progressTrackImage = trackCenterX;
                        } else {
                            lstJobTimestampsWithImages[3].progressTrackImage = trackCenterOk;
                        }
                        lstJobTimestampsWithImages[0].progressImage = jobSubmittedY;
                        lstJobTimestampsWithImages[1].progressImage = samplesReceivedY;
                        lstJobTimestampsWithImages[2].progressImage = testingProgresY;
                        lstJobTimestampsWithImages[2].progressLabel = labelTesting + labelComplete.substring(1, labelComplete.length());
                        lstJobTimestampsWithImages[3].progressImage = reportIssuedY;
                        lstJobTimestampsWithImages[0].progressTrackImage = trackCenterOk;
                        lstJobTimestampsWithImages[1].progressTrackImage = trackCenterOk;
                        lstJobTimestampsWithImages[2].progressTrackImage = trackCenterOk;
                    }
                }
                //Assign dates with most recent record            
                if (lstJobTimestampsWithImages[0].progressDate == null && timestamp.iCare_Job_Status__c.startsWithIgnoreCase(ST_JOB_SUBMITTED)) {  //Job Submitted
                    lstJobTimestampsWithImages[0].progressDate = timestamp.iCare_Job_Timestamp__c.format();
                } else if (lstJobTimestampsWithImages[1].progressDate == null && timestamp.iCare_Job_Status__c.equalsIgnoreCase(ST_SAMPLE_RECEIVED)) {  //Sample Received
                    lstJobTimestampsWithImages[1].progressDate = timestamp.iCare_Job_Timestamp__c.format();
                } else if (lstJobTimestampsWithImages[2].progressDate == null && timestamp.iCare_Job_Status__c.equalsIgnoreCase(ST_TEST_IN_PROGESS)) {  //Test in Progress
                    lstJobTimestampsWithImages[2].progressDate = timestamp.iCare_Job_Timestamp__c.format();
                }else if (lstJobTimestampsWithImages[3].progressDate == null && timestamp.iCare_Job_Status__c.equalsIgnoreCase(ST_TEST_REPORT_ISSUED)) {  //Test Report Issued
                    lstJobTimestampsWithImages[3].progressDate = timestamp.iCare_Job_Timestamp__c.format();
                }else if (timestamp.iCare_Job_Status__c.equalsIgnoreCase(ST_CANCELLED)){  //Cancelled
                    lstJobTimestampsWithImages[3].progressDate = timestamp.iCare_Job_Timestamp__c.format();
                }
                if (index <= lstJobTimestampsWithImages.size()) {
                    //Assign internal Job Id
                    lstJobTimestampsWithImages[index-1].iCareJobId = timestamp.iCare_Job__r.iCare_Job_ID__c;
                    //Assign current status
                    lstJobTimestampsWithImages[index-1].currentStatus = lastStatus;
                }
            }
           
            return lstJobTimestampsWithImages;
        } catch (Exception e){
            system.debug('DynamicProgressPathController-Error: ' + e.getMessage());
            return lstJobTimestampsWithImages;
        }
    }

    private static Map<String, String> getJobStatusPickListValues() {
        //Get Job Status Picklist Values
        List<String> options = new List<String>();
        Map<String, String> mapOptions = new Map<String, String>();
        Schema.DescribeFieldResult fieldResult = iCare_Job__c.iCare_Job_Status_Portal__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry f : ple)
        {
            mapOptions.put(f.getValue(), f.getLabel());
            
        }
        return mapOptions;
    }

    public class JobTimestampWrapper {

        @AuraEnabled
        public String recordId {get; set;}
        @AuraEnabled
        public String progressLabel {get; set;}
        @AuraEnabled
        public String progressImage {get; set;}
        @AuraEnabled
        public String progressTrackImage {get; set;}
        @AuraEnabled
        public String progressDate {get; set;}
        @AuraEnabled
        public String iCareJobId {get; set;}
        @AuraEnabled
        public String currentStatus {get; set;}

        private JobTimestampWrapper  (String recordId, String progressLabel, String progressImage, String progressTrackImage, String progressDate, String iCareJobId, String currentStatus) {
            this.recordId = recordId;
            this.progressLabel = progressLabel;
            this.progressImage = progressImage;
            this.progressTrackImage = progressTrackImage;
            this.progressDate = progressDate;
            this.iCareJobId = iCareJobId;
            this.currentStatus = currentStatus;
        }
    }
}