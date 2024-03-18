@isTest
global class IncheckSubBatchableMockResponseGenerator implements HttpCalloutMock{
    global HTTPResponse respond(HTTPRequest request) {
        System.assert(
            request.getEndpoint().contains('/inCheckSubscriptionStatus?') ,
            'Testing the /inCheckSubscriptionStatus'
        );
        
        List<String> parameters = request.getEndpoint()
            .substringAfter('?')
            .split('&');
        Map<String, String> param = new Map<String, String>();
        for (String p : parameters) {
            List<String> ab = p.split('=');
            param.put(ab[0], ab[1]);
        }
        
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        
        if (request.getEndpoint().contains('/inCheckSubscriptionStatus?')) {
            if (request.getMethod() == 'GET') {
                response = getFacilities(response, request, param);
            } 
        }  
        else {
            response.setBody('{"result":{"errorMessage":"Unknown error."}}');
            response.setStatusCode(500);
        }
        return response;
    }
    
    private HTTPResponse getFacilities(
        HTTPResponse response,
        HTTPRequest request,
        Map<String, String> param
    ) {
        System.assert(
            param.containsKey('organizationGUID'),
            'Testing organizationGUID'
        );
        String organizationGUID = param.get('organizationGUID');
        if (getIncheckDetailsByOrganizationGUID.containsKey(organizationGUID)) {
            response.setBody(getIncheckDetailsByOrganizationGUID.get(organizationGUID));
            response.setStatusCode(200);
        } else {
            response.setBody('{"result":{"errorMessage":"No results found."}}');
            response.setStatusCode(500); // ZDHC says 500.
        }
        return response;
    }
    
    public static Map<String, String> getIncheckDetailsByOrganizationGUID = new Map<String, String>{
        'D77D2CB25ABB5BABE0530100007F44A5' => '{"result": {"success": true},"InCheckStatus": "Active","OrganisationAID": "A792FD98","InCheckExpirationDate": "2024-06-14","InCheckStartDate": "2023-06-14"}',
            '9281631729E67F0CE0530100007FFD4B' => '{"result": {"success": true},"InCheckStatus": "Active","OrganisationAID": "A792FD98","InCheckExpirationDate": "2024-06-14","InCheckStartDate": "2023-06-14"}',
            '4CDE5F6F15E1416FE0530100007F256A' => '{"result": {"success": true},"InCheckStatus": "Active","OrganisationAID": "A792FD98","InCheckExpirationDate": "2024-06-14","InCheckStartDate": "2023-06-14"}',
            '6F731E04E38F6BFBE0530100007F90C8' => '{"result": {"success": true},"InCheckStatus": "Active","OrganisationAID": "A792FD98","InCheckExpirationDate": "2024-06-14","InCheckStartDate": "2023-06-14"}',
            '9010B9336CB85B14E0530100007FA3D9' => '{"result": {"success": true},"InCheckStatus": "Active","OrganisationAID": "A792FD98","InCheckExpirationDate": "2024-06-14","InCheckStartDate": "2023-06-14"}',
            '896197B6C7CD0B67E0530100007F7CF4' => '{"result": {"success": true},"InCheckStatus": "Active","OrganisationAID": "A792FD98","InCheckExpirationDate": "2024-06-14","InCheckStartDate": "2023-06-14"}',
            '7E0DA640555F1B6FE0530100007F5348' => '{"result": {"success": true},"InCheckStatus": "Active","OrganisationAID": "A792FD98","InCheckExpirationDate": "2024-06-14","InCheckStartDate": "2023-06-14"}',
            'B1142E0F542A5467E0530100007FEB0A' => '{"result": {"success": true},"InCheckStatus": "Active","OrganisationAID": "A792FD98","InCheckExpirationDate": "2024-06-14","InCheckStartDate": "2023-06-14"}',
            '90426863F26007D1E0530100007F7DA8' => '{"result": {"success": true},"InCheckStatus": "Active","OrganisationAID": "A792FD98","InCheckExpirationDate": "2024-06-14","InCheckStartDate": "2023-06-14"}',
            '5A01F02025207C05E0530100007F79BD' => '{"result": {"success": true},"InCheckStatus": "Active","OrganisationAID": "A792FD98","InCheckExpirationDate": "2024-06-14","InCheckStartDate": "2023-06-14"}',
            '7397A19C068F2F6BE0530100007F69C9' => '{"result": {"success": true},"InCheckStatus": "Active","OrganisationAID": "A792FD98","InCheckExpirationDate": "2024-06-14","InCheckStartDate": "2023-06-14"}',
            '8B09054ADA8366E0E0530100007F1FD7' => '{"result": {"success": true},"InCheckStatus": "Active","OrganisationAID": "A792FD98","InCheckExpirationDate": "2024-06-14","InCheckStartDate": "2023-06-14"}',
            '9C0ACD17FFC66CEBE0530100007FFA84' => '{"result": {"success": true},"InCheckStatus": "Active","OrganisationAID": "A792FD98","InCheckExpirationDate": "2024-06-14","InCheckStartDate": "2023-06-14"}',
            '877FB7B0F0C2124BE0530100007F7C0A' => '{"result": {"success": true},"InCheckStatus": "Active","OrganisationAID": "A792FD98","InCheckExpirationDate": "2024-06-14","InCheckStartDate": "2023-06-14"}',
            '7E76598DF53B3439E0530100007F8029' => '{"result": {"success": true},"InCheckStatus": "Active","OrganisationAID": "A792FD98","InCheckExpirationDate": "2024-06-14","InCheckStartDate": "2023-06-14"}',
            '8756DEE1C86231C6E0530100007F274B' => '{"result": {"success": true},"InCheckStatus": "Active","OrganisationAID": "A792FD98","InCheckExpirationDate": "2024-06-14","InCheckStartDate": "2023-06-14"}',
            '628D479F070E7261E0530100007F90C3' => '{"result": {"success": true},"InCheckStatus": "Active","OrganisationAID": "A792FD98","InCheckExpirationDate": "2024-06-14","InCheckStartDate": "2023-06-14"}',
            '416685DBDF9777FFE0530100007F9205' => '{"result": {"success": true},"InCheckStatus": "Active","OrganisationAID": "A792FD98","InCheckExpirationDate": "2024-06-14","InCheckStartDate": "2023-06-14"}',
            '9863F9D7B4CA3E8BE0530100007F890A' => '{"result": {"success": true},"InCheckStatus": "Active","OrganisationAID": "A792FD98","InCheckExpirationDate": "2024-06-14","InCheckStartDate": "2023-06-14"}',
            '6DDD5205A9957D8EE0530100007F4AF4' => '{"result": {"success": true},"InCheckStatus": "Active","OrganisationAID": "A792FD98","InCheckExpirationDate": "2024-06-14","InCheckStartDate": "2023-06-14"}',
            'B07D73CC40AB541AE0530100007FB907' => '{"result": {"success": true},"InCheckStatus": "Active","OrganisationAID": "A792FD98","InCheckExpirationDate": "2024-06-14","InCheckStartDate": "2023-06-14"}',
            '54013893EDD747F6E0530100007F8A01' => '{"result": {"success": true},"InCheckStatus": "Active","OrganisationAID": "A792FD98","InCheckExpirationDate": "2024-06-14","InCheckStartDate": "2023-06-14"}',
            '5C4827F331A671E1E0530100007FB2E8' => '{"result": {"success": true},"InCheckStatus": "Active","OrganisationAID": "A792FD98","InCheckExpirationDate": "2024-06-14","InCheckStartDate": "2023-06-14"}',
            '773BA3FF579B110DE0530100007F8F19' => '{"result": {"success": true},"InCheckStatus": "Active","OrganisationAID": "A792FD98","InCheckExpirationDate": "2024-06-14","InCheckStartDate": "2023-06-14"}',
            '5A01F02027FD7C05E0530100007F79BD' => '{"result": {"success": true},"InCheckStatus": "Active","OrganisationAID": "A792FD98","InCheckExpirationDate": "2024-06-14","InCheckStartDate": "2023-06-14"}',
            '8D049071E69E4C00E0530100007FD488' => '{"result": {"success": true},"InCheckStatus": "Subscribed but not yet activated/used","OrganisationAID": "A792FD98","InCheckExpirationDate": "2024-06-14","InCheckStartDate": "2023-06-14"}',
            '8CFDDE43E65F70EAE0530100007FF4B5' => '{"result": {"success": true},"InCheckStatus": "Subscribed but not yet activated/used","OrganisationAID": "A792FD98","InCheckExpirationDate": "2024-06-14","InCheckStartDate": "2023-06-14"}',
            '98357423DCE15326E0530100007F8905' => '{"result": {"success": true},"InCheckStatus": "Subscribed but not yet activated/used","OrganisationAID": "A792FD98","InCheckExpirationDate": "2024-06-14","InCheckStartDate": "2023-06-14"}',
            '7397AF93ED4F3371E0530100007F1C26' => '{"result": {"success": true},"InCheckStatus": "Subscribed but not yet activated/used","OrganisationAID": "A792FD98","InCheckExpirationDate": "2024-06-14","InCheckStartDate": "2023-06-14"}',
            '89A586854362151EE0530100007F783A' => '{"result": {"success": true},"InCheckStatus": "Subscribed but not yet activated/used","OrganisationAID": "A792FD98","InCheckExpirationDate": "2024-06-14","InCheckStartDate": "2023-06-14"}',
            '6498421CE2842F93E0530100007FEDA6' => '{"result": {"success": true},"InCheckStatus": "Subscribed but not yet activated/used","OrganisationAID": "A792FD98","InCheckExpirationDate": "2024-06-14","InCheckStartDate": "2023-06-14"}',
            '5A8CE1DF10F65052E0530100007FFCCF' => '{"result": {"success": true},"InCheckStatus": "Subscribed but not yet activated/used","OrganisationAID": "A792FD98","InCheckExpirationDate": "2024-06-14","InCheckStartDate": "2023-06-14"}',
            '9980AA535CF23BD4E0530100007FE2F8' => '{"result": {"success": true},"InCheckStatus": "Subscribed but not yet activated/used","OrganisationAID": "A792FD98","InCheckExpirationDate": "2024-06-14","InCheckStartDate": "2023-06-14"}',
            '9BB52CFA80564DD2E0530100007FFD58' => '{"result": {"success": true},"InCheckStatus": "Subscribed but not yet activated/used","OrganisationAID": "A792FD98","InCheckExpirationDate": "2024-06-14","InCheckStartDate": "2023-06-14"}',
            '674283E762183E79E0530100007F426A' => '{"result": {"success": true},"InCheckStatus": "Subscribed but not yet activated/used","OrganisationAID": "A792FD98","InCheckExpirationDate": "2024-06-14","InCheckStartDate": "2023-06-14"}',
            '9458BE1313371B3CE0530100007FE4BE' => '{"result": {"success": true},"InCheckStatus": "Subscribed but not yet activated/used","OrganisationAID": "A792FD98","InCheckExpirationDate": "2024-06-14","InCheckStartDate": "2023-06-14"}',
            '5D9C762C1C7522EAE0530100007F1C24' => '{"result": {"success": true},"InCheckStatus": "Subscribed but not yet activated/used","OrganisationAID": "A792FD98","InCheckExpirationDate": "2024-06-14","InCheckStartDate": "2023-06-14"}',
            '6E9359D43BE8766EE0530100007F30EF' => '{"result": {"success": true},"InCheckStatus": "Subscribed but not yet activated/used","OrganisationAID": "A792FD98","InCheckExpirationDate": "2024-06-14","InCheckStartDate": "2023-06-14"}'
            };
                }