@isTest
private class APIUtil_Test {
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
     * Test the request method using GET with 2 parameters.
     *
     * @return void
     */
    @isTest static void testRequest_GET_1() {
        Test.setMock(HttpCalloutMock.class, new APIUtil_CalloutMock());

        Test.startTest();
            APIRequest result = APIUtil.request('GET', 'https://www.salesforce.com');

            System.assertEquals(200, result.statusCode);
            System.assertNotEquals(null, result.body);
        Test.stopTest();
    }

    /**
     * Test the request method using GET with 3 parameters.
     *
     * @return void
     */
    @isTest static void testRequest_GET_2() {
        Test.setMock(HttpCalloutMock.class, new APIUtil_CalloutMock());

        Test.startTest();
            APIRequest result = APIUtil.request('GET', 'https://www.salesforce.com', new Map<String, String>{ 'Content-Type' => 'application/json' });

            System.assertEquals(200, result.statusCode);
            System.assertNotEquals(null, result.body);
        Test.stopTest();
    }

    /**
     * Test the request method as failing using GET with 2 parameters.
     *
     * @return void
     */
    @isTest static void testRequest_GET_3() {
        Test.setMock(HttpCalloutMock.class, new APIUtil_CalloutMock(false));

        Test.startTest();
            APIRequest result = APIUtil.request('GET', 'https://www.salesforce.com');

            System.assertEquals(500, result.statusCode);
            System.assertEquals(null, result.body);
        Test.stopTest();
    }

    /**
     * Test the request method using POST.
     *
     * @return void
     */
    @isTest static void testRequest_POST() {
        Test.setMock(HttpCalloutMock.class, new APIUtil_CalloutMock());

        Test.startTest();
            APIRequest result = APIUtil.request('POST', 'https://www.salesforce.com');

            System.assertEquals(201, result.statusCode);
            System.assertNotEquals(null, result.body);
        Test.stopTest();
    }

    /**
     * Test the request method using PATCH.
     *
     * @return void
     */
    @isTest static void testRequest_PATCH() {
        Test.setMock(HttpCalloutMock.class, new APIUtil_CalloutMock());

        Test.startTest();
            APIRequest result = APIUtil.request('PATCH', 'https://www.salesforce.com');

            System.assertEquals(200, result.statusCode);
            System.assertNotEquals(null, result.body);
        Test.stopTest();
    }

    /**
     * Test the request method using PUT.
     *
     * @return void
     */
    @isTest static void testRequest_PUT() {
        Test.setMock(HttpCalloutMock.class, new APIUtil_CalloutMock());

        Test.startTest();
            APIRequest result = APIUtil.request('PUT', 'https://www.salesforce.com');

            System.assertEquals(200, result.statusCode);
            System.assertNotEquals(null, result.body);
        Test.stopTest();
    }

    /**
     * Test the request method using DELETE.
     *
     * @return void
     */
    @isTest static void testRequest_DELETE() {
        Test.setMock(HttpCalloutMock.class, new APIUtil_CalloutMock());

        Test.startTest();
            APIRequest result = APIUtil.request('DELETE', 'https://www.salesforce.com');

            System.assertEquals(200, result.statusCode);
            System.assertNotEquals(null, result.body);
        Test.stopTest();
    }
}