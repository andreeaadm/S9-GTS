/**
 * Author: Kamlesh Kahar
 * History:
 * IB-22    Kamlesh.kahar   Created.
 */
public with sharing class iCare_GenerateSearchableJobIdsBatch implements Database.Batchable<SObject>{
    public Iterable<SObject> start(Database.BatchableContext BC) {
        String query = 'SELECT ID, iCare_Job_ID__c FROM iCare_Job__c WHERE iCare_Job_ID__c != NULL';
		return Database.getQueryLocator(query);
	}

    public void execute(Database.BatchableContext BC, List<iCare_Job__c> scope) {    
        List<Integer> patterns;
        for (iCare_Job__c job :scope) {
            String jobId = job.iCare_Job_ID__c.substringAfterLast('-');
            patterns = jobId.length() == 11 ? new List<Integer>{2,3,4,5,6,7,8,9,10} : new List<Integer>{2,3,4,5,6,7,8};
            job.iCare_Job_ID_TF__c = iCare_JobUtil.patternGenerator(jobId, patterns, '-');
        }
        update scope;
    }
	
	public void finish(Database.BatchableContext BC) {}
}