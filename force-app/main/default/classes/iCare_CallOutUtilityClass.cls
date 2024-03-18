/*******************************************************************************************
 * @Name         iCare_CallOutUtilityClass
 * @Author       Praveen Kumar R
 * @Description  This class is used to make API callout.
 *******************************************************************************************/
public inherited sharing class iCare_CallOutUtilityClass {
  public class CustomException extends Exception {
  }
  public static final String CLIENT_ID = 'CLIENT_ID';
  public static final String CLIENT_SECRET = 'CLIENT_SECRET';
  public static final String ENDPOINT_SERVICE_URL_CREATE_LEAD = '/customer/data';
  public static final String ENDPOINT_SERVICE_URL_CREATE_JOB = '/job/request';
  public static final String ENDPOINT_SERVICE_URL_FETCH_REPORT = '/report/download';
  public static final String CAMPAIGN_ID = 'CAMPAIGN_ID';
  public static final String POST_METHOD = 'POST';
  public static final String GET_METHOD = 'GET';
  public static final String NAMED_CREDENTIALS = 'NAMED_CREDENTIALS';

  /*
    public static String makeCalloutRequest(String baseURL, String serviceURL, String payload, String method, Map<String, String> headersMap) {
        
        // Setup HTTP request
        HTTPRequest request = new HTTPRequest();
        request.setMethod(method);
        request.setEndpoint(baseURL + serviceURL);
        request.setTimeout(120000); 
        if (payload != null) {
            request.setBody(payload);
        }
        
        for (String headerKey : headersMap.keySet()) {
            request.setHeader(headerKey, headersMap.get(headerKey));
        }
        
        Http http = new Http();
        Httpresponse response = http.send(request);
        // if response is unauthorized request
        if (response.getStatusCode() == 401) {
            throw new CustomException(response.getStatus());
        } /*else if (response.getStatusCode() != 200) {
                throw new CustomException(response.getStatus());
                }                                
        return response.getBody();
    }
    
    
    /** Username - Password based Authentication using named credentials
     */
  public static String basicAuthCallout(
    String serviceURL,
    String payload,
    String method,
    Map<String, String> headersMap,
    String namedCredentials
  ) {
    HttpRequest req = new HttpRequest();
    req.setEndpoint('callout:' + namedCredentials + '' + serviceURL);
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
    HTTPResponse res = http.send(req);
    //System.debug(res.getBody());

    return String.valueOf(res.getStatusCode()) +
      ':responseBody:' +
      res.getBody();
  }
}