public class INTK_iConnectIntegrationUtility {
    
    //Class Variables
    public class CustomException extends Exception {}
    public static final String CLIENT_ID = 'CLIENT_ID';
    public static final String CLIENT_SECRET = 'CLIENT_SECRET';
    public static final String ENDPOINT_SERVICE_URL_CREATE_LEAD = '/customer/data';
    public static final String ENDPOINT_SERVICE_URL_CREATE_JOB = '/job/request';
    public static final String ENDPOINT_SERVICE_URL_FETCH_REPORT = '/report/download';
    public static final String CAMPAIGN_ID = 'CAMPAIGN_ID';
    public static final String POST_METHOD = 'POST';
    public static final String GET_METHOD = 'GET';
    public static final String NAMED_CREDENTIALS = 'NAMED_CREDENTIALS';

    //Wrapper class for iConnect Lead JSON Payload
    public class iConnectLeadPayload {
        public String businessPhone;
        public String city;
        public String companyName;
        public String countryCode;
        public String description;
        public String email;
        public String externalSystem;
        public String externalSystemId;
        public String firstName;
        public String jobTitle;
        public String lastName;
        public String campaignCode;
        public String source;
        public String subject;
        public String state;
    }

    /** Username - Password based Authentication using named credentials
     */
    public static String basicAuthCallout(String namedCredentials, String serviceURL, String payload, String method, Map<String, String> headersMap){
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:'+namedCredentials +'' + serviceURL);
        req.setMethod(method);
        req.setTimeout(120000);
        req.setHeader('content-type', 'application/json');
        
        for (String headerKey : headersMap.keySet()) {
            if (headersMap.get(headerKey) != null) {
            	req.setHeader(headerKey, headersMap.get(headerKey));
            }
        }
        
        if (payload != null) {
            req.setBody(payload);
        }
        Http http = new Http();
        if(!Test.isRunningTest()){
            System.debug('---------namedCredentials='+namedCredentials);
            System.debug('---------serviceURL='+serviceURL);
            System.debug('---------payload='+payload);
            System.debug('---------headersMap='+headersMap);
            HTTPResponse res = http.send(req);
            System.debug('---------res.getStatusCode()='+res.getStatusCode());
            System.debug('---------res.getBody()='+res.getBody());
            return String.valueOf(res.getStatusCode()) + ':responseBody:' +res.getBody(); 
        }
        return '200';
    }
    
}