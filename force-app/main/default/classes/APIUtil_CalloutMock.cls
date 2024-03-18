@isTest
public class APIUtil_CalloutMock implements HttpCalloutMock {
    /**
     * Constructor.
     *
     * @return void
     */
    public APIUtil_CalloutMock() {
        this.success = true;
    }

    /**
     * Constructor.
     *
     * @param  Boolean  success
     * @return void
     */
    public APIUtil_CalloutMock(Boolean success) {
        this.success = success;
    }

    /**
     * Stores the HttpRequest.
     *
     * @var HttpRequest
     */
    private HttpRequest request;

    /**
     * Stores whether the response should be a success or error.
     *
     * @var Boolean
     */
    private Boolean success;

    /**
     * Return the HttpResponse from the HttpRequest.
     *
     * @param  HttpRequest  request
     * @return HttpResponse
     */
    public HttpResponse respond(HttpRequest request) {
        this.request = request;

        switch on request.getMethod() {
            when 'GET' {
                return (success) ? doSuccessResponse(200) : doErrorResponse(500);
            }
            when 'POST' {
                return (success) ? doSuccessResponse(201) : doErrorResponse(500);
            }
            when 'PATCH' {
                return (success) ? doSuccessResponse(200) : doErrorResponse(500);
            }
            when 'PUT' {
                return (success) ? doSuccessResponse(200) : doErrorResponse(500);
            }
            when 'DELETE' {
                return (success) ? doSuccessResponse(200) : doErrorResponse(500);
            }
            when else {
                return null;
            }
        }
    }

    /**
     * Return a success HttpResponse.
     *
     * @param  Integer  statusCode
     * @return HttpResponse
     */
    private HttpResponse doSuccessResponse(Integer statusCode) {
        HttpResponse response = new HttpResponse();
        response.setBody('{ "foo" : "bar" }');
        response.setHeader('Content-Type', 'application/json');
        response.setStatusCode(statusCode);
        
        return response;
    }

    /**
     * Return an error HttpResponse.
     *
     * @param  Integer  statusCode
     * @return HttpResponse
     */
    private HttpResponse doErrorResponse(Integer statusCode) {
        HttpResponse response = new HttpResponse();
        response.setStatusCode(statusCode);
        
        return response;
    }
}