@isTest
private class Batch_SObjectDML_Test {

	static Account a;
	static List<Contact> contacts;
    static {
        a = TestDataFactory.createAccount();
    }
	
	// ##################################################
    // Description: Batch_SObjectDML update 200 records
    // Expected result: no errors
    // ##################################################
	@isTest static void test_1_1() {
		
		contacts = TestDataFactory.createContacts(200, false, a.Id);		
		Test.startTest();

		Batch_SObjectDML b = new Batch_SObjectDML(contacts, 'update', null);

		// Execute out batch
		Database.executeBatch(b, 200);

		Test.stopTest();

	}

	// ##################################################
    // Description: Batch_SObjectDML insert 200 records
    // Expected result: no errors
    // ##################################################
	@isTest static void test_1_2() {

		List<Contact> newContacts = new List<Contact>();
		for(Integer i = 0; i < 1; i++) {
			Contact c = new Contact(AccountId=a.Id, LastName='Testerton_1_2'+i, Email='TestSObjectDML_1_2'+i+'@gmail.com');
			newContacts.add(c);
		}
		
		Test.startTest();

		Batch_SObjectDML b = new Batch_SObjectDML(newContacts, 'insert', null);

		// Execute out batch
		Database.executeBatch(b, 200);

		Test.stopTest();
	}
	
}