public class APIUtil {
    /*
    |--------------------------------------------------------------------------
    | Request
    |--------------------------------------------------------------------------
    |
    | The methods written below function as utility functions for making
    | callouts to remote server. Additionally, it uses an inner class
    | that operates as scaffolding for consolodating the response.
    |
    */

    /**
     * Make a request to the specified endpoint.
     *
     * @param  String  method
     * @param  String  endpoint
     * @return APIRequest
     */
    public static APIRequest request(String method, String endpoint) {
        return APIUtil.doRequest(method, endpoint, null);
    }

    /**
     * Make a request to the specified endpoint.
     *
     * @param  String  method
     * @param  String  endpoint
     * @param  Map<String, String>  headerMap
     * @return APIRequest
     */
    public static APIRequest request(String method, String endpoint, Map<String, String> headerMap) {
        return APIUtil.doRequest(method, endpoint, headerMap);
    }

    /**
     * Make a request using the specified method to the endpoint.
     *
     * @param  String  method
     * @param  String  endpoint
     * @param  Map<String, String>  headerMap
     * @return APIRequest
     */
    private static APIRequest doRequest(String method, String endpoint, Map<String, String> headerMap) {
        HttpRequest request = new HttpRequest();
        request.setMethod(method);
        request.setEndpoint(endpoint);

        if (headerMap != null && headerMap.size() > 0) {
            for (String key : headerMap.keySet()) {
                request.setHeader(key, headerMap.get(key));
            }
        }

        Http http = new Http();

        HttpResponse response = http.send(request);

        if (APIUtil.successRequest(method, response.getStatusCode())) {
            return new APIRequest(response.getBody(), APIUtil.getHeaders(response), response.getStatus(), response.getStatusCode());
        }
        else {
            return new APIRequest(APIUtil.getHeaders(response), response.getStatus(), response.getStatusCode());
        }
    }

    /**
     * Return a String to String Map of Headers from the response.
     *
     * @param  HttpResponse  response
     * @return Map<String, String>
     */
    private static Map<String, String> getHeaders(HttpResponse response) {
        Map<String, String> headerMap = new Map<String, String>();

        for (String key : response.getHeaderKeys()) {
            headerMap.put(key, response.getHeader(key));
        }

        return headerMap;
    }

    /**
     * Checks if a request was successful.
     *
     * @param  String  method
     * @param  Integer  statusCode
     * @return Boolean
     */
    private static Boolean successRequest(String method, Integer statusCode) {
        switch on method {
            when 'POST' {
                return (statusCode == 201) ? true : false;
            }
            when else {
                return (statusCode == 200) ? true : false;
            }
        }
    }

    /*
    |--------------------------------------------------------------------------
    | APIResponse
    |--------------------------------------------------------------------------
    |
    | The methods written here are utilised when handling requests
    | made to Salesforce from the remote and should use common,
    | generic, reusable functions related to said responses.
    |
    */
}