@isTest
public with sharing class EmailToCaseHandlerTest {
    @isTest static void test_1_1() {
        EmailToCaseHandler em = new EmailToCaseHandler();
        em.handleInboundEmail(null, null);
    }
}