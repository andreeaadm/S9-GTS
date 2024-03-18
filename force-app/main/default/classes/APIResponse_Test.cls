@isTest
private class APIResponse_Test {
    /**
     * Create test data.
     *
     * @return void
     */
    @testSetup static void testData(){
        List<Account> accountList = createAccounts(200, true);
    }

    /**
     * Return a List of Account records.
     *
     * @param  Integer  count
     * @param  Boolean  store
     * @return List<Account>
     */
    static List<Account> createAccounts(Integer count, Boolean store) {
        return TestDataFactory.createAccounts(count, store);
    }
    
    /**
     * Test the APIResponse inner class with 2 parameters.
     *
     * @return void
     */
    @isTest static void testAPIResponse_1() {
        Test.startTest();
            APIResponse result = new APIResponse('OK', 200);

            System.assertEquals(0, result.size);
            System.assertEquals('OK', result.status);
            System.assertEquals(200, result.statusCode);
        Test.stopTest();
    }

    /**
     * Test the APIResponse inner class with 3 parameters with a single object.
     *
     * @return void
     */
    @isTest static void testAPIResponse_2() {
        Account account = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
            APIResponse result = new APIResponse('OK', 200, account);

            System.assertEquals(1, result.objList.size());
            System.assertEquals(1, result.size);
            System.assertEquals('OK', result.status);
            System.assertEquals(200, result.statusCode);
        Test.stopTest();
    }

    /**
     * Test the APIResponse inner class with 3 parameters with a collection of objects.
     *
     * @return void
     */
    @isTest static void testAPIResponse_3() {
        List<Account> accountList = [SELECT Id FROM Account];

        Test.startTest();
            APIResponse result = new APIResponse('OK', 200, accountList);

            System.assertEquals(200, result.objList.size());
            System.assertEquals(200, result.size);
            System.assertEquals('OK', result.status);
            System.assertEquals(200, result.statusCode);
        Test.stopTest();
    }

    /**
     * Test the APIResponse inner class with 3 parameters with a single message.
     *
     * @return void
     */
    @isTest static void testAPIResponse_4() {
        Test.startTest();
            APIResponse result = new APIResponse('Bad Request', 400, 'Lorem ipsum dolor sit amet.');

            System.assertEquals(1, result.messages.size());
            System.assertEquals('Bad Request', result.status);
            System.assertEquals(400, result.statusCode);
        Test.stopTest();
    }

    /**
     * Test the APIResponse inner class with 3 parameters with a collection of messages.
     *
     * @return void
     */
    @isTest static void testAPIResponse_5() {
        List<Account> accountList = [SELECT Id FROM Account];

        Test.startTest();
            APIResponse result = new APIResponse('Bad Request', 400, new List<String> { 'Lorem ipsum dolor sit amet.', 'Foo Bar', 'Hello world!' });

            System.assertEquals(3, result.messages.size());
            System.assertEquals('Bad Request', result.status);
            System.assertEquals(400, result.statusCode);
        Test.stopTest();
    }

    /**
     * Test the APIResponse inner class with 3 parameters with a map of error messages to values.
     *
     * @return void
     */
    @isTest static void testAPIResponse_6() {
        List<Account> accountList = [SELECT Id FROM Account];

        Test.startTest();
            APIResponse result = new APIResponse('Bad Request', 400, new Map<Object, SObject> { 'Account' => accountList[0] });

            System.assertEquals(1, result.objMap.keyset().size());
            System.assertEquals('Bad Request', result.status);
            System.assertEquals(400, result.statusCode);
        Test.stopTest();
    }

}