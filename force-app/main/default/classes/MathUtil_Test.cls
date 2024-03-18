@isTest
private class MathUtil_Test {
    /**
     * Test the random method on the MathUtil class.
     *
     * @return void
     */
    @isTest static void testRandom() {
        Test.startTest();
            Integer result = MathUtil.random(10, 15);

            System.assert(result >= 10);
            System.assert(result <= 15);
        Test.stopTest();
    }
}