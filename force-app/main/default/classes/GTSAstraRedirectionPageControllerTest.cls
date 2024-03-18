/*
* @author       Globant
* @created      17-Jan-2024
* @description  Test class to verify the functionality of GTSAstraRedirectionPageController
*/
@isTest
public class GTSAstraRedirectionPageControllerTest {

    @isTest
    private static void testRedirect() {
        String astraId = '1234';

        iCare_Job__c jobRecord = new iCare_Job__c();
        jobRecord.iCare_Ops_System_Job_Number__c = astraId;
        insert jobRecord;
        
        Test.startTest();
        PageReference pageRef = GTSAstraRedirectionPageController.trackJobRedirection(astraId);
        Test.stopTest();
        //Positive - Verify that the result returns a page reference
        System.assertNotEquals(null, pageRef, 'A page reference should have been returned');
        System.assertEquals(true,pageRef.getRedirect(), 'The returned page reference should have had the redirect attribute');
        System.assertEquals(true,pageRef.getUrl().contains(jobRecord.Id),'The URL should have contained the job\'s Ops System number');
    }

    @isTest
    private static void testRedirectWithInvalidId() {
        String invalidAstraId = '5555';

        Test.startTest();
        Exception expectedException;
        try {
            PageReference pageRef = GTSAstraRedirectionPageController.trackJobRedirection(invalidAstraId);
        } catch(ListException ex) {
			expectedException = ex;
        } catch(Exception ex) {
        }
        Test.stopTest();
        //Negative - Verify that searching for an invalid Astra ID results in a list exception being thrown
        System.assertNotEquals(null, expectedException, 'The system should have thrown a list exception as no Job should have been found');
    }

}