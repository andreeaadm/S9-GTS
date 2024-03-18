public without sharing class GTSJobRequestSave {
	@AuraEnabled
	public static icare_Job_Request__c saveJobRequest(icare_Job_Request__c jobRequest) {
		if(jobRequest.Id == null){
			insert jobRequest;
		}else {
			update jobRequest;
		}
		return jobRequest;
	}

	@AuraEnabled
	public static icare_Job_Request__c saveJobRequestAndAssociatedJobRequest(icare_Job_Request__c jobRequest, Id jobId) {
		if(jobRequest.Id == null){
			insert jobRequest;

			GTS_Associated_Job_Request__c associatedJobRequest = new GTS_Associated_Job_Request__c(
				GTS_Job_Request__c = jobRequest.Id, GTS_Job__c = jobId
			);
			insert associatedJobRequest;
		}else {
			update jobRequest;
		}
		return jobRequest;
	}
}