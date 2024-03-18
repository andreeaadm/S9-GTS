/*******************************************************************************************
 * @author       Globant
 * @created      8-March-2024
 * @description  Test class to verify the functionality of AccountTrgHandler
 */
@IsTest
private class AccountTrgHandlerTest {
  @IsTest
  static void gtsProcessSharingLogicTest() {
    Account parent1 = GTSTestDataFactory.createAccount('ParentAccount1', true);
    Account parent2 = GTSTestDataFactory.createAccount('ParentAccount2', true);
    Account child = GTSTestDataFactory.createAccount('ChildAccount', false);
    child.ParentId = parent1.Id;
    insert child;

    Test.startTest();
    child.ParentId = parent2.Id;
    parent1.ParentId = parent2.Id;
    update new List<Account>{ child, parent1 };
    Test.stopTest();

    List<AsyncApexJob> asyncJobs = [
      SELECT Id
      FROM AsyncApexJob
      WHERE JobType = 'Queueable'
    ];

    System.assertEquals(
      2,
      asyncJobs.size(),
      'Expected Queueable job not enqueued'
    );
  }
}