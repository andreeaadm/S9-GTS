/*******************************************************************************************
* @Name         iCare_MockHttpResponseGenerator 
* @Author       Praveen Kumar R
* @Description  This acts as the mock response generator.
*******************************************************************************************/
@isTest
global class iCare_MockHttpResponseGenerator implements HttpCalloutMock {
    // Implement this interface method
    global HTTPResponse respond(HTTPRequest req) {
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"message": "successfully received the data"}');
        if (req.getEndpoint().containsIgnoreCase(iCare_CallOutUtilityClass.ENDPOINT_SERVICE_URL_FETCH_REPORT)) {
            res.setBody('{"filePath": "https://www.intertek.com/files/sampleReport.pdf"}');
        }
        res.setStatusCode(200);
        return res;
    }
}