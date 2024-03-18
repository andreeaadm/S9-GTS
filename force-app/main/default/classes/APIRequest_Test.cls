@isTest
private class APIRequest_Test {
    /**
     * Test the APIUtil.Request inner class with 2 parameters.
     *
     * @return void
     */
    @isTest static void testAPIUtil_Request_1() {
        Test.startTest();
            APIRequest result = new APIRequest('OK', 200);

            System.assertEquals(null, result.body);
            System.assertEquals(null, result.headerMap);
            System.assertEquals('OK', result.status);
            System.assertEquals(200, result.statusCode);
        Test.stopTest();
    }

    /**
     * Test the APIUtil.Request inner class with 3 parameters.
     *
     * @return void
     */
    @isTest static void testAPIUtil_Request_2() {
        Test.startTest();
            APIRequest result = new APIRequest(new Map<String, String> { 'Content-Type' => 'application/json' }, 'OK', 200);

            System.assertEquals(null, result.body);
            System.assertNotEquals(null, result.headerMap);
            System.assertEquals('OK', result.status);
            System.assertEquals(200, result.statusCode);
        Test.stopTest();
    }

    /**
     * Test the APIUtil.Request inner class with 3 parameters.
     *
     * @return void
     */
    @isTest static void testAPIUtil_Request_3() {
        Test.startTest();
            APIRequest result = new APIRequest('{ \'foo\' : \'bar\' }', 'OK', 200);

            System.assertNotEquals(null, result.body);
            System.assertEquals(null, result.headerMap);
            System.assertEquals('OK', result.status);
            System.assertEquals(200, result.statusCode);
        Test.stopTest();
    }

    /**
     * Test the APIUtil.Request inner class with 4 parameters.
     *
     * @return void
     */
    @isTest static void testAPIUtil_Request_4() {
        Test.startTest();
            APIRequest result = new APIRequest('{ \'foo\' : \'bar\' }', new Map<String, String> { 'Content-Type' => 'application/json' }, 'OK', 200);

            System.assertNotEquals(null, result.body);
            System.assertNotEquals(null, result.headerMap);
            System.assertEquals('OK', result.status);
            System.assertEquals(200, result.statusCode);
        Test.stopTest();
    }
}